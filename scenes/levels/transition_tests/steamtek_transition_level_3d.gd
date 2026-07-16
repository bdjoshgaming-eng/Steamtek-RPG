class_name SteamtekTransitionLevel3D
extends Node3D

@export var camera_follow_response := 9.0
@export var fade_seconds := 0.28

@onready var character: SteamtekHumanoidCharacter3D = $VesperKane_PlayerCharacter_v01
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var interaction_prompt: Label = $TransitionUI/InteractionPrompt
@onready var fade_rect: ColorRect = $TransitionUI/Fade

var transition_in_progress := false


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
	_fade_from_black()


func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x, 0.0, target.z)
	var weight := 1.0 - exp(-camera_follow_response * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(desired, weight)


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
	# Character movement and model-facing are authored in world space. Only route
	# the position here so a rotated Marker3D cannot offset that contract.
	character.global_position = spawn.global_position


func _snap_camera_to_character() -> void:
	var target := character.global_position
	camera_rig.global_position = Vector3(target.x, 0.0, target.z)


func _on_interaction_focus_changed(prompt_text: String, _target: Node) -> void:
	interaction_prompt.visible = not prompt_text.is_empty() and not transition_in_progress
	interaction_prompt.text = "[ E ]  " + prompt_text


func _on_zone_transition_requested(target_scene_path: String, target_spawn_id: String) -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	character.set_player_controlled(false)
	interaction_prompt.visible = false
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
