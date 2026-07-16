extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/characters/player/VesperKane_PlayerCharacter_v01.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Vesper production character scene")
		quit(2)
		return
	var character := packed.instantiate()
	get_root().add_child(character)
	await process_frame
	var required_paths := [
		"BodyCollision", "VisualPivot", "VisualPivot/InteractionOrigin",
		"CameraTarget", "GroundContact", "Audio",
	]
	for path in required_paths:
		if character.get_node_or_null(path) == null:
			push_error("Missing production character node: %s" % path)
			quit(3)
			return
	var player: AnimationPlayer = character.get_character_animation_player()
	if player == null:
		push_error("Vesper production character has no AnimationPlayer")
		quit(4)
		return
	for required_animation in ["STK_IDLE", "STK_WALK"]:
		if not required_animation in player.get_animation_list():
			push_error("Missing animation: %s" % required_animation)
			quit(5)
			return
	print("VESPER_PLAYER_CHARACTER_OK=", character.name)
	print("VESPER_PLAYER_COLLISION_LAYER=", character.collision_layer)
	print("VESPER_PLAYER_COLLISION_MASK=", character.collision_mask)
	print("VESPER_PLAYER_ANIMATIONS=", player.get_animation_list())
	print("VESPER_PLAYER_FORWARD_CORRECTION=", character.model_forward_yaw_offset_degrees)
	character.queue_free()
	await process_frame
	quit()

