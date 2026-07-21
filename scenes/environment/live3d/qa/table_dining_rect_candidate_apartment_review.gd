extends Node3D

@onready var review_camera: Camera3D = $LockedApartmentReviewCamera


func _ready() -> void:
	review_camera.look_at(Vector3(0.2, 0.65, 0.3), Vector3.UP)
