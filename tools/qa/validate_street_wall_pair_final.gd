extends SceneTree


const WALLS := {
	"res://assets/environment/street_kit/walls/STK_ENV_Street_Wall_1p2_A.tscn": {
		"dimensions": Vector3(1.2, 3.2, 0.16),
		"snap_left": Vector3(-0.6, 0, 0),
		"snap_right": Vector3(0.6, 0, 0),
		"front_x": [-0.36, 0.0, 0.36],
	},
	"res://assets/environment/street_kit/walls/STK_ENV_Street_Wall_2p4_A.tscn": {
		"dimensions": Vector3(2.4, 3.2, 0.16),
		"snap_left": Vector3(-1.2, 0, 0),
		"snap_right": Vector3(1.2, 0, 0),
		"front_x": [-0.6, 0.0, 0.6],
	},
}
const FRONT_Y := [1.05, 1.6, 2.65]
const FRONT_Z := 0.081


func _init() -> void:
	var errors: Array[String] = []
	var results: Array[Dictionary] = []
	for scene_path in WALLS:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			errors.append("Could not load %s" % scene_path)
			continue
		var wall := packed.instantiate() as Node3D
		get_root().add_child(wall)
		var spec: Dictionary = WALLS[scene_path]
		_check_wall(wall, scene_path, spec, errors, results)
		wall.free()
	print("STREET_WALL_PAIR_FINAL=" + JSON.stringify({
		"passed": errors.is_empty(),
		"errors": errors,
		"walls": results,
	}))
	quit(0 if errors.is_empty() else 1)


func _check_wall(
	wall: Node3D,
	scene_path: String,
	spec: Dictionary,
	errors: Array[String],
	results: Array[Dictionary]
) -> void:
	_check_vector(scene_path + " dimensions", wall.get_meta("dimensions_m", Vector3.ZERO), spec.dimensions, errors)
	_check_vector(scene_path + " root scale", wall.scale, Vector3.ONE, errors)
	if str(wall.get_meta("pivot", "")) != "bottom_center":
		errors.append("%s pivot is not bottom_center" % scene_path)
	if str(wall.get_meta("front_axis", "")) != "+Z":
		errors.append("%s front axis is not +Z" % scene_path)

	var collision := wall.get_node_or_null("Collision") as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D:
		errors.append("%s is missing its box collision" % scene_path)
	else:
		_check_vector(scene_path + " collision", (collision.shape as BoxShape3D).size, spec.dimensions, errors)
		_check_vector(scene_path + " collision center", collision.position, Vector3(0, 1.6, 0), errors)

	_check_snap(wall, "SnapPoints/Snap_Left", spec.snap_left, errors)
	_check_snap(wall, "SnapPoints/Snap_Right", spec.snap_right, errors)

	var attachments := wall.get_node_or_null("AttachmentPoints")
	if attachments == null:
		errors.append("%s is missing AttachmentPoints" % scene_path)
		return
	var front_sockets: Array[Marker3D] = []
	for child in attachments.get_children():
		if child is Marker3D and str(child.get_meta("socket_role", "")) == "wall_prop_surface":
			front_sockets.append(child as Marker3D)
	if front_sockets.size() != 9:
		errors.append("%s expected 9 front prop sockets, found %d" % [scene_path, front_sockets.size()])
	for x_value in spec.front_x:
		for y_value in FRONT_Y:
			var expected := Vector3(float(x_value), float(y_value), FRONT_Z)
			var socket := _find_socket_at(front_sockets, expected)
			if socket == null:
				errors.append("%s missing front prop socket at %s" % [scene_path, expected])
				continue
			if not socket.is_in_group("steamtek_live3d_snap"):
				errors.append("%s/%s is not a Live3D socket" % [scene_path, socket.name])
			if socket.get_meta("socket_normal_local", Vector3.ZERO) != Vector3(0, 0, 1):
				errors.append("%s/%s does not face +Z" % [scene_path, socket.name])
	results.append({
		"scene": scene_path,
		"dimensions_m": spec.dimensions,
		"front_prop_sockets": front_sockets.size(),
		"structural_snap_sockets": 2,
		"root_scale": wall.scale,
	})


func _check_snap(wall: Node3D, marker_path: String, expected: Vector3, errors: Array[String]) -> void:
	var marker := wall.get_node_or_null(marker_path) as Marker3D
	if marker == null:
		errors.append("%s missing %s" % [wall.scene_file_path, marker_path])
		return
	_check_vector(wall.scene_file_path + "/" + marker_path, marker.position, expected, errors)
	if not marker.is_in_group("steamtek_live3d_snap"):
		errors.append("%s/%s is not a Live3D snap socket" % [wall.scene_file_path, marker_path])
	if str(marker.get_meta("socket_role", "")) != "facade_horizontal":
		errors.append("%s/%s has the wrong socket role" % [wall.scene_file_path, marker_path])


func _find_socket_at(sockets: Array[Marker3D], expected: Vector3) -> Marker3D:
	for socket in sockets:
		if socket.position.is_equal_approx(expected):
			return socket
	return null


func _check_vector(label: String, actual: Vector3, expected: Vector3, errors: Array[String]) -> void:
	if not actual.is_equal_approx(expected):
		errors.append("%s expected %s, found %s" % [label, expected, actual])
