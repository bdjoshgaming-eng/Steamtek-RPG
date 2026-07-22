class_name SteamtekQuestMarker3D
extends Node3D

enum MarkerType { MAIN, SIDE, CHAIN, INTERACTABLE }

const MARKER_COLORS := {
	MarkerType.MAIN: Color(1.0, 1.0, 1.0, 1.0),
	MarkerType.SIDE: Color(0.35, 0.95, 1.0, 1.0),
	MarkerType.CHAIN: Color(1.2, 0.9, 0.4, 1.0),
	MarkerType.INTERACTABLE: Color(1.6, 1.6, 1.6, 1.0),
}

@export var marker_type: MarkerType = MarkerType.MAIN
@export var animated := false
@export var float_amplitude := 0.08
@export var float_speed := 1.8
@export var pulse_min := 0.7
@export var pulse_max := 1.0
@export var pulse_speed := 1.2

@onready var icon: Sprite3D = $Icon

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y
	_apply_color()


func _process(delta: float) -> void:
	if not animated:
		return
	_time += delta
	position.y = _base_y + sin(_time * float_speed * TAU) * float_amplitude
	var pulse := lerpf(pulse_min, pulse_max, (sin(_time * pulse_speed * TAU) + 1.0) * 0.5)
	icon.modulate.a = pulse


func _apply_color() -> void:
	icon.modulate = MARKER_COLORS.get(marker_type, Color.WHITE)


func set_marker_type(type: MarkerType) -> void:
	marker_type = type
	if is_inside_tree():
		_apply_color()


func set_animated(enable: bool) -> void:
	animated = enable
	if not enable and is_inside_tree():
		position.y = _base_y
		icon.modulate.a = 1.0
