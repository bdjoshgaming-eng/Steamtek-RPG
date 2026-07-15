extends CharacterBody2D

signal interaction_started(npc: CharacterBody2D)

const DIRECTION_NAMES := [
	"east",
	"south_east",
	"south",
	"south_west",
	"west",
	"north_west",
	"north",
	"north_east",
]

@export var display_name := "Pressure Technician"
@export_multiline var greeting := "Line pressure's unstable. Keep clear of the copper mains."
@export var patrol_enabled := true
@export var move_speed := 38.0
@export var waypoint_tolerance := 6.0
@export var pause_duration := 1.75
@export var interaction_range := 82.0
@export var interaction_duration := 4.0
@export var player_path: NodePath = NodePath("../../Player")
@export var patrol_offsets := PackedVector2Array([
	Vector2(0, 0),
	Vector2(120, 0),
	Vector2(120, 64),
	Vector2(0, 64),
])

@onready var visual: AnimatedSprite2D = $CharacterVisual/Visual
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var name_label: Label = $NameLabel
@onready var speech_label: Label = $SpeechLabel

var player: CharacterBody2D
var patrol_origin := Vector2.ZERO
var waypoint_index := 0
var pause_remaining := 0.0
var interaction_remaining := 0.0
var facing_direction := "south"


func _ready() -> void:
	patrol_origin = global_position
	if not player_path.is_empty():
		player = get_node_or_null(player_path) as CharacterBody2D
	name_label.text = display_name
	speech_label.text = greeting
	speech_label.visible = false
	navigation_agent.path_desired_distance = waypoint_tolerance
	navigation_agent.target_desired_distance = waypoint_tolerance
	_play_animation("idle")


func _physics_process(delta: float) -> void:
	if interaction_remaining > 0.0:
		interaction_remaining = maxf(interaction_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		if is_instance_valid(player):
			_face_vector(player.global_position - global_position)
		_play_animation("idle")
		if interaction_remaining == 0.0:
			speech_label.visible = false
		return

	if not patrol_enabled or patrol_offsets.is_empty():
		velocity = Vector2.ZERO
		_play_animation("idle")
		return

	if pause_remaining > 0.0:
		pause_remaining = maxf(pause_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		_play_animation("idle")
		return

	var target := patrol_origin + patrol_offsets[waypoint_index]
	var target_delta := target - global_position
	if target_delta.length() <= waypoint_tolerance:
		global_position = target
		velocity = Vector2.ZERO
		waypoint_index = (waypoint_index + 1) % patrol_offsets.size()
		pause_remaining = pause_duration
		_play_animation("idle")
		return

	velocity = target_delta.normalized() * move_speed
	_face_vector(velocity)
	move_and_slide()
	_play_animation("walk")


func try_interact(actor: CharacterBody2D) -> bool:
	if actor == null or global_position.distance_to(actor.global_position) > interaction_range:
		return false
	player = actor
	interaction_remaining = interaction_duration
	speech_label.visible = true
	_face_vector(actor.global_position - global_position)
	_play_animation("idle")
	interaction_started.emit(self)
	return true


func _face_vector(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	var octant := wrapi(int(round(rad_to_deg(direction.angle()) / 45.0)), 0, 8)
	facing_direction = DIRECTION_NAMES[octant]


func _play_animation(state: String) -> void:
	var animation_name := StringName("%s_%s" % [state, facing_direction])
	if not visual.sprite_frames.has_animation(animation_name):
		push_error("Steamtek_C002 is missing animation: %s" % animation_name)
		return
	visual.flip_h = false
	if visual.animation != animation_name or not visual.is_playing():
		visual.play(animation_name)
