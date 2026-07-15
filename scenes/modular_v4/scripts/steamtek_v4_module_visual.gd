@tool
extends Node2D

enum ModuleKind { PLAIN, WINDOW, DOOR, UTILITY, ROOF, CORNER, END_CAP }
enum AxisFamily { FRONT, SIDE }

const AXIS_A := Vector2(313.534, -90.509)
const AXIS_B := Vector2(-181.020, -156.768)
const STOREY_RISE := 219.0

@export var module_kind: ModuleKind = ModuleKind.PLAIN:
	set(value):
		module_kind = value
		queue_redraw()
@export var axis_family: AxisFamily = AxisFamily.FRONT:
	set(value):
		axis_family = value
		queue_redraw()

var wall_dark := Color("#252a2c")
var wall_mid := Color("#343a3c")
var wall_light := Color("#464c4d")
var steel_dark := Color("#171c1e")
var steel_mid := Color("#2c3234")
var copper := Color("#76543d")
var grime := Color("#111617")
var glass := Color("#19262b")


func _ready() -> void:
	queue_redraw()


func _axis() -> Vector2:
	return AXIS_A if axis_family == AxisFamily.FRONT else AXIS_B


func _point(u: float, v: float) -> Vector2:
	return _axis() * u + Vector2(0.0, -STOREY_RISE * v)


func _quad(u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([_point(u0, v0), _point(u1, v0), _point(u1, v1), _point(u0, v1)])


func _draw() -> void:
	if module_kind == ModuleKind.ROOF:
		_draw_roof()
		return
	if module_kind == ModuleKind.CORNER:
		_draw_corner()
		return
	_draw_facade()


func _draw_facade() -> void:
	var outline := PackedVector2Array([_point(0.0, 0.0), _point(1.0, 0.0), _point(1.0, 1.0), _point(0.0, 1.0)])
	draw_colored_polygon(outline, wall_mid)
	draw_polyline(outline + PackedVector2Array([outline[0]]), steel_dark, 5.0, true)
	for row in range(1, 4):
		var v := float(row) / 4.0
		draw_line(_point(0.02, v), _point(0.98, v), Color(wall_dark, 0.9), 3.0, true)
	for column in range(1, 5):
		var u := float(column) / 5.0
		var stagger := 0.025 if column % 2 == 0 else -0.018
		draw_line(_point(u + stagger, 0.04), _point(u, 0.96), Color(wall_light, 0.32), 2.0, true)
	draw_colored_polygon(_quad(0.06, 0.27, 0.08, 0.22), Color("#2a3031"))
	draw_colored_polygon(_quad(0.73, 0.94, 0.58, 0.78), Color("#303536"))
	draw_line(_point(0.11, 0.48), _point(0.28, 0.43), Color(grime, 0.8), 4.0, true)
	draw_line(_point(0.63, 0.16), _point(0.82, 0.10), Color(grime, 0.65), 5.0, true)
	draw_colored_polygon(_quad(0.0, 1.0, 0.0, 0.075), steel_dark)
	draw_colored_polygon(_quad(0.0, 1.0, 0.91, 1.0), steel_mid)
	draw_line(_point(0.0, 0.91), _point(1.0, 0.91), Color("#666c6b"), 3.0, true)
	match module_kind:
		ModuleKind.WINDOW:
			_draw_window()
		ModuleKind.DOOR:
			_draw_door()
		ModuleKind.UTILITY:
			_draw_utility()
		ModuleKind.END_CAP:
			_draw_end_cap()
		_:
			_draw_plain_services()


func _draw_window() -> void:
	var frame := _quad(0.14, 0.86, 0.23, 0.76)
	draw_colored_polygon(frame, steel_dark)
	draw_polyline(frame + PackedVector2Array([frame[0]]), Color("#626867"), 4.0, true)
	draw_colored_polygon(_quad(0.18, 0.82, 0.28, 0.70), glass)
	draw_line(_point(0.50, 0.28), _point(0.50, 0.70), Color("#111719"), 5.0, true)
	draw_line(_point(0.20, 0.34), _point(0.78, 0.31), Color("#677276"), 2.0, true)
	for u in [0.27, 0.39, 0.58, 0.73]:
		draw_line(_point(u, 0.31), _point(u - 0.015, 0.61), Color("#788083", 0.28), 2.0, true)
	_draw_pipe_run(0.10)


func _draw_door() -> void:
	var frame := _quad(0.23, 0.70, 0.02, 0.82)
	draw_colored_polygon(frame, steel_dark)
	draw_polyline(frame + PackedVector2Array([frame[0]]), Color("#686b68"), 5.0, true)
	draw_colored_polygon(_quad(0.28, 0.65, 0.06, 0.76), Color("#202629"))
	draw_line(_point(0.31, 0.61), _point(0.61, 0.58), Color("#3e4546"), 3.0, true)
	draw_circle(_point(0.59, 0.34), 5.0, copper)
	draw_colored_polygon(_quad(0.73, 0.84, 0.33, 0.53), steel_dark)
	draw_polyline(_quad(0.73, 0.84, 0.33, 0.53) + PackedVector2Array([_point(0.73, 0.33)]), Color("#606665"), 3.0, true)
	_draw_pipe_run(0.88)


func _draw_utility() -> void:
	draw_colored_polygon(_quad(0.14, 0.48, 0.16, 0.55), steel_dark)
	draw_colored_polygon(_quad(0.18, 0.44, 0.20, 0.50), Color("#353b3d"))
	for u in [0.57, 0.67, 0.78]:
		draw_line(_point(u, 0.08), _point(u, 0.82), copper, 5.0, true)
	draw_line(_point(0.57, 0.45), _point(0.88, 0.45), copper, 5.0, true)
	draw_circle(_point(0.78, 0.45), 10.0, steel_dark)
	draw_circle(_point(0.78, 0.45), 6.0, Color("#555c5c"))


func _draw_plain_services() -> void:
	_draw_pipe_run(0.22)
	draw_colored_polygon(_quad(0.67, 0.89, 0.22, 0.49), steel_dark)
	draw_colored_polygon(_quad(0.70, 0.86, 0.26, 0.45), Color("#353a3b"))


func _draw_pipe_run(v: float) -> void:
	draw_line(_point(0.06, v), _point(0.94, v + 0.02), Color("#171b1c"), 10.0, true)
	draw_line(_point(0.06, v), _point(0.94, v + 0.02), copper, 5.0, true)


func _draw_end_cap() -> void:
	draw_colored_polygon(_quad(0.0, 0.13, 0.0, 1.0), Color("#1b2021"))
	draw_line(_point(0.13, 0.0), _point(0.13, 1.0), Color("#676b68"), 4.0, true)


func _draw_corner() -> void:
	var old_family := axis_family
	axis_family = AxisFamily.FRONT
	_draw_facade()
	axis_family = AxisFamily.SIDE
	_draw_facade()
	axis_family = old_family
	draw_line(Vector2.ZERO, Vector2(0.0, -STOREY_RISE), Color("#777b77"), 8.0, true)


func _draw_roof() -> void:
	var roof := PackedVector2Array([Vector2.ZERO, AXIS_A, AXIS_A + AXIS_B, AXIS_B])
	draw_colored_polygon(roof, Color("#202628"))
	draw_polyline(roof + PackedVector2Array([roof[0]]), Color("#555b5b"), 4.0, true)
	draw_line(AXIS_A * 0.5, AXIS_B + AXIS_A * 0.5, Color("#111617"), 2.0, true)
	draw_line(AXIS_B * 0.5, AXIS_A + AXIS_B * 0.5, Color("#3c4243"), 2.0, true)
	draw_colored_polygon(PackedVector2Array([AXIS_A * 0.20 + AXIS_B * 0.20, AXIS_A * 0.42 + AXIS_B * 0.20, AXIS_A * 0.42 + AXIS_B * 0.43, AXIS_A * 0.20 + AXIS_B * 0.43]), Color("#2d3334"))
	draw_line(AXIS_A * 0.08 + AXIS_B * 0.78, AXIS_A * 0.92 + AXIS_B * 0.78, Color("#111617"), 5.0, true)
