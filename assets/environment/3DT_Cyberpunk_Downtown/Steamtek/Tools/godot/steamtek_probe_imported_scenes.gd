extends SceneTree

const REPORT_PATH := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Godot_Direct_FBX_Probe.json"
const SOURCE_PATHS := [
	"res://assets/environment/3DT_Cyberpunk_Downtown/FBX/Walls/SM_3DT_Apartment_Wall_Piece_A_01.fbx",
	"res://assets/environment/3DT_Cyberpunk_Downtown/FBX/Road/SM_3DT_Road_01.fbx",
	"res://assets/environment/3DT_Cyberpunk_Downtown/FBX/Windows/SM_3DT_Window_A_01.fbx",
	"res://assets/environment/3DT_Cyberpunk_Downtown/FBX/Pipes/SM_3DT_Pipe_01.fbx",
	"res://assets/environment/3DT_Cyberpunk_Downtown/FBX/Props/SM_3DT_Crate.fbx",
	"res://assets/environment/3DT_Cyberpunk_Downtown/FBX/Signs/SM_3DT_Sign_Hotel.fbx",
]


func _init() -> void:
	var assets: Array[Dictionary] = []
	var errors: Array[Dictionary] = []
	for source_path in SOURCE_PATHS:
		var packed := load(source_path) as PackedScene
		if packed == null:
			errors.append({"source": source_path, "error": "load_failed"})
			continue
		var instance := packed.instantiate()
		if not instance is Node3D:
			errors.append({"source": source_path, "error": "root_is_not_node3d"})
			instance.free()
			continue
		var root_3d := instance as Node3D
		get_root().add_child(root_3d)
		var mesh_instances: Array[MeshInstance3D] = []
		_collect_meshes(root_3d, mesh_instances)
		var meshes: Array[Dictionary] = []
		var combined := AABB()
		var has_bounds := false
		for mesh_instance in mesh_instances:
			if mesh_instance.mesh == null:
				continue
			var relative := _relative_transform(root_3d, mesh_instance)
			var bounds := relative * mesh_instance.get_aabb()
			combined = bounds if not has_bounds else combined.merge(bounds)
			has_bounds = true
			var materials: Array[String] = []
			for surface_index in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.mesh.surface_get_material(surface_index)
				materials.append(material.resource_name if material != null else "")
			meshes.append({
				"name": str(mesh_instance.name),
				"transform": _transform_array(relative),
				"bounds_position": _vector3_array(bounds.position),
				"bounds_size": _vector3_array(bounds.size),
				"materials": materials,
			})
		assets.append({
			"source": source_path,
			"root_name": str(root_3d.name),
			"mesh_count": meshes.size(),
			"bounds_position": _vector3_array(combined.position),
			"bounds_size": _vector3_array(combined.size),
			"meshes": meshes,
		})
		root_3d.free()

	var report := {
		"schema": "SteamtekGodotDirectFBXProbe-1",
		"godot_version": Engine.get_version_info(),
		"assets": assets,
		"errors": errors,
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write " + REPORT_PATH)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("STEAMTEK_GODOT_DIRECT_FBX_PROBE=" + JSON.stringify(report))
	quit(1 if not errors.is_empty() else 0)


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)


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


func _transform_array(value: Transform3D) -> Array:
	return [
		_vector3_array(value.basis.x),
		_vector3_array(value.basis.y),
		_vector3_array(value.basis.z),
		_vector3_array(value.origin),
	]
