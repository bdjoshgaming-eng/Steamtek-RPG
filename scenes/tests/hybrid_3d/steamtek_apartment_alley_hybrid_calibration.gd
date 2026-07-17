extends Node3D

## First Shadowrun-style Steamtek environment gate:
## a painted apartment card in locked 3D camera space with the production
## protagonist moving on a real 3D floor. The card is intentionally unsplit;
## foreground/occlusion layers are the next gate after scale is approved.

@export var camera_follow_response := 9.0

@onready var character: SteamtekHumanoidCharacter3D = $VesperKane_PlayerCharacter_v01
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D


func _ready() -> void:
	_snap_camera_to_character()
	camera.look_at(character.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x, 0.0, target.z)
	var weight := 1.0 - exp(-camera_follow_response * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(desired, weight)


func _snap_camera_to_character() -> void:
	var target := character.global_position
	camera_rig.global_position = Vector3(target.x, 0.0, target.z)
