extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var hero: Node3D = $STK_HERO_BaseBody_01
@onready var status: Label = $ReviewUI/Status

var yaw_degrees := 0.0


func _ready() -> void:
	camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	_update_status()
	await get_tree().process_frame
	await get_tree().process_frame
	_print_runtime_receipt()
	_capture_review_frame()
	print("STK_HERO_BASEBODY_REVIEW_READY=true")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		yaw_degrees -= 15.0
	elif event.is_action_pressed("ui_right"):
		yaw_degrees += 15.0
	else:
		return
	hero.rotation_degrees.y = yaw_degrees
	_update_status()


func _update_status() -> void:
	status.text = "Static repair master     Neutral lighting     Height: 1.83 m / 6 ft     Yaw: %.0f deg" % yaw_degrees


func _print_runtime_receipt() -> void:
	var triangles := 0
	var mesh_count := 0
	for child in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		mesh_count += 1
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var arrays := mesh_instance.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += indices.size() / 3
	print("STK_HERO_BASEBODY_MESH_COUNT=", mesh_count)
	print("STK_HERO_BASEBODY_TRIANGLES=", triangles)
	print("STK_HERO_BASEBODY_ROOT_SCALE=", hero.scale)


func _capture_review_frame() -> void:
	var image := get_viewport().get_texture().get_image()
	var output_path := "res://docs/reviews/characters/STK_HERO_BaseBody_01/STK_HERO_BaseBody_01_GodotReview.png"
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("STK_HERO_BASEBODY_GODOT_CAPTURE=", output_path)
	else:
		push_error("Could not save hero base-body review capture: %s" % error_string(error))
