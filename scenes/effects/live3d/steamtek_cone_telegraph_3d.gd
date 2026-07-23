class_name SteamtekConeTelegraph3D
extends Node3D

## Cone-shaped telegraph for arc weapons (Flame Thrower). The wedge mesh
## is rebuilt every call rather than scaled/rotated, so it always matches
## the live aim direction with no basis-convention guesswork.

const CONE_SEGMENTS := 20
const WEDGE_HEIGHT := 0.03

@onready var mesh_instance: MeshInstance3D = $Wedge


func set_shape(aim_direction: Vector3, length: float, angle_degrees: float) -> void:
	if not is_instance_valid(mesh_instance):
		return
	var forward := aim_direction
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var half_angle := deg_to_rad(angle_degrees) * 0.5
	var apex := Vector3(0, WEDGE_HEIGHT, 0)
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous_point := _rotate_around_y(forward, -half_angle) * length + apex
	for i in range(1, CONE_SEGMENTS + 1):
		var t := -half_angle + (2.0 * half_angle) * (float(i) / float(CONE_SEGMENTS))
		var point := _rotate_around_y(forward, t) * length + apex
		surface_tool.add_vertex(apex)
		surface_tool.add_vertex(previous_point)
		surface_tool.add_vertex(point)
		previous_point = point
	mesh_instance.mesh = surface_tool.commit()


func _rotate_around_y(vector: Vector3, angle: float) -> Vector3:
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	return Vector3(vector.x * cos_a - vector.z * sin_a, vector.y, vector.x * sin_a + vector.z * cos_a)
