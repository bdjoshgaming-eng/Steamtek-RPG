class_name SteamtekSCUMk1Enemy
extends SteamtekHumanoidCharacter3D

## Production wrapper for the regular SCU Mk1 enemy.
## Combat AI and stats remain separate; this script owns the visual LOD contract.

@export var lod0_end_distance := 14.0
@export var lod1_end_distance := 28.0
@export var animation_preview_enabled := false

var _lod_meshes: Dictionary = {}
var _forced_lod := -1


func _ready() -> void:
	super._ready()
	if not animation_preview_enabled:
		_reset_to_rest_pose()
	_configure_lods()


func force_lod(level: int) -> void:
	_forced_lod = clampi(level, -1, 2)
	_configure_lods()


func get_lod_mesh(level: int) -> MeshInstance3D:
	return _lod_meshes.get(level) as MeshInstance3D


func play_idle() -> void:
	if animation_preview_enabled:
		super.play_idle()
	else:
		_reset_to_rest_pose()


func play_walk() -> void:
	if animation_preview_enabled:
		super.play_walk()
	else:
		_reset_to_rest_pose()


func play_run() -> void:
	if animation_preview_enabled:
		super.play_run()
	else:
		_reset_to_rest_pose()


func _reset_to_rest_pose() -> void:
	if animation_player != null:
		animation_player.stop()
	active_animation = ""
	if character_instance == null:
		return
	for child in character_instance.find_children("*", "Skeleton3D", true, false):
		var skeleton := child as Skeleton3D
		if skeleton != null:
			skeleton.reset_bone_poses()


func _configure_lods() -> void:
	_lod_meshes.clear()
	if character_instance == null:
		push_error("SCU Mk1 visual instance was not created")
		return
	for child in character_instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null:
			continue
		for level in range(3):
			if "_LOD%d" % level in mesh_instance.name:
				_lod_meshes[level] = mesh_instance
	for level in range(3):
		if not _lod_meshes.has(level):
			push_error("SCU Mk1 is missing LOD%d" % level)
			continue
		var mesh_instance := _lod_meshes[level] as MeshInstance3D
		if not animation_preview_enabled:
			mesh_instance.skin = null
			mesh_instance.skeleton = NodePath()
		mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		if _forced_lod >= 0:
			mesh_instance.visible = level == _forced_lod
			mesh_instance.visibility_range_begin = 0.0
			mesh_instance.visibility_range_end = 0.0
			continue
		mesh_instance.visible = true
		match level:
			0:
				mesh_instance.visibility_range_begin = 0.0
				mesh_instance.visibility_range_end = lod0_end_distance
			1:
				mesh_instance.visibility_range_begin = lod0_end_distance
				mesh_instance.visibility_range_end = lod1_end_distance
			2:
				mesh_instance.visibility_range_begin = lod1_end_distance
				mesh_instance.visibility_range_end = 0.0
