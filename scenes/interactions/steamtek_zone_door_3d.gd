class_name SteamtekZoneDoor3D
extends SteamtekInteractable3D

signal zone_transition_requested(target_scene_path: String, target_spawn_id: String)

@export_file("*.tscn") var target_scene_path := ""
@export var target_spawn_id := ""


func can_interact(actor: Node) -> bool:
	return super.can_interact(actor) and not target_scene_path.is_empty()


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	interaction_requested.emit(actor)
	zone_transition_requested.emit(target_scene_path, target_spawn_id)
