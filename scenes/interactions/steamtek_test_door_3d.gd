class_name SteamtekTestDoor3D
extends SteamtekInteractable3D

@export var closed_prompt := "Open test door"
@export var open_prompt := "Close test door"
@export var visual_path: NodePath
@export var blocking_collision_path: NodePath
@export var open_offset := Vector3(0.0, 2.15, 0.0)
@export var transition_seconds := 0.32

var is_open := false
var closed_visual_position := Vector3.ZERO
var active_tween: Tween

@onready var door_visual: Node3D = get_node(visual_path)
@onready var blocking_collision: CollisionShape3D = get_node(blocking_collision_path)


func _ready() -> void:
	closed_visual_position = door_visual.position
	interaction_prompt = closed_prompt


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	is_open = not is_open
	interaction_prompt = open_prompt if is_open else closed_prompt
	blocking_collision.set_deferred("disabled", is_open)
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var target := closed_visual_position + open_offset if is_open else closed_visual_position
	active_tween.tween_property(door_visual, "position", target, transition_seconds)
	interaction_requested.emit(actor)
