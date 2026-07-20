extends Node3D

@onready var review_camera: Camera3D = $ReviewCamera


func _ready() -> void:
	review_camera.look_at(Vector3(0.0, 0.46, 0.0), Vector3.UP)
	if OS.get_environment("STK_CAPTURE_COUCH_A_MATTE") == "1":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var output_path := ProjectSettings.globalize_path(
			"res://incoming/meshy_apartment_assets/APT_Couch_2seat_Rust/STK_PROP_Couch_A_Godot_MatteReview.png"
		)
		var result := get_viewport().get_texture().get_image().save_png(output_path)
		if result != OK:
			push_error("Failed to save two-seat couch matte review: %s" % result)
		get_tree().quit(result)
