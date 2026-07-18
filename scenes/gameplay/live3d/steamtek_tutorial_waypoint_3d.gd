class_name SteamtekTutorialWaypoint3D
extends Node3D

@export var waypoint_text := "OBJECTIVE"
@export var starts_active := false
@export_range(0.0, 2.0, 0.01) var bob_distance := 0.12
@export_range(0.1, 4.0, 0.1) var pulse_speed := 1.6

@onready var beacon: Node3D = $Beacon
@onready var objective_label: Label3D = $Beacon/ObjectiveLabel
@onready var objective_light: OmniLight3D = $Beacon/ObjectiveLight

var pulse_time := 0.0


func _ready() -> void:
	objective_label.text = waypoint_text
	set_active(starts_active)


func set_active(enabled: bool) -> void:
	visible = enabled
	set_process(enabled)
	if enabled:
		pulse_time = 0.0


func _process(delta: float) -> void:
	pulse_time += delta * pulse_speed
	var wave := (sin(pulse_time * TAU) + 1.0) * 0.5
	beacon.position.y = 1.42 + sin(pulse_time * TAU) * bob_distance
	objective_light.light_energy = lerpf(0.7, 1.35, wave)

