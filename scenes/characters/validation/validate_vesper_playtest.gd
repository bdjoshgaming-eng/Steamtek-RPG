extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/tests/characters/VesperKane_PlayerCharacter_Playtest_v01.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Vesper standalone playtest scene")
		quit(2)
		return
	var playtest := packed.instantiate()
	get_root().add_child(playtest)
	await process_frame
	var required_paths := [
		"VesperKane_PlayerCharacter_v01",
		"VesperKane_PlayerCharacter_v01/VisualPivot/STK_C001_VesperKane_ProductionAppearance_v01",
		"VesperKane_PlayerCharacter_v01/VisualPivot/InteractionDetector/Collision",
		"CameraRig/Camera3D", "Floor/Collision", "TestDoor/DoorBody/Collision",
		"TestDoor/InteractionArea/Collision", "PlaytestUI/InteractionPrompt",
	]
	for path in required_paths:
		if playtest.get_node_or_null(path) == null:
			push_error("Missing playtest node: %s" % path)
			quit(3)
			return
	print("VESPER_PLAYTEST_OK=", playtest.name)
	print("VESPER_EDITOR_VISIBLE_MODEL_OK=true")
	var door: Area3D = playtest.get_node("TestDoor/InteractionArea")
	var character: CharacterBody3D = playtest.get_node("VesperKane_PlayerCharacter_v01")
	var closed_prompt := String(door.call("get_interaction_prompt"))
	door.call("interact", character)
	var open_prompt := String(door.call("get_interaction_prompt"))
	if closed_prompt == open_prompt:
		push_error("Door interaction did not change state")
		quit(4)
		return
	print("VESPER_INTERACTION_CONTRACT_OK=", closed_prompt, " -> ", open_prompt)
	playtest.queue_free()
	await process_frame
	quit()
