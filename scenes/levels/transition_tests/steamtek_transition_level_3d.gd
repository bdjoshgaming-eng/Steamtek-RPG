class_name SteamtekTransitionLevel3D
extends Node3D

const HUD_SCENE := preload("res://scenes/gameplay/live3d/SteamtekLive3DHud.tscn")

@export var camera_follow_response := 9.0
@export var fade_seconds := 0.28

@onready var character: SteamtekHumanoidCharacter3D = $VesperKane_PlayerCharacter_v01
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var interaction_prompt: Label = $TransitionUI/InteractionPrompt
@onready var fade_rect: ColorRect = $TransitionUI/Fade

var transition_in_progress := false
var hud: SteamtekLive3DHud
var _prompt_target: Node3D
var _prompt_tag: PanelContainer
var _prompt_tag_label: Label
var _prompt_suppressed := false


func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_apply_pending_spawn()
	_snap_camera_to_character()
	character.interaction_focus_changed.connect(_on_interaction_focus_changed)
	_on_interaction_focus_changed("", null)
	for door_node in get_tree().get_nodes_in_group("steamtek_zone_door_3d"):
		var door := door_node as SteamtekZoneDoor3D
		if door != null and is_ancestor_of(door):
			door.zone_transition_requested.connect(_on_zone_transition_requested)
	for enemy_node in get_tree().get_nodes_in_group("steamtek_tutorial_enemy_3d"):
		if is_ancestor_of(enemy_node) and enemy_node.has_method("set_player_reference"):
			enemy_node.call("set_player_reference", character)
	interaction_prompt.visible = false
	_build_prompt_tag()
	_setup_hud()
	_fade_from_black()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8:
		get_tree().quit()


func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x, 0.0, target.z)
	var weight := 1.0 - exp(-camera_follow_response * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(desired, weight)
	_update_prompt_tag_position()


func _build_prompt_tag() -> void:
	var canvas := $TransitionUI as CanvasLayer

	_prompt_tag = PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.08, 0.07, 0.055, 0.75)
	pill_style.border_color = Color(0.2, 0.95, 0.4, 0.45)
	pill_style.set_border_width_all(1)
	pill_style.corner_radius_top_left = 14
	pill_style.corner_radius_top_right = 14
	pill_style.corner_radius_bottom_left = 14
	pill_style.corner_radius_bottom_right = 14
	pill_style.content_margin_left = 8
	pill_style.content_margin_right = 12
	pill_style.content_margin_top = 4
	pill_style.content_margin_bottom = 4
	_prompt_tag.add_theme_stylebox_override("panel", pill_style)
	_prompt_tag.visible = false
	_prompt_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	_prompt_tag.add_child(hbox)

	var key_box := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color(0, 0, 0, 0)
	key_style.border_color = Color(0.7, 0.63, 0.47, 0.4)
	key_style.set_border_width_all(1)
	key_style.corner_radius_top_left = 3
	key_style.corner_radius_top_right = 3
	key_style.corner_radius_bottom_left = 3
	key_style.corner_radius_bottom_right = 3
	key_style.content_margin_left = 4
	key_style.content_margin_right = 4
	key_style.content_margin_top = 1
	key_style.content_margin_bottom = 1
	key_box.add_theme_stylebox_override("panel", key_style)
	var key_label := Label.new()
	key_label.text = "E"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var key_settings := LabelSettings.new()
	key_settings.font_size = 10
	key_settings.font_color = Color(0.72, 0.63, 0.44, 1)
	key_label.label_settings = key_settings
	key_box.add_child(key_label)
	hbox.add_child(key_box)

	_prompt_tag_label = Label.new()
	var label_settings := LabelSettings.new()
	label_settings.font_size = 12
	label_settings.font_color = Color(0.78, 0.75, 0.63, 1)
	_prompt_tag_label.label_settings = label_settings
	hbox.add_child(_prompt_tag_label)

	canvas.add_child(_prompt_tag)


func set_prompt_suppressed(suppressed: bool) -> void:
	_prompt_suppressed = suppressed
	if suppressed and _prompt_tag != null:
		_prompt_tag.visible = false


func _update_prompt_tag_position() -> void:
	if _prompt_tag == null or not _prompt_tag.visible:
		return
	if _prompt_target == null or not is_instance_valid(_prompt_target):
		_prompt_tag.visible = false
		return
	var world_pos := _prompt_target.global_position + Vector3(0, 0.6, 0)
	if camera.is_position_behind(world_pos):
		_prompt_tag.visible = false
		return
	var screen_pos := camera.unproject_position(world_pos)
	_prompt_tag.position = screen_pos - Vector2(_prompt_tag.size.x * 0.5, _prompt_tag.size.y + 4)


func _setup_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	_get_progress()
	var inventory := SteamtekLive3DProgressStore.get_global_inventory()
	if inventory.is_empty():
		inventory = {"items": {}, "weapons_owned": {}, "cogs": 0, "equipped_weapon": ""}
	hud.bind(inventory, func(): SteamtekLive3DProgressStore.save_global_inventory(inventory))
	hud.set_inventory_enabled(true)
	character.set_inventory(inventory)
	var combat_state := SteamtekLive3DProgressStore.get_global_combat_state()
	if combat_state.is_empty():
		combat_state = {"current_health": 500.0, "max_health": 500.0, "current_action": 850.0, "max_action": 850.0}
	character.set_combat_state(combat_state, func(): SteamtekLive3DProgressStore.save_global_combat_state(combat_state))
	hud.bind_combat_state(combat_state)
	hud.panel_opened.connect(_on_hud_panel_opened)
	hud.panel_opened.connect(func(): set_prompt_suppressed(true))
	hud.panel_opened.connect(func(): character.combat_blocked = true)
	hud.panel_closed.connect(_on_hud_panel_closed)
	hud.panel_closed.connect(func(): set_prompt_suppressed(false))
	hud.panel_closed.connect(func(): character.combat_blocked = false)
	hud.inventory_slot_double_clicked.connect(_on_inventory_slot_double_clicked)


func _get_progress() -> Dictionary:
	return {}


func _save_progress() -> void:
	pass


func _on_hud_panel_opened() -> void:
	pass


func _on_hud_panel_closed() -> void:
	pass


func _on_inventory_slot_double_clicked(item_key: String) -> void:
	# Base/default equip handling: any scene that doesn't override this
	# (apartment does, for its own door-unlock + message-toast behavior)
	# still lets the player equip an owned weapon from the inventory
	# window. Without this, scenes like the lantern/surface canvas had no
	# way to change equipped weapon at all once past the apartment.
	var weapons_owned: Dictionary = hud.progress_ref.get("weapons_owned", {})
	if not weapons_owned.has(item_key):
		return
	hud.progress_ref["equipped_weapon"] = item_key
	if hud.save_callback.is_valid():
		hud.save_callback.call()
	hud._refresh_inventory_display()


func _apply_pending_spawn() -> void:
	var spawn_id := String(get_tree().root.get_meta("steamtek_pending_spawn_id", ""))
	if get_tree().root.has_meta("steamtek_pending_spawn_id"):
		get_tree().root.remove_meta("steamtek_pending_spawn_id")
	if spawn_id.is_empty():
		return
	var spawn := find_child(spawn_id, true, false) as Marker3D
	if spawn == null:
		push_warning("Steamtek transition spawn was not found: %s" % spawn_id)
		return
	character.global_position = spawn.global_position


func _snap_camera_to_character() -> void:
	var target := character.global_position
	camera_rig.global_position = Vector3(target.x, 0.0, target.z)


func _on_interaction_focus_changed(prompt_text: String, target: Node) -> void:
	interaction_prompt.visible = false
	if _prompt_tag == null:
		return
	if prompt_text.is_empty() or transition_in_progress:
		_prompt_tag.visible = false
		_prompt_target = null
		return
	_prompt_target = target as Node3D
	_prompt_tag_label.text = prompt_text
	_prompt_tag.visible = not _prompt_suppressed
	_update_prompt_tag_position()


func _on_zone_transition_requested(target_scene_path: String, target_spawn_id: String) -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	character.set_player_controlled(false)
	character.save_combat_state()
	interaction_prompt.visible = false
	if _prompt_tag != null:
		_prompt_tag.visible = false
	get_tree().root.set_meta("steamtek_pending_spawn_id", target_spawn_id)
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_seconds)
	await tween.finished
	var error := get_tree().change_scene_to_file(target_scene_path)
	if error != OK:
		push_error("Steamtek scene transition failed: %s" % target_scene_path)
		transition_in_progress = false
		character.set_player_controlled(true)
		fade_rect.color.a = 0.0


func _fade_from_black() -> void:
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, fade_seconds)
