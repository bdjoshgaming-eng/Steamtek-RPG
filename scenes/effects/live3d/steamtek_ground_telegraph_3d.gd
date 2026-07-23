class_name SteamtekGroundTelegraph3D
extends Node3D

@onready var disc: MeshInstance3D = $Disc


func set_radius(new_radius: float) -> void:
	var radius := maxf(0.1, new_radius)
	if is_instance_valid(disc):
		# Disc is a QuadMesh rotated -90 deg on X so it lies flat facing up.
		# Scale is applied in the mesh's own local (pre-rotation) X/Y plane,
		# so both those axes -- not X/Z -- must carry the radius.
		disc.scale = Vector3(radius, radius, 1.0)
