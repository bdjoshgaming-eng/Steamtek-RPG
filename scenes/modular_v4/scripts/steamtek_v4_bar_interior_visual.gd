@tool
extends Node2D

const FLOOR := Color("#201f1d")
const FLOOR_ALT := Color("#292724")
const WALL := Color("#373633")
const STEEL := Color("#161b1c")
const COPPER := Color("#76523a")
const WOOD := Color("#493729")


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([-720, -430, 720, -430, 720, 430, -720, 430]), FLOOR)
	for x in range(-720, 721, 120):
		draw_line(Vector2(x, -430), Vector2(x, 430), FLOOR_ALT, 3.0, true)
	for y in range(-430, 431, 100):
		draw_line(Vector2(-720, y), Vector2(720, y), FLOOR_ALT, 3.0, true)
	# Back and side walls.
	draw_colored_polygon(PackedVector2Array([-720, -430, 720, -430, 655, -300, -655, -300]), WALL)
	draw_colored_polygon(PackedVector2Array([-720, -430, -655, -300, -655, 430, -720, 430]), WALL.darkened(0.14))
	# Long pressure-bar counter.
	draw_colored_polygon(PackedVector2Array([-500, -165, 355, -165, 410, -80, -445, -80]), WOOD)
	draw_polyline(PackedVector2Array([-500, -165, 355, -165, 410, -80, -445, -80, -500, -165]), COPPER, 6.0, true)
	for x in range(-410, 331, 92):
		draw_circle(Vector2(x, -116), 14.0, STEEL)
		draw_circle(Vector2(x, -116), 6.0, COPPER)
	# Back-bar tanks and pipework.
	for x in [-430.0, -285.0, -140.0, 5.0, 150.0, 295.0]:
		draw_rect(Rect2(x, -352, 82, 116), STEEL, true)
		draw_rect(Rect2(x + 10, -340, 62, 64), Color("#282d2c"), true)
		draw_line(Vector2(x + 41, -235), Vector2(x + 41, -190), COPPER, 7.0, true)
	# Tables and stools.
	for center in [Vector2(-350, 115), Vector2(35, 145), Vector2(405, 105)]:
		draw_circle(center, 52.0, WOOD)
		draw_circle(center, 52.0, COPPER, false, 5.0)
		for offset in [Vector2(-72, 0), Vector2(72, 0), Vector2(0, 66)]:
			draw_circle(center + offset, 20.0, STEEL)
	# Entry threshold.
	draw_line(Vector2(-105, 386), Vector2(105, 386), COPPER, 9.0, true)
