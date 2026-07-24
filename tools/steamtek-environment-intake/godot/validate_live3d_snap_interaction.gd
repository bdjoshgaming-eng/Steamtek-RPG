extends SceneTree

const BUILDER_SCRIPT := preload("res://addons/steamtek_live3d_builder/steamtek_live3d_builder.gd")
const REPORT_PATH := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Live3D_Snap_Interaction_Validation.json"
const TOLERANCE_M := 0.002

const WALL_SCENE := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Scenes/Architecture/Walls/STK_ARCH_Wall_Apartment_A_01.tscn"
const ROAD_SCENE := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Scenes/Architecture/Roads/STK_ARCH_Road_01.tscn"
const PIPE_SCENE := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Scenes/Infrastructure/Pipes/STK_INFRA_Pipe_01.tscn"
const SIGN_SCENE := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Scenes/Props/Signs/STK_PROP_Sign_Emissive_013.tscn"

func _init() -> void:
	var results: Array[Dictionary] = []
	results.append(_run_chain_case("wall_x", WALL_SCENE, Vector3(2.0, 0.0, 0.0), Vector3(2.190474, 0.0, 0.0)))
	results.append(_run_chain_case("road_z", ROAD_SCENE, Vector3(0.0, 0.0, 13.0), Vector3(0.0, 0.0, 14.866686)))
	results.append(_run_chain_case("pipe_y", PIPE_SCENE, Vector3(0.0, 3.0, 0.0), Vector3(0.0, 4.607897, 0.0)))
	results.append(_run_attachment_case())
	var failures := 0
	for result in results:
		if not bool(result.get("passed", false)):
			failures += 1
	var report := {"schema": "SteamtekLive3DSnapInteractionValidation-1", "godot_version": Engine.get_version_info(), "passed": failures == 0, "failure_count": failures, "cases": results, "validation": "shared_live3d_builder_candidate_solver_applies_real_module_transform"}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write " + REPORT_PATH)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("STEAMTEK_LIVE3D_SNAP_INTERACTION=" + JSON.stringify(report))
	quit(0 if failures == 0 else 1)

func _run_chain_case(label: String, scene_path: String, starting_position: Vector3, expected_position: Vector3) -> Dictionary:
	var root := Node3D.new()
	root.name = "SnapInteraction_" + label
	get_root().add_child(root)
	var host := _instantiate(scene_path)
	var moving := _instantiate(scene_path)
	if host == null or moving == null:
		root.free()
		return {"case": label, "passed": false, "error": "scene_load_or_instance_failed"}
	root.add_child(host)
	root.add_child(moving)
	host.position = Vector3.ZERO
	moving.position = starting_position
	_force_transform_tree(root)
	var builder = BUILDER_SCRIPT.new()
	var result: Dictionary = builder.snap_generated_module_for_qa(moving, root)
	_force_transform_tree(root)
	var final_position := moving.position
	var passed := bool(result.get("found", false)) and float(result.get("distance_after_m", INF)) <= TOLERANCE_M and final_position.distance_to(expected_position) <= TOLERANCE_M and moving.scale.is_equal_approx(Vector3.ONE)
	var record := {"case": label, "scene": scene_path, "starting_position_m": _vec(starting_position), "expected_position_m": _vec(expected_position), "final_position_m": _vec(final_position), "distance_before_m": float(result.get("distance_before_m", INF)), "distance_after_m": float(result.get("distance_after_m", INF)), "capture_distance_m": float(result.get("capture_distance_m", 0.0)), "source_marker": str(result.get("source_name", "")), "target_marker": str(result.get("target_name", "")), "root_scale_one": moving.scale.is_equal_approx(Vector3.ONE), "passed": passed}
	builder.free()
	root.free()
	return record

func _run_attachment_case() -> Dictionary:
	var root := Node3D.new()
	root.name = "SnapInteraction_wall_sign"
	get_root().add_child(root)
	var host := _instantiate(WALL_SCENE)
	var moving := _instantiate(SIGN_SCENE)
	if host == null or moving == null:
		root.free()
		return {"case": "wall_sign_attachment", "passed": false, "error": "scene_load_or_instance_failed"}
	root.add_child(host)
	root.add_child(moving)
	var target := host.get_node_or_null("AttachmentPoints/Attach_Front_Center") as Marker3D
	if target == null:
		root.free()
		return {"case": "wall_sign_attachment", "passed": false, "error": "wall_attachment_marker_missing"}
	moving.global_position = target.global_position + Vector3(0.8, 0.0, 0.0)
	_force_transform_tree(root)
	var starting_position := moving.global_position
	var expected_position := target.global_position
	var builder = BUILDER_SCRIPT.new()
	var result: Dictionary = builder.snap_generated_module_for_qa(moving, root)
	_force_transform_tree(root)
	var final_position := moving.global_position
	var passed := bool(result.get("found", false)) and float(result.get("distance_after_m", INF)) <= TOLERANCE_M and final_position.distance_to(expected_position) <= TOLERANCE_M and moving.scale.is_equal_approx(Vector3.ONE)
	var record := {"case": "wall_sign_attachment", "host_scene": WALL_SCENE, "attachment_scene": SIGN_SCENE, "starting_position_m": _vec(starting_position), "expected_position_m": _vec(expected_position), "final_position_m": _vec(final_position), "distance_before_m": float(result.get("distance_before_m", INF)), "distance_after_m": float(result.get("distance_after_m", INF)), "capture_distance_m": float(result.get("capture_distance_m", 0.0)), "source_marker": str(result.get("source_name", "")), "target_marker": str(result.get("target_name", "")), "root_scale_one": moving.scale.is_equal_approx(Vector3.ONE), "passed": passed}
	builder.free()
	root.free()
	return record

func _instantiate(scene_path: String) -> Node3D:
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if packed == null:
		return null
	return packed.instantiate() as Node3D

func _vec(value: Vector3) -> Array[float]:
	return [snappedf(value.x, 0.000001), snappedf(value.y, 0.000001), snappedf(value.z, 0.000001)]

func _force_transform_tree(node: Node) -> void:
	if node is Node3D:
		(node as Node3D).force_update_transform()
	for child in node.get_children():
		_force_transform_tree(child)