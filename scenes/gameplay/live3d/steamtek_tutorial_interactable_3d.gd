class_name SteamtekTutorialInteractable3D
extends SteamtekInteractable3D

signal tutorial_action_requested(action_id: String, actor: Node, source: Node)

@export var action_id := ""
@export var single_use := false
@export var completed_prompt := "Completed"

var was_used := false


func can_interact(actor: Node) -> bool:
	return super.can_interact(actor) and (not single_use or not was_used)


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	interaction_requested.emit(actor)
	tutorial_action_requested.emit(action_id, actor, self)
	if single_use:
		was_used = true
		interaction_prompt = completed_prompt


func mark_available(available: bool) -> void:
	interaction_enabled = available


func mark_used() -> void:
	was_used = true
	interaction_prompt = completed_prompt
