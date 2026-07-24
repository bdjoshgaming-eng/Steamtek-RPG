extends SceneTree

func _initialize() -> void:
	var packed := load("res://output/corec_male_character/corec_hacker_review.tscn") as PackedScene
	if packed == null:
		push_error("Review scene failed to load")
		quit(1)
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	var player := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player != null:
		print("ANIMATION_LIST ", player.get_animation_list())
	if player == null or not player.has_animation("STK_Idle_Mixamo_01"):
		push_error("STK_Idle_Mixamo_01 was not found")
		quit(2)
		return
	var animation := player.get_animation("STK_Idle_Mixamo_01")
	print("COREC_IDLE_OK name=STK_Idle_Mixamo_01 duration=", animation.length, " loop_mode=", animation.loop_mode)
	quit(0)
