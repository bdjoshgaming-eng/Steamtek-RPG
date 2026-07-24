extends SceneTree

const DEFAULT_SOURCE_ROOT := "res://assets/environment/3DT_Cyberpunk_Downtown/FBX"
const DEFAULT_REPORT_PATH := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Godot_Full_Source_Probe.json"


func _init() -> void:
	var arguments := _named_arguments()
	var source_root := str(arguments.get("source-root", DEFAULT_SOURCE_ROOT))
	var report_path := str(arguments.get("report", DEFAULT_REPORT_PATH))
	var source_paths: Array[String] = []
	_collect_source_paths(source_root, source_paths)
	source_paths.sort()
	var assets: Array[Dictionary] = []
	var errors: Array[Dictionary] = []
	for source_path in source_paths:
		var result := _probe_source(source_path)
		if result.has("error"):
			errors.append(result)
		else:
			assets.append(result)
	var report := {
		"schema": "SteamtekGodotSourceProbe-1",
		"godot_version": Engine.get_version_info(),
		"source_root": source_root,
		"asset_count": assets.size(),
		"assets": assets,
		"errors": errors,
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write " + report_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("STEAMTEK_GODOT_SOURCE_PROBE_TOTALS=" + JSON.stringify({
		"assets": assets.size(),
		"errors": errors.size(),
		"report": report_path,
	}))
	quit(0 if errors.is_empty() else 1)


func _probe_source(source_path: String) -> Dictionary:
	var packed := load(source_path) as PackedScene
	if packed == null:
		return {"source": source_path, "error": "load_failed"}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"source": source_path, "error": "root_is_not_node3d"}
	var root_3d := instance as Node3D
	get_root().add_child(root_3d)
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_meshes(root_3d, mesh_instances)
	var bounds := AABB()
	var has_bounds := false
	var materials: Array[String] = []
	var surface_count := 0
	var vertices := 0
	var triangles := 0
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		var mesh_bounds := _relative_transform(root_3d, mesh_instance) * mesh_instance.get_aabb()
		bounds = mesh_bounds if not has_bounds else bounds.merge(mesh_bounds)
		has_bounds = true
		for surface_index in mesh_instance.mesh.get_surface_count():
			surface_count += 1
			var material := mesh_instance.mesh.surface_get_material(surface_index)
			var material_name := material.resource_name if material != null else ""
			if material_name not in materials:
				materials.append(material_name)
			vertices += mesh_instance.mesh.surface_get_array_len(surface_index)
			var indices: int = mesh_instance.mesh.surface_get_array_index_len(surface_index)
			triangles += indices / 3 if indices > 0 else 0
	if not has_bounds:
		root_3d.free()
		return {"source": source_path, "error": "no_mesh_bounds"}
	materials.sort()
	var animation_players: Array[AnimationPlayer] = []
	_collect_animation_players(root_3d, animation_players)
	var animation_count := 0
	for player in animation_players:
		for library_name in player.get_animation_library_list():
			var library := player.get_animation_library(library_name)
			if library != null:
				animation_count += library.get_animation_list().size()
	var result := {
		"source": source_path,
		"root_name": str(root_3d.name),
		"mesh_count": mesh_instances.size(),
		"surface_count": surface_count,
		"materials": materials,
		"vertices": vertices,
		"triangles": triangles,
		"bounds_position": _vector3_array(bounds.position),
		"bounds_size": _vector3_array(bounds.size),
		"animation_count": animation_count,
	}
	root_3d.free()
	return result


func _collect_source_paths(directory_path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_source_paths(child_path, output)
		elif entry.get_extension().to_lower() == "fbx":
			output.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)


func _collect_animation_players(node: Node, output: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		output.append(node as AnimationPlayer)
	for child in node.get_children():
		_collect_animation_players(child, output)


func _relative_transform(root_3d: Node3D, descendant: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node = descendant
	while current != null and current != root_3d:
		if current is Node3D:
			chain.push_front(current as Node3D)
		current = current.get_parent()
	var result := Transform3D.IDENTITY
	for node in chain:
		result *= node.transform
	return result


func _vector3_array(value: Vector3) -> Array[float]:
	return [
		snappedf(value.x, 0.000001),
		snappedf(value.y, 0.000001),
		snappedf(value.z, 0.000001),
	]

func _named_arguments() -> Dictionary:
	var result := {}
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		var key := argument.substr(2, separator - 2)
		var value := argument.substr(separator + 1)
		result[key] = value
	return result
