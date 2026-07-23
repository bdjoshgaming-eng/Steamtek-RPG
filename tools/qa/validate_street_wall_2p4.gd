extends SceneTree

const WALL_SCENE := "res://assets/environment/street_kit/walls/STK_ENV_Street_Wall_2p4_A.tscn"
const QA_SCENE := "res://assets/environment/street_kit/walls/qa/STK_ENV_Street_Wall_2p4_A_ModularityValidation.tscn"
const EPSILON := 0.0001


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(WALL_SCENE) as PackedScene
	var qa_packed := load(QA_SCENE) as PackedScene
	if packed == null or qa_packed == null:
		push_error("Could not load wall or modularity QA scene.")
		quit(1)
		return

	var wall := packed.instantiate() as Node3D
	var qa := qa_packed.instantiate() as Node3D
	get_root().add_child(wall)
	get_root().add_child(qa)
	await process_frame

	var errors: Array[String] = []
	_check_vector("metadata dimensions", wall.get_meta("dimensions_m", Vector3.ZERO), Vector3(2.4, 3.2, 0.16), errors)
	_check_vector("root scale", wall.scale, Vector3.ONE, errors)
	if str(wall.get_meta("pivot", "")) != "bottom_center":
		errors.append("Pivot metadata is not bottom_center.")
	if str(wall.get_meta("front_axis", "")) != "+Z":
		errors.append("Front axis metadata is not +Z.")

	var collision := wall.get_node("Collision") as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D:
		errors.append("Collision is not one BoxShape3D.")
	else:
		_check_vector("collision size", (collision.shape as BoxShape3D).size, Vector3(2.4, 3.2, 0.16), errors)
		_check_vector("collision center", collision.position, Vector3(0, 1.6, 0), errors)

	_check_marker(wall, "SnapPoints/Snap_Left", Vector3(-1.2, 0, 0), errors)
	_check_marker(wall, "SnapPoints/Snap_Center", Vector3(0, 0, 0), errors)
	_check_marker(wall, "SnapPoints/Snap_Right", Vector3(1.2, 0, 0), errors)
	for marker_path in [
		"AttachmentPoints/Attach_Front_Left_Upper",
		"AttachmentPoints/Attach_Front_Left_Center",
		"AttachmentPoints/Attach_Front_Left_Lower",
		"AttachmentPoints/Attach_Front_Right_Upper",
		"AttachmentPoints/Attach_Front_Right_Center",
		"AttachmentPoints/Attach_Front_Right_Lower",
		"AttachmentPoints/Attach_Front_Center",
	]:
		if not wall.has_node(marker_path):
			errors.append("Missing " + marker_path)

	var mesh_instances: Array[MeshInstance3D] = []
	_collect_meshes(wall, mesh_instances)
	var triangle_count := 0
	var material_names: Dictionary = {}
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var arrays := mesh_instance.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			triangle_count += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
			var material := mesh_instance.get_active_material(surface)
			if material != null:
				material_names[material.resource_name] = true
	if triangle_count != 3180:
		errors.append("Imported triangle count is %d, expected 3180." % triangle_count)

	# Verify the three exact modular layouts encoded in the QA scene.
	_check_row_centers(qa, "Row_2p4_Beside_Two_1p2", [-1.2, 0.6, 1.8], errors)
	_check_row_centers(qa, "Row_Two_2p4", [-1.2, 1.2], errors)
	_check_row_centers(qa, "Row_Mixed_1p2_2p4_1p2", [-1.8, 0.0, 1.8], errors)

	var report := {
		"scene": WALL_SCENE,
		"dimensions_m": [2.4, 3.2, 0.16],
		"root_scale": [wall.scale.x, wall.scale.y, wall.scale.z],
		"pivot": wall.get_meta("pivot", ""),
		"front_axis": wall.get_meta("front_axis", ""),
		"triangle_count": triangle_count,
		"materials": material_names.keys(),
		"collision_m": [2.4, 3.2, 0.16],
		"errors": errors,
		"passed": errors.is_empty(),
	}
	print("STREET_WALL_2P4_VALIDATION=" + JSON.stringify(report))
	wall.free()
	qa.free()
	quit(0 if errors.is_empty() else 1)


func _check_vector(label: String, actual: Vector3, expected: Vector3, errors: Array[String]) -> void:
	if not actual.is_equal_approx(expected):
		errors.append("%s is %s, expected %s." % [label, actual, expected])


func _check_marker(root: Node, path: String, expected: Vector3, errors: Array[String]) -> void:
	var marker := root.get_node_or_null(path) as Marker3D
	if marker == null:
		errors.append("Missing " + path)
		return
	if marker.position.distance_to(expected) > EPSILON:
		errors.append("%s is at %s, expected %s." % [path, marker.position, expected])


func _check_row_centers(qa: Node, row_path: String, expected_x: Array, errors: Array[String]) -> void:
	var row := qa.get_node_or_null(row_path)
	if row == null:
		errors.append("Missing QA row " + row_path)
		return
	var actual: Array[float] = []
	for child in row.get_children():
		if child is Node3D:
			actual.append((child as Node3D).position.x)
	actual.sort()
	if actual.size() != expected_x.size():
		errors.append("%s has %d modules, expected %d." % [row_path, actual.size(), expected_x.size()])
		return
	for index in actual.size():
		if absf(actual[index] - float(expected_x[index])) > EPSILON:
			errors.append("%s center %d is %f, expected %f." % [row_path, index, actual[index], float(expected_x[index])])


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)
