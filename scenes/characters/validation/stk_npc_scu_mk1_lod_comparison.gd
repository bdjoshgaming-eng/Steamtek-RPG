@tool
extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var lod0_scu: SteamtekSCUMk1Enemy = $LOD0_SCU
@onready var lod1_scu: SteamtekSCUMk1Enemy = $LOD1_SCU
@onready var lod2_scu: SteamtekSCUMk1Enemy = $LOD2_SCU
@onready var status: Label = $ReviewUI/Status

var yaw_degrees := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_editor_preview_tint.call_deferred()
		return
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	lod0_scu.set_player_controlled(false)
	lod1_scu.set_player_controlled(false)
	lod2_scu.set_player_controlled(false)
	lod0_scu.force_lod(0)
	lod1_scu.force_lod(1)
	lod2_scu.force_lod(2)
	_apply_lod2_test_tint()
	_update_status()
	await get_tree().process_frame
	await get_tree().process_frame
	_print_runtime_receipt()
	_capture_review_frame()
	print("SCU_LOD_COMPARISON_READY=true")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		yaw_degrees -= 15.0
	elif event.is_action_pressed("ui_right"):
		yaw_degrees += 15.0
	else:
		return
	for scu in [lod0_scu, lod1_scu, lod2_scu]:
		scu.visual_pivot.rotation_degrees.y = yaw_degrees
	_update_status()


func _update_status() -> void:
	status.text = "LOD0: 18,000 tris     LOD1: 10,000 tris     LOD2: 4,500 tris + SAFETY ORANGE TEST     Yaw: %.0f deg" % yaw_degrees
func _apply_lod2_test_tint() -> void:
	var mesh_instance := lod2_scu.get_lod_mesh(2)
	if mesh_instance == null or mesh_instance.mesh == null:
		push_error("SCU LOD2 tint test could not find the LOD2 mesh")
		return
	_apply_safety_orange_material(mesh_instance)
	print("SCU_LOD2_TEST_TINT=safety_orange")


func _apply_editor_preview_tint() -> void:
	for child in lod2_scu.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null and "_LOD2" in mesh_instance.name:
			_apply_safety_orange_material(mesh_instance)
			return


func _apply_safety_orange_material(mesh_instance: MeshInstance3D) -> void:
	var source_material := mesh_instance.get_active_material(0)
	if not source_material is BaseMaterial3D:
		push_error("SCU LOD2 tint test requires a BaseMaterial3D")
		return
	var test_material := source_material.duplicate() as BaseMaterial3D
	test_material.albedo_color = Color("#ff6a00")
	mesh_instance.material_override = test_material


func _print_runtime_receipt() -> void:
	var triangle_counts: Array[int] = []
	for entry in [[lod0_scu, 0], [lod1_scu, 1], [lod2_scu, 2]]:
		var scu := entry[0] as SteamtekSCUMk1Enemy
		var level := entry[1] as int
		var mesh_instance := scu.get_lod_mesh(level)
		if mesh_instance == null or mesh_instance.mesh == null:
			push_error("SCU LOD comparison could not find LOD%d" % level)
			triangle_counts.append(0)
			continue
		var count := 0
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var arrays := mesh_instance.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			count += indices.size() / 3
		triangle_counts.append(count)
	print("SCU_LOD_COMPARISON_TRIANGLES=", triangle_counts)


func _capture_review_frame() -> void:
	var image := get_viewport().get_texture().get_image()
	var output_path := "res://docs/reviews/characters/STK_NPC_SCU_Mk1/STK_NPC_SCU_Mk1_LOD_Comparison.png"
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("SCU_LOD_COMPARISON_CAPTURE=", output_path)
	else:
		push_error("Could not save SCU LOD comparison capture: %s" % error_string(error))
