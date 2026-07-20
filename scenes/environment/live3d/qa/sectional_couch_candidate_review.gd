extends Node3D

@onready var review_camera: Camera3D = $ReviewCamera
@onready var couch_candidate: Node3D = $CouchCandidate


func _ready() -> void:
	review_camera.look_at(Vector3(0.0, 0.48, -0.08), Vector3.UP)
	var capture_label := "SourceMatte"
	var environment_variant := OS.get_environment("STK_CAPTURE_SECTIONAL_VARIANT")
	if not environment_variant.is_empty():
		capture_label = environment_variant
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--sectional-variant="):
			capture_label = argument.trim_prefix("--sectional-variant=")
	if capture_label != "SourceMatte":
			var material_path := (
				"res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_left/"
				+ "STK_MAT_Couch_L4_Left_%s.tres" % capture_label
			)
			var material := load(material_path) as Material
			if material == null:
				push_error("Unknown sectional review material: %s" % material_path)
			else:
				couch_candidate.variant_material = material
	if "--capture-sectional" in OS.get_cmdline_user_args() or not environment_variant.is_empty():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var output_path := ProjectSettings.globalize_path(
			"res://incoming/meshy_apartment_assets/APT_Couch_L4_Left/staged_pipeline/previews/STK_PROP_Couch_L4_Left_Candidate_Godot_%s.png" % capture_label
		)
		var result := get_viewport().get_texture().get_image().save_png(output_path)
		if result != OK:
			push_error("Failed to save sectional candidate capture: %s" % result)
		get_tree().quit(result)
