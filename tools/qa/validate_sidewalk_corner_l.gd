extends SceneTree

const TEST_SCENE := "res://scenes/environment/live3d/qa/SteamtekSidewalkCornerLTest.tscn"


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load L-shaped sidewalk corner regression scene.")
		quit(1)
		return
	var test_root := packed.instantiate() as Node3D
	get_root().add_child(test_root)
	await process_frame

	var pairs := [
		[
			test_root.get_node("Corner/Sockets/SidewalkNegX") as Marker3D,
			test_root.get_node("StraightNegX/Sockets/ChainPosX") as Marker3D,
		],
		[
			test_root.get_node("Corner/Sockets/SidewalkNegZ") as Marker3D,
			test_root.get_node("StraightNegZ/Sockets/ChainNegX") as Marker3D,
		],
	]
	var largest_error := 0.0
	for pair in pairs:
		largest_error = maxf(
			largest_error,
			(pair[0] as Marker3D).global_position.distance_to((pair[1] as Marker3D).global_position)
		)

	var corner := test_root.get_node("Corner") as Node3D
	var corner_slab := corner.get_node("CornerSlab") as MeshInstance3D
	var horizontal_band := corner.get_node("HorizontalStreetEdgeBand") as MeshInstance3D
	var vertical_band := corner.get_node("VerticalStreetEdgeBand") as MeshInstance3D
	var corner_size := (corner_slab.mesh as BoxMesh).size
	var horizontal_band_size := (horizontal_band.mesh as BoxMesh).size
	var vertical_band_size := (vertical_band.mesh as BoxMesh).size
	var shape_valid := (
		corner_size.is_equal_approx(Vector3(1.2, 0.18, 1.2))
		and corner_slab.position.is_equal_approx(Vector3(0, -0.09, 0))
	)
	var bands_valid := (
		horizontal_band_size.is_equal_approx(Vector3(1.12, 0.025, 0.08))
		and vertical_band_size.is_equal_approx(Vector3(1.12, 0.025, 0.08))
		and horizontal_band.position.is_equal_approx(Vector3(0, 0.0125, 0.55))
		and vertical_band.position.is_equal_approx(Vector3(0.55, 0.0125, 0))
	)
	var normals_valid: bool = (
		(test_root.get_node("Corner/Sockets/SidewalkNegX") as Marker3D).get_meta("socket_normal_local", Vector3.ZERO) == Vector3(-1, 0, 0)
		and (test_root.get_node("Corner/Sockets/SidewalkNegZ") as Marker3D).get_meta("socket_normal_local", Vector3.ZERO) == Vector3(0, 0, -1)
	)
	var collision_valid: bool = (
		corner.has_node("CollisionBody/Shape")
		and ((corner.get_node("CollisionBody/Shape") as CollisionShape3D).shape as BoxShape3D).size.is_equal_approx(Vector3(1.2, 0.04, 1.2))
	)
	if largest_error > 0.0001 or not shape_valid or not bands_valid or not normals_valid or not collision_valid:
		push_error("Sidewalk L-corner regression failed: socket=%f shape=%s bands=%s normals=%s collision=%s" % [largest_error, shape_valid, bands_valid, normals_valid, collision_valid])
		test_root.free()
		quit(1)
		return

	print("SIDEWALK_CORNER_L_VALIDATION=" + JSON.stringify({
		"largest_socket_error_m": largest_error,
		"shape_valid": shape_valid,
		"bands_valid": bands_valid,
		"normals_valid": normals_valid,
		"collision_valid": collision_valid,
		"passed": true,
	}))
	test_root.free()
	quit(0)
