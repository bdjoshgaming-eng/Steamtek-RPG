extends SceneTree

const TEST_SCENE := "res://scenes/environment/live3d/qa/SteamtekSidewalkRampRoadTest.tscn"


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load sidewalk ramp regression scene.")
		quit(1)
		return
	var test_root := packed.instantiate() as Node3D
	get_root().add_child(test_root)
	await process_frame

	var pairs := [
		[
			test_root.get_node("Road/Sockets/EdgePosZ") as Marker3D,
			test_root.get_node("Ramp/Sockets/RoadEdge") as Marker3D,
		],
		[
			test_root.get_node("Ramp/Sockets/ChainNegX") as Marker3D,
			test_root.get_node("SidewalkLeft/Sockets/ChainPosX") as Marker3D,
		],
		[
			test_root.get_node("Ramp/Sockets/ChainPosX") as Marker3D,
			test_root.get_node("SidewalkRight/Sockets/ChainNegX") as Marker3D,
		],
		[
			test_root.get_node("Ramp/Sockets/CurbChainNegX") as Marker3D,
			test_root.get_node("CurbLeft/Sockets/ChainPosX") as Marker3D,
		],
		[
			test_root.get_node("Ramp/Sockets/CurbChainPosX") as Marker3D,
			test_root.get_node("CurbRight/Sockets/ChainNegX") as Marker3D,
		],
	]
	var largest_socket_error := 0.0
	for pair in pairs:
		largest_socket_error = maxf(
			largest_socket_error,
			(pair[0] as Marker3D).global_position.distance_to((pair[1] as Marker3D).global_position)
		)

	var ramp := test_root.get_node("Ramp") as Node3D
	var opening_walkway := ramp.get_node("OpeningWalkway") as CSGPolygon3D
	var sidewalk_left := ramp.get_node("SidewalkLeft") as MeshInstance3D
	var sidewalk_right := ramp.get_node("SidewalkRight") as MeshInstance3D
	var curb_left := ramp.get_node("CurbLeft") as MeshInstance3D
	var curb_right := ramp.get_node("CurbRight") as MeshInstance3D
	var edge_band_left := ramp.get_node("CurbEdgeBandLeft") as MeshInstance3D
	var edge_band_right := ramp.get_node("CurbEdgeBandRight") as MeshInstance3D
	var side_size := (sidewalk_left.mesh as BoxMesh).size
	var side_depth_error := absf(side_size.z - 1.2) + absf((sidewalk_right.mesh as BoxMesh).size.z - 1.2)
	var curb_depth_error := absf((curb_left.mesh as BoxMesh).size.z - 0.2) + absf((curb_right.mesh as BoxMesh).size.z - 0.2)
	var opening_width_error := absf(opening_walkway.depth - 1.4)
	var total_width_error := absf(side_size.x + opening_walkway.depth + (sidewalk_right.mesh as BoxMesh).size.x - 2.4)
	var overall_depth_error := absf(float(ramp.get_meta("sidewalk_depth_m", 0.0)) + float(ramp.get_meta("curb_depth_m", 0.0)) - 1.4)
	var ramp_depth_error := absf(float(ramp.get_meta("ramp_depth_m", 0.0)) - 0.3524)
	var edge_band_size := (edge_band_left.mesh as BoxMesh).size
	var edge_band_depth_error := absf(edge_band_size.z - 0.08)
	var edge_band_alignment_error := (
		absf(edge_band_left.position.z + 0.55)
		+ absf(edge_band_right.position.z + 0.55)
		+ absf(edge_band_left.position.x + 0.93)
		+ absf(edge_band_right.position.x - 0.93)
	)
	var road_height_error := absf((ramp.get_node("Sockets/RoadEdge") as Marker3D).global_position.y)
	var sidewalk_height_error := absf(sidewalk_left.global_position.y + side_size.y * 0.5 - 0.18)
	if (
		largest_socket_error > 0.0001
		or road_height_error > 0.0001
		or sidewalk_height_error > 0.0001
		or side_depth_error > 0.0001
		or curb_depth_error > 0.0001
		or opening_width_error > 0.0001
		or total_width_error > 0.0001
		or overall_depth_error > 0.0001
		or ramp_depth_error > 0.0001
		or edge_band_depth_error > 0.0001
		or edge_band_alignment_error > 0.0001
	):
		push_error(
			"Sidewalk + curb opening regression failed: socket=%f road=%f sidewalk=%f side_depth=%f curb_depth=%f opening_width=%f total_width=%f overall_depth=%f ramp_depth=%f band_depth=%f band_alignment=%f"
			% [largest_socket_error, road_height_error, sidewalk_height_error, side_depth_error, curb_depth_error, opening_width_error, total_width_error, overall_depth_error, ramp_depth_error, edge_band_depth_error, edge_band_alignment_error]
		)
		test_root.free()
		quit(1)
		return

	print("SIDEWALK_RAMP_ROAD_VALIDATION=" + JSON.stringify({
		"largest_socket_error_m": largest_socket_error,
		"road_height_error_m": road_height_error,
		"sidewalk_height_error_m": sidewalk_height_error,
		"side_depth_error_m": side_depth_error,
		"curb_depth_error_m": curb_depth_error,
		"opening_width_error_m": opening_width_error,
		"total_width_error_m": total_width_error,
		"overall_depth_error_m": overall_depth_error,
		"ramp_depth_error_m": ramp_depth_error,
		"edge_band_depth_error_m": edge_band_depth_error,
		"edge_band_alignment_error_m": edge_band_alignment_error,
		"passed": true,
	}))
	test_root.free()
	quit(0)
