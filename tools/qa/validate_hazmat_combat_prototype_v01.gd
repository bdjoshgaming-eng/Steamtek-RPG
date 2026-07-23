extends Node


const SCENE_PATH := "res://scenes/characters/enemies/STK_NPC_Hazmat_CombatPrototype_v01.tscn"
const EXPECTED_ANIMATIONS := [
	"STK_DEATH_FORWARD",
	"STK_HIT_REACT_STRONG",
	"STK_RIFLE_BUTTSTROKE",
	"STK_RIFLE_CROUCH_STRAFE_LEFT",
	"STK_RIFLE_CROUCH_STRAFE_RIGHT",
	"STK_RIFLE_FIRE",
	"STK_RIFLE_IDLE",
	"STK_RIFLE_RELOAD",
	"STK_RIFLE_TURN_LEFT",
	"STK_RIFLE_TURN_RIGHT",
	"STK_RUN",
	"STK_WALK",
]


func _ready() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load Hazmat combat prototype scene")
		get_tree().quit(2)
		return
	var instance := packed.instantiate() as SteamtekHazmatCombatPrototype
	if instance == null:
		push_error("Hazmat combat prototype has the wrong root script")
		get_tree().quit(3)
		return
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame

	var errors: Array[String] = []
	var animation_player := instance.get_character_animation_player()
	if animation_player == null:
		errors.append("missing AnimationPlayer")
	else:
		for expected in EXPECTED_ANIMATIONS:
			var found := false
			for imported_name in animation_player.get_animation_list():
				if String(imported_name) == expected or String(imported_name).ends_with("/" + expected):
					found = true
					break
			if not found:
				errors.append("missing animation %s" % expected)

	var skeleton_count := instance.character_instance.find_children("*", "Skeleton3D", true, false).size()
	if skeleton_count != 1:
		errors.append("expected one Skeleton3D, found %d" % skeleton_count)
	if instance.get_rifle_attachment() == null:
		errors.append("missing RightHand RifleAttachment")
	if instance.get_rifle_mount() == null:
		errors.append("missing RifleMount")
	if instance.idle_animation.is_empty():
		errors.append("rifle idle did not resolve")

	var report := {
		"scene": SCENE_PATH,
		"passed": errors.is_empty(),
		"errors": errors,
		"skeleton_count": skeleton_count,
		"animations": (
			Array(animation_player.get_animation_list())
			if animation_player != null
			else []
		),
		"rifle_attachment": (
			instance.get_rifle_attachment().get_path()
			if instance.get_rifle_attachment() != null
			else NodePath()
		),
		"rifle_mount": (
			instance.get_rifle_mount().get_path()
			if instance.get_rifle_mount() != null
			else NodePath()
		),
	}
	print("STEAMTEK_HAZMAT_COMBAT_SCENE_REPORT=" + JSON.stringify(report))
	get_tree().quit(0 if errors.is_empty() else 1)
