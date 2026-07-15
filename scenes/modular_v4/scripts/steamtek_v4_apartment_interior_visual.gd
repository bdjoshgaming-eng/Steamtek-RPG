@tool
extends Node2D

const FLOOR := Color("#252a2a")
const FLOOR_ALT := Color("#202525")
const WALL := Color("#353b3b")
const STEEL := Color("#171c1d")
const COPPER := Color("#704d36")


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([-560, -360, 560, -360, 560, 360, -560, 360]), FLOOR)
	for x in range(-560, 561, 110):
		draw_line(Vector2(x, -360), Vector2(x, 360), FLOOR_ALT, 3.0, true)
	for y in range(-360, 361, 90):
		draw_line(Vector2(-560, y), Vector2(560, y), FLOOR_ALT, 3.0, true)
	draw_colored_polygon(PackedVector2Array([-560, -360, 560, -360, 500, -248, -500, -248]), WALL)
	draw_colored_polygon(PackedVector2Array([-560, -360, -500, -248, -500, 360, -560, 360]), WALL.darkened(0.12))
	# Rain window and radiator.
	draw_rect(Rect2(170, -326, 230, 70), STEEL, true)
	draw_rect(Rect2(183, -316, 204, 47), Color("#243840"), true)
	for x in range(195, 378, 34):
		draw_line(Vector2(x, -310), Vector2(x - 13, -274), Color(0.65, 0.75, 0.78, 0.22), 2.0, true)
	for x in range(198, 376, 25):
		draw_rect(Rect2(x, -225, 14, 54), STEEL, true)
	# Bed.
	draw_colored_polygon(PackedVector2Array([-398, 192, -150, 192, -126, 90, -374, 90]), Color("#20282b"))
	draw_polyline(PackedVector2Array([-398, 192, -150, 192, -126, 90, -374, 90, -398, 192]), Color("#59605e"), 5.0, true)
	draw_colored_polygon(PackedVector2Array([-360, 114, -282, 114, -272, 82, -350, 82]), Color("#77766c"))
	# Workbench and pressure equipment.
	draw_colored_polygon(PackedVector2Array([-390, -72, -105, -72, -77, -150, -362, -150]), Color("#2c302f"))
	draw_polyline(PackedVector2Array([-390, -72, -105, -72, -77, -150, -362, -150, -390, -72]), COPPER, 4.0, true)
	for x in [-330.0, -260.0, -190.0, -120.0]:
		draw_circle(Vector2(x, -132), 15.0, STEEL)
		draw_circle(Vector2(x, -132), 8.0, COPPER)
	# Storage and entry threshold.
	draw_rect(Rect2(350, 68, 118, 154), STEEL, true)
	draw_rect(Rect2(364, 84, 90, 118), WALL, true)
	draw_line(Vector2(-90, 323), Vector2(90, 323), COPPER, 8.0, true)
