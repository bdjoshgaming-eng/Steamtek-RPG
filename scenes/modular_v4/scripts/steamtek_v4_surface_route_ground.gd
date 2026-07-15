@tool
extends Node2D

const AXIS_A := Vector2(313.534, -90.509)
const AXIS_B := Vector2(-181.020, -156.768)

@export_range(8, 24) var width_cells := 17:
	set(value):
		width_cells = value
		queue_redraw()
@export_range(8, 20) var depth_cells := 13:
	set(value):
		depth_cells = value
		queue_redraw()


func _draw() -> void:
	for x in range(-2, width_cells):
		for y in range(-2, depth_cells):
			var origin := AXIS_A * x + AXIS_B * y
			var tile := PackedVector2Array([origin, origin + AXIS_A, origin + AXIS_A + AXIS_B, origin + AXIS_B])
			var variation := float(abs(x * 23 + y * 31) % 6) * 0.008
			var base := Color(0.105 + variation, 0.122 + variation, 0.126 + variation, 1.0)
			draw_colored_polygon(tile, base)
			draw_polyline(tile + PackedVector2Array([tile[0]]), Color("#2e3435"), 2.0, true)
			if abs(x * 7 + y * 11) % 10 == 0:
				var wet := PackedVector2Array([
					origin + AXIS_A * 0.18 + AXIS_B * 0.34,
					origin + AXIS_A * 0.74 + AXIS_B * 0.38,
					origin + AXIS_A * 0.68 + AXIS_B * 0.61,
					origin + AXIS_A * 0.25 + AXIS_B * 0.57,
				])
				draw_colored_polygon(wet, Color(0.055, 0.075, 0.08, 0.72))
				draw_polyline(wet + PackedVector2Array([wet[0]]), Color(0.5, 0.55, 0.55, 0.20), 2.0, true)
	# A darker straight street spine, expressed on the same locked A/B basis.
	var street := PackedVector2Array([
		AXIS_A * 4.0 + AXIS_B * -1.0,
		AXIS_A * 12.0 + AXIS_B * -1.0,
		AXIS_A * 12.0 + AXIS_B * 2.1,
		AXIS_A * 4.0 + AXIS_B * 2.1,
	])
	draw_colored_polygon(street, Color(0.065, 0.078, 0.082, 0.92))
	draw_polyline(street + PackedVector2Array([street[0]]), Color("#3a4141"), 4.0, true)
	for i in range(4, 13):
		var seam_origin := AXIS_A * float(i) + AXIS_B * -1.0
		draw_line(seam_origin, seam_origin + AXIS_B * 3.1, Color(0.19, 0.21, 0.21, 0.58), 2.0, true)
	# Drainage seam follows the street's far curb.
	draw_line(AXIS_A * 4.0 + AXIS_B * 2.0, AXIS_A * 12.0 + AXIS_B * 2.0, Color("#080d0e"), 14.0, true)
	draw_line(AXIS_A * 4.0 + AXIS_B * 2.03, AXIS_A * 12.0 + AXIS_B * 2.03, Color(0.46, 0.50, 0.48, 0.32), 2.0, true)
