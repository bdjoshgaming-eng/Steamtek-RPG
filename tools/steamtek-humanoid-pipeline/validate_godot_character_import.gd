extends SceneTree


func _init() -> void:
	var asset_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--asset="):
			asset_path = argument.trim_prefix("--asset=")
	if asset_path.is_empty():
		push_error("Pass --asset=res://path/to/character.glb")
		quit(2)
		return

	var packed := load(asset_path) as PackedScene
	if packed == null:
		push_error("Could not load character scene: %s" % asset_path)
		quit(2)
		return

	var instance := packed.instantiate()
	root.add_child(instance)
	var report := {
		"asset": asset_path,
		"skeletons": [],
		"meshes": [],
		"animations": [],
		"sockets": [],
	}
	collect_character_data(instance, report)
	report.animations.sort()
	report.sockets.sort()

	var required_animations := ["STK_IDLE", "STK_WALK", "STK_RUN"]
	var missing_animations: Array[String] = []
	for animation_name in required_animations:
		if animation_name not in report.animations:
			missing_animations.append(animation_name)
	var required_sockets := ["SOCKET_Head", "SOCKET_Hand_R", "SOCKET_Hand_L", "SOCKET_Back"]
	var missing_sockets: Array[String] = []
	for socket_name in required_sockets:
		if socket_name not in report.sockets:
			missing_sockets.append(socket_name)
	report["missing_animations"] = missing_animations
	report["missing_sockets"] = missing_sockets
	report["passed"] = (
		report.skeletons.size() == 1
		and not report.meshes.is_empty()
		and missing_animations.is_empty()
		and missing_sockets.is_empty()
	)
	print("STEAMTEK_GODOT_CHARACTER_REPORT=" + JSON.stringify(report))
	quit(0 if report.passed else 1)


func collect_character_data(node: Node, report: Dictionary) -> void:
	if node is Skeleton3D:
		report.skeletons.append({
			"name": node.name,
			"bone_count": node.get_bone_count(),
		})
	elif node is MeshInstance3D:
		report.meshes.append({
			"name": node.name,
			"has_skin": node.skin != null,
		})
	elif node is AnimationPlayer:
		for animation_name in node.get_animation_list():
			var normalized := String(animation_name)
			if normalized not in report.animations:
				report.animations.append(normalized)
	if String(node.name).begins_with("SOCKET_"):
		report.sockets.append(String(node.name))
	for child in node.get_children():
		collect_character_data(child, report)
