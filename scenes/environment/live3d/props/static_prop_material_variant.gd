@tool
extends Node3D

@export var variant_material: Material:
	set(value):
		variant_material = value
		if is_inside_tree():
			call_deferred("_apply_variant_material")


func _enter_tree() -> void:
	call_deferred("_apply_variant_material")


func _ready() -> void:
	_apply_variant_material()


func _apply_variant_material() -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null:
			mesh_instance.material_override = variant_material
