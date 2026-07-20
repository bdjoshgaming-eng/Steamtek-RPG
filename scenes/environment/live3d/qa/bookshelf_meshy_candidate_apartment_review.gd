extends Node3D

@onready var review_camera: Camera3D = $LockedApartmentReviewCamera


func _ready() -> void:
	review_camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	if "--capture-bookshelf-apartment" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var output_path := ProjectSettings.globalize_path(
			"res://incoming/meshy_apartment_assets/APT_Bookshelf_A/staged_pipeline/previews/STK_PROP_Bookshelf_A_Candidate_Godot_ApartmentComparison.png"
		)
		var result := get_viewport().get_texture().get_image().save_png(output_path)
		if result != OK:
			push_error("Failed to save bookshelf apartment comparison: %s" % result)
		get_tree().quit(result)
