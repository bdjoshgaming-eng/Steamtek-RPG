extends SceneTree

const CANDIDATE_SCENE := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Right.tscn"
const REVIEW_SCENE := "res://scenes/environment/live3d/qa/STK_PROP_Couch_L4_Right_Candidate_Review.tscn"
const APARTMENT_REVIEW_SCENE := "res://scenes/environment/live3d/qa/STK_PROP_Couch_L4_Right_Candidate_ApartmentReview.tscn"
const VARIANT_EDITOR_SCRIPT := "res://addons/steamtek_material_variant_editor/steamtek_material_variant_editor.gd"
const BUILDER_SCRIPT := "res://addons/steamtek_live3d_builder/steamtek_live3d_builder.gd"
const MATERIAL_DIR := "res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_right/"
const APARTMENT_SCENE := "res://scenes/environment/live3d/interiors/apartments/SteamtekPlayerApartmentProductionAssembly3D_v02.tscn"

var failures: PackedStringArray = []


func _initialize() -> void:
	var packed := load(CANDIDATE_SCENE) as PackedScene
	_check(packed != null, "right production wrapper loads")
	if packed == null:
		_finish()
		return

	var candidate := packed.instantiate() as Node3D
	root.add_child(candidate)
	await process_frame

	_check(candidate.name == "STK_PROP_Couch_L4_Right", "right wrapper root name")
	_check(candidate.scale.is_equal_approx(Vector3.ONE), "positive identity root scale")
	_check(_near(candidate.get_meta("module_dimensions_m", Vector3.ZERO), Vector3(3.2, 0.9, 1.8)), "3.20 x 0.90 x 1.80 meter contract")
	_check(str(candidate.get_meta("contact_pivot", "")) == "floor_center", "floor-centered pivot contract")
	_check(str(candidate.get_meta("front_axis", "")).begins_with("+Z"), "+Z front contract")
	_check(str(candidate.get_meta("sectional_orientation", "")) == "right", "right orientation metadata")
	_check(str(candidate.get_meta("sectional_direction", "")) == "return_on_negative_x_when_facing_plus_z", "return occupies negative X")
	_check(str(candidate.get_meta("material_variant_profile", "")) == "steamtek_sectional_couch_v1", "sectional material profile")
	_check(str(candidate.get_meta("production_status", "")) == "approved_production_asset", "gameplay approval recorded")
	_check(str(candidate.get_meta("builder_registration", "")) == "registered_after_gameplay_approval", "Builder registration approval recorded")
	_check(int(candidate.get_meta("seat_count", 0)) == 4, "four-seat contract")

	var mesh_instances: Array[MeshInstance3D] = []
	_collect_render_nodes(candidate, mesh_instances)
	_check(mesh_instances.size() == 1, "one combined render mesh")
	_check(candidate.find_children("*", "Skeleton3D", true, false).is_empty(), "no skeleton")
	_check(candidate.find_children("*", "AnimationPlayer", true, false).is_empty(), "no animation player")
	_check(candidate.find_children("*", "Camera3D", true, false).is_empty(), "wrapper contains no cameras")
	_check(candidate.find_children("*", "Light3D", true, false).is_empty(), "wrapper contains no lights")

	var combined_aabb := AABB()
	var has_aabb := false
	var triangle_count := 0
	var vertex_count := 0
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		var world_aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		combined_aabb = combined_aabb.merge(world_aabb) if has_aabb else world_aabb
		has_aabb = true
		for surface_index in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			vertex_count += vertices.size()
			triangle_count += vertices.size() / 3 if indices.is_empty() else indices.size() / 3
	_check(has_aabb, "render bounds available")
	if has_aabb:
		_check(_near(combined_aabb.position, Vector3(-1.6, 0.0, -0.9)), "bottom-centered render origin")
		_check(_near(combined_aabb.size, Vector3(3.2, 0.9, 1.8)), "exact render dimensions")
	_check(triangle_count == 17529, "17,529 render triangles")
	_check(vertex_count == 13745, "13,745 imported render vertices")

	var collision_shapes := candidate.find_children("*", "CollisionShape3D", true, false)
	_check(collision_shapes.size() == 6, "six simplified collision boxes")
	for collision_shape in collision_shapes:
		_check((collision_shape as CollisionShape3D).shape is BoxShape3D, "%s uses BoxShape3D" % collision_shape.name)
	var return_collision := candidate.get_node_or_null("StaticBody/ReturnLowerCollision") as CollisionShape3D
	_check(return_collision != null and return_collision.position.x < 0.0, "collision follows right-facing return")

	var seat_markers := candidate.get_node("Sockets").find_children("Seat*", "Marker3D", false, false)
	_check(seat_markers.size() == 4, "four seat sockets")
	var return_seat := candidate.get_node_or_null("Sockets/Seat04_Return") as Marker3D
	_check(return_seat != null and return_seat.position.x < 0.0 and is_equal_approx(return_seat.position.y, 0.45), "return seat socket is oriented on negative X")
	var snap_markers := candidate.get_node("Sockets").find_children("*", "Marker3D", false, false)
	_check(snap_markers.size() == 8, "four seat plus four furniture/alignment sockets")

	for material_name in ["SourceMatte", "Oxblood", "DeepTeal", "ElectricPlum", "BurnishedOchre"]:
		var material_path := MATERIAL_DIR + "STK_MAT_Couch_L4_Right_%s.tres" % material_name
		var material := load(material_path) as ShaderMaterial
		_check(material != null, "%s material loads" % material_name)
		if material != null:
			_check(material.get_shader_parameter("mask_cushion_leather") != null, "%s cushion mask bound" % material_name)
			_check(material.get_shader_parameter("mask_frame_paint") != null, "%s frame mask bound" % material_name)
			_check(material.get_shader_parameter("mask_accent_metal") != null, "%s accent mask bound" % material_name)

	var teal_material := load(MATERIAL_DIR + "STK_MAT_Couch_L4_Right_DeepTeal.tres") as ShaderMaterial
	if teal_material != null:
		candidate.set("variant_material", teal_material)
		await process_frame
		_check(mesh_instances[0].material_override == teal_material, "right material variant applies to render mesh")

	_check(load(VARIANT_EDITOR_SCRIPT) != null, "Material Variant Editor script parses")
	var variant_editor_text := _read_text(VARIANT_EDITOR_SCRIPT)
	_check(variant_editor_text.contains("SECTIONAL_RIGHT_TEMPLATE_MATERIAL_PATH"), "variant editor selects the right texture set")
	_check(variant_editor_text.contains("_sectional_base_scene_path(module)"), "saved right variants retain the right base scene")
	var builder_text := _read_text(BUILDER_SCRIPT)
	_check(builder_text.count("STK_PROP_Couch_L4_Right.tscn") == 1, "approved right couch is registered once in Builder")
	_check(builder_text.count("STK_PROP_Couch_L4_Left.tscn") == 1, "approved left couch remains registered once")
	_check(load(REVIEW_SCENE) is PackedScene, "reference comparison scene loads")
	_check(load(APARTMENT_REVIEW_SCENE) is PackedScene, "v02 apartment comparison scene loads")
	var apartment_text := _read_text(APARTMENT_SCENE)
	_check(apartment_text.contains("STK_PROP_Couch_L4_Left.tscn"), "approved left couch remains in v02 apartment")
	_check(not apartment_text.contains("STK_PROP_Couch_L4_Right.tscn"), "right candidate does not replace apartment furniture")

	candidate.queue_free()
	_finish()


func _collect_render_nodes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_render_nodes(child, meshes)


func _near(actual: Vector3, expected: Vector3) -> bool:
	return actual.distance_to(expected) < 0.001


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: %s" % label)


func _finish() -> void:
	if failures.is_empty():
		print("SECTIONAL_RIGHT_CANDIDATE_QA PASS")
		quit(0)
	else:
		push_error("SECTIONAL_RIGHT_CANDIDATE_QA FAIL (%d): %s" % [failures.size(), ", ".join(failures)])
		quit(1)
