extends SceneTree

const EXTERIOR := "res://scenes/levels/surface_3d/ApartmentExterior_TransitionTest_v01.tscn"
const INTERIOR := "res://scenes/levels/apartment_3d/ApartmentInterior_TransitionTest_v01.tscn"


func _initialize() -> void:
	var exterior: Node = await _instantiate_scene(EXTERIOR)
	if exterior == null:
		quit(2)
		return
	if not _verify_level(exterior, "ApartmentFacade/ApartmentDoor", INTERIOR, "ExteriorReturnSpawn"):
		quit(3)
		return
	exterior.queue_free()
	await process_frame
	var interior: Node = await _instantiate_scene(INTERIOR)
	if interior == null:
		quit(4)
		return
	if not _verify_level(interior, "ExitDoor", EXTERIOR, "InteriorEntrySpawn"):
		quit(5)
		return
	print("APARTMENT_3D_ROUND_TRIP_OK=true")
	interior.queue_free()
	await process_frame
	quit()


func _instantiate_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load transition scene: %s" % path)
		return null
	var scene := packed.instantiate()
	get_root().add_child(scene)
	await process_frame
	return scene


func _verify_level(level: Node, door_path: String, target_scene: String, spawn_name: String) -> bool:
	for required in ["VesperKane_PlayerCharacter_v01", "CameraRig/Camera3D", "TransitionUI/Fade", door_path, spawn_name]:
		if level.get_node_or_null(required) == null:
			push_error("Missing transition node: %s" % required)
			return false
	var door: SteamtekZoneDoor3D = level.get_node(door_path)
	if door.target_scene_path != target_scene:
		push_error("Incorrect transition target on %s" % door_path)
		return false
	if door.target_spawn_id.is_empty():
		push_error("Missing destination spawn on %s" % door_path)
		return false
	return true
