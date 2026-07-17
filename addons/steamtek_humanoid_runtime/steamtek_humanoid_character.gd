@tool
class_name SteamtekHumanoidCharacter
extends CharacterBody3D

@export var move_speed: float = 4.5
@export var acceleration: float = 18.0
@export var rotation_speed: float = 12.0
@export_node_path("AnimationPlayer") var animation_player_path: NodePath

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), rotation_speed * delta)
		_play_contract_animation("STK_WALK")
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		_play_contract_animation("STK_IDLE")
	move_and_slide()


func _play_contract_animation(animation_name: String) -> void:
	if animation_player == null:
		return
	if animation_player.has_animation(animation_name) and animation_player.current_animation != animation_name:
		animation_player.play(animation_name, 0.15)

