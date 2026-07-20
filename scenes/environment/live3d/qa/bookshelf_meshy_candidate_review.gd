extends Node3D

@onready var review_camera: Camera3D = $ReviewCamera
@onready var bookshelf_candidate: Node3D = $BookshelfCandidate


func _ready() -> void:
	review_camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	var capture_label := "SourceMatte"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--bookshelf-variant="):
			capture_label = argument.trim_prefix("--bookshelf-variant=")
			var material_path := (
				"res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf_meshy_candidate/"
				+ "STK_MAT_Bookshelf_A_Meshy_%s.tres" % capture_label
			)
			var material := load(material_path) as Material
			if material == null:
				push_error("Unknown bookshelf review material: %s" % material_path)
			else:
				bookshelf_candidate.variant_material = material
	if "--capture-bookshelf" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var output_path := ProjectSettings.globalize_path(
			"res://incoming/meshy_apartment_assets/APT_Bookshelf_A/staged_pipeline/previews/STK_PROP_Bookshelf_A_Candidate_Godot_%s.png" % capture_label
		)
		var result := get_viewport().get_texture().get_image().save_png(output_path)
		if result != OK:
			push_error("Failed to save bookshelf candidate capture: %s" % result)
		get_tree().quit(result)
