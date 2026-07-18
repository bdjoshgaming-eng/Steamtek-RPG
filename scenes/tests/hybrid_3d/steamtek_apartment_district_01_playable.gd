extends Node3D

## Playable wrapper for the linked Apartment District 01 assembly.
## Environment art remains replaceable; the approved character wrapper and
## camera offset are reused without scale changes.

const SCALE_CONTRACT_ID := "SteamtekLive3DScaleContract-1"
const BUILDING_OCCLUSION_MASK := 4
const OCCLUSION_SHADER_SOURCE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_back;

uniform vec4 body_color : source_color = vec4(0.18, 0.31, 0.40, 0.26);
uniform vec4 rim_color : source_color = vec4(0.10, 0.70, 0.82, 0.72);
uniform float rim_power : hint_range(0.5, 8.0) = 2.6;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.78;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, rim_power) * rim_strength;
	ALBEDO = mix(body_color.rgb, rim_color.rgb, rim);
	ALPHA = mix(body_color.a, rim_color.a, rim);
}
"""

@export var camera_follow_response := 9.0
@export var respawn_height := -3.0

@export_group("Character Occlusion Silhouette")
@export var occlusion_body_color := Color(0.18, 0.31, 0.40, 0.26)
@export var occlusion_rim_color := Color(0.10, 0.70, 0.82, 0.72)
@export_range(0.5, 8.0, 0.1) var occlusion_rim_power := 2.6
@export_range(0.0, 1.0, 0.01) var occlusion_rim_strength := 0.78

@onready var character: SteamtekHumanoidCharacter3D = $VesperKane_PlayerCharacter_v01
@onready var player_entry: Marker3D = $PlayerEntry_South
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var fade_rect: ColorRect = $PlayableUI/Fade

var character_meshes: Array[MeshInstance3D] = []
var original_material_overlays: Dictionary = {}
var occlusion_material: ShaderMaterial
var character_is_occluded := false


func _ready() -> void:
	_prepare_character_occlusion_overlay()
	_snap_camera_to_character()
	camera.look_at(character.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_fade_from_black()


func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x, 0.0, target.z)
	var weight := 1.0 - exp(-camera_follow_response * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(desired, weight)
	_update_camera_occlusion()
	if character.global_position.y < respawn_height:
		_respawn_character()


func _snap_camera_to_character() -> void:
	var target := character.global_position
	camera_rig.global_position = Vector3(target.x, 0.0, target.z)


func _respawn_character() -> void:
	character.global_position = player_entry.global_position
	character.velocity = Vector3.ZERO
	_snap_camera_to_character()


func _update_camera_occlusion() -> void:
	var query := PhysicsRayQueryParameters3D.create(
		camera.global_position,
		character.global_position + Vector3(0.0, 1.0, 0.0),
		BUILDING_OCCLUSION_MASK
	)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_set_character_occluded(not hit.is_empty())


func _prepare_character_occlusion_overlay() -> void:
	_collect_character_meshes(character)
	if character_meshes.is_empty():
		push_warning("No MeshInstance3D descendants found for C001 occlusion overlay.")
		return
	var shader := Shader.new()
	shader.code = OCCLUSION_SHADER_SOURCE
	occlusion_material = ShaderMaterial.new()
	occlusion_material.shader = shader
	occlusion_material.render_priority = 1
	occlusion_material.set_shader_parameter("body_color", occlusion_body_color)
	occlusion_material.set_shader_parameter("rim_color", occlusion_rim_color)
	occlusion_material.set_shader_parameter("rim_power", occlusion_rim_power)
	occlusion_material.set_shader_parameter("rim_strength", occlusion_rim_strength)


func _collect_character_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		character_meshes.append(mesh_instance)
		original_material_overlays[mesh_instance.get_instance_id()] = mesh_instance.material_overlay
	for child in node.get_children():
		_collect_character_meshes(child)


func _set_character_occluded(is_occluded: bool) -> void:
	if character_is_occluded == is_occluded:
		return
	character_is_occluded = is_occluded
	for mesh_instance in character_meshes:
		if not is_instance_valid(mesh_instance):
			continue
		if is_occluded:
			mesh_instance.material_overlay = occlusion_material
		else:
			mesh_instance.material_overlay = original_material_overlays.get(
				mesh_instance.get_instance_id()
			) as Material


func _fade_from_black() -> void:
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.28)
