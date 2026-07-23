extends Node3D
class_name SteamtekPlayerChatBubble3D

## WoW/FFXIV-style floating bubble above the player character's head.
## Distinct from SteamtekQuestBubble3D (persistent, marks an NPC/
## interactable) and from SteamtekDialogueBox (the modal panel reserved
## for reading actual quest items like notes) -- this one is for the
## PLAYER CHARACTER's own lines. Two visual modes sharing the same
## panel/label: SPEECH (say/say_sequence, pointed tail -- talking to
## someone) and THOUGHT (think/think_sequence, trailing dots -- inner
## monologue). Advances on the interact key, not a timer (Josh asked for
## click/key-to-advance, not auto-fade).
##
## Panel is a PanelContainer that auto-sizes to its Label's wrapped text
## (a fixed-size Panel clipped/overflowed multi-line text) -- the tail/
## dots are repositioned every frame to track the panel's current size
## for the same reason.

const ADVANCE_ACTION := "interact"
const SPEECH_MODE := "speech"
const THOUGHT_MODE := "thought"

@onready var canvas: CanvasLayer = $CanvasLayer
@onready var panel: PanelContainer = $CanvasLayer/Panel
@onready var label: Label = $CanvasLayer/Panel/Label
@onready var tail: Polygon2D = $CanvasLayer/Panel/Tail
@onready var tail_border_left: Line2D = $CanvasLayer/Panel/TailBorderLeft
@onready var tail_border_right: Line2D = $CanvasLayer/Panel/TailBorderRight
@onready var thought_dot_1: Polygon2D = $CanvasLayer/Panel/ThoughtDot1
@onready var thought_dot_2: Polygon2D = $CanvasLayer/Panel/ThoughtDot2
@onready var thought_dot_3: Polygon2D = $CanvasLayer/Panel/ThoughtDot3

var _camera: Camera3D
var _line_queue: Array = []
var _active := false
var _mode := SPEECH_MODE


func _ready() -> void:
	panel.visible = false
	thought_dot_1.polygon = _circle_polygon(5.0)
	thought_dot_2.polygon = _circle_polygon(3.5)
	thought_dot_3.polygon = _circle_polygon(2.5)
	_apply_mode()


func say(text: String) -> void:
	say_sequence([text])


func say_sequence(lines: Array) -> void:
	_start(lines, SPEECH_MODE)


func think(text: String) -> void:
	think_sequence([text])


func think_sequence(lines: Array) -> void:
	_start(lines, THOUGHT_MODE)


func _start(lines: Array, mode: String) -> void:
	_mode = mode
	_apply_mode()
	_line_queue = lines.duplicate()
	_show_next_line()


func _apply_mode() -> void:
	var is_thought := _mode == THOUGHT_MODE
	tail.visible = not is_thought
	tail_border_left.visible = not is_thought
	tail_border_right.visible = not is_thought
	thought_dot_1.visible = is_thought
	thought_dot_2.visible = is_thought
	thought_dot_3.visible = is_thought


func _show_next_line() -> void:
	if _line_queue.is_empty():
		_active = false
		panel.visible = false
		return
	label.text = String(_line_queue.pop_front())
	_active = true


func _process(_delta: float) -> void:
	if not _active:
		return
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	if InputMap.has_action(ADVANCE_ACTION) and Input.is_action_just_pressed(ADVANCE_ACTION):
		_show_next_line()
		if not _active:
			return
	if _camera.is_position_behind(global_position):
		panel.visible = false
		return
	panel.visible = true
	var screen_pos := _camera.unproject_position(global_position)
	const TAIL_HEIGHT := 10.0
	panel.position = screen_pos - Vector2(panel.size.x * 0.5, panel.size.y + TAIL_HEIGHT)
	var anchor := Vector2(panel.size.x * 0.5, panel.size.y)
	if _mode == THOUGHT_MODE:
		thought_dot_1.position = anchor + Vector2(-6, 6)
		thought_dot_2.position = anchor + Vector2(-13, 15)
		thought_dot_3.position = anchor + Vector2(-19, 23)
	else:
		tail.position = anchor
		tail_border_left.position = anchor
		tail_border_right.position = anchor


func _circle_polygon(radius: float, segments: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
