extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var scu: SteamtekSCUMk1Enemy = $STK_NPC_SCU_Mk1
@onready var c001: SteamtekHumanoidCharacter3D = $VesperKane_PlayerCharacter_v01
@onready var status: Label = $ReviewUI/Status

var walking := false
var yaw_degrees := 0.0
var forced_lod := -1


func _ready() -> void:
	camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	c001.set_player_controlled(false)
	scu.set_player_controlled(false)
	c001.play_idle()
	scu.force_lod(-1)
	_update_status()
	await get_tree().process_frame
	await get_tree().process_frame
	_print_runtime_receipt()
	_capture_review_frame()
	print("SCU_REVIEW_READY=true")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		walking = not walking
		if walking:
			c001.play_walk()
		else:
			c001.play_idle()
		_update_status()
		return
	if event.is_action_pressed("ui_left"):
		yaw_degrees -= 15.0
	elif event.is_action_pressed("ui_right"):
		yaw_degrees += 15.0
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_0:
				forced_lod = -1
			KEY_1:
				forced_lod = 0
			KEY_2:
				forced_lod = 1
			KEY_3:
				forced_lod = 2
			_:
				return
		scu.force_lod(forced_lod)
		_update_status()
		return
	else:
		return
	scu.visual_pivot.rotation_degrees.y = yaw_degrees
	_update_status()


func _update_status() -> void:
	var lod_text := "AUTO" if forced_lod < 0 else "LOD%d" % forced_lod
	status.text = "C001: %s   SCU: REST (rig correction pending)   Yaw: %.0f deg   Display: %s" % [
		"STK_WALK" if walking else "STK_IDLE",
		yaw_degrees,
		lod_text,
	]


func _print_runtime_receipt() -> void:
	var triangles: Array[int] = []
	for level in range(3):
		var mesh_instance := scu.get_lod_mesh(level)
		if mesh_instance == null or mesh_instance.mesh == null:
			push_error("SCU review could not find LOD%d" % level)
			triangles.append(0)
			continue
		var count := 0
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var arrays := mesh_instance.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			count += indices.size() / 3
		triangles.append(count)
	var animation_player := scu.get_character_animation_player()
	var animations := PackedStringArray()
	if animation_player != null:
		animations = animation_player.get_animation_list()
	print("SCU_GODOT_LOD_TRIANGLES=", triangles)
	print("SCU_GODOT_ANIMATIONS=", animations)
	print("SCU_GODOT_ROOT_SCALE=", scu.scale)
	print("SCU_GODOT_VISUAL_SCALE=", scu.visual_pivot.scale)


func _capture_review_frame() -> void:
	var image := get_viewport().get_texture().get_image()
	var output_path := "res://docs/reviews/characters/STK_NPC_SCU_Mk1/STK_NPC_SCU_Mk1_GodotReview.png"
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("SCU_GODOT_REVIEW_CAPTURE=", output_path)
	else:
		push_error("Could not save SCU Godot review capture: %s" % error_string(error))