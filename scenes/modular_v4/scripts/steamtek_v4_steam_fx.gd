@tool
extends Node2D

@export var active := true
@export var spread := 38.0
@export var rise := 150.0
@export var puff_count := 9
@export var tint := Color(0.78, 0.83, 0.82, 0.23)

var _time := 0.0


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	for i in range(puff_count):
		var phase := fmod(_time * 0.24 + float(i) / float(puff_count), 1.0)
		var sway := sin(float(i) * 2.7 + _time * 1.2) * spread * phase
		var p := Vector2(sway, -phase * rise)
		var radius := 8.0 + phase * 25.0
		var color := tint
		color.a *= sin(phase * PI)
		draw_circle(p, radius, color)
