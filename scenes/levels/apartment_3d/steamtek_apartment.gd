extends SteamtekTransitionLevel3D

const PROGRESS_STATE_META := "steamtek_apartment_progress"
const TAKE_ALL_HOLD_SECONDS := 0.6

@onready var title_label: Label = $TransitionUI/Title
@onready var objective_label: Label = $TransitionUI/Objective
@onready var message_label: Label = $TransitionUI/Message
@onready var exit_door: SteamtekZoneDoor3D = $ExitDoor
@onready var storage_window: Control = $TransitionUI/StorageWindow
@onready var storage_panel: SteamtekItemGridPanel = $TransitionUI/StorageWindow/Panel
@onready var your_items_panel: SteamtekItemGridPanel = $TransitionUI/StorageWindow/YourItemsPanel
@onready var note_marker: Node3D = $QuestNoteInteractable/NoteQuestMarker
@onready var storage_marker: Node3D = $StarterStorageInteractable/StorageQuestMarker
@onready var door_outline: Node3D = $ExitDoor/DoorOutline

var progress: Dictionary = {}
var message_serial := 0
var _take_all_hold_time := 0.0
var _suppress_storage_reopen := false
var _dialogue_queue: Array = []
var _dialogue_speaker := ""


func _ready() -> void:
	super._ready()
	_connect_interactables()
	_apply_progress_to_scene()
	_update_objective()


func _get_progress() -> Dictionary:
	progress = SteamtekLive3DProgressStore.get_progress(PROGRESS_STATE_META)
	return progress


func _save_progress() -> void:
	SteamtekLive3DProgressStore.save_progress(PROGRESS_STATE_META, progress)


func _on_hud_panel_opened() -> void:
	_set_quest_log_visible(false)


func _on_hud_panel_closed() -> void:
	_set_quest_log_visible(true)


func _on_inventory_slot_double_clicked(key: String) -> void:
	var weapons_owned: Dictionary = progress.get("weapons_owned", {})
	if weapons_owned.has(key):
		_equip_starter_weapon(key)
	else:
		_show_message("Nothing to do with this yet.")


func _process(delta: float) -> void:
	super._process(delta)
	if _suppress_storage_reopen and not Input.is_action_pressed("interact"):
		_suppress_storage_reopen = false
	if storage_window.visible and Input.is_physical_key_pressed(KEY_R):
		_take_all_hold_time += delta
		if _take_all_hold_time >= TAKE_ALL_HOLD_SECONDS:
			_take_all_from_storage()
			_take_all_hold_time = -1000.0
	else:
		_take_all_hold_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if storage_window.visible and event.is_action_pressed("interact"):
		_set_storage_open(false)
		_suppress_storage_reopen = true
		get_viewport().set_input_as_handled()
		return


func _connect_interactables() -> void:
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_interactable_3d"):
		var interactable := node as Node
		if interactable != null and is_ancestor_of(interactable) and interactable.has_signal("tutorial_action_requested"):
			interactable.tutorial_action_requested.connect(_on_interactable_action_requested)


func _apply_progress_to_scene() -> void:
	var note_found := bool(progress.get("note_found", false))
	var equipped := bool(progress.get("equipment_complete", false))
	exit_door.interaction_enabled = note_found and equipped
	var note := $QuestNoteInteractable
	if note_found:
		note.mark_used()
	note_marker.visible = not note_found
	storage_marker.visible = note_found and not equipped
	door_outline.visible = false
	hud.set_inventory_enabled(note_found)


func _on_interactable_action_requested(action_id: String, _actor: Node, _source: Node) -> void:
	match action_id:
		"opening_note":
			if bool(progress.get("note_found", false)):
				_show_dialogue_sequence("Note", ["The note says to head east to The Brass Lantern."])
				return
			progress["note_found"] = true
			progress["quest_stage"] = 1
			progress["quest_title"] = "Rough Streets"
			_save_progress()
			_apply_progress_to_scene()
			_show_dialogue_sequence("Note", [
				"\"Storm's got the whole block dark again. Went to check on things at the Brass Lantern -- should've been back an hour ago. Don't wait up. -- Joss\"",
				"An hour ago, in this? That's not like them.",
				"If I'm going out there, I should grab my gear first. These streets don't forgive being careless.",
			])
			_update_objective()
		"starter_storage":
			if not _suppress_storage_reopen:
				_open_starter_storage()
	_update_objective()


func _show_dialogue_sequence(speaker: String, lines: Array) -> void:
	_dialogue_speaker = speaker
	_dialogue_queue = lines.duplicate()
	character.set_player_controlled(false)
	_advance_dialogue()


func _advance_dialogue() -> void:
	if _dialogue_queue.is_empty():
		hud.dialogue_box.close()
		character.call_deferred("set_player_controlled", true)
		return
	var line: String = _dialogue_queue.pop_front()
	var options: Array
	if _dialogue_queue.is_empty():
		options = [{"label": "Close", "callback": _advance_dialogue}]
	else:
		options = [{"label": "Continue", "callback": _advance_dialogue}]
	hud.dialogue_box.show_dialogue(_dialogue_speaker, line, options)


func _set_quest_log_visible(is_visible: bool) -> void:
	title_label.visible = is_visible
	objective_label.visible = is_visible


func _update_objective() -> void:
	if not bool(progress.get("note_found", false)):
		objective_label.text = "OBJECTIVE  |  Explore with WASD and read the note near the bed"
	elif not bool(progress.get("equipment_complete", false)):
		objective_label.text = "OBJECTIVE  |  Open your storage crate and equip a weapon"
	else:
		objective_label.text = "OBJECTIVE  |  Head out through the north door"


func _open_starter_storage() -> void:
	if not progress.has("crate_items") and not progress.has("crate_weapons"):
		progress["crate_items"] = {
			"Crate of Bandages (5 charges)": 2,
			"Mineral Survey Tool": 1,
			"Rusty Crafting Kit": 1,
		}
		progress["crate_weapons"] = ["Rusty Pistol", "Canister Launcher"]
		progress["cogs"] = maxi(int(progress.get("cogs", 0)), 100)
		_save_progress()
		hud._refresh_cogs()
	_set_storage_open(true)


func _set_storage_open(open: bool) -> void:
	storage_window.visible = open
	set_prompt_suppressed(open)
	if open:
		character.set_player_controlled(false)
		_refresh_storage_window()
	else:
		character.call_deferred("set_player_controlled", true)


func _refresh_storage_window() -> void:
	var crate_entries: Array = []
	var crate_items: Dictionary = progress.get("crate_items", {})
	for item_name in crate_items.keys():
		crate_entries.append({"key": item_name, "label": item_name, "count": int(crate_items[item_name])})
	var crate_weapons: Array = progress.get("crate_weapons", [])
	for weapon_name in crate_weapons:
		crate_entries.append({"key": weapon_name, "label": weapon_name, "count": 1})
	storage_panel.configure("CRATE CONTENTS", crate_entries, _on_storage_slot_double_clicked)

	var your_entries: Array = []
	var items: Dictionary = progress.get("items", {})
	for item_name in items.keys():
		your_entries.append({"key": item_name, "label": item_name, "count": int(items[item_name])})
	var weapons_owned: Dictionary = progress.get("weapons_owned", {})
	var equipped := String(progress.get("equipped_weapon", ""))
	for weapon_name in weapons_owned.keys():
		var label := String(weapon_name)
		if weapon_name == equipped:
			label += " (equipped)"
		your_entries.append({"key": weapon_name, "label": label, "icon_name": weapon_name, "count": 1})
	your_items_panel.configure("YOUR ITEMS", your_entries, _on_your_items_slot_double_clicked)


func _take_all_from_storage() -> void:
	var crate_items: Dictionary = progress.get("crate_items", {})
	var item_names: Array = crate_items.keys().duplicate()
	for item_name in item_names:
		_on_storage_item_taken(item_name)
	var crate_weapons: Array = (progress.get("crate_weapons", []) as Array).duplicate()
	for weapon_name in crate_weapons:
		_on_storage_weapon_taken(weapon_name)
	if not item_names.is_empty() or not crate_weapons.is_empty():
		_show_message("Took everything.")


func _on_storage_slot_double_clicked(key: String) -> void:
	var crate_items: Dictionary = progress.get("crate_items", {})
	if crate_items.has(key):
		_on_storage_item_taken(key)
	else:
		_on_storage_weapon_taken(key)


func _on_storage_item_taken(item_name: String) -> void:
	var crate_items: Dictionary = progress.get("crate_items", {})
	if not crate_items.has(item_name):
		return
	var items: Dictionary = progress.get("items", {})
	items[item_name] = int(items.get(item_name, 0)) + int(crate_items[item_name])
	progress["items"] = items
	crate_items.erase(item_name)
	progress["crate_items"] = crate_items
	_save_progress()
	_refresh_storage_window()
	_refresh_inventory_window()
	_show_message("Took %s." % item_name)


func _on_storage_weapon_taken(weapon_name: String) -> void:
	var crate_weapons: Array = progress.get("crate_weapons", [])
	if not crate_weapons.has(weapon_name):
		return
	crate_weapons.erase(weapon_name)
	progress["crate_weapons"] = crate_weapons
	var weapons_owned: Dictionary = progress.get("weapons_owned", {})
	weapons_owned[weapon_name] = true
	progress["weapons_owned"] = weapons_owned
	_save_progress()
	_refresh_storage_window()
	_refresh_inventory_window()
	_show_message("Took %s. Open your inventory with [I] to equip it." % weapon_name)


func _on_your_items_slot_double_clicked(key: String) -> void:
	var weapons_owned: Dictionary = progress.get("weapons_owned", {})
	if weapons_owned.has(key):
		_store_weapon(key)
	else:
		_store_item(key)


func _store_item(item_name: String) -> void:
	var items: Dictionary = progress.get("items", {})
	if not items.has(item_name):
		return
	var crate_items: Dictionary = progress.get("crate_items", {})
	crate_items[item_name] = int(crate_items.get(item_name, 0)) + int(items[item_name])
	progress["crate_items"] = crate_items
	items.erase(item_name)
	progress["items"] = items
	_save_progress()
	_refresh_storage_window()
	_refresh_inventory_window()
	_show_message("Stored %s." % item_name)


func _store_weapon(weapon_name: String) -> void:
	var weapons_owned: Dictionary = progress.get("weapons_owned", {})
	if not weapons_owned.has(weapon_name):
		return
	weapons_owned.erase(weapon_name)
	progress["weapons_owned"] = weapons_owned
	var crate_weapons: Array = progress.get("crate_weapons", [])
	crate_weapons.append(weapon_name)
	progress["crate_weapons"] = crate_weapons
	var unequipped := false
	if String(progress.get("equipped_weapon", "")) == weapon_name:
		progress["equipped_weapon"] = ""
		progress["equipment_complete"] = false
		unequipped = true
	_save_progress()
	_refresh_storage_window()
	_refresh_inventory_window()
	if unequipped:
		_apply_progress_to_scene()
		_update_objective()
	_show_message("Stored %s." % weapon_name)


func _refresh_inventory_window() -> void:
	var entries: Array = []
	var items: Dictionary = progress.get("items", {})
	for item_name in items.keys():
		entries.append({"key": item_name, "label": item_name, "count": int(items[item_name])})
	var weapons_owned: Dictionary = progress.get("weapons_owned", {})
	var equipped := String(progress.get("equipped_weapon", ""))
	for weapon_name in weapons_owned.keys():
		var label := String(weapon_name)
		if weapon_name == equipped:
			label += " (equipped)"
		entries.append({"key": weapon_name, "label": label, "icon_name": weapon_name, "count": 1})
	var status := "EQUIPPED WEAPON: %s" % (equipped if not equipped.is_empty() else "None")
	hud.refresh_inventory(entries, [], int(progress.get("cogs", 0)), status)


func _equip_starter_weapon(weapon_name: String) -> void:
	progress["equipped_weapon"] = weapon_name
	progress["equipment_complete"] = true
	_save_progress()
	_apply_progress_to_scene()
	_refresh_inventory_window()
	_update_objective()
	_show_message("EQUIPPED - %s. Time to head out." % weapon_name)


func _show_message(text: String) -> void:
	message_serial += 1
	var serial := message_serial
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(3.2).timeout
	if serial == message_serial:
		message_label.visible = false
