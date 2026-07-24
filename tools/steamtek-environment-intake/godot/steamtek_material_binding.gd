@tool
extends Node3D

## Applies shared external materials to imported source surfaces without
## modifying the vendor FBX or duplicating the imported ArrayMesh.

@export var material_bindings: Dictionary = {}
@export var warn_on_unresolved_surface := true

var _last_unresolved: PackedStringArray = []


func _ready() -> void:
	apply_material_bindings()


func apply_material_bindings() -> PackedStringArray:
	var unresolved := PackedStringArray()
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_meshes(self, mesh_instances)
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.mesh.surface_get_material(surface_index)
			var source_name := source_material.resource_name if source_material != null else ""
			var resolved := _resolve_binding(source_name)
			if resolved == null:
				var label := "%s[%d]:%s" % [
					mesh_instance.get_path() if mesh_instance.is_inside_tree() else mesh_instance.name,
					surface_index,
					source_name,
				]
				if label not in unresolved:
					unresolved.append(label)
				continue
			mesh_instance.set_surface_override_material(surface_index, resolved)
			if resolved is BaseMaterial3D:
				var base_material := resolved as BaseMaterial3D
				if base_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mesh_instance.sorting_use_aabb_center = true
	_last_unresolved = unresolved
	if warn_on_unresolved_surface and not unresolved.is_empty():
		push_warning("Steamtek material bindings unresolved: " + ", ".join(unresolved))
	return unresolved


func unresolved_surfaces() -> PackedStringArray:
	return _last_unresolved


func _resolve_binding(source_name: String) -> Material:
	if material_bindings.has(source_name):
		return material_bindings[source_name] as Material
	var normalized_source := _normalized_material_name(source_name)
	for key in material_bindings:
		if _normalized_material_name(str(key)) == normalized_source:
			return material_bindings[key] as Material
	return null


func _normalized_material_name(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	var duplicate_suffix := RegEx.new()
	duplicate_suffix.compile("\\.\\d{3}$")
	normalized = duplicate_suffix.sub(normalized, "")
	normalized = normalized.replace("_", " ").replace("-", " ")
	while "  " in normalized:
		normalized = normalized.replace("  ", " ")
	return normalized


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)
