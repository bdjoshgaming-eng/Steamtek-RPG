extends Node3D

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.35, 0.0), Vector3.UP)

