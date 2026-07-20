extends Node3D

@onready var review_camera: Camera3D = $LockedApartmentReviewCamera


func _ready() -> void:
	review_camera.look_at(Vector3(0.0, 1.0, 1.4), Vector3.UP)
	if "--capture-sectional-right-apartment" in OS.get_cmdline_user_args() or OS.get_environment("STK_CAPTURE_SECTIONAL_RIGHT_APARTMENT") == "1":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var output_path := ProjectSettings.globalize_path(
			"res://incoming/meshy_apartment_assets/APT_Couch_L4_Right/staged_pipeline/previews/STK_PROP_Couch_L4_Right_Candidate_Godot_ApartmentComparison.png"
		)
		var result := get_viewport().get_texture().get_image().save_png(output_path)
		if result != OK:
			push_error("Failed to save right-sectional apartment comparison: %s" % result)
		get_tree().quit(result)
