class_name SteamtekHumanoidCharacter3D
extends CharacterBody3D

signal interaction_focus_changed(prompt_text: String, target: Node)
signal interaction_performed(target: Node)

## Reusable Steamtek humanoid wrapper for the fixed-camera 2.5D pipeline.
## Character art is supplied as an imported GLB; collision, movement, facing,
## interaction anchors, and animation selection remain shared infrastructure.

@export var character_scene: PackedScene
@export var character_instance_name := "SteamtekHumanoidVisual"
@export var player_controlled := true
@export var walk_speed := 4.2
@export var run_speed := 6.4
@export var movement_acceleration := 18.0
@export var movement_deceleration := 24.0
@export var stop_immediately := true
@export var turn_response := 36.0
@export var turn_snap_threshold_degrees := 0.75
@export var locomotion_blend_seconds := 0.1
@export var gravity_strength := 18.0
@export var step_height := 0.25
@export var model_forward_yaw_offset_degrees := 40.0
@export var idle_animation_key := "STK_IDLE"
@export var walk_animation_key := "STK_WALK"
@export var run_animation_key := "STK_RUN"
@export var interaction_action := "interact"

@onready var visual_pivot: Node3D = $VisualPivot
@onready var camera_target: Marker3D = $CameraTarget
@onready var interaction_origin: Marker3D = $VisualPivot/InteractionOrigin
@onready var interaction_detector: Area3D = $VisualPivot/InteractionDetector
@onready var ground_contact: Marker3D = $GroundContact

var character_instance: Node3D
var animation_player: AnimationPlayer
var idle_animation := ""
var walk_animation := ""
var run_animation := ""
var active_animation := ""
var target_facing_yaw := 0.0
var focused_interactable: Area3D
var focused_prompt_text := ""


func _ready() -> void:
	_instantiate_character()


func _physics_process(delta: float) -> void:
	if not player_controlled:
		return
	_refresh_interaction_focus()
	if InputMap.has_action(interaction_action) and Input.is_action_just_pressed(interaction_action):
		attempt_interaction()
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := _camera_relative_direction(input_vector)
	if move_direction.length_squared() > 0.001:
		move_direction = move_direction.normalized()
		var wants_to_run := Input.is_key_pressed(KEY_SHIFT)
		var movement_speed := run_speed if wants_to_run else walk_speed
		var target_velocity := move_direction * movement_speed * clampf(input_vector.length(), 0.0, 1.0)
		velocity.x = move_toward(velocity.x, target_velocity.x, movement_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, movement_acceleration * delta)
		# Movement is authored in world space. Convert its world-facing yaw into
		# VisualPivot-local space so an accidental rotation on the character root
		# cannot make the model strafe sideways relative to its velocity.
		var target_world_facing_yaw := (
			atan2(move_direction.x, move_direction.z)
			+ deg_to_rad(model_forward_yaw_offset_degrees)
		)
		target_facing_yaw = _world_yaw_to_visual_local_yaw(target_world_facing_yaw)
		var turn_weight := 1.0 - exp(-turn_response * delta)
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_facing_yaw, turn_weight)
		if absf(angle_difference(visual_pivot.rotation.y, target_facing_yaw)) <= deg_to_rad(turn_snap_threshold_degrees):
			visual_pivot.rotation.y = target_facing_yaw
		_play_animation(run_animation if wants_to_run else walk_animation)
	else:
		if stop_immediately:
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, movement_deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, movement_deceleration * delta)
		_play_animation(idle_animation)

	var was_on_floor := is_on_floor()
	if not was_on_floor:
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = -0.2
	var saved_velocity := velocity
	move_and_slide()
	if is_on_wall() and was_on_floor:
		_try_step_up(saved_velocity, delta)


func _try_step_up(saved_velocity: Vector3, _delta: float) -> void:
	var h_vel := Vector3(saved_velocity.x, 0, saved_velocity.z)
	if h_vel.length_squared() < 0.01:
		return
	var step_up_xform := global_transform
	step_up_xform.origin.y += step_height
	if test_move(step_up_xform, h_vel.normalized() * 0.15):
		return
	var forward_xform := step_up_xform
	forward_xform.origin += h_vel.normalized() * 0.15
	if not test_move(forward_xform, Vector3(0, -step_height * 1.5, 0)):
		return
	global_position.y += step_height
	velocity = Vector3(h_vel.x, -0.2, h_vel.z)


func set_player_controlled(enabled: bool) -> void:
	player_controlled = enabled
	if not enabled:
		velocity = Vector3.ZERO
		_play_animation(idle_animation)


func play_idle() -> void:
	_play_animation(idle_animation)


func play_walk() -> void:
	_play_animation(walk_animation)


func play_run() -> void:
	_play_animation(run_animation)


func get_character_animation_player() -> AnimationPlayer:
	return animation_player


func attempt_interaction() -> bool:
	_refresh_interaction_focus()
	if focused_interactable == null or not is_instance_valid(focused_interactable):
		return false
	if not focused_interactable.has_method("interact"):
		return false
	focused_interactable.call("interact", self)
	interaction_performed.emit(focused_interactable)
	_refresh_interaction_focus()
	return true


func get_interaction_prompt() -> String:
	return focused_prompt_text


func get_focused_interactable() -> Area3D:
	return focused_interactable


func _refresh_interaction_focus() -> void:
	var best_area: Area3D
	var best_distance := INF
	var best_prompt := ""
	for candidate in interaction_detector.get_overlapping_areas():
		var area := candidate as Area3D
		if area == null or not area.has_method("interact"):
			continue
		if area.has_method("can_interact") and not bool(area.call("can_interact", self)):
			continue
		var distance := interaction_origin.global_position.distance_to(area.global_position)
		if distance >= best_distance:
			continue
		best_area = area
		best_distance = distance
		if area.has_method("get_interaction_prompt"):
			best_prompt = String(area.call("get_interaction_prompt"))
		else:
			best_prompt = "Interact"
	if best_area == focused_interactable and best_prompt == focused_prompt_text:
		return
	focused_interactable = best_area
	focused_prompt_text = best_prompt
	interaction_focus_changed.emit(focused_prompt_text, focused_interactable)


func _instantiate_character() -> void:
	character_instance = visual_pivot.get_node_or_null(character_instance_name) as Node3D
	if character_instance == null:
		if character_scene == null:
			push_warning("Steamtek humanoid has no character_scene assigned: %s" % name)
			return
		character_instance = character_scene.instantiate() as Node3D
		if character_instance == null:
			push_error("Assigned Steamtek character scene is not Node3D: %s" % name)
			return
		character_instance.name = character_instance_name
		visual_pivot.add_child(character_instance)
	animation_player = _find_animation_player(character_instance)
	if animation_player == null:
		push_error("No AnimationPlayer found in character scene: %s" % character_instance_name)
		return
	idle_animation = _find_animation_name(idle_animation_key)
	walk_animation = _find_animation_name(walk_animation_key)
	run_animation = _find_animation_name(run_animation_key)
	_configure_loop(idle_animation)
	_configure_loop(walk_animation)
	_configure_loop(run_animation)
	if idle_animation.is_empty() or walk_animation.is_empty() or run_animation.is_empty():
		push_warning(
			"Character is missing a required locomotion animation. Imported: %s"
			% str(animation_player.get_animation_list())
		)
	_play_animation(idle_animation)


func _camera_relative_direction(input_vector: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input_vector.x, 0.0, -input_vector.y)
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	return camera_right * input_vector.x + camera_forward * -input_vector.y


func _world_yaw_to_visual_local_yaw(world_yaw: float) -> float:
	var visual_parent := visual_pivot.get_parent_node_3d()
	if visual_parent == null:
		return world_yaw
	var parent_forward := visual_parent.global_transform.basis.z
	parent_forward.y = 0.0
	if parent_forward.length_squared() <= 0.000001:
		return world_yaw
	parent_forward = parent_forward.normalized()
	var parent_world_yaw := atan2(parent_forward.x, parent_forward.z)
	return wrapf(world_yaw - parent_world_yaw, -PI, PI)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_animation_name(required_key: String) -> String:
	if animation_player == null:
		return ""
	for animation_name in animation_player.get_animation_list():
		var candidate := String(animation_name)
		if candidate == required_key or candidate.ends_with("/" + required_key) or required_key in candidate:
			return candidate
	return ""


func _configure_loop(animation_name: String) -> void:
	if animation_player == null or animation_name.is_empty():
		return
	var animation := animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR


func _play_animation(animation_name: String) -> void:
	if animation_player == null or animation_name.is_empty() or active_animation == animation_name:
		return
	animation_player.play(animation_name, locomotion_blend_seconds)
	animation_player.speed_scale = 1.0
	active_animation = animation_name
