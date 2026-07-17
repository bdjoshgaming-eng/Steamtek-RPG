@tool
class_name SteamtekEquipmentItem
extends Resource

enum AttachmentMode {
	SKINNED,
	RIGID_SOCKET,
}

@export_group("Identity")
@export var item_id: StringName
@export var display_name: String = "Equipment"
@export_enum("head", "torso", "legs", "feet", "hands", "weapon_main", "weapon_off", "back") var slot: String = "torso"

@export_group("Visual")
@export var scene: PackedScene
@export var attachment_mode: AttachmentMode = AttachmentMode.SKINNED
@export_enum("Socket_Head", "Socket_Hand_R", "Socket_Hand_L", "Socket_Back") var socket_name: String = "Socket_Head"

@export_group("Body Visibility")
@export var hide_body_regions: PackedStringArray = []

