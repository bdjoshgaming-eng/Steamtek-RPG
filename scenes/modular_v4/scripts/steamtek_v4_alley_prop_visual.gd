@tool
extends Node2D

enum PropKind {
	PRESSURE_BIN,
	DUMPSTER,
	STEAM_VENT,
	UTILITY_CABINET,
	PIPE_RACK,
	STREET_FIXTURE,
	BARRIER,
}

@export var prop_kind: PropKind = PropKind.PRESSURE_BIN:
	set(value):
		prop_kind = value
		queue_redraw()

const IRON := Color("#242a2b")
const IRON_DARK := Color("#121718")
const IRON_LIGHT := Color("#4d5554")
const COPPER := Color("#74513a")
const CONCRETE := Color("#343a3a")
const GRIME := Color("#090d0e")


func _draw() -> void:
	match prop_kind:
		PropKind.PRESSURE_BIN:
			_draw_pressure_bin()
		PropKind.DUMPSTER:
			_draw_dumpster()
		PropKind.STEAM_VENT:
			_draw_steam_vent()
		PropKind.UTILITY_CABINET:
			_draw_utility_cabinet()
		PropKind.PIPE_RACK:
			_draw_pipe_rack()
		PropKind.STREET_FIXTURE:
			_draw_street_fixture()
		PropKind.BARRIER:
			_draw_barrier()


func _draw_pressure_bin() -> void:
	var body := PackedVector2Array([-48, 5, 48, 5, 38, -92, -38, -92])
	draw_colored_polygon(body, IRON)
	draw_polyline(body + PackedVector2Array([body[0]]), IRON_LIGHT, 4.0, true)
	draw_line(Vector2(-34, -70), Vector2(34, -70), Color("#101516"), 5.0, true)
	draw_line(Vector2(-28, -42), Vector2(28, -42), COPPER, 4.0, true)
	draw_circle(Vector2(0, -17), 7.0, Color("#101516"))
	_draw_grime(Rect2(-36, -88, 72, 88), 7)


func _draw_dumpster() -> void:
	var body := PackedVector2Array([-94, 8, 94, 8, 78, -88, -78, -88])
	draw_colored_polygon(body, Color("#29302f"))
	draw_polyline(body + PackedVector2Array([body[0]]), IRON_LIGHT, 5.0, true)
	draw_colored_polygon(PackedVector2Array([-86, -88, 76, -88, 50, -112, -60, -112]), IRON_DARK)
	for x in [-48.0, 0.0, 48.0]:
		draw_line(Vector2(x, -76), Vector2(x, -8), Color("#151b1b"), 4.0, true)
	draw_line(Vector2(-70, -27), Vector2(70, -27), COPPER.darkened(0.2), 3.0, true)
	_draw_grime(Rect2(-78, -84, 156, 88), 11)


func _draw_steam_vent() -> void:
	draw_colored_polygon(PackedVector2Array([-60, 12, 60, 12, 47, -34, -47, -34]), CONCRETE)
	draw_polyline(PackedVector2Array([-60, 12, 60, 12, 47, -34, -47, -34, -60, 12]), IRON_LIGHT, 4.0, true)
	for x in range(-38, 39, 13):
		draw_line(Vector2(x, -27), Vector2(x + 8, 3), IRON_DARK, 5.0, true)


func _draw_utility_cabinet() -> void:
	draw_rect(Rect2(-55, -126, 110, 126), IRON, true)
	draw_rect(Rect2(-55, -126, 110, 126), IRON_LIGHT, false, 4.0)
	draw_rect(Rect2(-39, -105, 78, 62), Color("#1a2020"), true)
	for y in [-91.0, -77.0, -63.0]:
		draw_line(Vector2(-29, y), Vector2(24, y), Color("#4a514f"), 3.0, true)
	draw_circle(Vector2(31, -20), 6.0, COPPER)
	_draw_grime(Rect2(-48, -118, 96, 115), 9)


func _draw_pipe_rack() -> void:
	for y in [-148.0, -112.0, -76.0]:
		draw_line(Vector2(-118, y), Vector2(118, y + 34), IRON_DARK, 16.0, true)
		draw_line(Vector2(-118, y), Vector2(118, y + 34), COPPER.darkened(0.15), 8.0, true)
	for x in [-76.0, 4.0, 84.0]:
		draw_line(Vector2(x, -166), Vector2(x, -20), IRON_LIGHT.darkened(0.2), 7.0, true)
	draw_circle(Vector2(104, -42), 17.0, IRON_DARK)
	draw_circle(Vector2(104, -42), 11.0, COPPER)


func _draw_street_fixture() -> void:
	draw_colored_polygon(PackedVector2Array([-42, 10, 42, 10, 31, -24, -31, -24]), CONCRETE)
	draw_rect(Rect2(-10, -188, 20, 166), IRON_DARK, true)
	draw_rect(Rect2(-15, -192, 30, 170), IRON_LIGHT, false, 3.0)
	draw_colored_polygon(PackedVector2Array([-38, -186, 38, -186, 27, -232, -27, -232]), IRON)
	draw_rect(Rect2(-24, -222, 48, 26), Color("#e5e8df"), true)
	draw_line(Vector2(-12, -118), Vector2(12, -118), COPPER, 4.0, true)


func _draw_barrier() -> void:
	draw_colored_polygon(PackedVector2Array([-90, 6, 90, 6, 70, -42, -70, -42]), CONCRETE)
	draw_polyline(PackedVector2Array([-90, 6, 90, 6, 70, -42, -70, -42, -90, 6]), IRON_LIGHT, 4.0, true)
	for x in range(-64, 65, 32):
		draw_line(Vector2(x, -34), Vector2(x + 25, -2), Color("#8a6234"), 9.0, true)


func _draw_grime(area: Rect2, count: int) -> void:
	for i in range(count):
		var px := area.position.x + fmod(float(i * 37 + 11), area.size.x)
		var py := area.position.y + fmod(float(i * 53 + 19), area.size.y)
		draw_circle(Vector2(px, py), 2.0 + float(i % 3), GRIME, false, 2.0)
