extends Node3D

@onready var review_camera: Camera3D = $ReviewCamera


func _ready() -> void:
	review_camera.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
