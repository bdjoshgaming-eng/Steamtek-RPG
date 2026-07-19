extends SteamtekTransitionLevel3D

const TUTORIAL_STATE_META := "steamtek_opening_tutorial_state"

@onready var objective_label: Label = $TransitionUI/Objective
@onready var message_label: Label = $TransitionUI/Message
@onready var exit_door: SteamtekZoneDoor3D = $ExitDoor
@onready var inventory_panel: Control = $TransitionUI/StarterInventoryPanel
@onready var inventory_items_label: Label = $TransitionUI/StarterInventoryPanel/Items
@onready var equipped_label: Label = $TransitionUI/StarterInventoryPanel/Equipped

var tutorial_state: Dictionary = {}
var message_serial := 0


func _ready() -> void:
	super._ready()
	var review_annotations := get_node_or_null("ApartmentAssembly/ReviewAnnotations") as Node3D
	if review_annotations != null:
		review_annotations.visible = false
	tutorial_state = _load_state()
	_connect_tutorial_interactables()
	_apply_state_to_scene()
	_update_objective()
	_refresh_inventory_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not bool(tutorial_state.get("starter_storage_collected", false)):
		return
	if event.is_action_pressed("equip_menu"):
		_set_inventory_open(not inventory_panel.visible)
		get_viewport().set_input_as_handled()
		return
	if not inventory_panel.visible:
		return
	if event.is_action_pressed("slot_1"):
		_equip_starter_weapon("Brass Knuckles")
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_2:
		_equip_starter_weapon("Service Pistol")
		get_viewport().set_input_as_handled()


func _load_state() -> Dictionary:
	var stored: Variant = get_tree().root.get_meta(TUTORIAL_STATE_META, {})
	if stored is Dictionary:
		return (stored as Dictionary).duplicate(true)
	return {}


func _save_state() -> void:
	get_tree().root.set_meta(TUTORIAL_STATE_META, tutorial_state.duplicate(true))


func _connect_tutorial_interactables() -> void:
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_interactable_3d"):
		var interactable := node as Node
		if interactable != null and is_ancestor_of(interactable) and interactable.has_signal("tutorial_action_requested"):
			interactable.tutorial_action_requested.connect(_on_tutorial_action_requested)


func _apply_state_to_scene() -> void:
	var note_found := bool(tutorial_state.get("note_found", false))
	exit_door.interaction_enabled = (
		note_found
		and bool(tutorial_state.get("starter_storage_collected", false))
		and bool(tutorial_state.get("equipment_tutorial_complete", false))
	)
	var note := $QuestNoteInteractable
	if note_found:
		note.mark_used()


func _on_tutorial_action_requested(action_id: String, _actor: Node, _source: Node) -> void:
	match action_id:
		"opening_note":
			if bool(tutorial_state.get("note_found", false)):
				_show_message("The note points east: meet the contact at The Lantern.")
				return
			tutorial_state["note_found"] = true
			tutorial_state["quest_stage"] = 1
			tutorial_state["quest_title"] = "A Light in the Rain"
			_save_state()
			_apply_state_to_scene()
			_show_message("QUEST STARTED - Reach The Lantern on Main Street.")
			_update_objective()
		"apartment_terminal":
			_show_message("Terminal: surface pressure is unstable. Rain Alley remains open.")
		"starter_storage":
			_open_starter_storage()
	_update_objective()


func _update_objective() -> void:
	if not bool(tutorial_state.get("note_found", false)):
		objective_label.text = "OBJECTIVE  |  Explore with WASD and read the note beside the bed"
	elif not bool(tutorial_state.get("starter_storage_collected", false)):
		objective_label.text = "OBJECTIVE  |  Cross the apartment and open your storage box"
	elif not bool(tutorial_state.get("equipment_tutorial_complete", false)):
		objective_label.text = "OBJECTIVE  |  Press [I], then equip Brass Knuckles [1] or the Service Pistol [2]"
	else:
		objective_label.text = "OBJECTIVE  |  Use the door between the workstation and storage"


func _open_starter_storage() -> void:
	if not bool(tutorial_state.get("starter_storage_collected", false)):
		var items: Dictionary = tutorial_state.get("items", {})
		items["Crafting Tool"] = 1
		items["Mineral Survey Kit"] = 1
		items["Brass Knuckles"] = 1
		items["Service Pistol"] = 1
		tutorial_state["items"] = items
		# Guarantee enough currency to complete the mandatory bartender lesson,
		# even when the optional Surface loot route is skipped.
		tutorial_state["cogs"] = maxi(int(tutorial_state.get("cogs", 0)), 10)
		tutorial_state["starter_storage_collected"] = true
		_save_state()
		_show_message("STARTER GEAR COLLECTED - Open equipment with [I].")
	_set_inventory_open(true)
	_refresh_inventory_panel()


func _equip_starter_weapon(weapon_name: String) -> void:
	tutorial_state["equipped_weapon"] = weapon_name
	tutorial_state["equipment_tutorial_complete"] = true
	_save_state()
	_apply_state_to_scene()
	_refresh_inventory_panel()
	_update_objective()
	_show_message("EQUIPPED - %s" % weapon_name)


func _set_inventory_open(open: bool) -> void:
	inventory_panel.visible = open
	character.set_player_controlled(not open)
	_refresh_inventory_panel()


func _refresh_inventory_panel() -> void:
	if not is_instance_valid(inventory_panel):
		return
	inventory_items_label.text = (
		"UTILITY\n  Crafting Tool\n  Mineral Survey Kit\n\n"
		+ "WEAPONS\n  [1] Brass Knuckles\n  [2] Service Pistol"
	)
	var equipped := String(tutorial_state.get("equipped_weapon", "None"))
	equipped_label.text = "EQUIPPED WEAPON: %s\n\n[I] Close equipment" % equipped


func _show_message(text: String) -> void:
	message_serial += 1
	var serial := message_serial
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(3.2).timeout
	if serial == message_serial:
		message_label.visible = false
