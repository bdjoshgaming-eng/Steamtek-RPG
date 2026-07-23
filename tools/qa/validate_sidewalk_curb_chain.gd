extends SceneTree

const TEST_SCENE := "res://scenes/environment/live3d/qa/SteamtekSidewalkCurbChainTest.tscn"


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load sidewalk curb-chain regression scene.")
		quit(1)
		return
	var test_root := packed.instantiate() as Node3D
	get_root().add_child(test_root)
	await process_frame

	var pairs := [
		[
			test_root.get_node("Curb/Sockets/SidewalkEdge") as Marker3D,
			test_root.get_node("SidewalkCenter/Sockets/StreetEdge") as Marker3D,
		],
		[
			test_root.get_node("SidewalkCenter/Sockets/ChainNegX") as Marker3D,
			test_root.get_node("SidewalkLeft/Sockets/ChainPosX") as Marker3D,
		],
		[
			test_root.get_node("SidewalkCenter/Sockets/ChainPosX") as Marker3D,
			test_root.get_node("SidewalkRight/Sockets/ChainNegX") as Marker3D,
		],
	]
	var largest_error := 0.0
	for pair in pairs:
		largest_error = maxf(
			largest_error,
			(pair[0] as Marker3D).global_position.distance_to((pair[1] as Marker3D).global_position)
		)

	var center := test_root.get_node("SidewalkCenter") as Node3D
	var left := test_root.get_node("SidewalkLeft") as Node3D
	var right := test_root.get_node("SidewalkRight") as Node3D
	var facing_error := maxf(
		1.0 - center.global_basis.z.normalized().dot(left.global_basis.z.normalized()),
		1.0 - center.global_basis.z.normalized().dot(right.global_basis.z.normalized())
	)
	if largest_error > 0.0001 or facing_error > 0.0001:
		push_error("Sidewalk curb-chain regression failed: socket=%f facing=%f" % [largest_error, facing_error])
		test_root.free()
		quit(1)
		return

	print("SIDEWALK_CURB_CHAIN_VALIDATION=" + JSON.stringify({
		"largest_socket_error_m": largest_error,
		"facing_error": facing_error,
		"passed": true,
	}))
	test_root.free()
	quit(0)
