class_name SteamtekSurfaceWeather3D
extends Node3D

@export var rain_height := 10.0
@export var follow_response := 6.0

var _character: Node3D


func _ready() -> void:
	await get_tree().process_frame
	var characters := get_tree().get_nodes_in_group("steamtek_humanoid")
	if not characters.is_empty():
		_character = characters[0] as Node3D


func _process(delta: float) -> void:
	if _character == null or not is_instance_valid(_character):
		return
	var target_xz := _character.global_position
	var desired := Vector3(target_xz.x, rain_height, target_xz.z)
	var weight := 1.0 - exp(-follow_response * delta)
	global_position = global_position.lerp(desired, weight)
