extends Node3D

const ASCENT_ORTHO_SIZE := 9.14

@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var framing_label: Label = $Interface/Framing


func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_set_ortho_size(ASCENT_ORTHO_SIZE)


func _set_ortho_size(value: float) -> void:
	camera.size = value
	framing_label.text = "THE ASCENT GAMEPLAY LOCK  |  35 DEG ELEVATION  |  ORTHOGRAPHIC SIZE %.2f" % value
