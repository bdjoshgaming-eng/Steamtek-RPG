extends Node3D
class_name SteamtekQuestBubble3D

## Floating speech-bubble text near an NPC/interactable, tracking its 3D
## position onto a screen-space CanvasLayer each frame. Pairs with (does
## not replace) SteamtekQuestMarker3D's icon-only "!" — this one carries
## actual text, and only shows once the camera (a fixed-offset proxy for
## the player, per SteamtekTransitionLevel3D's camera-follow) is close.

@export var bubble_text: String = "":
	set(value):
		bubble_text = value
		if is_instance_valid(label):
			label.text = value
@export var show_radius := 4.0

@onready var canvas: CanvasLayer = $CanvasLayer
@onready var panel: Panel = $CanvasLayer/Panel
@onready var label: Label = $CanvasLayer/Panel/Label

var _camera: Camera3D


func _ready() -> void:
	label.text = bubble_text
	panel.visible = false


func _process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return

	var distance := _camera.global_position.distance_to(global_position)
	if distance > show_radius:
		panel.visible = false
		return

	var screen_pos := _camera.unproject_position(global_position)
	if _camera.is_position_behind(global_position):
		panel.visible = false
		return

	panel.visible = true
	# The tail (a small triangle hanging off the panel's bottom-center,
	# see SteamtekQuestBubble3D.tscn) should point at screen_pos, not the
	# panel's own center — so anchor by bottom-center plus the tail's
	# height, not a simple half-size centering.
	const TAIL_HEIGHT := 12.0
	panel.position = screen_pos - Vector2(panel.size.x * 0.5, panel.size.y + TAIL_HEIGHT)
