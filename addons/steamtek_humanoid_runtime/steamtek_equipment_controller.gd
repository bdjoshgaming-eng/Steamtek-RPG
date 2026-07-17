@tool
class_name SteamtekEquipmentController
extends Node

signal item_equipped(slot: String, item: SteamtekEquipmentItem)
signal item_unequipped(slot: String)
signal equipment_error(message: String)

@export_group("Canonical Character")
@export_node_path("Skeleton3D") var skeleton_path: NodePath
@export_node_path("Node3D") var skinned_equipment_root_path: NodePath
@export_node_path("Node3D") var body_regions_root_path: NodePath

@export_group("Animation Contract")
@export var required_animation_names: PackedStringArray = ["STK_IDLE", "STK_WALK"]

var _equipped_nodes: Dictionary = {}
var _equipped_items: Dictionary = {}

const BONE_ALIASES := {
	"hips": PackedStringArray(["hips", "pelvis", "root"]),
	"spine": PackedStringArray(["spine", "spine1", "spine2", "chest"]),
	"head": PackedStringArray(["head"]),
	"left_hand": PackedStringArray(["lefthand", "hand_l", "hand.l"]),
	"right_hand": PackedStringArray(["righthand", "hand_r", "hand.r"]),
}

const SOCKET_BONES := {
	"Socket_Head": "head",
	"Socket_Hand_R": "right_hand",
	"Socket_Hand_L": "left_hand",
	"Socket_Back": "spine",
}


func equip(item: SteamtekEquipmentItem) -> bool:
	if item == null or item.scene == null:
		return _fail("Equipment item or scene is missing.")

	unequip(item.slot)
	var instance := item.scene.instantiate()
	instance.name = _safe_node_name(item.item_id if item.item_id != &"" else StringName(item.display_name))

	if item.attachment_mode == SteamtekEquipmentItem.AttachmentMode.SKINNED:
		if not _attach_skinned(instance):
			instance.queue_free()
			return false
	else:
		if not _attach_rigid(instance, item.socket_name):
			instance.queue_free()
			return false

	_set_body_regions(item.hide_body_regions, false)
	_equipped_nodes[item.slot] = instance
	_equipped_items[item.slot] = item
	item_equipped.emit(item.slot, item)
	return true


func unequip(slot: String) -> void:
	if not _equipped_nodes.has(slot):
		return
	var old_item: SteamtekEquipmentItem = _equipped_items.get(slot)
	if old_item:
		_set_body_regions(old_item.hide_body_regions, true)
	var old_node: Node = _equipped_nodes[slot]
	if is_instance_valid(old_node):
		old_node.queue_free()
	_equipped_nodes.erase(slot)
	_equipped_items.erase(slot)
	item_unequipped.emit(slot)


func validate_character() -> PackedStringArray:
	var issues := PackedStringArray()
	var skeleton := _skeleton()
	if skeleton == null:
		issues.append("Canonical Skeleton3D is not assigned.")
	else:
		for semantic_name in BONE_ALIASES:
			if _find_semantic_bone(skeleton, semantic_name) < 0:
				issues.append("Recommended semantic bone is missing: %s" % semantic_name)
		_configure_socket_bones(skeleton, issues)

	var animation_player := _find_animation_player(get_parent())
	if animation_player == null:
		issues.append("No AnimationPlayer found under the character.")
	else:
		for required_name in required_animation_names:
			if not _animation_exists(animation_player, required_name):
				issues.append("Animation is missing: %s" % required_name)
	return issues


func _attach_skinned(instance: Node) -> bool:
	var skeleton := _skeleton()
	var root := get_node_or_null(skinned_equipment_root_path) as Node3D
	if skeleton == null or root == null:
		return _fail("Assign the canonical skeleton and SkinnedEquipment root first.")
	root.add_child(instance)
	var meshes := _find_meshes(instance)
	if meshes.is_empty():
		return _fail("Skinned equipment contains no MeshInstance3D.")
	for mesh in meshes:
		if mesh.skin == null or mesh.skin.get_bind_count() == 0:
			return _fail("%s has no skin weights. Bind it in Blender Intake before export." % mesh.name)
		mesh.skeleton = mesh.get_path_to(skeleton)
	return true


func _attach_rigid(instance: Node, socket_name: String) -> bool:
	var skeleton := _skeleton()
	if skeleton == null:
		return _fail("Canonical Skeleton3D is not assigned.")
	var socket := skeleton.get_node_or_null(NodePath(socket_name)) as BoneAttachment3D
	if socket == null:
		return _fail("Rigid socket was not found: %s" % socket_name)
	socket.add_child(instance)
	return true


func _set_body_regions(regions: PackedStringArray, visible_value: bool) -> void:
	var root := get_node_or_null(body_regions_root_path)
	if root == null:
		return
	for region in regions:
		var region_node := root.get_node_or_null(NodePath(region)) as Node3D
		if region_node:
			region_node.visible = visible_value


func _skeleton() -> Skeleton3D:
	return get_node_or_null(skeleton_path) as Skeleton3D


func _configure_socket_bones(skeleton: Skeleton3D, issues: PackedStringArray) -> void:
	for socket_name in SOCKET_BONES:
		var socket := skeleton.get_node_or_null(NodePath(socket_name)) as BoneAttachment3D
		if socket == null:
			issues.append("Rigid equipment socket is missing: %s" % socket_name)
			continue
		var bone_index := _find_semantic_bone(skeleton, SOCKET_BONES[socket_name])
		if bone_index >= 0:
			socket.bone_name = skeleton.get_bone_name(bone_index)


func _find_semantic_bone(skeleton: Skeleton3D, semantic_name: String) -> int:
	var aliases: PackedStringArray = BONE_ALIASES.get(semantic_name, PackedStringArray())
	for bone_index in range(skeleton.get_bone_count()):
		var normalized := String(skeleton.get_bone_name(bone_index)).to_lower().replace("-", "_")
		var short_name := normalized.get_slice(":", normalized.get_slice_count(":") - 1)
		for alias in aliases:
			if normalized == alias or short_name == alias:
				return bone_index
	return -1


func _find_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		result.append(root)
	for child in root.get_children():
		result.append_array(_find_meshes(child))
	return result


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null


func _animation_exists(player: AnimationPlayer, animation_name: String) -> bool:
	for library_name in player.get_animation_library_list():
		var library := player.get_animation_library(library_name)
		if library and library.has_animation(animation_name):
			return true
	return false


func _safe_node_name(value: StringName) -> String:
	var cleaned := String(value).strip_edges().replace(" ", "_").replace("-", "_")
	return cleaned if not cleaned.is_empty() else "Equipment"


func _fail(message: String) -> bool:
	push_error("Steamtek Equipment: " + message)
	equipment_error.emit(message)
	return false
