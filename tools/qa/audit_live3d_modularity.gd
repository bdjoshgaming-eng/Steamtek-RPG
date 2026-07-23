extends SceneTree

const BUILDER_PATH := "res://addons/steamtek_live3d_builder/steamtek_live3d_builder.gd"
const MODULE_GROUP := "steamtek_live3d_modular"
const SOCKET_GROUP := "steamtek_live3d_snap"
const MODULE_SYSTEM := "live3d_meter_v1"
const GENERATED_VARIANTS := "res://scenes/environment/live3d/props/apartment_interior/generated_variants"
const CHAIN_ROLES := [
	"facade_horizontal",
	"floor_horizontal",
	"roof_horizontal",
	"parapet_horizontal",
	"balcony_horizontal",
	"street_road_chain",
	"street_sidewalk_chain",
	"street_curb_chain",
	"street_drain_chain",
	"street_alley_chain",
	"street_fence_chain",
	"interior_floor_chain",
	"interior_wall_chain",
	"interior_partition_chain",
	"wall_service_chain",
	"furniture_chain",
]
const BUILDER_SOCKET_ROLES := CHAIN_ROLES + [
	"storey_vertical",
	"corner_wall_attachment",
	"parapet_corner_attachment",
	"street_road_edge",
	"street_curb_road_edge",
	"street_sidewalk_road_edge",
	"street_curb_ramp_road_edge",
	"street_curb_sidewalk_edge",
	"prop_anchor",
	"prop_surface",
	"wall_prop_surface",
	"floor_prop_surface",
	"interior_wall_base",
	"interior_wall_floor_edge",
]


func _init() -> void:
	var paths := _builder_scene_paths()
	for generated_path in _tscn_files(GENERATED_VARIANTS):
		if generated_path not in paths:
			paths.append(generated_path)
	paths.sort()

	var summaries: Array[Dictionary] = []
	var failure_count := 0
	var seam_warning_count := 0
	for scene_path in paths:
		var summary := _audit_scene(scene_path)
		summaries.append(summary)
		failure_count += (summary["issues"] as Array).size()
		seam_warning_count += (summary["seam_warnings"] as Array).size()

	for summary in summaries:
		if not (summary["issues"] as Array).is_empty():
			print("LIVE3D_AUDIT_ISSUE=" + JSON.stringify(summary))
		if not (summary["seam_warnings"] as Array).is_empty():
			print("LIVE3D_SEAM_WARNING=" + JSON.stringify({
				"path": summary["path"],
				"bounds_size": summary["bounds_size"],
				"warnings": summary["seam_warnings"],
			}))
	print("LIVE3D_AUDIT_TOTALS=" + JSON.stringify({
		"modules": summaries.size(),
		"issues": failure_count,
		"seam_warnings": seam_warning_count,
	}))
	quit(0)


func _builder_scene_paths() -> Array[String]:
	var source := FileAccess.get_file_as_string(BUILDER_PATH)
	var expression := RegEx.new()
	expression.compile("\\\"path\\\"\\s*:\\s*\\\"(res://[^\\\"]+\\.tscn)\\\"")
	var paths: Array[String] = []
	for result in expression.search_all(source):
		var scene_path := result.get_string(1)
		if scene_path not in paths:
			paths.append(scene_path)
	return paths


func _tscn_files(directory_path: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return paths
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "tscn":
			paths.append(directory_path.path_join(file_name))
		file_name = directory.get_next()
	directory.list_dir_end()
	return paths


func _audit_scene(scene_path: String) -> Dictionary:
	var issues: Array[String] = []
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return {"path": scene_path, "issues": ["scene_load_failed"], "seam_warnings": []}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"path": scene_path, "issues": ["root_is_not_node3d"], "seam_warnings": []}

	var root := instance as Node3D
	get_root().add_child(root)
	if not root.is_in_group(MODULE_GROUP):
		issues.append("missing_module_group")
	if str(root.get_meta("module_system", "")) != MODULE_SYSTEM:
		issues.append("missing_or_invalid_module_system")
	if not root.scale.is_equal_approx(Vector3.ONE):
		issues.append("root_scale_is_not_one")

	var markers: Array[Marker3D] = []
	_collect_markers(root, markers)
	var sockets: Array[Dictionary] = []
	for marker in markers:
		var role := str(marker.get_meta("socket_role", ""))
		var grouped := marker.is_in_group(SOCKET_GROUP)
		if grouped or not role.is_empty():
			sockets.append({
				"name": marker.name,
				"position": _vector3_array(_relative_transform(root, marker).origin),
				"role": role,
				"grouped": grouped,
			})
		if grouped and role.is_empty():
			issues.append("socket_without_role:" + marker.name)
		if role in BUILDER_SOCKET_ROLES and not grouped:
			issues.append("socket_role_without_group:" + marker.name)
	_validate_chain_sockets(root, sockets, issues)

	if _is_structural_path(scene_path) and sockets.is_empty():
		issues.append("structural_module_has_no_sockets")

	var bounds := _visual_bounds(root)
	var seam_warnings := _chain_seam_warnings(root, sockets, bounds)
	var summary := {
		"path": scene_path,
		"name": root.name,
		"module_family": str(root.get_meta("module_family", "")),
		"module_type": str(root.get_meta("module_type", "")),
		"bounds_position": _vector3_array(bounds.position),
		"bounds_size": _vector3_array(bounds.size),
		"sockets": sockets,
		"seam_warnings": seam_warnings,
		"issues": issues,
	}
	root.free()
	return summary


func _chain_seam_warnings(root: Node3D, sockets: Array[Dictionary], bounds: AABB) -> Array[Dictionary]:
	var warnings: Array[Dictionary] = []
	if "corner" in str(root.get_meta("module_type", "")):
		return warnings
	for role in CHAIN_ROLES:
		var positions: Array[Vector3] = []
		for socket in sockets:
			if socket["role"] == role:
				positions.append(_array_vector3(socket["position"]))
		if positions.size() < 2:
			continue
		for axis_index in [0, 2]:
			var minimum := INF
			var maximum := -INF
			for position in positions:
				var component := position[axis_index]
				minimum = minf(minimum, component)
				maximum = maxf(maximum, component)
			if minimum >= -0.0001 or maximum <= 0.0001:
				continue
			var socket_span := maximum - minimum
			var visual_span := bounds.size[axis_index]
			var delta := visual_span - socket_span
			if absf(delta) > 0.021:
				warnings.append({
					"role": role,
					"axis": "X" if axis_index == 0 else "Z",
					"socket_span": snappedf(socket_span, 0.0001),
					"visual_span": snappedf(visual_span, 0.0001),
					"visual_minus_socket": snappedf(delta, 0.0001),
				})
	return warnings


func _validate_chain_sockets(root: Node3D, sockets: Array[Dictionary], issues: Array[String]) -> void:
	var module_kind := "%s %s" % [
		str(root.get_meta("module_family", "")),
		str(root.get_meta("module_type", "")),
	]
	var permits_one_sided_chain := "corner" in module_kind or "apron" in module_kind
	for role in CHAIN_ROLES:
		var role_sockets: Array[Dictionary] = []
		for socket in sockets:
			if socket["role"] == role:
				role_sockets.append(socket)
		if role_sockets.is_empty():
			continue
		if role_sockets.size() < 2:
			issues.append("chain_role_has_fewer_than_two_sockets:" + role)
			continue
		if permits_one_sided_chain:
			continue
		for socket in role_sockets:
			var position := _array_vector3(socket["position"])
			if position.is_zero_approx():
				continue
			var has_opposite := false
			for candidate in role_sockets:
				if candidate == socket:
					continue
				var candidate_position := _array_vector3(candidate["position"])
				if _chain_positions_are_opposite(position, candidate_position):
					has_opposite = true
					break
			if not has_opposite:
				issues.append("chain_socket_has_no_opposite:%s:%s" % [role, socket["name"]])


func _chain_positions_are_opposite(position: Vector3, candidate: Vector3) -> bool:
	# Chain ends oppose one another along their dominant placement axis. Their
	# orthogonal coordinates may share a deliberate offset from the module root
	# (for example, curb-chain sockets embedded in a combined sidewalk module).
	var axis := 0
	if absf(position.y) > absf(position.x):
		axis = 1
	if absf(position.z) > absf(position[axis]):
		axis = 2
	for component in range(3):
		if component == axis:
			if not is_zero_approx(position[component] + candidate[component]):
				return false
		elif not is_equal_approx(position[component], candidate[component]):
			return false
	return true


func _is_structural_path(scene_path: String) -> bool:
	return "/kits/" in scene_path or "/assets/environment/street_kit/" in scene_path


func _collect_markers(node: Node, output: Array[Marker3D]) -> void:
	if node is Marker3D:
		output.append(node as Marker3D)
	for child in node.get_children():
		_collect_markers(child, output)


func _visual_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		var relative := _relative_transform(root, mesh_instance)
		var mesh_bounds := relative * mesh_instance.get_aabb()
		if not has_bounds:
			bounds = mesh_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(mesh_bounds)
	return bounds


func _relative_transform(root: Node3D, descendant: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node = descendant
	while current != null and current != root:
		if current is Node3D:
			chain.push_front(current as Node3D)
		current = current.get_parent()
	var result := Transform3D.IDENTITY
	for node in chain:
		result *= node.transform
	return result


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)


func _vector3_array(value: Vector3) -> Array[float]:
	return [snappedf(value.x, 0.0001), snappedf(value.y, 0.0001), snappedf(value.z, 0.0001)]


func _array_vector3(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
