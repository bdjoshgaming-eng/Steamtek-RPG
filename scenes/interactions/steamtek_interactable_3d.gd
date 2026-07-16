class_name SteamtekInteractable3D
extends Area3D

signal interaction_requested(actor: Node)

@export var interaction_prompt := "Interact"
@export var interaction_enabled := true


func can_interact(_actor: Node) -> bool:
	return interaction_enabled and is_visible_in_tree()


func get_interaction_prompt() -> String:
	return interaction_prompt


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	interaction_requested.emit(actor)
