class_name SteamtekHazmatCombatPrototype
extends SteamtekHumanoidCharacter3D

## Combat-animation carrier for the future Hazmat enemy.
##
## The current visible mesh is the approved Steamtek base-body proxy. Replace
## only the visual when the Hazmat outfit is ready; keep this scene, animation
## names, collision, and RightHand rifle attachment contract.

const RIFLE_IDLE := "STK_RIFLE_IDLE"
const RIFLE_FIRE := "STK_RIFLE_FIRE"
const RIFLE_RELOAD := "STK_RIFLE_RELOAD"
const RIFLE_TURN_LEFT := "STK_RIFLE_TURN_LEFT"
const RIFLE_TURN_RIGHT := "STK_RIFLE_TURN_RIGHT"
const RIFLE_CROUCH_STRAFE_LEFT := "STK_RIFLE_CROUCH_STRAFE_LEFT"
const RIFLE_CROUCH_STRAFE_RIGHT := "STK_RIFLE_CROUCH_STRAFE_RIGHT"
const RIFLE_BUTTSTROKE := "STK_RIFLE_BUTTSTROKE"
const HIT_REACT_STRONG := "STK_HIT_REACT_STRONG"
const DEATH_FORWARD := "STK_DEATH_FORWARD"

@export var rifle_scene: PackedScene
@export var rifle_position_offset := Vector3.ZERO
@export var rifle_rotation_offset_degrees := Vector3.ZERO
@export var rifle_scale := Vector3.ONE

var rifle_attachment: BoneAttachment3D
var rifle_mount: Marker3D
var rifle_instance: Node3D
var _return_to_idle_after_action := false


func _ready() -> void:
	super._ready()
	add_to_group("steamtek_enemy")
	add_to_group("steamtek_hazmat_enemy")
	set_player_controlled(false)
	_ensure_rifle_attachment()
	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	play_rifle_idle()


func play_rifle_idle() -> bool:
	_return_to_idle_after_action = false
	return _play_contract_animation(RIFLE_IDLE, true)


func play_rifle_fire() -> bool:
	return _play_one_shot(RIFLE_FIRE)


func play_rifle_reload() -> bool:
	return _play_one_shot(RIFLE_RELOAD)


func play_rifle_turn_left() -> bool:
	return _play_one_shot(RIFLE_TURN_LEFT)


func play_rifle_turn_right() -> bool:
	return _play_one_shot(RIFLE_TURN_RIGHT)


func play_crouch_strafe_left() -> bool:
	_return_to_idle_after_action = false
	return _play_contract_animation(RIFLE_CROUCH_STRAFE_LEFT, true)


func play_crouch_strafe_right() -> bool:
	_return_to_idle_after_action = false
	return _play_contract_animation(RIFLE_CROUCH_STRAFE_RIGHT, true)


func play_rifle_buttstroke() -> bool:
	return _play_one_shot(RIFLE_BUTTSTROKE)


func play_hit_reaction() -> bool:
	return _play_one_shot(HIT_REACT_STRONG)


func play_death() -> bool:
	_return_to_idle_after_action = false
	return _play_contract_animation(DEATH_FORWARD, false)


func get_rifle_attachment() -> BoneAttachment3D:
	return rifle_attachment


func get_rifle_mount() -> Marker3D:
	return rifle_mount


func get_combat_animation_names() -> PackedStringArray:
	return PackedStringArray([
		DEATH_FORWARD,
		HIT_REACT_STRONG,
		RIFLE_BUTTSTROKE,
		RIFLE_CROUCH_STRAFE_LEFT,
		RIFLE_CROUCH_STRAFE_RIGHT,
		RIFLE_FIRE,
		RIFLE_IDLE,
		RIFLE_RELOAD,
		RIFLE_TURN_LEFT,
		RIFLE_TURN_RIGHT,
		"STK_RUN",
		"STK_WALK",
	])


func _play_one_shot(animation_key: String) -> bool:
	_return_to_idle_after_action = true
	var played := _play_contract_animation(animation_key, false)
	if not played:
		_return_to_idle_after_action = false
	return played


func _play_contract_animation(animation_key: String, loop: bool) -> bool:
	if animation_player == null:
		push_error("Hazmat combat prototype has no AnimationPlayer")
		return false
	var resolved_name := _find_animation_name(animation_key)
	if resolved_name.is_empty():
		push_error("Hazmat combat prototype is missing animation: %s" % animation_key)
		return false
	var animation := animation_player.get_animation(resolved_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	animation_player.play(resolved_name, locomotion_blend_seconds)
	animation_player.speed_scale = 1.0
	active_animation = resolved_name
	return true


func _on_animation_finished(animation_name: StringName) -> void:
	if not _return_to_idle_after_action:
		return
	if String(animation_name) != active_animation:
		return
	_return_to_idle_after_action = false
	play_rifle_idle()


func _ensure_rifle_attachment() -> void:
	if character_instance == null:
		push_error("Hazmat combat prototype has no visual instance")
		return
	var skeleton: Skeleton3D
	for child in character_instance.find_children("*", "Skeleton3D", true, false):
		skeleton = child as Skeleton3D
		if skeleton != null:
			break
	if skeleton == null:
		push_error("Hazmat combat prototype could not find its Skeleton3D")
		return
	if skeleton.find_bone("RightHand") < 0:
		push_error("Hazmat combat prototype skeleton has no RightHand bone")
		return

	rifle_attachment = skeleton.get_node_or_null("RifleAttachment") as BoneAttachment3D
	if rifle_attachment == null:
		rifle_attachment = BoneAttachment3D.new()
		rifle_attachment.name = "RifleAttachment"
		rifle_attachment.bone_name = "RightHand"
		skeleton.add_child(rifle_attachment)

	rifle_mount = rifle_attachment.get_node_or_null("RifleMount") as Marker3D
	if rifle_mount == null:
		rifle_mount = Marker3D.new()
		rifle_mount.name = "RifleMount"
		rifle_attachment.add_child(rifle_mount)
	rifle_mount.position = rifle_position_offset
	rifle_mount.rotation_degrees = rifle_rotation_offset_degrees
	rifle_mount.scale = rifle_scale

	if rifle_scene == null:
		return
	rifle_instance = rifle_scene.instantiate() as Node3D
	if rifle_instance == null:
		push_error("Assigned Hazmat rifle scene is not a Node3D")
		return
	rifle_instance.name = "RifleVisual"
	rifle_mount.add_child(rifle_instance)
