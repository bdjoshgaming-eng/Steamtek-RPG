extends SteamtekTransitionLevel3D

const TUTORIAL_STATE_META := "steamtek_opening_tutorial_state"

@onready var objective_label: Label = $TransitionUI/Objective
@onready var message_label: Label = $TransitionUI/Message
@onready var contact_waypoint: Node3D = $ObjectiveWaypoints/LanternContact
@onready var bartender_waypoint: Node3D = $ObjectiveWaypoints/Bartender
@onready var exit_waypoint: Node3D = $ObjectiveWaypoints/SurfaceExit
@onready var exit_door: SteamtekZoneDoor3D = $SurfaceExitDoor
@onready var vendor_panel: Control = $TransitionUI/VendorPanel
@onready var vendor_status_label: Label = $TransitionUI/VendorPanel/Status

var tutorial_state: Dictionary = {}
var message_serial := 0


func _ready() -> void:
	super._ready()
	_connect_tutorial_interactables()
	_update_scene_state()


func _get_progress() -> Dictionary:
	tutorial_state = SteamtekLive3DProgressStore.get_progress(TUTORIAL_STATE_META)
	if tutorial_state.is_empty():
		tutorial_state = {
			"note_found": true,
			"quest_stage": 1,
			"quest_title": "A Light in the Rain",
			"main_combat_complete": true,
			"first_skill_learned": true,
			"garage_inspected": true,
		}
		_save_progress()
	return tutorial_state


func _save_progress() -> void:
	SteamtekLive3DProgressStore.save_progress(TUTORIAL_STATE_META, tutorial_state)


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not vendor_panel.visible:
		return
	if event.is_action_pressed("equip_menu") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		_set_vendor_open(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("slot_1"):
		_buy_vendor_item("Field Ration", 4)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_2:
		_buy_vendor_item("Water Flask", 2)
		get_viewport().set_input_as_handled()


func _connect_tutorial_interactables() -> void:
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_interactable_3d"):
		var interactable := node as Node
		if interactable != null and is_ancestor_of(interactable) and interactable.has_signal("tutorial_action_requested"):
			interactable.tutorial_action_requested.connect(_on_tutorial_action_requested)


func _on_tutorial_action_requested(action_id: String, _actor: Node, _source: Node) -> void:
	match action_id:
		"lantern_contact":
			_attempt_quest_handoff()
		"bartender_vendor":
			_set_vendor_open(true)


func _attempt_quest_handoff() -> void:
	if int(tutorial_state.get("quest_stage", 1)) >= 2:
		_show_message("The contact is heading below. Stock up with the bartender, then use the Maintenance Lift.")
		return
	if not bool(tutorial_state.get("main_combat_complete", false)):
		_show_message("The contact is waiting for the Main Road thugs to be cleared.")
		return
	if not bool(tutorial_state.get("first_skill_learned", false)):
		_show_message("Spend your earned Combat XP before heading underground.")
		return
	if not bool(tutorial_state.get("garage_inspected", false)):
		_show_message("Check the Garage workbench before leaving the Surface.")
		return
	tutorial_state["quest_stage"] = 2
	tutorial_state["quest_title"] = "Below the Surface"
	_save_progress()
	_update_scene_state()
	_show_message("QUEST COMPLETE -- A Light in the Rain\nNEW QUEST -- Descend to Undertown through the Maintenance Lift.")


func _set_vendor_open(open: bool) -> void:
	vendor_panel.visible = open
	character.set_player_controlled(not open)
	_update_vendor_panel()


func _buy_vendor_item(item_name: String, cost: int) -> void:
	var cogs := int(hud.progress_ref.get("cogs", 0))
	if cogs < cost:
		_show_message("Not enough Cogs for %s." % item_name)
		return
	var items: Dictionary = hud.progress_ref.get("items", {})
	items[item_name] = int(items.get(item_name, 0)) + 1
	hud.progress_ref["items"] = items
	hud.progress_ref["cogs"] = cogs - cost
	if hud.save_callback.is_valid():
		hud.save_callback.call()
	tutorial_state["vendor_tutorial_complete"] = true
	_save_progress()
	_update_vendor_panel()
	_update_scene_state()
	_show_message("PURCHASED -- %s for %d Cogs." % [item_name, cost])


func _update_vendor_panel() -> void:
	if not is_instance_valid(vendor_status_label):
		return
	var items: Dictionary = hud.progress_ref.get("items", {})
	vendor_status_label.text = (
		"COGS: %d\n\n[1] FIELD RATION --4 Cogs   Owned: %d\n[2] WATER FLASK --2 Cogs   Owned: %d\n\nPurchase either item to complete the vendor tutorial.\n\n[I] Close vendor"
		% [
			int(hud.progress_ref.get("cogs", 0)),
			int(items.get("Field Ration", 0)),
			int(items.get("Water Flask", 0)),
		]
	)


func _update_scene_state() -> void:
	var handoff_complete := int(tutorial_state.get("quest_stage", 1)) >= 2
	var vendor_complete := bool(tutorial_state.get("vendor_tutorial_complete", false))
	contact_waypoint.call("set_active", not handoff_complete)
	bartender_waypoint.call("set_active", handoff_complete and not vendor_complete)
	exit_waypoint.call("set_active", handoff_complete and vendor_complete)
	exit_door.interaction_enabled = not handoff_complete or vendor_complete
	if not handoff_complete:
		objective_label.text = "OBJECTIVE  |  Speak with the contact behind The Lantern bar"
	elif not vendor_complete:
		objective_label.text = "OBJECTIVE  |  Buy food or water from the bartender"
	else:
		objective_label.text = "OBJECTIVE  |  Return outside and continue east to the Maintenance Lift"


func _show_message(text: String) -> void:
	message_serial += 1
	var serial := message_serial
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(4.0).timeout
	if serial == message_serial:
		message_label.visible = false
