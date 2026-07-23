class_name SteamtekSurfaceWeather3D
extends Node3D

@export var rain_height := 10.0
@export var follow_response := 6.0

# Debug weather toggle: press F4 to flip rain/storm on and off while
# testing/placing geometry, same raw-physical-keycode convention as the
# F8 quit handler (steamtek_transition_level_3d.gd) -- not a named
# InputMap action since this is a dev convenience, not real gameplay.
const TOGGLE_KEY := KEY_F4

@onready var rain_streaks: GPUParticles3D = $RainVolume/RainStreaks
@onready var storm_atmosphere: SteamtekStormAtmosphere3D = $StormAtmosphere

var weather_enabled := true
var _character: Node3D


func _ready() -> void:
	await get_tree().process_frame
	var characters := get_tree().get_nodes_in_group("steamtek_humanoid")
	if not characters.is_empty():
		_character = characters[0] as Node3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		set_weather_enabled(not weather_enabled)
		get_viewport().set_input_as_handled()


func set_weather_enabled(enabled: bool) -> void:
	weather_enabled = enabled
	if is_instance_valid(rain_streaks):
		rain_streaks.emitting = enabled
	if is_instance_valid(storm_atmosphere):
		storm_atmosphere.set_enabled(enabled)


func _process(delta: float) -> void:
	if _character == null or not is_instance_valid(_character):
		return
	var target_xz := _character.global_position
	var desired := Vector3(target_xz.x, rain_height, target_xz.z)
	var weight := 1.0 - exp(-follow_response * delta)
	global_position = global_position.lerp(desired, weight)
