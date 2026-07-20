extends SceneTree

const CANDIDATE_SCENE := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Left.tscn"
const APARTMENT_REVIEW_SCENE := "res://scenes/environment/live3d/qa/STK_PROP_Couch_L4_Left_Candidate_ApartmentReview.tscn"
const VARIANT_EDITOR_SCRIPT := "res://addons/steamtek_material_variant_editor/steamtek_material_variant_editor.gd"
const BUILDER_SCRIPT := "res://addons/steamtek_live3d_builder/steamtek_live3d_builder.gd"
const MATERIAL_DIR := "res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_left/"
const COUCH_A_SCENE := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_A.tscn"

var failures: PackedStringArray = []


func _initialize() -> void:
	var packed := load(CANDIDATE_SCENE) as PackedScene
	_check(packed != null, "production wrapper loads")
	if packed == null:
		_finish()
		return

	var candidate := packed.instantiate() as Node3D
	root.add_child(candidate)
	await process_frame

	_check(candidate.name == "STK_PROP_Couch_L4_Left", "production wrapper root name")
	_check(candidate.get_meta("module_dimensions_m", Vector3.ZERO).is_equal_approx(Vector3(3.2, 0.9, 1.8)), "3.20 x 0.90 x 1.80 meter contract")
	_check(str(candidate.get_meta("contact_pivot", "")) == "floor_center", "floor-centered pivot contract")
	_check(str(candidate.get_meta("front_axis", "")).begins_with("+Z"), "+Z front contract")
	_check(str(candidate.get_meta("sectional_direction", "")) == "return_on_positive_x_when_facing_plus_z", "left-sectional direction contract")
	_check(str(candidate.get_meta("material_variant_profile", "")) == "steamtek_sectional_couch_v1", "sectional material profile")
	_check(str(candidate.get_meta("builder_registration", "")) == "registered_after_gameplay_approval", "Builder registration approval recorded")
	_check(int(candidate.get_meta("seat_count", 0)) == 4, "four-seat contract")
	_check(is_equal_approx(float(candidate.get_meta("seat_height_m", 0.0)), 0.45), "0.45 meter seat-height contract")

	var mesh_instances: Array[MeshInstance3D] = []
	_collect_render_nodes(candidate, mesh_instances)
	_check(mesh_instances.size() == 1, "one combined render mesh")
	_check(candidate.find_children("*", "Skeleton3D", true, false).is_empty(), "no skeleton")
	_check(candidate.find_children("*", "AnimationPlayer", true, false).is_empty(), "no animation player")

	var combined_aabb := AABB()
	var has_aabb := false
	var triangle_count := 0
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		var world_aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		combined_aabb = combined_aabb.merge(world_aabb) if has_aabb else world_aabb
		has_aabb = true
		triangle_count += _mesh_triangle_count(mesh_instance.mesh)
	_check(has_aabb, "render bounds available")
	if has_aabb:
		_check(combined_aabb.position.is_equal_approx(Vector3(-1.6, 0.0, -0.9)), "bottom-centered render origin")
		_check(combined_aabb.size.is_equal_approx(Vector3(3.2, 0.9, 1.8)), "exact render dimensions")
	_check(triangle_count == 18455, "18,455 render triangles")

	var collision_shapes := candidate.find_children("*", "CollisionShape3D", true, false)
	_check(collision_shapes.size() == 6, "six simplified collision boxes")
	for collision_shape in collision_shapes:
		_check((collision_shape as CollisionShape3D).shape is BoxShape3D, "%s uses BoxShape3D" % collision_shape.name)

	var seat_markers := get_nodes_in_group("steamtek_live3d_seat")
	var snap_markers := get_nodes_in_group("steamtek_live3d_snap")
	_check(seat_markers.size() == 4, "four seat sockets")
	_check(snap_markers.size() == 4, "two outer plus front/rear alignment sockets")

	for material_name in ["SourceMatte", "Oxblood", "DeepTeal", "ElectricPlum", "BurnishedOchre"]:
		var material_path := MATERIAL_DIR + "STK_MAT_Couch_L4_Left_%s.tres" % material_name
		var material := load(material_path) as ShaderMaterial
		_check(material != null, "%s material loads" % material_name)
		if material != null:
			_check(material.get_shader_parameter("mask_cushion_leather") != null, "%s cushion mask bound" % material_name)
			_check(material.get_shader_parameter("mask_frame_paint") != null, "%s frame mask bound" % material_name)
			_check(material.get_shader_parameter("mask_accent_metal") != null, "%s accent mask bound" % material_name)

	var teal_material := load(MATERIAL_DIR + "STK_MAT_Couch_L4_Left_DeepTeal.tres") as ShaderMaterial
	_check(teal_material != null, "sectional runtime preview material available")
	if teal_material != null:
		candidate.set("variant_material", teal_material)
		await process_frame
		var applied_meshes := 0
		for mesh_instance in mesh_instances:
			if mesh_instance.material_override == teal_material:
				applied_meshes += 1
		_check(applied_meshes == mesh_instances.size(), "sectional variant applies to every render mesh")
		_check(float(teal_material.get_shader_parameter("cushion_strength")) > 0.8, "sectional cushion recolor strength is active")
		_check(float(teal_material.get_shader_parameter("frame_strength")) > 0.2, "sectional frame recolor strength is active")

	_check(load(VARIANT_EDITOR_SCRIPT) != null, "Material Variant Editor script parses")
	_check(load(BUILDER_SCRIPT) != null, "Live3D Builder script parses")
	var variant_editor_text := _read_text(VARIANT_EDITOR_SCRIPT)
	_check(variant_editor_text.contains("dock.name = \"STK Variants\""), "Material Variants dock has a short unique identity")
	_check(variant_editor_text.contains("add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)"), "Material Variants dock is a lower-right tab")
	var builder_text := _read_text(BUILDER_SCRIPT)
	_check(builder_text.contains("dock.name = \"Steamtek Live3D Builder\""), "Live3D Builder dock has the correct identity")
	_check(builder_text.contains("add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)"), "Live3D Builder remains in the lower-right slot")
	_check(builder_text.count("STK_PROP_Couch_L4_Left.tscn") == 1, "approved base asset appears once in the Builder catalog")
	_check(load(APARTMENT_REVIEW_SCENE) is PackedScene, "v02 apartment comparison scene loads")
	_check(FileAccess.file_exists("res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Couch_L4_Left_Production.glb"), "production GLB exists")
	var apartment_text := _read_text("res://scenes/environment/live3d/interiors/apartments/SteamtekPlayerApartmentProductionAssembly3D_v02.tscn")
	_check(apartment_text.contains("STK_PROP_Couch_L4_Left.tscn"), "approved sectional is placed in the production apartment")
	_check(apartment_text.contains("STK_PROP_Couch_A.tscn"), "user-added two-seat comparison couch remains in the apartment")
	_check(apartment_text.contains("STK_MAT_Couch_A_SourceMatte.tres"), "two-seat apartment couch uses the matte source material")

	var couch_a_packed := load(COUCH_A_SCENE) as PackedScene
	_check(couch_a_packed != null, "two-seat couch wrapper loads")
	if couch_a_packed != null:
		var couch_a := couch_a_packed.instantiate() as Node3D
		var couch_a_material := couch_a.get("variant_material") as ShaderMaterial
		_check(couch_a_material != null, "two-seat couch has a default matte material")
		if couch_a_material != null:
			_check(is_zero_approx(float(couch_a_material.get_shader_parameter("tint_strength"))), "two-seat source color remains untinted")
			_check(couch_a_material.shader.code.contains("upholstery_roughness = max(roughness, 0.84)"), "two-seat upholstery matte floor")
			_check(couch_a_material.shader.code.contains("SPECULAR = 0.18"), "two-seat restrained specular response")
		couch_a.free()

	candidate.queue_free()
	_finish()


func _collect_render_nodes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_render_nodes(child, meshes)


func _mesh_triangle_count(mesh: Mesh) -> int:
	var total := 0
	for surface_index in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface_index)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += vertices.size() / 3
		else:
			total += indices.size() / 3
	return total


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: %s" % label)


func _finish() -> void:
	if failures.is_empty():
		print("SECTIONAL_PRODUCTION_QA PASS")
		quit(0)
	else:
		push_error("SECTIONAL_PRODUCTION_QA FAIL (%d): %s" % [failures.size(), ", ".join(failures)])
		quit(1)
