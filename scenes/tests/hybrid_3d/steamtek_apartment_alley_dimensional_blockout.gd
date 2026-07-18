extends Node3D

## Dimensionally authoritative apartment/alley blockout for the live-3D hybrid.
## One Godot unit equals one meter. The approved protagonist is never rescaled
## to compensate for legacy environment art.

const SCALE_CONTRACT_ID := "SteamtekLive3DScaleContract-1"

const BUILDING_WIDTH := 10.0
const BUILDING_DEPTH := 7.0
const STOREY_HEIGHT := 3.2
const BUILDING_HEIGHT := STOREY_HEIGHT * 2.0
const DOOR_WIDTH := 1.2
const DOOR_HEIGHT := 2.2
const ALLEY_WIDTH := 3.5

@export var camera_follow_response := 9.0
@export var facade_albedo: Texture2D
@export var ground_albedo: Texture2D

@onready var architecture: Node3D = $Architecture
@onready var character: SteamtekHumanoidCharacter3D = $VesperKane_PlayerCharacter_v01
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var interaction_prompt: Label = $TransitionUI/InteractionPrompt
@onready var fade_rect: ColorRect = $TransitionUI/Fade

var concrete_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var door_material: StandardMaterial3D
var wet_ground_material: StandardMaterial3D
var alley_ground_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var amber_emission_material: StandardMaterial3D
var puddle_material: StandardMaterial3D
var drain_material: StandardMaterial3D
var transition_in_progress := false


func _ready() -> void:
	_create_materials()
	_build_dimensional_shell()
	_apply_pending_spawn()
	_snap_camera_to_character()
	camera.look_at(character.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	character.interaction_focus_changed.connect(_on_interaction_focus_changed)
	_on_interaction_focus_changed("", null)
	for door_node in get_tree().get_nodes_in_group("steamtek_zone_door_3d"):
		var door := door_node as SteamtekZoneDoor3D
		if door != null and is_ancestor_of(door):
			door.zone_transition_requested.connect(_on_zone_transition_requested)
	_fade_from_black()


func _process(delta: float) -> void:
	var target := character.global_position
	var desired := Vector3(target.x, 0.0, target.z)
	var weight := 1.0 - exp(-camera_follow_response * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(desired, weight)


func _create_materials() -> void:
	concrete_material = _material("WetConcrete", Color(0.11, 0.13, 0.16), 0.12, 0.58)
	wall_material = _material("DarkSteelWall", Color(0.74, 0.77, 0.82), 0.32, 0.58)
	if facade_albedo != null:
		wall_material.albedo_texture = facade_albedo
		wall_material.uv1_triplanar = true
		wall_material.uv1_world_triplanar = true
		wall_material.uv1_scale = Vector3(0.62, 0.62, 0.62)
	trim_material = _material("CopperTrim", Color(0.18, 0.105, 0.065), 0.68, 0.4)
	door_material = _material("ApartmentDoor", Color(0.095, 0.065, 0.045), 0.6, 0.42)
	roof_material = _material("RoofSteel", Color(0.065, 0.075, 0.09), 0.52, 0.36)
	amber_emission_material = _emissive_material("AmberDoorLight", Color(0.12, 0.045, 0.012), Color(0.9, 0.22, 0.025), 1.25)
	wet_ground_material = _material("WetStreet", Color(0.055, 0.07, 0.09), 0.28, 0.3)
	alley_ground_material = _material("ServiceAlley", Color(0.075, 0.085, 0.1), 0.18, 0.46)
	for ground_material in [concrete_material, wet_ground_material, alley_ground_material]:
		_apply_ground_texture(ground_material)
	puddle_material = _material("ShallowPuddle", Color(0.025, 0.045, 0.065, 0.72), 0.72, 0.12)
	puddle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	drain_material = _material("DrainSteel", Color(0.025, 0.03, 0.038), 0.78, 0.3)


func _build_dimensional_shell() -> void:
	# World floor and visually distinct circulation zones.
	_add_block("WorldFloor", Vector3(0.5, -0.16, -3.5), Vector3(24.0, 0.3, 22.0), wet_ground_material, true)
	_add_block("FrontSidewalk", Vector3(-1.0, 0.015, -1.5), Vector3(10.0, 0.06, 3.0), concrete_material, false)
	_add_block("ServiceAlleyGround", Vector3(5.75, 0.02, -6.5), Vector3(ALLEY_WIDTH, 0.07, BUILDING_DEPTH), alley_ground_material, false)
	_add_ground_details()

	# Apartment footprint: x -6..4, z -3..-10. The facade opening is a real
	# 1.2 m x 2.2 m door instead of a character-scaled painted suggestion.
	_add_block("FrontWallLeft", Vector3(-5.0, BUILDING_HEIGHT * 0.5, -3.0), Vector3(2.0, BUILDING_HEIGHT, 0.3), wall_material, true)
	_add_block("FrontWallRight", Vector3(0.6, BUILDING_HEIGHT * 0.5, -3.0), Vector3(6.8, BUILDING_HEIGHT, 0.3), wall_material, true)
	_add_block("FrontDoorHeader", Vector3(-3.4, DOOR_HEIGHT + (BUILDING_HEIGHT - DOOR_HEIGHT) * 0.5, -3.0), Vector3(DOOR_WIDTH, BUILDING_HEIGHT - DOOR_HEIGHT, 0.3), wall_material, true)
	_add_block("ApartmentDoor", Vector3(-3.4, DOOR_HEIGHT * 0.5, -3.04), Vector3(1.08, DOOR_HEIGHT, 0.12), door_material, true)

	_add_block("RightSideWall", Vector3(4.0, BUILDING_HEIGHT * 0.5, -6.5), Vector3(0.3, BUILDING_HEIGHT, BUILDING_DEPTH), wall_material, true)
	_add_block("BackWall", Vector3(-1.0, BUILDING_HEIGHT * 0.5, -10.0), Vector3(BUILDING_WIDTH, BUILDING_HEIGHT, 0.3), wall_material, true)
	_add_block("Roof", Vector3(-1.0, BUILDING_HEIGHT + 0.12, -6.5), Vector3(10.3, 0.24, 7.3), roof_material, true)
	# Exterior gameplay never enters the shell directly; the apartment door will
	# transition to a separate interior scene. This invisible footprint blocker
	# prevents access from an unmodeled side or corner and stops roof clipping.
	_add_collision_box(
		"BuildingFootprintBlocker",
		Vector3(-1.0, BUILDING_HEIGHT * 0.5, -6.5),
		Vector3(BUILDING_WIDTH, BUILDING_HEIGHT, BUILDING_DEPTH)
	)

	# Storey and roof lines make the physical measurements legible at a glance.
	_add_block("StoreyBandFront", Vector3(-1.0, STOREY_HEIGHT, -2.81), Vector3(BUILDING_WIDTH, 0.12, 0.08), trim_material, false)
	_add_block("StoreyBandSide", Vector3(4.19, STOREY_HEIGHT, -6.5), Vector3(0.08, 0.12, BUILDING_DEPTH), trim_material, false)
	_add_block("FrontParapet", Vector3(-1.0, BUILDING_HEIGHT + 0.42, -2.9), Vector3(10.3, 0.6, 0.25), wall_material, true)
	_add_block("SideParapet", Vector3(4.1, BUILDING_HEIGHT + 0.42, -6.5), Vector3(0.25, 0.6, 7.3), wall_material, true)

	# Meter-scale window packed scenes are authored and placed in the .tscn.
	# This keeps glass/frame variants reusable without changing the openings.

	# Neo-industrial facade detailing remains deterministic geometry, allowing
	# later texture replacement without changing scale, pivots, or collision.
	_add_block("DoorFrameLeft", Vector3(-4.0, 1.15, -2.78), Vector3(0.12, 2.3, 0.14), trim_material, false)
	_add_block("DoorFrameRight", Vector3(-2.8, 1.15, -2.78), Vector3(0.12, 2.3, 0.14), trim_material, false)
	_add_block("DoorFrameTop", Vector3(-3.4, 2.26, -2.78), Vector3(1.32, 0.12, 0.14), trim_material, false)
	_add_block("DoorHeaderLight", Vector3(-3.4, 2.43, -2.68), Vector3(0.72, 0.08, 0.08), amber_emission_material, false)
	_add_block("DoorAccessPanel", Vector3(-2.69, 1.12, -2.67), Vector3(0.14, 0.24, 0.07), amber_emission_material, false)
	_add_block("FrontBaseCourse", Vector3(-1.0, 0.18, -2.78), Vector3(BUILDING_WIDTH, 0.22, 0.14), trim_material, false)
	_add_block("SideBaseCourse", Vector3(4.18, 0.18, -6.5), Vector3(0.14, 0.22, BUILDING_DEPTH), trim_material, false)
	_add_block("FacadePipeA", Vector3(3.15, 3.0, -2.72), Vector3(0.12, 5.8, 0.12), trim_material, false)
	_add_block("FacadePipeClampLow", Vector3(3.15, 1.4, -2.64), Vector3(0.34, 0.1, 0.1), roof_material, false)
	_add_block("FacadePipeClampHigh", Vector3(3.15, 4.6, -2.64), Vector3(0.34, 0.1, 0.1), roof_material, false)
	_add_block("RoofVentBase", Vector3(-0.5, 6.48, -6.7), Vector3(1.6, 0.5, 1.3), roof_material, false)
	_add_block("RoofVentCap", Vector3(-0.5, 6.78, -6.7), Vector3(1.9, 0.14, 1.55), trim_material, false)

	# A measured opposite wall establishes the 3.5 m service-alley clearance.
	_add_block("OppositeAlleyWall", Vector3(7.65, 2.4, -6.5), Vector3(0.3, 4.8, BUILDING_DEPTH), concrete_material, true)


func _apply_ground_texture(material: StandardMaterial3D) -> void:
	if ground_albedo == null:
		return
	material.albedo_texture = ground_albedo
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(0.48, 0.48, 0.48)


func _add_ground_details() -> void:
	# Thin, non-colliding glossy overlays keep reflections adjustable without
	# baking them into the hand-painted concrete texture.
	_add_puddle("SidewalkPuddleA", Vector3(-0.2, 0.052, -1.4), Vector2(2.0, 0.62), -8.0)
	_add_puddle("SidewalkPuddleB", Vector3(-4.55, 0.052, -0.78), Vector2(1.15, 0.42), 14.0)
	_add_puddle("AlleyPuddleA", Vector3(5.45, 0.064, -5.4), Vector2(1.25, 2.0), -12.0)
	_add_puddle("AlleyPuddleB", Vector3(6.25, 0.064, -8.25), Vector2(1.45, 1.05), 18.0)

	# A recessed-looking drainage channel and grate establish industrial scale
	# and give the alley runoff a believable destination.
	_add_block("AlleyDrainChannel", Vector3(5.95, 0.064, -6.65), Vector3(0.42, 0.018, 2.45), drain_material, false)
	for index in range(8):
		var grate_z := -7.65 + float(index) * 0.29
		_add_block("AlleyDrainBar%02d" % index, Vector3(5.95, 0.077, grate_z), Vector3(0.5, 0.025, 0.055), trim_material, false)
	_add_block("AlleySteamPipe", Vector3(4.32, 0.72, -8.4), Vector3(0.18, 1.3, 0.18), trim_material, false)
	_add_block("AlleySteamPipeCap", Vector3(4.32, 1.4, -8.4), Vector3(0.34, 0.12, 0.34), drain_material, false)


func _add_puddle(puddle_name: String, center: Vector3, size: Vector2, rotation_y_degrees: float) -> void:
	var puddle := MeshInstance3D.new()
	puddle.name = puddle_name
	puddle.position = center
	puddle.rotation_degrees.y = rotation_y_degrees
	var puddle_mesh := CylinderMesh.new()
	puddle_mesh.top_radius = 0.5
	puddle_mesh.bottom_radius = 0.5
	puddle_mesh.height = 0.012
	puddle_mesh.radial_segments = 24
	puddle_mesh.material = puddle_material
	puddle.mesh = puddle_mesh
	puddle.scale = Vector3(size.x, 1.0, size.y)
	architecture.add_child(puddle)


func _add_block(
	block_name: String,
	center: Vector3,
	size: Vector3,
	material: StandardMaterial3D,
	collidable: bool
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = block_name
	mesh_instance.position = center
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = material
	mesh_instance.mesh = box_mesh
	architecture.add_child(mesh_instance)

	if not collidable:
		return
	var body := StaticBody3D.new()
	body.name = block_name + "Body"
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	architecture.add_child(body)


func _add_collision_box(collision_name: String, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = collision_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	architecture.add_child(body)


func _material(
	material_name: String,
	color: Color,
	metallic: float,
	roughness: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = material_name
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _emissive_material(
	material_name: String,
	color: Color,
	emission_color: Color,
	emission_energy: float
) -> StandardMaterial3D:
	var material := _material(material_name, color, 0.35, 0.28)
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = emission_energy
	return material


func _snap_camera_to_character() -> void:
	var target := character.global_position
	camera_rig.global_position = Vector3(target.x, 0.0, target.z)


func _apply_pending_spawn() -> void:
	var spawn_id := String(get_tree().root.get_meta("steamtek_pending_spawn_id", ""))
	if get_tree().root.has_meta("steamtek_pending_spawn_id"):
		get_tree().root.remove_meta("steamtek_pending_spawn_id")
	if spawn_id.is_empty():
		return
	var spawn := find_child(spawn_id, true, false) as Marker3D
	if spawn == null:
		push_warning("Steamtek dimensional exterior spawn was not found: %s" % spawn_id)
		return
	character.global_position = spawn.global_position


func _on_interaction_focus_changed(prompt_text: String, _target: Node) -> void:
	interaction_prompt.visible = not prompt_text.is_empty() and not transition_in_progress
	interaction_prompt.text = "[ E ]  " + prompt_text


func _on_zone_transition_requested(target_scene_path: String, target_spawn_id: String) -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	character.set_player_controlled(false)
	interaction_prompt.visible = false
	get_tree().root.set_meta("steamtek_pending_spawn_id", target_spawn_id)
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.28)
	await tween.finished
	var error := get_tree().change_scene_to_file(target_scene_path)
	if error != OK:
		push_error("Steamtek dimensional exterior transition failed: %s" % target_scene_path)
		transition_in_progress = false
		character.set_player_controlled(true)
		fade_rect.color.a = 0.0


func _fade_from_black() -> void:
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.28)
