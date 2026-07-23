class_name SteamtekStormAtmosphere3D
extends Node3D

@export var lightning_min_interval := 4.0
@export var lightning_max_interval := 12.0
@export var thunder_delay_min := 0.3
@export var thunder_delay_max := 1.8
@export var lightning_flash_energy := 6.0
@export var lightning_flash_duration := 0.12
@export var lightning_double_flash_chance := 0.35
@export var ambient_rain_volume_db := -24.0
@export var thunder_volume_db := -20.0

@onready var rain_audio: AudioStreamPlayer = $RainAmbient
@onready var thunder_audio: AudioStreamPlayer = $ThunderOneShot

var _lightning_lights: Array[OmniLight3D] = []
var _rain_overlays: Array[MeshInstance3D] = []
var _next_lightning_time := 0.0
var _elapsed := 0.0
var _enabled := true


# Stops/resumes the lightning cycle and rain/thunder audio without
# freeing or reparenting anything -- called by SteamtekSurfaceWeather3D's
# debug weather toggle (F4).
func set_enabled(enabled: bool) -> void:
	if enabled == _enabled:
		return
	_enabled = enabled
	set_process(enabled)
	if enabled:
		_schedule_next_lightning()
		if rain_audio.stream != null:
			rain_audio.volume_db = ambient_rain_volume_db
			rain_audio.play()
	else:
		rain_audio.stop()
		thunder_audio.stop()
		for light in _lightning_lights:
			light.light_energy = 0.0
		_set_rain_lightning_boost(0.0)


func _ready() -> void:
	for child in get_children():
		if child is OmniLight3D:
			child.light_energy = 0.0
			_lightning_lights.append(child)
	_collect_rain_overlays()
	_schedule_next_lightning()
	await get_tree().process_frame
	if rain_audio.stream != null:
		rain_audio.volume_db = ambient_rain_volume_db
		rain_audio.play()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _next_lightning_time:
		_trigger_lightning()
		_schedule_next_lightning()


func _collect_rain_overlays() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		if child is MeshInstance3D and child.name.begins_with("WindowRain"):
			_rain_overlays.append(child)


func _schedule_next_lightning() -> void:
	_next_lightning_time = _elapsed + randf_range(lightning_min_interval, lightning_max_interval)


func _trigger_lightning() -> void:
	_flash()
	if randf() < lightning_double_flash_chance:
		await get_tree().create_timer(0.08).timeout
		_flash()
	var delay := randf_range(thunder_delay_min, thunder_delay_max)
	await get_tree().create_timer(delay).timeout
	_play_thunder()


func _flash() -> void:
	for light in _lightning_lights:
		light.light_energy = lightning_flash_energy
	_set_rain_lightning_boost(1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	for light in _lightning_lights:
		tween.tween_property(light, "light_energy", 0.0, lightning_flash_duration)
	tween.tween_method(_set_rain_lightning_boost, 1.0, 0.0, lightning_flash_duration)


func _set_rain_lightning_boost(value: float) -> void:
	for overlay in _rain_overlays:
		var mat := overlay.material_override as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("lightning_boost", value)


func _play_thunder() -> void:
	if thunder_audio.stream == null:
		return
	thunder_audio.volume_db = thunder_volume_db + randf_range(-3.0, 0.0)
	thunder_audio.pitch_scale = randf_range(0.8, 1.15)
	thunder_audio.play()
