extends Node3D

const REVIEW_CHARACTER_SCENE := preload("res://scenes/characters/player/VesperKane_PlayerCharacter_v01.tscn")

@onready var standalone_review_camera: Camera3D = $StandaloneReviewCamera


func _ready() -> void:
	var running_as_standalone_scene := get_tree().current_scene == self
	standalone_review_camera.current = running_as_standalone_scene
	if running_as_standalone_scene:
		standalone_review_camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		_spawn_standalone_review_character()


func _spawn_standalone_review_character() -> void:
	var review_character := REVIEW_CHARACTER_SCENE.instantiate() as Node3D
	if review_character == null:
		push_error("Steamtek apartment review character could not be instantiated.")
		return
	review_character.name = "StandaloneReviewC001"
	review_character.position = Vector3(0.0, 0.08, 0.0)
	add_child(review_character)
	if review_character.has_method("set_player_controlled"):
		review_character.call("set_player_controlled", false)
