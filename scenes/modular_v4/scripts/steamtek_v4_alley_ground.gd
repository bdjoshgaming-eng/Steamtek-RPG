@tool
extends Node2D

const AXIS_A := Vector2(313.534, -90.509)
const AXIS_B := Vector2(-181.020, -156.768)

@export_range(2, 16) var width_cells := 8:
	set(value):
		width_cells = value
		queue_redraw()
@export_range(2, 16) var depth_cells := 8:
	set(value):
		depth_cells = value
		queue_redraw()


func _draw() -> void:
	for x in range(-2, width_cells):
		for y in range(-2, depth_cells):
			var origin := AXIS_A * x + AXIS_B * y
			var tile := PackedVector2Array([origin, origin + AXIS_A, origin + AXIS_A + AXIS_B, origin + AXIS_B])
			var variation := float((abs(x * 17 + y * 29) % 5)) * 0.012
			var base := Color(0.12 + variation, 0.14 + variation, 0.145 + variation, 1.0)
			draw_colored_polygon(tile, base)
			draw_polyline(tile + PackedVector2Array([tile[0]]), Color("#313738"), 2.0, true)
			if (x + y) % 7 == 0:
				draw_line(origin + AXIS_A * 0.20 + AXIS_B * 0.58, origin + AXIS_A * 0.72 + AXIS_B * 0.62, Color("#0c1011"), 4.0, true)
			if abs(x * 11 + y * 7) % 9 == 0:
				var puddle := PackedVector2Array([
					origin + AXIS_A * 0.24 + AXIS_B * 0.35,
					origin + AXIS_A * 0.66 + AXIS_B * 0.39,
					origin + AXIS_A * 0.70 + AXIS_B * 0.58,
					origin + AXIS_A * 0.30 + AXIS_B * 0.55,
				])
				draw_colored_polygon(puddle, Color(0.08, 0.105, 0.11, 0.78))
				draw_polyline(puddle + PackedVector2Array([puddle[0]]), Color(0.46, 0.52, 0.52, 0.25), 2.0, true)
			if abs(x * 5 - y * 13) % 12 == 0:
				var patch := PackedVector2Array([
					origin + AXIS_A * 0.08 + AXIS_B * 0.16,
					origin + AXIS_A * 0.46 + AXIS_B * 0.13,
					origin + AXIS_A * 0.51 + AXIS_B * 0.36,
					origin + AXIS_A * 0.13 + AXIS_B * 0.40,
				])
				draw_colored_polygon(patch, Color("#171d1e"))
