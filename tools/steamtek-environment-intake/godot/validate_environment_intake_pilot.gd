extends SceneTree

const DEFAULT_MANIFEST_PATH := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Pilot_Manifest.json"
const DEFAULT_REPORT_PATH := "res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Pilot_Godot_Validation.json"
const TOLERANCE_M := 0.002
const LIVE3D_BUILDER_SCRIPT := preload("res://addons/steamtek_live3d_builder/steamtek_live3d_builder.gd")
const CHAIN_ROLES := [
	"facade_horizontal", "floor_horizontal", "street_road_chain", "street_sidewalk_chain",
	"street_curb_chain", "street_fence_chain", "wall_service_chain",
]
const SUPPORTED_ROLES := [
	"facade_horizontal", "floor_horizontal", "street_road_chain", "street_sidewalk_chain",
	"street_curb_chain", "street_fence_chain", "wall_service_chain", "street_road_edge",
	"street_sidewalk_road_edge", "street_curb_road_edge", "street_curb_sidewalk_edge",
	"prop_anchor", "prop_surface", "wall_prop_surface", "floor_prop_surface",
]


func _init() -> void:
	var arguments := _named_arguments()
	var manifest_path := str(arguments.get("manifest", DEFAULT_MANIFEST_PATH))
	var report_path := str(arguments.get("report", DEFAULT_REPORT_PATH))
	var manifest := _read_json(manifest_path)
	if manifest.is_empty():
		push_error("Missing or invalid environment intake manifest: " + manifest_path)
		quit(2)
		return
	var full_manifest := str(manifest.get("schema", "")) == "SteamtekEnvironmentFullManifest-1"

	var results: Array[Dictionary] = []
	var material_qa_results: Array[Dictionary] = []
	var failure_count := 0
	var warning_count := 0
	for asset in manifest.get("assets", []):
		var result := _validate_asset(asset as Dictionary)
		results.append(result)
		material_qa_results.append({"scene": str(result.get("scene", "")), "material_qa": result.get("material_qa", {})})
		failure_count += (result.get("errors", []) as Array).size()
		warning_count += (result.get("warnings", []) as Array).size()

	var pilot_scene_path := str(manifest.get("pilot_scene", ""))
	var pilot_result := {
		"loads": true,
		"errors": [],
		"warnings": [],
		"validation_skipped": "full_manifest_validates_wrappers_only",
	} if full_manifest else _validate_pilot_scene(
		pilot_scene_path,
		manifest.get("snap_demonstrations", []) as Array,
		manifest.get("attachment_demonstrations", []) as Array
	)
	failure_count += (pilot_result.get("errors", []) as Array).size()
	warning_count += (pilot_result.get("warnings", []) as Array).size()
	var report_warnings: Array[Dictionary] = [
		{
			"code": "normal_editor_visual_approval_required",
			"message": "Technical validation does not approve appearance, framing, or artistic fit.",
		},
		{
			"code": "uv_orientation_not_validated",
			"message": "UV0 presence is checked; orientation, seams, density, and rendered alignment require normal-editor review.",
		},
		{
			"code": "cache_replace_is_not_editor_reimport",
			"message": "CACHE_MODE_REPLACE tests fresh imported-resource loads but does not trigger a normal-editor reimport.",
		},
	]
	warning_count += report_warnings.size()
	var report := {
		"schema": (
			"SteamtekEnvironmentFullGodotValidation-1"
			if full_manifest
			else "SteamtekEnvironmentPilotGodotValidation-2.1"
		),
		"validator_version": "2.1.0",
		"godot_version": Engine.get_version_info(),
		"passed": failure_count == 0,
		"failure_count": failure_count,
		"warning_count": warning_count,
		"warnings": report_warnings,
		"pilot_scene": pilot_scene_path,
		"pilot_scene_loads": bool(pilot_result.get("loads", false)),
		"pilot_scene_validation": pilot_result,
		"material_qa": material_qa_results,
		"environment_qa": pilot_result.get("environment_qa", {}),
		"assets": results,
		"validation_boundary": "technical_load_hash_transform_uv0_stats_material_import_metadata_collision_socket_snap_neutral_qa_environment_and_cache_replace_stability_not_visual_or_uv_orientation_approval",
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write " + report_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print(
		(
			"STEAMTEK_ENVIRONMENT_FULL_VALIDATION="
			if full_manifest
			else "STEAMTEK_ENVIRONMENT_PILOT_VALIDATION="
		)
		+ JSON.stringify(report)
	)
	quit(0 if failure_count == 0 else 1)


func _named_arguments() -> Dictionary:
	var result := {}
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		result[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return result


func _validate_asset(asset: Dictionary) -> Dictionary:
	var scene_path := str(asset.get("scene", ""))
	var errors: Array[String] = []
	var warnings: Array[Dictionary] = []
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if packed == null:
		return {"scene": scene_path, "errors": ["scene_load_failed"], "warnings": warnings}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"scene": scene_path, "errors": ["root_is_not_node3d"], "warnings": warnings}
	var root_3d := instance as Node3D
	get_root().add_child(root_3d)

	if not root_3d.is_in_group("steamtek_live3d_modular"):
		errors.append("missing_modular_group")
	if str(root_3d.get_meta("module_system", "")) != "live3d_meter_v1":
		errors.append("invalid_module_system")
	if not root_3d.scale.is_equal_approx(Vector3.ONE):
		errors.append("root_scale_not_one")
	var expected_status := str(asset.get("status", ""))
	var actual_status := str(root_3d.get_meta("production_status", ""))
	var promoted_pilot_wrapper := (
		expected_status == "pilot_pending_normal_editor_approval"
		and actual_status == "full_generated_pending_category_visual_review"
	)
	if actual_status != expected_status and not promoted_pilot_wrapper:
		errors.append("production_status_mismatch:%s!=%s" % [actual_status, expected_status])
	var contract := asset.get("modular_contract", {}) as Dictionary
	for key in ["classification", "primary_socket_role", "snap_axis", "rejection_reason", "builder_profile"]:
		var metadata_key: String = "modular_classification" if key == "classification" else str(key)
		if str(root_3d.get_meta(metadata_key, "")) != str(contract.get(key, "")):
			errors.append("modular_contract_metadata_mismatch:" + key)
	if bool(root_3d.get_meta("rejected_modular_candidate", false)) != bool(contract.get("rejected_modular_candidate", false)):
		errors.append("modular_rejection_flag_mismatch")
	if not bool(root_3d.get_meta("builder_candidate", false)):
		errors.append("builder_candidate_metadata_missing")
	if bool(root_3d.get_meta("builder_registration_enabled", true)):
		errors.append("builder_registration_not_locked")
	if str(root_3d.get_meta("rotation_contract", "")) != "Yaw only: 0, 90, 180, or 270 degrees":
		errors.append("rotation_contract_mismatch")

	var non_finite: Array[String] = []
	_collect_non_finite(root_3d, root_3d, non_finite)
	if not non_finite.is_empty():
		errors.append("non_finite_transforms:" + ",".join(non_finite))
	var unresolved := PackedStringArray()
	if root_3d.has_method("apply_material_bindings"):
		unresolved = root_3d.call("apply_material_bindings") as PackedStringArray
	if not unresolved.is_empty():
		errors.append("unresolved_materials:" + ",".join(unresolved))

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root_3d, meshes)
	if meshes.is_empty():
		errors.append("no_mesh_instances")
	var actual_materials := _material_paths(meshes, errors)
	var expected_materials: Array[String] = []
	for value in asset.get("materials", []):
		expected_materials.append(str(value))
	expected_materials.sort()
	if actual_materials != expected_materials:
		errors.append("material_path_mismatch")
	var material_qa := _validate_material_qa(meshes, errors, warnings)

	var performance := _mesh_performance(meshes, true, errors, warnings)
	var expected_triangles := int(root_3d.get_meta("triangle_count", -1))
	if expected_triangles >= 0 and int(performance.get("triangles", 0)) != expected_triangles:
		errors.append("triangle_count_metadata_mismatch:%d!=%d" % [performance.get("triangles", 0), expected_triangles])
	var bounds := _visual_bounds(root_3d)
	var dimensions := _array_vector3(asset.get("dimensions_m", []))
	if not _finite_aabb(bounds):
		errors.append("non_finite_visual_bounds")
	if not _near_vector(bounds.size, dimensions):
		errors.append("dimension_mismatch:%s!=%s" % [bounds.size, dimensions])
	if absf(bounds.position.y) > TOLERANCE_M:
		errors.append("pivot_not_grounded_y:%f" % bounds.position.y)
	if absf(bounds.get_center().x) > TOLERANCE_M or absf(bounds.get_center().z) > TOLERANCE_M:
		errors.append("pivot_not_bottom_centered:%s" % bounds.get_center())

	var collision := _validate_collision(root_3d, str(asset.get("collision", "none")), dimensions, errors)
	var sockets := _validate_sockets(root_3d, str(asset.get("socket_role", "")), dimensions, int(asset.get("snap_point_count", -1)), errors)
	var source_hash := _validate_source_hash(asset, root_3d, errors)
	var stability := _validate_stability(scene_path, str(asset.get("source", "")), str(asset.get("socket_role", "")), errors)
	var result := {
		"scene": scene_path,
		"source": str(root_3d.get_meta("source_asset", "")),
		"source_hash": source_hash,
		"dimensions_m": _vec_array(bounds.size),
		"bounds_position": _vec_array(bounds.position),
		"materials": actual_materials,
		"material_qa": material_qa,
		"collision": collision,
		"sockets": sockets,
		"performance": performance,
		"finite_transforms": non_finite.is_empty(),
		"cache_replace_stability": stability,
		"errors": errors,
		"warnings": warnings,
	}
	root_3d.free()
	return result


func _validate_material_qa(meshes: Array[MeshInstance3D], errors: Array[String], warnings: Array[Dictionary]) -> Dictionary:
	var initial_error_count := errors.size()
	var surfaces: Array[Dictionary] = []
	var normal_imports: Array[Dictionary] = []
	var roughness_imports: Array[Dictionary] = []
	var checked_normals := {}
	var checked_roughness := {}
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface_index)
			if not material is StandardMaterial3D:
				warnings.append({
					"code": "material_qa_not_standard_material3d",
					"mesh": str(mesh_instance.name),
					"surface": surface_index,
					"material": material.resource_path if material != null else "",
				})
				continue
			var standard := material as StandardMaterial3D
			var material_path := standard.resource_path
			var surface_id := "%s:%d:%s" % [mesh_instance.name, surface_index, material_path]
			var emission_enabled := bool(_property_value(standard, &"emission_enabled", false))
			var emission_texture_value = _property_value(standard, &"emission_texture", null)
			var emission_has_texture := emission_texture_value is Texture2D
			var emission_operator := int(_property_value(standard, &"emission_operator", -1))
			var emission_energy := float(_property_value(standard, &"emission_energy_multiplier", -1.0))
			if emission_enabled and emission_has_texture:
				if emission_operator != 1:
					errors.append("emission_operator_not_multiply:" + surface_id)
				if not is_finite(emission_energy) or emission_energy <= 0.0 or emission_energy > 1.0:
					errors.append("emission_energy_not_controlled:%s:%f" % [surface_id, emission_energy])

			var transparency := int(_property_value(standard, &"transparency", 0))
			var cull_mode := int(_property_value(standard, &"cull_mode", -1))
			var depth_draw_mode := int(_property_value(standard, &"depth_draw_mode", -1))
			var uses_transparency := transparency != 0
			var sorting_use_aabb_center := bool(_property_value(mesh_instance, &"sorting_use_aabb_center", false))
			if uses_transparency:
				if transparency != 4:
					errors.append("transparent_material_not_alpha_depth_prepass:" + surface_id)
				if cull_mode != 2:
					errors.append("transparent_material_culling_not_disabled:" + surface_id)
				if depth_draw_mode != 0:
					errors.append("transparent_material_depth_draw_not_opaque_only:" + surface_id)
				if not sorting_use_aabb_center:
					errors.append("transparent_mesh_aabb_sorting_disabled:" + surface_id)

			var normal_texture_value = _property_value(standard, &"normal_texture", null)
			var roughness_texture_value = _property_value(standard, &"roughness_texture", null)
			var normal_path: String = normal_texture_value.resource_path if normal_texture_value is Texture2D else ""
			var roughness_path: String = roughness_texture_value.resource_path if roughness_texture_value is Texture2D else ""
			if not normal_path.is_empty() and not checked_normals.has(normal_path):
				checked_normals[normal_path] = true
				normal_imports.append(_validate_normal_import(normal_path, errors))
			if not roughness_path.is_empty() and not checked_roughness.has(roughness_path):
				checked_roughness[roughness_path] = true
				roughness_imports.append(_validate_roughness_import(roughness_path, normal_path, errors))

			surfaces.append({
				"mesh": str(mesh_instance.name),
				"surface": surface_index,
				"material": material_path,
				"emission_enabled": emission_enabled,
				"emission_has_texture": emission_has_texture,
				"emission_operator": emission_operator,
				"emission_energy_multiplier": emission_energy,
				"transparency": transparency,
				"cull_mode": cull_mode,
				"depth_draw_mode": depth_draw_mode,
				"sorting_use_aabb_center": sorting_use_aabb_center,
				"normal_texture": normal_path,
				"roughness_texture": roughness_path,
			})
	return {
		"passed": errors.size() == initial_error_count,
		"standard_material_surfaces": surfaces,
		"normal_imports": normal_imports,
		"roughness_imports": roughness_imports,
	}


func _validate_normal_import(texture_path: String, errors: Array[String]) -> Dictionary:
	var sidecar := _read_import_params(texture_path)
	var values := sidecar.get("values", {}) as Dictionary
	if not bool(sidecar.get("exists", false)):
		errors.append("normal_import_sidecar_missing:" + texture_path)
	else:
		if str(values.get("compress/normal_map", "")) != "1":
			errors.append("normal_import_not_marked_normal_map:" + texture_path)
		if str(values.get("roughness/mode", "")) != "0":
			errors.append("normal_import_roughness_mode_not_disabled:" + texture_path)
		if not _import_string(str(values.get("roughness/src_normal", ""))).is_empty():
			errors.append("normal_import_self_or_other_roughness_source:" + texture_path)
		if str(values.get("process/normal_map_invert_y", "")) != "false":
			errors.append("normal_import_y_inversion_not_disabled:" + texture_path)
	return {
		"texture": texture_path,
		"sidecar": texture_path + ".import",
		"exists": bool(sidecar.get("exists", false)),
		"compress_normal_map": str(values.get("compress/normal_map", "")),
		"roughness_mode": str(values.get("roughness/mode", "")),
		"roughness_src_normal": _import_string(str(values.get("roughness/src_normal", ""))),
		"normal_map_invert_y": str(values.get("process/normal_map_invert_y", "")),
	}


func _validate_roughness_import(texture_path: String, paired_normal_path: String, errors: Array[String]) -> Dictionary:
	var sidecar := _read_import_params(texture_path)
	var values := sidecar.get("values", {}) as Dictionary
	var source_normal := _import_string(str(values.get("roughness/src_normal", "")))
	if not bool(sidecar.get("exists", false)):
		errors.append("roughness_import_sidecar_missing:" + texture_path)
	else:
		if str(values.get("compress/normal_map", "")) != "0":
			errors.append("roughness_import_misclassified_as_normal_map:" + texture_path)
		if not paired_normal_path.is_empty():
			if str(values.get("roughness/mode", "")) != "1":
				errors.append("roughness_import_channel_mode_not_red:" + texture_path)
			if source_normal != paired_normal_path:
				errors.append("roughness_import_paired_normal_mismatch:%s:%s!=%s" % [texture_path, source_normal, paired_normal_path])
	return {
		"texture": texture_path,
		"sidecar": texture_path + ".import",
		"exists": bool(sidecar.get("exists", false)),
		"compress_normal_map": str(values.get("compress/normal_map", "")),
		"roughness_mode": str(values.get("roughness/mode", "")),
		"roughness_src_normal": source_normal,
		"paired_normal_texture": paired_normal_path,
	}


func _read_import_params(texture_path: String) -> Dictionary:
	var sidecar_path := texture_path + ".import"
	var file := FileAccess.open(sidecar_path, FileAccess.READ)
	if file == null:
		return {"exists": false, "values": {}}
	var values := {}
	var in_params := false
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			in_params = line == "[params]"
			continue
		if not in_params or line.is_empty() or line.begins_with(";"):
			continue
		var separator := line.find("=")
		if separator <= 0:
			continue
		values[line.substr(0, separator).strip_edges()] = line.substr(separator + 1).strip_edges()
	file.close()
	return {"exists": true, "values": values}


func _import_string(raw_value: String) -> String:
	if raw_value.is_empty():
		return ""
	var parsed = JSON.parse_string(raw_value)
	return str(parsed) if parsed is String else raw_value.trim_prefix("\"").trim_suffix("\"")

func _validate_collision(root: Node3D, policy: String, dimensions: Vector3, errors: Array[String]) -> Dictionary:
	var shapes: Array[CollisionShape3D] = []
	_collect_collisions(root, shapes)
	var details: Array[Dictionary] = []
	for shape_node in shapes:
		var size := Vector3.ZERO
		if shape_node.shape is BoxShape3D:
			size = (shape_node.shape as BoxShape3D).size
		details.append({
			"node": str(root.get_path_to(shape_node)),
			"disabled": shape_node.disabled,
			"shape_type": shape_node.shape.get_class() if shape_node.shape != null else "",
			"size_m": _vec_array(size),
			"center_m": _vec_array(_relative_transform(root, shape_node).origin),
		})
	if str(root.get_meta("collision_policy", "")) != policy:
		errors.append("collision_policy_metadata_mismatch")
	if policy == "box":
		if not root is StaticBody3D:
			errors.append("box_root_is_not_static_body3d")
		elif (root as StaticBody3D).collision_layer != 1:
			errors.append("box_collision_layer_not_exactly_one:%d" % (root as StaticBody3D).collision_layer)
		if shapes.size() != 1:
			errors.append("box_collision_count_not_one:%d" % shapes.size())
		else:
			var collision := shapes[0]
			if collision.disabled:
				errors.append("box_collision_disabled")
			if not collision.shape is BoxShape3D:
				errors.append("collision_is_not_box")
			elif not _near_vector((collision.shape as BoxShape3D).size, dimensions):
				errors.append("box_collision_size_mismatch:%s!=%s" % [(collision.shape as BoxShape3D).size, dimensions])
			var expected_center := Vector3(0.0, dimensions.y * 0.5, 0.0)
			var actual_center := _relative_transform(root, collision).origin
			if not _near_vector(actual_center, expected_center):
				errors.append("box_collision_center_mismatch:%s!=%s" % [actual_center, expected_center])
	elif policy == "none" or policy == "manual_review_no_collision":
		if not shapes.is_empty():
			errors.append("unexpected_collision:%d" % shapes.size())
	else:
		errors.append("unsupported_collision_policy:" + policy)
	return {"policy": policy, "shape_count": shapes.size(), "details": details}


func _validate_sockets(root: Node3D, primary_role: String, dimensions: Vector3, expected_total: int, errors: Array[String]) -> Dictionary:
	var builder = LIVE3D_BUILDER_SCRIPT.new()
	var builder_recognizes := bool(builder.recognizes_generated_module(root))
	if not builder_recognizes:
		errors.append("live3d_builder_does_not_recognize_module")
	var builder_markers: Array[Marker3D] = builder.recognized_generated_markers(root)
	var markers: Array[Marker3D] = []
	_collect_markers(root, markers)
	if builder_markers.size() != markers.size():
		errors.append("live3d_builder_marker_count_mismatch:%d!=%d" % [builder_markers.size(), markers.size()])
	if expected_total >= 0 and markers.size() != expected_total:
		errors.append("snap_point_total_mismatch:%d!=%d" % [markers.size(), expected_total])
	if int(root.get_meta("snap_point_count", -1)) != markers.size():
		errors.append("snap_point_metadata_mismatch:%d!=%d" % [int(root.get_meta("snap_point_count", -1)), markers.size()])
	var primary: Array[Marker3D] = []
	var records: Array[Dictionary] = []
	for marker in markers:
		var role := str(marker.get_meta("socket_role", ""))
		var in_group := marker.is_in_group("steamtek_live3d_snap")
		if role.is_empty():
			if in_group:
				errors.append("socket_role_missing:" + str(root.get_path_to(marker)))
			continue
		if role not in SUPPORTED_ROLES:
			errors.append("unsupported_socket_role:%s:%s" % [root.get_path_to(marker), role])
		if not in_group:
			errors.append("socket_missing_group:" + str(root.get_path_to(marker)))
		if not marker.scale.is_equal_approx(Vector3.ONE):
			errors.append("socket_scale_not_one:" + str(root.get_path_to(marker)))
		var position := _relative_transform(root, marker).origin
		records.append({"node": str(root.get_path_to(marker)), "role": role, "in_snap_group": in_group, "position_m": _vec_array(position)})
		if role == primary_role:
			primary.append(marker)
	var expected_count := 2 if primary_role in CHAIN_ROLES else (1 if primary_role == "prop_anchor" else 0)
	if not primary_role.is_empty() and primary_role not in SUPPORTED_ROLES:
		errors.append("unsupported_primary_socket_role:" + primary_role)
	if primary.size() != expected_count:
		errors.append("socket_count_mismatch:%d!=%d" % [primary.size(), expected_count])
	var positions: Array[Vector3] = []
	for marker in primary:
		positions.append(_relative_transform(root, marker).origin)
	var expected_separation := 0.0
	var actual_separation := 0.0
	var compatibility_passed := true
	var orientation_passed := true
	var rotation_passed := true
	var axis := str(root.get_meta("snap_axis", ""))
	if primary_role in CHAIN_ROLES and positions.size() == 2:
		var negative := Vector3.ZERO
		var positive := Vector3.ZERO
		match axis:
			"x":
				expected_separation = dimensions.x
				negative = Vector3(-dimensions.x * 0.5, 0.0, 0.0)
				positive = Vector3(dimensions.x * 0.5, 0.0, 0.0)
			"y":
				expected_separation = dimensions.y
				negative = Vector3.ZERO
				positive = Vector3(0.0, dimensions.y, 0.0)
			"z":
				expected_separation = dimensions.z
				negative = Vector3(0.0, 0.0, -dimensions.z * 0.5)
				positive = Vector3(0.0, 0.0, dimensions.z * 0.5)
			_:
				errors.append("unsupported_snap_axis:" + axis)
		if not _contains_near(positions, negative):
			errors.append("socket_negative_endpoint_mismatch:" + str(negative))
		if not _contains_near(positions, positive):
			errors.append("socket_positive_endpoint_mismatch:" + str(positive))
		actual_separation = positions[0].distance_to(positions[1])
		if absf(actual_separation - expected_separation) > TOLERANCE_M:
			errors.append("socket_pair_separation_mismatch:%f!=%f" % [actual_separation, expected_separation])
		var expected_midpoint := (negative + positive) * 0.5
		if not _near_vector((positions[0] + positions[1]) * 0.5, expected_midpoint):
			errors.append("socket_pair_midpoint_mismatch")
		compatibility_passed = bool(builder.generated_socket_roles_compatible(primary[0], primary[1]))
		if not compatibility_passed:
			errors.append("live3d_builder_rejects_primary_pair")
		var normal_a = primary[0].get_meta("socket_normal_local", Vector3.ZERO)
		var normal_b = primary[1].get_meta("socket_normal_local", Vector3.ZERO)
		orientation_passed = normal_a is Vector3 and normal_b is Vector3 and (normal_a as Vector3).normalized().dot((normal_b as Vector3).normalized()) < -0.999
		if not orientation_passed:
			errors.append("socket_pair_orientation_not_opposed")
		for quarter_turn in range(4):
			var yaw := Basis(Vector3.UP, deg_to_rad(90.0 * quarter_turn))
			var rotated_separation := (yaw * (positions[1] - positions[0])).length()
			if absf(rotated_separation - expected_separation) > TOLERANCE_M:
				rotation_passed = false
		if not rotation_passed:
			errors.append("cardinal_yaw_rotation_contract_failed")
	elif primary_role == "prop_anchor" and positions.size() == 1 and not _near_vector(positions[0], Vector3.ZERO):
		errors.append("prop_anchor_not_at_origin:" + str(positions[0]))
	var position_arrays: Array[Array] = []
	for position in positions:
		position_arrays.append(_vec_array(position))
	builder.free()
	return {
		"primary_role": primary_role,
		"snap_axis": axis,
		"primary_count": primary.size(),
		"expected_primary_count": expected_count,
		"total_count": markers.size(),
		"expected_total_count": expected_total,
		"live3d_builder_recognizes_module": builder_recognizes,
		"live3d_builder_recognized_marker_count": builder_markers.size(),
		"compatibility_passed": compatibility_passed,
		"orientation_passed": orientation_passed,
		"cardinal_yaw_rotation_passed": rotation_passed,
		"endpoint_positions_m": position_arrays,
		"expected_pair_separation_m": snappedf(expected_separation, 0.000001),
		"actual_pair_separation_m": snappedf(actual_separation, 0.000001),
		"all_markers": records,
	}
func _validate_source_hash(asset: Dictionary, root: Node3D, errors: Array[String]) -> Dictionary:
	var manifest_source := str(asset.get("source", ""))
	var wrapper_source := str(root.get_meta("source_asset", ""))
	var manifest_hash := str(asset.get("source_sha256", "")).to_lower()
	var wrapper_hash := str(root.get_meta("source_sha256", "")).to_lower()
	var current_hash := ""
	if manifest_source.is_empty() or not FileAccess.file_exists(manifest_source):
		errors.append("source_file_missing:" + manifest_source)
	else:
		current_hash = FileAccess.get_sha256(manifest_source).to_lower()
		if current_hash.is_empty():
			errors.append("source_sha256_read_failed")
	if wrapper_source != manifest_source:
		errors.append("wrapper_manifest_source_mismatch")
	if wrapper_hash.is_empty():
		errors.append("wrapper_source_sha256_missing")
	elif not current_hash.is_empty() and wrapper_hash != current_hash:
		errors.append("wrapper_source_sha256_mismatch")
	if not manifest_hash.is_empty() and manifest_hash != current_hash:
		errors.append("manifest_source_sha256_mismatch")
	if not manifest_hash.is_empty() and manifest_hash != wrapper_hash:
		errors.append("manifest_wrapper_source_sha256_mismatch")
	return {
		"manifest_source": manifest_source,
		"wrapper_source": wrapper_source,
		"manifest_sha256": manifest_hash,
		"wrapper_sha256": wrapper_hash,
		"current_sha256": current_hash,
		"manifest_declares_sha256": not manifest_hash.is_empty(),
		"wrapper_matches_current": not wrapper_hash.is_empty() and wrapper_hash == current_hash,
	}


func _validate_stability(scene_path: String, source_path: String, socket_role: String, errors: Array[String]) -> Dictionary:
	var wrapper_first := _wrapper_snapshot(scene_path, socket_role)
	var wrapper_second := _wrapper_snapshot(scene_path, socket_role)
	var source_first := _source_snapshot(source_path)
	var source_second := _source_snapshot(source_path)
	var wrapper_stable := _same_snapshot(wrapper_first, wrapper_second)
	var source_stable := _same_snapshot(source_first, source_second)
	if not bool(wrapper_first.get("loads", false)) or not bool(wrapper_second.get("loads", false)):
		errors.append("cache_replace_wrapper_load_failed")
	elif not wrapper_stable:
		errors.append("cache_replace_wrapper_snapshot_changed")
	if not bool(source_first.get("loads", false)) or not bool(source_second.get("loads", false)):
		errors.append("cache_replace_source_load_failed")
	elif not source_stable:
		errors.append("cache_replace_source_snapshot_changed")
	return {
		"method": "two_repeated_ResourceLoader_CACHE_MODE_REPLACE_loads",
		"editor_reimport_triggered": false,
		"wrapper_scene_stable": wrapper_stable,
		"imported_source_stable": source_stable,
		"wrapper_first": wrapper_first,
		"wrapper_second": wrapper_second,
		"source_first": source_first,
		"source_second": source_second,
	}

func _wrapper_snapshot(scene_path: String, socket_role: String) -> Dictionary:
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if packed == null:
		return {"loads": false}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"loads": false, "root_is_node3d": false}
	var root := instance as Node3D
	get_root().add_child(root)
	var unresolved := PackedStringArray()
	if root.has_method("apply_material_bindings"):
		unresolved = root.call("apply_material_bindings") as PackedStringArray
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	var ignored_errors: Array[String] = []
	var ignored_warnings: Array[Dictionary] = []
	var collisions: Array[CollisionShape3D] = []
	_collect_collisions(root, collisions)
	var markers: Array[Marker3D] = []
	_collect_markers(root, markers)
	var positions: Array[Array] = []
	for marker in markers:
		if str(marker.get_meta("socket_role", "")) == socket_role:
			positions.append(_vec_array(_relative_transform(root, marker).origin))
	var non_finite: Array[String] = []
	_collect_non_finite(root, root, non_finite)
	var unresolved_array: Array[String] = []
	for value in unresolved:
		unresolved_array.append(str(value))
	var snapshot := {
		"loads": true,
		"bounds": _aabb_record(_visual_bounds(root)),
		"performance": _mesh_performance(meshes, false, ignored_errors, ignored_warnings),
		"materials": _material_paths(meshes, ignored_errors),
		"collision_shape_count": collisions.size(),
		"primary_socket_positions_m": positions,
		"source": str(root.get_meta("source_asset", "")),
		"source_sha256": str(root.get_meta("source_sha256", "")),
		"unresolved_materials": unresolved_array,
		"finite_transforms": non_finite.is_empty(),
	}
	root.free()
	return snapshot


func _source_snapshot(source_path: String) -> Dictionary:
	var packed := ResourceLoader.load(source_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if packed == null:
		return {"loads": false}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"loads": false, "root_is_node3d": false}
	var root := instance as Node3D
	get_root().add_child(root)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	var ignored_errors: Array[String] = []
	var ignored_warnings: Array[Dictionary] = []
	var non_finite: Array[String] = []
	_collect_non_finite(root, root, non_finite)
	var snapshot := {
		"loads": true,
		"bounds": _aabb_record(_visual_bounds(root)),
		"performance": _mesh_performance(meshes, false, ignored_errors, ignored_warnings),
		"finite_transforms": non_finite.is_empty(),
		"current_sha256": FileAccess.get_sha256(source_path).to_lower() if FileAccess.file_exists(source_path) else "",
	}
	root.free()
	return snapshot


func _validate_pilot_scene(scene_path: String, demo_manifests: Array, attachment_manifests: Array) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[Dictionary] = []
	if scene_path.is_empty():
		return {"loads": false, "errors": ["pilot_scene_path_missing"], "warnings": warnings, "snap_demonstrations": []}
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if packed == null:
		return {"loads": false, "errors": ["pilot_scene_load_failed"], "warnings": warnings, "snap_demonstrations": []}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"loads": false, "errors": ["pilot_scene_root_is_not_node3d"], "warnings": warnings, "snap_demonstrations": []}
	var root := instance as Node3D
	get_root().add_child(root)
	if not root.scale.is_equal_approx(Vector3.ONE):
		errors.append("pilot_scene_root_scale_not_one")
	var non_finite: Array[String] = []
	_collect_non_finite(root, root, non_finite)
	if not non_finite.is_empty():
		errors.append("pilot_scene_non_finite_transforms:" + ",".join(non_finite))
	var demos: Array[Dictionary] = []
	for value in demo_manifests:
		if value is Dictionary:
			demos.append(_validate_demo(root, value as Dictionary, errors))
	var attachment_demos: Array[Dictionary] = []
	for value in attachment_manifests:
		if value is Dictionary:
			attachment_demos.append(_validate_attachment_demo(root, value as Dictionary, errors))
	var environment_qa := _validate_qa_environment(root, errors)
	var first := _pilot_snapshot(scene_path)
	var second := _pilot_snapshot(scene_path)
	var stable := _same_snapshot(first, second)
	if not bool(first.get("loads", false)) or not bool(second.get("loads", false)):
		errors.append("pilot_scene_cache_replace_load_failed")
	elif not stable:
		errors.append("pilot_scene_cache_replace_snapshot_changed")
	var result := {
		"loads": true,
		"root_scale_one": root.scale.is_equal_approx(Vector3.ONE),
		"finite_transforms": non_finite.is_empty(),
		"snap_demonstrations": demos,
		"attachment_demonstrations": attachment_demos,
		"environment_qa": environment_qa,
		"fresh_load_stability": {
			"method": "two_repeated_ResourceLoader_CACHE_MODE_REPLACE_loads",
			"passed": stable,
			"first": first,
			"second": second,
		},
		"errors": errors,
		"warnings": warnings,
	}
	root.free()
	return result


func _validate_qa_environment(root: Node3D, errors: Array[String]) -> Dictionary:
	var initial_error_count := errors.size()
	var world_node := root.find_child("WorldEnvironment", true, false)
	if not world_node is WorldEnvironment:
		world_node = _find_first_by_class(root, &"WorldEnvironment")
	var environment: Environment = null
	if world_node is WorldEnvironment:
		environment = (world_node as WorldEnvironment).environment
	else:
		errors.append("qa_world_environment_missing")
	if environment == null:
		errors.append("qa_environment_resource_missing")

	var background_mode := -1
	var background_color := Color.BLACK
	var ambient_source := -1
	var ambient_color := Color.BLACK
	var ambient_energy := -1.0
	var tonemap_mode := -1
	var tonemap_exposure := -1.0
	var glow_enabled := true
	if environment != null:
		background_mode = int(_property_value(environment, &"background_mode", -1))
		var background_color_value = _property_value(environment, &"background_color", Color.BLACK)
		if background_color_value is Color:
			background_color = background_color_value
		ambient_source = int(_property_value(environment, &"ambient_light_source", -1))
		var ambient_color_value = _property_value(environment, &"ambient_light_color", Color.BLACK)
		if ambient_color_value is Color:
			ambient_color = ambient_color_value
		ambient_energy = float(_property_value(environment, &"ambient_light_energy", -1.0))
		tonemap_mode = int(_property_value(environment, &"tonemap_mode", -1))
		tonemap_exposure = float(_property_value(environment, &"tonemap_exposure", -1.0))
		glow_enabled = bool(_property_value(environment, &"glow_enabled", true))
		if background_mode != 1:
			errors.append("qa_background_not_controlled_color")
		if not _is_neutral_color(background_color, 0.03) or background_color.get_luminance() < 0.05 or background_color.get_luminance() > 0.35:
			errors.append("qa_background_not_neutral_modest")
		if ambient_source != 2:
			errors.append("qa_ambient_source_not_color")
		if not _is_neutral_color(ambient_color, 0.03) or ambient_color.r < 0.9:
			errors.append("qa_ambient_color_not_neutral_white")
		if not is_finite(ambient_energy) or ambient_energy <= 0.0 or ambient_energy > 0.5:
			errors.append("qa_ambient_energy_not_modest:%f" % ambient_energy)
		if tonemap_mode != 4:
			errors.append("qa_tonemap_not_agx")
		if not is_finite(tonemap_exposure) or tonemap_exposure < 0.75 or tonemap_exposure > 1.1:
			errors.append("qa_tonemap_exposure_not_controlled:%f" % tonemap_exposure)
		if glow_enabled:
			errors.append("qa_glow_not_disabled")

	var key_node := root.find_child("KeyLight", true, false)
	var key_energy := -1.0
	var key_color := Color.BLACK
	if not key_node is DirectionalLight3D:
		errors.append("qa_key_directional_light_missing")
	else:
		var key := key_node as DirectionalLight3D
		key_energy = float(_property_value(key, &"light_energy", -1.0))
		var key_color_value = _property_value(key, &"light_color", Color.BLACK)
		if key_color_value is Color:
			key_color = key_color_value
		if not is_finite(key_energy) or key_energy < 0.55 or key_energy > 0.85:
			errors.append("qa_key_energy_not_near_point_seven:%f" % key_energy)
		if not _is_neutral_color(key_color, 0.03) or key_color.r < 0.9:
			errors.append("qa_key_light_not_neutral_white")

	var warm_fill_present := root.find_child("WarmFill", true, false) != null
	if warm_fill_present:
		errors.append("qa_warm_fill_present")
	var witness_present := root.find_child("WindowTransparencyWitness", true, false) != null
	if not witness_present:
		errors.append("qa_window_transparency_witness_missing")

	var camera_node := _find_first_by_class(root, &"Camera3D")
	if not camera_node is Camera3D:
		errors.append("qa_camera_missing")
	var attributes_value = _property_value(world_node, &"camera_attributes", null) if world_node is WorldEnvironment else null
	if not attributes_value is CameraAttributes and camera_node is Camera3D:
		attributes_value = _property_value(camera_node, &"attributes", null)
	var camera_attributes_present := attributes_value is CameraAttributes
	var auto_exposure_enabled := true
	if camera_attributes_present:
		if _has_property(attributes_value, &"auto_exposure_enabled"):
			auto_exposure_enabled = bool(attributes_value.get(&"auto_exposure_enabled"))
		else:
			errors.append("qa_camera_auto_exposure_property_missing")
		if auto_exposure_enabled:
			errors.append("qa_camera_auto_exposure_enabled")
	else:
		errors.append("qa_camera_attributes_missing")

	return {
		"passed": errors.size() == initial_error_count,
		"world_environment_present": world_node is WorldEnvironment,
		"environment_resource_present": environment != null,
		"background_mode": background_mode,
		"background_color": _color_array(background_color),
		"ambient_light_source": ambient_source,
		"ambient_light_color": _color_array(ambient_color),
		"ambient_light_energy": ambient_energy,
		"tonemap_mode": tonemap_mode,
		"tonemap_exposure": tonemap_exposure,
		"glow_enabled": glow_enabled,
		"key_light_present": key_node is DirectionalLight3D,
		"key_light_energy": key_energy,
		"key_light_color": _color_array(key_color),
		"warm_fill_present": warm_fill_present,
		"camera_attributes_present": camera_attributes_present,
		"camera_auto_exposure_enabled": auto_exposure_enabled,
		"window_transparency_witness_present": witness_present,
	}

func _validate_demo(root: Node3D, demo: Dictionary, errors: Array[String]) -> Dictionary:
	var source_scene := str(demo.get("source_scene", ""))
	var first_path := str(demo.get("first_node", ""))
	var second_path := str(demo.get("second_node", ""))
	var axis := str(demo.get("axis", "")).to_lower()
	var expected := float(demo.get("expected_separation_m", 0.0))
	var prefix := "snap_demo:%s:%s" % [first_path, second_path]
	var first := _find_pilot_node(root, first_path)
	var second := _find_pilot_node(root, second_path)
	if not first is Node3D:
		errors.append(prefix + ":first_node_missing_or_not_node3d")
	if not second is Node3D:
		errors.append(prefix + ":second_node_missing_or_not_node3d")
	if not first is Node3D or not second is Node3D:
		return {
			"source_scene": source_scene, "first_node": first_path, "second_node": second_path,
			"axis": axis, "expected_separation_m": expected, "passed": false,
		}
	var first_3d := first as Node3D
	var second_3d := second as Node3D
	if first_3d == second_3d:
		errors.append(prefix + ":nodes_are_identical")
	if not first_3d.scale.is_equal_approx(Vector3.ONE):
		errors.append(prefix + ":first_scale_not_one")
	if not second_3d.scale.is_equal_approx(Vector3.ONE):
		errors.append(prefix + ":second_scale_not_one")
	if not source_scene.is_empty():
		if first_3d.scene_file_path != source_scene:
			errors.append(prefix + ":first_source_scene_mismatch")
		if second_3d.scene_file_path != source_scene:
			errors.append(prefix + ":second_source_scene_mismatch")
	if axis not in ["x", "z"]:
		errors.append(prefix + ":unsupported_axis:" + axis)
	if not is_finite(expected) or expected <= 0.0:
		errors.append(prefix + ":invalid_expected_separation")
	var first_position := _relative_transform(root, first_3d).origin
	var second_position := _relative_transform(root, second_3d).origin
	var delta := second_position - first_position
	var actual := absf(delta.x) if axis == "x" else absf(delta.z)
	var off_axis := maxf(absf(delta.y), absf(delta.z)) if axis == "x" else maxf(absf(delta.x), absf(delta.y))
	if absf(actual - expected) > TOLERANCE_M:
		errors.append(prefix + ":separation_mismatch:%f!=%f" % [actual, expected])
	if off_axis > TOLERANCE_M:
		errors.append(prefix + ":off_axis_misalignment:%f" % off_axis)
	var first_bounds := _visual_bounds_between(root, first_3d)
	var second_bounds := _visual_bounds_between(root, second_3d)
	var seam := _axis_seam_delta(first_bounds.position.x, first_bounds.end.x, second_bounds.position.x, second_bounds.end.x) if axis == "x" else _axis_seam_delta(first_bounds.position.z, first_bounds.end.z, second_bounds.position.z, second_bounds.end.z)
	if absf(seam) > TOLERANCE_M:
		errors.append(prefix + ":visual_seam_gap_or_overlap:%f" % seam)
	var demo_errors := 0
	for error in errors:
		if error.begins_with(prefix + ":"):
			demo_errors += 1
	return {
		"source_scene": source_scene,
		"first_node": first_path,
		"second_node": second_path,
		"axis": axis,
		"expected_separation_m": snappedf(expected, 0.000001),
		"actual_separation_m": snappedf(actual, 0.000001),
		"off_axis_alignment_error_m": snappedf(off_axis, 0.000001),
		"visual_seam_delta_m": snappedf(seam, 0.000001),
		"seam_delta_sign": "gap" if seam > 0.0 else ("overlap" if seam < 0.0 else "touch"),
		"first_bounds": _aabb_record(first_bounds),
		"second_bounds": _aabb_record(second_bounds),
		"root_scales_one": first_3d.scale.is_equal_approx(Vector3.ONE) and second_3d.scale.is_equal_approx(Vector3.ONE),
		"passed": demo_errors == 0,
	}


func _validate_attachment_demo(root: Node3D, demo: Dictionary, errors: Array[String]) -> Dictionary:
	var host_name := str(demo.get("host_node", ""))
	var attachment_name := str(demo.get("attachment_node", ""))
	var prefix := "attachment_demo:%s:%s" % [host_name, attachment_name]
	var host := _find_pilot_node(root, host_name) as Node3D
	var attachment := _find_pilot_node(root, attachment_name) as Node3D
	if host == null:
		errors.append(prefix + ":host_missing")
	if attachment == null:
		errors.append(prefix + ":attachment_missing")
	if host == null or attachment == null:
		return {"host_node": host_name, "attachment_node": attachment_name, "passed": false}
	var host_marker := host.get_node_or_null(NodePath(str(demo.get("host_marker", "")))) as Marker3D
	var attachment_marker := attachment.get_node_or_null(NodePath(str(demo.get("attachment_marker", "")))) as Marker3D
	if host_marker == null:
		errors.append(prefix + ":host_marker_missing")
	if attachment_marker == null:
		errors.append(prefix + ":attachment_marker_missing")
	if host_marker == null or attachment_marker == null:
		return {"host_node": host_name, "attachment_node": attachment_name, "passed": false}
	var distance := host_marker.global_position.distance_to(attachment_marker.global_position)
	if distance > TOLERANCE_M:
		errors.append(prefix + ":marker_gap_or_overlap:%f" % distance)
	var host_role := str(host_marker.get_meta("socket_role", ""))
	var attachment_role := str(attachment_marker.get_meta("socket_role", ""))
	if host_role != str(demo.get("host_role", "")):
		errors.append(prefix + ":host_role_mismatch")
	if attachment_role != str(demo.get("attachment_role", "")):
		errors.append(prefix + ":attachment_role_mismatch")
	var builder = LIVE3D_BUILDER_SCRIPT.new()
	var compatible := bool(builder.generated_socket_roles_compatible(attachment_marker, host_marker))
	builder.free()
	if not compatible:
		errors.append(prefix + ":live3d_builder_role_incompatible")
	var demo_errors := 0
	for error in errors:
		if error.begins_with(prefix + ":"):
			demo_errors += 1
	return {
		"host_node": host_name,
		"attachment_node": attachment_name,
		"host_role": host_role,
		"attachment_role": attachment_role,
		"marker_distance_m": snappedf(distance, 0.000001),
		"live3d_builder_compatible": compatible,
		"passed": demo_errors == 0,
	}

func _pilot_snapshot(scene_path: String) -> Dictionary:
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if packed == null:
		return {"loads": false}
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return {"loads": false, "root_is_node3d": false}
	var root := instance as Node3D
	get_root().add_child(root)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	var ignored_errors: Array[String] = []
	var ignored_warnings: Array[Dictionary] = []
	var non_finite: Array[String] = []
	_collect_non_finite(root, root, non_finite)
	var snapshot := {
		"loads": true,
		"root_scale": _vec_array(root.scale),
		"direct_child_count": root.get_child_count(),
		"performance": _mesh_performance(meshes, false, ignored_errors, ignored_warnings),
		"finite_transforms": non_finite.is_empty(),
	}
	root.free()
	return snapshot


func _find_pilot_node(root: Node3D, requested_path: String) -> Node:
	if requested_path.is_empty():
		return null
	var direct := root.get_node_or_null(NodePath(requested_path))
	if direct != null:
		return direct
	var prefix := str(root.name) + "/"
	if requested_path.begins_with(prefix):
		direct = root.get_node_or_null(NodePath(requested_path.trim_prefix(prefix)))
		if direct != null:
			return direct
	if "/" not in requested_path:
		return root.find_child(requested_path, true, false)
	return null


func _axis_seam_delta(first_min: float, first_max: float, second_min: float, second_max: float) -> float:
	return second_min - first_max if first_min <= second_min else first_min - second_max


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}


func _material_paths(meshes: Array[MeshInstance3D], errors: Array[String]) -> Array[String]:
	var paths: Array[String] = []
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface_index)
			var path := material.resource_path if material != null else ""
			paths.append(path)
			if path.is_empty() or "/Steamtek/Materials/Source_Reconstructed/" not in path:
				errors.append("surface_not_using_shared_material:%s:%d" % [mesh_instance.name, surface_index])
	paths.sort()
	return paths


func _mesh_performance(meshes: Array[MeshInstance3D], validate_uv: bool, errors: Array[String], warnings: Array[Dictionary]) -> Dictionary:
	var surfaces := 0
	var vertices_total := 0
	var triangles_total := 0
	var surfaces_with_uv0 := 0
	var details: Array[Dictionary] = []
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			if validate_uv:
				errors.append("mesh_resource_missing:" + str(mesh_instance.name))
			continue
		var mesh := mesh_instance.mesh
		for surface_index in range(mesh.get_surface_count()):
			surfaces += 1
			var arrays := mesh.surface_get_arrays(surface_index)
			var vertex_array = arrays[Mesh.ARRAY_VERTEX] if arrays.size() > Mesh.ARRAY_VERTEX else null
			var index_array = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX else null
			var uv_array = arrays[Mesh.ARRAY_TEX_UV] if arrays.size() > Mesh.ARRAY_TEX_UV else null
			var vertices: int = vertex_array.size() if vertex_array != null else 0
			var indices: int = index_array.size() if index_array != null else 0
			var uv0: int = uv_array.size() if uv_array != null else 0
			var primitive: int = Mesh.PRIMITIVE_TRIANGLES
			if mesh is ArrayMesh:
				primitive = (mesh as ArrayMesh).surface_get_primitive_type(surface_index)
			var triangles := 0
			if primitive == Mesh.PRIMITIVE_TRIANGLES:
				triangles = int(indices / 3 if indices > 0 else vertices / 3)
			elif validate_uv:
				warnings.append({"code": "non_triangle_surface", "mesh": str(mesh_instance.name), "surface": surface_index, "primitive": primitive})
			if validate_uv and vertices > 0 and uv0 == 0:
				errors.append("surface_missing_uv0:%s:%d" % [mesh_instance.name, surface_index])
			if uv0 > 0:
				surfaces_with_uv0 += 1
			vertices_total += vertices
			triangles_total += triangles
			details.append({
				"mesh": str(mesh_instance.name), "surface": surface_index, "primitive": primitive,
				"vertices": vertices, "indices": indices, "triangles": triangles, "uv0_count": uv0,
			})
	return {
		"mesh_instances": meshes.size(), "surfaces": surfaces, "vertices": vertices_total,
		"triangles": triangles_total, "surfaces_with_uv0": surfaces_with_uv0, "surface_details": details,
	}


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)


func _collect_collisions(node: Node, output: Array[CollisionShape3D]) -> void:
	if node is CollisionShape3D:
		output.append(node as CollisionShape3D)
	for child in node.get_children():
		_collect_collisions(child, output)


func _collect_markers(node: Node, output: Array[Marker3D]) -> void:
	if node is Marker3D:
		output.append(node as Marker3D)
	for child in node.get_children():
		_collect_markers(child, output)


func _collect_non_finite(root: Node3D, node: Node, output: Array[String]) -> void:
	if node is Node3D:
		var node_3d := node as Node3D
		var transform := node_3d.transform
		if not _finite_vector(transform.origin) or not _finite_vector(transform.basis.x) or not _finite_vector(transform.basis.y) or not _finite_vector(transform.basis.z):
			output.append("." if node_3d == root else str(root.get_path_to(node_3d)))
	for child in node.get_children():
		_collect_non_finite(root, child, output)


func _visual_bounds(root: Node3D) -> AABB:
	return _visual_bounds_between(root, root)


func _visual_bounds_between(reference_root: Node3D, subtree: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(subtree, meshes)
	var bounds := AABB()
	var has_bounds := false
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		var mesh_bounds := _relative_transform(reference_root, mesh_instance) * mesh_instance.get_aabb()
		bounds = mesh_bounds if not has_bounds else bounds.merge(mesh_bounds)
		has_bounds = true
	return bounds


func _relative_transform(root: Node3D, descendant: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node = descendant
	while current != null and current != root:
		if current is Node3D:
			chain.push_front(current as Node3D)
		current = current.get_parent()
	var result := Transform3D.IDENTITY
	for node in chain:
		result *= node.transform
	return result


func _contains_near(positions: Array[Vector3], expected: Vector3) -> bool:
	for position in positions:
		if _near_vector(position, expected):
			return true
	return false


func _same_snapshot(first: Dictionary, second: Dictionary) -> bool:
	return JSON.stringify(first) == JSON.stringify(second)


func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)


func _finite_aabb(value: AABB) -> bool:
	return _finite_vector(value.position) and _finite_vector(value.size)


func _near_vector(first: Vector3, second: Vector3) -> bool:
	return absf(first.x - second.x) <= TOLERANCE_M and absf(first.y - second.y) <= TOLERANCE_M and absf(first.z - second.z) <= TOLERANCE_M


func _property_value(object_value: Object, property_name: StringName, fallback: Variant) -> Variant:
	if object_value == null or not _has_property(object_value, property_name):
		return fallback
	return object_value.get(property_name)


func _has_property(object_value: Object, property_name: StringName) -> bool:
	if object_value == null:
		return false
	for descriptor in object_value.get_property_list():
		if StringName(str((descriptor as Dictionary).get("name", ""))) == property_name:
			return true
	return false


func _find_first_by_class(node: Node, class_name_value: StringName) -> Node:
	if node.is_class(class_name_value):
		return node
	for child in node.get_children():
		var match := _find_first_by_class(child, class_name_value)
		if match != null:
			return match
	return null


func _is_neutral_color(value: Color, tolerance: float) -> bool:
	var darkest := minf(value.r, minf(value.g, value.b))
	var brightest := maxf(value.r, maxf(value.g, value.b))
	return brightest - darkest <= tolerance


func _color_array(value: Color) -> Array[float]:
	return [
		snappedf(value.r, 0.000001), snappedf(value.g, 0.000001),
		snappedf(value.b, 0.000001), snappedf(value.a, 0.000001),
	]

func _array_vector3(values: Array) -> Vector3:
	if values.size() != 3:
		return Vector3.ZERO
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func _vec_array(value: Vector3) -> Array[float]:
	return [snappedf(value.x, 0.000001), snappedf(value.y, 0.000001), snappedf(value.z, 0.000001)]


func _aabb_record(value: AABB) -> Dictionary:
	return {"position": _vec_array(value.position), "size": _vec_array(value.size), "end": _vec_array(value.end)}