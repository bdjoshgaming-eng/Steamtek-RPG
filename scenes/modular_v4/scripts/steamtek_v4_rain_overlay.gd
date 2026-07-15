@tool
extends Node2D

@export_range(40, 320) var streak_count := 180
@export var velocity := Vector2(-115, 760)
@export var streak_length := 22.0
@export var rain_color := Color(0.62, 0.75, 0.82, 0.34)

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var direction := velocity.normalized()
	for i in range(streak_count):
		var seed_x := fmod(float(i * 193 + 47), viewport_size.x + 180.0) - 90.0
		var seed_y := fmod(float(i * 109 + 17), viewport_size.y + 120.0) - 60.0
		var travel := fmod(_time * velocity.y + float(i * 31), viewport_size.y + 180.0)
		var p := Vector2(seed_x + _time * velocity.x, seed_y + travel)
		p.x = fmod(p.x + viewport_size.x + 180.0, viewport_size.x + 180.0) - 90.0
		p.y = fmod(p.y + viewport_size.y + 120.0, viewport_size.y + 120.0) - 60.0
		draw_line(p, p - direction * streak_length, rain_color, 1.35, true)
