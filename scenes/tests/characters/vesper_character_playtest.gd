extends Node3D

@export var camera_follow_response := 9.0

@onready var character: CharacterBody3D = $VesperKane_PlayerCharacter_v01
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var interaction_prompt: Label = $PlaytestUI/InteractionPrompt


func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_snap_camera_to_character()
	character.interaction_focus_changed.connect(_on_interaction_focus_changed)
	_on_interaction_focus_changed("", null)


func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x, 0.0, target.z)
	var weight := 1.0 - exp(-camera_follow_response * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(desired, weight)


func _snap_camera_to_character() -> void:
	var target := character.global_position
	camera_rig.global_position = Vector3(target.x, 0.0, target.z)


func _on_interaction_focus_changed(prompt_text: String, _target: Node) -> void:
	interaction_prompt.visible = not prompt_text.is_empty()
	interaction_prompt.text = "[ E ]  " + prompt_text
