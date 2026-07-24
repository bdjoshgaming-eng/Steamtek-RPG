extends Node3D

const CAPTURE_DIR := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Visual_QA"
const PRIMARY_ASSET_NODES := [
	"STK_ARCH_Wall_Apartment_A_01",
	"STK_ARCH_Road_01",
	"STK_ARCH_Window_A_01",
	"STK_INFRA_Pipe_01",
	"STK_PROP_Crate_01",
	"STK_PROP_Sign_Emissive_013",
]
const ALL_REVIEW_ASSET_NODES := [
	"STK_ARCH_Wall_Apartment_A_01",
	"STK_ARCH_Road_01",
	"STK_ARCH_Window_A_01",
	"STK_INFRA_Pipe_01",
	"STK_PROP_Crate_01",
	"STK_PROP_Sign_Emissive_013",
	"STK_ARCH_Wall_Apartment_A_01_Snap_Duplicate_2",
	"STK_ARCH_Wall_Apartment_A_01_Snap_Duplicate_3",
	"STK_ARCH_Road_01_Snap_Duplicate_2",
	"STK_ARCH_Road_01_Snap_Duplicate_3",
	"STK_PROP_Sign_Emissive_013_Attachment_Test",
]
const PRESETS := [
	{
		"slug": "overview",
		"label": "Tight six-asset overview",
		"position": Vector3(18.0, 16.0, 18.0),
		"target": Vector3(0.077605, 0.874598, -0.149413),
		"projection": Camera3D.PROJECTION_ORTHOGONAL,
		"size": 10.5,
		"visible_nodes": PRIMARY_ASSET_NODES,
	},
	{
		"slug": "wall_seam",
		"label": "Three-piece wall seam and sign attachment",
		"position": Vector3(-2.309526, 1.65, -1.5),
		"target": Vector3(-2.309526, 0.45, -5.0),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 45.0,
		"visible_nodes": [
			"STK_ARCH_Wall_Apartment_A_01",
			"STK_ARCH_Wall_Apartment_A_01_Snap_Duplicate_2",
			"STK_ARCH_Wall_Apartment_A_01_Snap_Duplicate_3",
			"STK_PROP_Sign_Emissive_013_Attachment_Test",
		],
	},
	{
		"slug": "road_seam",
		"label": "Three-piece road seam",
		"position": Vector3(10.0, 9.0, 22.0),
		"target": Vector3(0.0, 0.061616, 14.866686),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 40.0,
		"visible_nodes": [
			"STK_ARCH_Road_01",
			"STK_ARCH_Road_01_Snap_Duplicate_2",
			"STK_ARCH_Road_01_Snap_Duplicate_3",
		],
	},
	{
		"slug": "crate",
		"label": "Crate material",
		"position": Vector3(-3.5, 1.05, 6.0),
		"target": Vector3(-4.5, 0.326, 5.0),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 38.0,
		"visible_nodes": ["STK_PROP_Crate_01"],
	},
	{
		"slug": "window_front",
		"label": "Window A - front",
		"position": Vector3(-4.5, 1.10, 1.8),
		"target": Vector3(-4.5, 0.812, -2.5),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 38.0,
		"visible_nodes": ["STK_ARCH_Window_A_01"],
		"window_witness": true,
		"witness_z": -2.72,
	},
	{
		"slug": "window_rear",
		"label": "Window A - rear",
		"position": Vector3(-4.5, 1.10, -6.8),
		"target": Vector3(-4.5, 0.812, -2.5),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 38.0,
		"visible_nodes": ["STK_ARCH_Window_A_01"],
		"window_witness": true,
		"witness_z": -2.28,
	},
	{
		"slug": "pole",
		"label": "Pipe / pole scale",
		"position": Vector3(1.0, 2.6, 7.0),
		"target": Vector3(-4.5, 2.303948, 1.5),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 40.0,
		"visible_nodes": ["STK_INFRA_Pipe_01"],
	},
	{
		"slug": "emissive_sign",
		"label": "Emissive sign",
		"position": Vector3(4.5, 0.85, -2.7),
		"target": Vector3(4.5, 0.544188, -5.0),
		"projection": Camera3D.PROJECTION_PERSPECTIVE,
		"fov": 38.0,
		"visible_nodes": ["STK_PROP_Sign_Emissive_013"],
	},
]

var _camera: Camera3D
var _witness: Node3D
var _hud: Label
var _preset_index := 0
var _camera_target := Vector3.ZERO
var _labels_visible := false
var _collision_visible := false


func _ready() -> void:
	_camera = get_node_or_null("QAReviewCamera") as Camera3D
	if _camera == null:
		_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
	_witness = get_node_or_null("WindowTransparencyWitness") as Node3D
	_build_hud()
	if _camera == null:
		push_error("Steamtek pilot review requires QAReviewCamera")
		return
	_apply_preset(0)
	if "--steamtek-capture-material-qa" in OS.get_cmdline_user_args():
		call_deferred("_capture_all")


func _process(delta: float) -> void:
	if _camera == null:
		return
	var pan_input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_input.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_input.y -= 1.0
	if pan_input.is_zero_approx():
		return
	var right := _camera.global_transform.basis.x
	right.y = 0.0
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	if right.length_squared() <= 0.000001 or forward.length_squared() <= 0.000001:
		return
	right = right.normalized()
	forward = forward.normalized()
	var direction := right * pan_input.x + forward * pan_input.y
	if direction.length_squared() <= 0.000001:
		return
	var motion := direction.normalized() * _pan_speed() * delta
	_camera.global_position += motion
	_camera_target += motion
	_camera.look_at(_camera_target, Vector3.UP)
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(0.86)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.16)
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_apply_preset(0)
		KEY_2:
			_apply_preset(1)
		KEY_3:
			_apply_preset(2)
		KEY_4:
			_apply_preset(3)
		KEY_5:
			_apply_preset(4)
		KEY_6:
			_apply_preset(5)
		KEY_7:
			_apply_preset(6)
		KEY_8:
			_apply_preset(7)
		KEY_R:
			_apply_preset(_preset_index)
		KEY_L:
			_labels_visible = not _labels_visible
			_update_label_visibility()
			_refresh_hud()
		KEY_C:
			_collision_visible = not _collision_visible
			get_tree().debug_collisions_hint = _collision_visible
			_refresh_hud()
		KEY_P, KEY_F12:
			_capture_current()


func _apply_preset(index: int) -> void:
	if _camera == null or index < 0 or index >= PRESETS.size():
		return
	_preset_index = index
	var preset: Dictionary = PRESETS[index]
	_camera.projection = int(preset["projection"])
	_camera.position = preset["position"] as Vector3
	_camera_target = preset["target"] as Vector3
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_camera.size = float(preset.get("size", 10.5))
	else:
		_camera.fov = float(preset.get("fov", 40.0))
	_camera.look_at(_camera_target, Vector3.UP)
	_apply_asset_visibility(preset)
	_update_label_visibility()
	_refresh_hud()


func _apply_asset_visibility(preset: Dictionary) -> void:
	var visible_nodes: Array = preset.get("visible_nodes", PRIMARY_ASSET_NODES)
	for node_name in ALL_REVIEW_ASSET_NODES:
		var asset := get_node_or_null(NodePath(str(node_name))) as Node3D
		if asset != null:
			asset.visible = str(node_name) in visible_nodes
	if _witness != null:
		_witness.visible = bool(preset.get("window_witness", false))
		if _witness.visible:
			_witness.position.z = float(preset.get("witness_z", -2.72))


func _update_label_visibility() -> void:
	for child in get_children():
		if not child is Label3D:
			continue
		var label := child as Label3D
		if not _labels_visible:
			label.visible = false
			continue
		if str(label.name) == "ReviewBoundary":
			label.visible = _preset_index == 0
			continue
		var asset_name := str(label.name).trim_prefix("Label_")
		var asset := get_node_or_null(NodePath(asset_name)) as Node3D
		label.visible = asset != null and asset.visible


func _zoom_camera(factor: float) -> void:
	if _camera == null:
		return
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_camera.size = clampf(_camera.size * factor, 1.5, 30.0)
	else:
		var offset := _camera.global_position - _camera_target
		if offset.length_squared() <= 0.000001:
			return
		var distance := clampf(offset.length() * factor, 0.8, 80.0)
		_camera.global_position = _camera_target + offset.normalized() * distance
		_camera.look_at(_camera_target, Vector3.UP)
	_refresh_hud()


func _pan_speed() -> float:
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		return maxf(0.75, _camera.size * 0.6)
	return maxf(0.75, _camera.global_position.distance_to(_camera_target) * 0.4)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ReviewHUD"
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16.0, 14.0)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_hud.add_theme_constant_override("shadow_offset_x", 2)
	_hud.add_theme_constant_override("shadow_offset_y", 2)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)


func _refresh_hud() -> void:
	if _hud == null or _camera == null:
		return
	var preset: Dictionary = PRESETS[_preset_index]
	var camera_details := ""
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		camera_details = "Orthographic size %.2f" % _camera.size
	else:
		camera_details = "Perspective FOV %.1f deg | distance %.2f m" % [
			_camera.fov,
			_camera.global_position.distance_to(_camera_target),
		]
	_hud.text = "Steamtek six-asset QA | %d/8 %s | %s\n1 Overview  2 Wall seam  3 Road seam  4 Crate  5 Window front  6 Window rear  7 Pole  8 Sign\nWASD/arrows pan | wheel zoom | R reset | C collisions: %s | L labels: %s | P/F12 capture\nFull-pack generation locked - visual approval pending" % [
		_preset_index + 1,
		str(preset["label"]),
		camera_details,
		"ON" if _collision_visible else "OFF",
		"ON" if _labels_visible else "OFF",
	]


func _capture_current() -> String:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var absolute_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create material-QA capture directory: %s" % directory_error)
		return ""
	var preset: Dictionary = PRESETS[_preset_index]
	var path := "%s/%02d_%s.png" % [absolute_dir, _preset_index + 1, str(preset["slug"])]
	var save_error := image.save_png(path)
	if save_error != OK:
		push_error("Could not save material-QA screenshot: %s" % path)
		return ""
	print("STEAMTEK_MATERIAL_QA_CAPTURE=" + path)
	return path


func _capture_all() -> void:
	var captures: Array[String] = []
	for index in range(PRESETS.size()):
		_apply_preset(index)
		var path := await _capture_current()
		if not path.is_empty():
			captures.append(path)
	print("STEAMTEK_MATERIAL_QA_CAPTURE_COUNT=%d" % captures.size())
	if "--steamtek-quit-after-capture" in OS.get_cmdline_user_args():
		get_tree().quit(0 if captures.size() == PRESETS.size() else 1)