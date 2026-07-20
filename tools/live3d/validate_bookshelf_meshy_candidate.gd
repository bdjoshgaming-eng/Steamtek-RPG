extends SceneTree


func _init() -> void:
	var resources := [
		"res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Bookshelf_A_Production.glb",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_Bookshelf_ProjectedVariant.gdshader",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_SourceMatte.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_DeepTeal.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_Oxblood.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_ElectricPlum.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_BurnishedOchre.tres",
		"res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn",
		"res://assets/environment/live3d/models/apartment_interior/meshy/candidates/STK_PROP_Bookshelf_A_ProductionCandidate.glb",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/STK_Bookshelf_MeshyVariant.gdshader",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/STK_MAT_Bookshelf_A_Meshy_SourceMatte.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/STK_MAT_Bookshelf_A_Meshy_DeepTeal.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/STK_MAT_Bookshelf_A_Meshy_Oxblood.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/STK_MAT_Bookshelf_A_Meshy_ElectricPlum.tres",
		"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/STK_MAT_Bookshelf_A_Meshy_BurnishedOchre.tres",
		"res://scenes/environment/live3d/props/apartment_interior/candidates/STK_PROP_Bookshelf_A_MeshyCandidate.tscn",
		"res://scenes/environment/live3d/qa/STK_PROP_Bookshelf_A_MeshyCandidate_Review.tscn",
		"res://scenes/environment/live3d/qa/STK_PROP_Bookshelf_A_MeshyCandidate_ApartmentReview.tscn",
	]
	var failed := false
	for path in resources:
		var resource := ResourceLoader.load(path)
		if resource == null:
			failed = true
			push_error("BOOKSHELF_CANDIDATE_LOAD_FAILED: %s" % path)
		else:
			print("BOOKSHELF_CANDIDATE_LOAD_OK: %s" % path)
	var production_scene := load("res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn") as PackedScene
	if production_scene != null:
		var production_instance := production_scene.instantiate() as Node3D
		var supported_mesh_found := false
		for child in production_instance.find_children("*", "MeshInstance3D", true, false):
			print("BOOKSHELF_PRODUCTION_MESH: %s" % child.name)
			if child.name in ["ProjectedShell", "STK_PROP_Bookshelf_A_Mesh", "STK_PROP_Bookshelf_A"]:
				supported_mesh_found = true
		if not supported_mesh_found:
			failed = true
			push_error("BOOKSHELF_VARIANT_PREVIEW_MESH_NOT_FOUND")
		production_instance.free()
	quit(1 if failed else 0)
