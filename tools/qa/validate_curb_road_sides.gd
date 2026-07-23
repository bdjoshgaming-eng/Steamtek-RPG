extends SceneTree

const TEST_SCENE := "res://scenes/environment/live3d/qa/SteamtekCurbRoadBothSidesTest.tscn"


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load curb two-sided regression scene.")
		quit(1)
		return
	var test_root := packed.instantiate() as Node3D
	get_root().add_child(test_root)
	await process_frame

	var road_negative := test_root.get_node("Road/Sockets/EdgeNegZ") as Marker3D
	var road_positive := test_root.get_node("Road/Sockets/EdgePosZ") as Marker3D
	var curb_negative := test_root.get_node("Curb_NegativeZ/Sockets/RoadEdge") as Marker3D
	var curb_positive := test_root.get_node("Curb_PositiveZ/Sockets/RoadEdge") as Marker3D
	var socket_pairs := {
		"negative_z": [road_negative, curb_negative],
		"positive_z": [road_positive, curb_positive],
		"negative_x_negative_half": [
			test_root.get_node("Road/Sockets/SideNegXNegZHalf") as Marker3D,
			test_root.get_node("Curb_NegativeX_NegativeHalf/Sockets/RoadEdge") as Marker3D,
		],
		"negative_x_positive_half": [
			test_root.get_node("Road/Sockets/SideNegXPosZHalf") as Marker3D,
			test_root.get_node("Curb_NegativeX_PositiveHalf/Sockets/RoadEdge") as Marker3D,
		],
		"positive_x_negative_half": [
			test_root.get_node("Road/Sockets/SidePosXNegZHalf") as Marker3D,
			test_root.get_node("Curb_PositiveX_NegativeHalf/Sockets/RoadEdge") as Marker3D,
		],
		"positive_x_positive_half": [
			test_root.get_node("Road/Sockets/SidePosXPosZHalf") as Marker3D,
			test_root.get_node("Curb_PositiveX_PositiveHalf/Sockets/RoadEdge") as Marker3D,
		],
	}
	var errors := {}
	var largest_error := 0.0
	for pair_name in socket_pairs:
		var pair: Array = socket_pairs[pair_name]
		var error := (pair[0] as Marker3D).global_position.distance_to((pair[1] as Marker3D).global_position)
		errors[pair_name + "_socket_error_m"] = error
		largest_error = maxf(largest_error, error)

	if largest_error > 0.0001:
		push_error("Curb road-edge regression failed: " + JSON.stringify(errors))
		test_root.free()
		quit(1)
		return

	errors["largest_socket_error_m"] = largest_error
	errors["passed"] = true
	print("CURB_ALL_SIDES_VALIDATION=" + JSON.stringify(errors))
	test_root.free()
	quit(0)
