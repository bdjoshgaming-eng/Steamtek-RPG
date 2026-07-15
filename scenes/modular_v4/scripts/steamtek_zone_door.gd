extends Area2D

@export_file("*.tscn") var target_scene: String
@export var prompt_text := "Enter apartment"

var _player_nearby := false
@onready var prompt: Label = get_node_or_null("Prompt")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt != null:
		prompt.text = prompt_text + "  [Enter]"
		prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	var pressed := event.is_action_pressed("ui_accept")
	if InputMap.has_action("interact"):
		pressed = pressed or event.is_action_pressed("interact")
	if pressed and not target_scene.is_empty():
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(target_scene)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D or body.is_in_group("player"):
		_player_nearby = true
		if prompt != null:
			prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D or body.is_in_group("player"):
		_player_nearby = false
		if prompt != null:
			prompt.visible = false
