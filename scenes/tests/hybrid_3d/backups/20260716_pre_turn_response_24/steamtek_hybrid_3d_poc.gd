extends Node3D

## Steamtek hybrid 2.5D proof of concept.
## Live 3D character + locked orthographic camera + painted environment art in 3D.

const WALK_SPEED := 4.2
const MOVEMENT_ACCELERATION := 18.0
const MOVEMENT_DECELERATION := 24.0
const TURN_RESPONSE := 12.0
const GRAVITY := 18.0
const CAMERA_POSITION := Vector3(8.660254, 10.0, 15.0)
const CAMERA_SIZE := 18.0
const PAINTED_WALL_TEXTURE := "res://assets/modular_v2/apartment_exterior_v3/production/SMV3_FrontPlain.png"
const CHARACTER_SCENE := "res://assets/characters/npc/Steamtek_C002/production/STK_C002_RigProof_v1.glb"

var player: CharacterBody3D
var player_visual: Node3D
var camera: Camera3D
var character_animation_player: AnimationPlayer
var idle_animation := ""
var walk_animation := ""
var active_animation := ""
var diagnostics_label: Label
var force_stationary_walk := false


func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_lighting()
	_build_floor()
	_build_live_3d_occluders()
	_build_painted_environment_plane()
	_build_player()
	_build_interface()


func _physics_process(delta: float) -> void:
	if player == null or camera == null:
		return
	if Input.is_action_just_pressed("ui_accept"):
		force_stationary_walk = not force_stationary_walk

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	# A keyboard supplies eight target directions, while a controller stick can
	# supply any angle. Movement and facing are blended toward either target so
	# the live 3D character never visibly snaps between compass directions.
	var input_strength := clampf(input_vector.length(), 0.0, 1.0)
	var move_direction := camera_right * input_vector.x + camera_forward * -input_vector.y
	if force_stationary_walk:
		player.velocity.x = move_toward(player.velocity.x, 0.0, MOVEMENT_DECELERATION * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, MOVEMENT_DECELERATION * delta)
		_play_character_animation(walk_animation)
	elif move_direction.length_squared() > 0.001:
		move_direction = move_direction.normalized()
		var target_velocity := move_direction * WALK_SPEED * input_strength
		player.velocity.x = move_toward(
			player.velocity.x,
			target_velocity.x,
			MOVEMENT_ACCELERATION * delta
		)
		player.velocity.z = move_toward(
			player.velocity.z,
			target_velocity.z,
			MOVEMENT_ACCELERATION * delta
		)

		var target_yaw := atan2(move_direction.x, move_direction.z)
		var turn_weight := 1.0 - exp(-TURN_RESPONSE * delta)
		player_visual.rotation.y = lerp_angle(
			player_visual.rotation.y,
			target_yaw,
			turn_weight
		)
		_play_character_animation(walk_animation)
	else:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			MOVEMENT_DECELERATION * delta
		)
		player.velocity.z = move_toward(
			player.velocity.z,
			0.0,
			MOVEMENT_DECELERATION * delta
		)
		_play_character_animation(idle_animation)

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	else:
		player.velocity.y = -0.2

	player.move_and_slide()
	_update_animation_telemetry()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "NightEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("071018")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("31445b")
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "LockedIsoCamera_60Azimuth_30Elevation"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.position = CAMERA_POSITION
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true


func _build_lighting() -> void:
	var moon := DirectionalLight3D.new()
	moon.name = "MoonKey"
	moon.rotation_degrees = Vector3(-52.0, -25.0, 0.0)
	moon.light_color = Color("9cbce8")
	moon.light_energy = 1.35
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
	add_child(moon)

	_add_omni_light("CyanPractical", Vector3(-4.5, 2.5, -1.0), Color("16d9ff"), 7.0, 7.5)
	_add_omni_light("MagentaPractical", Vector3(4.2, 1.8, 1.0), Color("ff2aa8"), 5.0, 6.0)
	_add_omni_light("AmberPractical", Vector3(0.0, 3.0, -4.5), Color("ff9b38"), 4.0, 5.5)


func _add_omni_light(node_name: String, world_position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = world_position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = true
	add_child(light)


func _build_floor() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "WetIndustrialFloor3D"
	add_child(floor_root)

	var floor_material_a := _make_material(Color("141c26"), 0.72, 0.24)
	var floor_material_b := _make_material(Color("1b2633"), 0.78, 0.19)
	for z_index in range(-3, 4):
		for x_index in range(-3, 4):
			var tile := MeshInstance3D.new()
			tile.name = "Floor_%s_%s" % [x_index, z_index]
			var mesh := BoxMesh.new()
			mesh.size = Vector3(2.45, 0.12, 2.45)
			mesh.material = floor_material_a if (x_index + z_index) % 2 == 0 else floor_material_b
			tile.mesh = mesh
			tile.position = Vector3(x_index * 2.5, -0.06, z_index * 2.5)
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			floor_root.add_child(tile)

	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorCollision"
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(18.0, 0.2, 18.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	floor_root.add_child(floor_body)


func _build_live_3d_occluders() -> void:
	var structures := Node3D.new()
	structures.name = "Live3DDepthTest"
	add_child(structures)

	var wall_material := _make_material(Color("202630"), 0.58, 0.48)
	var trim_material := _make_material(Color("2f3742"), 0.88, 0.22)

	_add_box_with_collision(structures, "DepthWall", Vector3(4.8, 3.0, 0.45), Vector3(3.7, 1.5, -1.2), wall_material)
	_add_box_with_collision(structures, "DepthColumn", Vector3(0.72, 4.1, 0.72), Vector3(1.0, 2.05, 2.1), trim_material)
	_add_box_with_collision(structures, "RaisedMachine", Vector3(2.0, 1.7, 1.6), Vector3(-3.4, 0.85, 1.4), wall_material)


func _add_box_with_collision(parent: Node3D, node_name: String, size_value: Vector3, world_position: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = world_position
	parent.add_child(body)

	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh.material = material
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(visual)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)


func _build_painted_environment_plane() -> void:
	var texture := load(PAINTED_WALL_TEXTURE) as Texture2D
	if texture == null:
		push_warning("Painted wall texture is unavailable: %s" % PAINTED_WALL_TEXTURE)
		return

	var painted_wall := Sprite3D.new()
	painted_wall.name = "ExistingPaintedWall_On3DPlane"
	painted_wall.texture = texture
	painted_wall.pixel_size = 0.0052
	painted_wall.position = Vector3(-3.3, 1.9, -4.2)
	painted_wall.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	painted_wall.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	painted_wall.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	painted_wall.no_depth_test = false
	painted_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(painted_wall)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Live3DPlayer"
	player.position = Vector3(0.0, 0.03, 3.5)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.88
	player.add_child(collision)

	player_visual = Node3D.new()
	player_visual.name = "CharacterVisual_AnimatedRigProof"
	player.add_child(player_visual)

	var packed_character := load(CHARACTER_SCENE) as PackedScene
	if packed_character == null:
		push_error("Animated character scene is unavailable: %s" % CHARACTER_SCENE)
		return

	var character_instance := packed_character.instantiate()
	character_instance.name = "STK_C002_RigProof"
	player_visual.add_child(character_instance)
	character_animation_player = _find_animation_player(character_instance)
	if character_animation_player == null:
		push_error("No AnimationPlayer was imported from %s" % CHARACTER_SCENE)
		return

	idle_animation = _find_animation_name("STK_IDLE")
	walk_animation = _find_animation_name("STK_WALK")
	if idle_animation.is_empty() or walk_animation.is_empty():
		push_error("Required STK_IDLE/STK_WALK animations were not found. Imported: %s" % str(character_animation_player.get_animation_list()))
		return
	_configure_animation_loop(idle_animation)
	_configure_animation_loop(walk_animation)
	_print_imported_animation_report()
	_play_character_animation(idle_animation)


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_animation_name(required_suffix: String) -> String:
	if character_animation_player == null:
		return ""
	for animation_name in character_animation_player.get_animation_list():
		var candidate := String(animation_name)
		if candidate == required_suffix or candidate.ends_with("/" + required_suffix) or required_suffix in candidate:
			return candidate
	return ""


func _play_character_animation(animation_name: String) -> void:
	if character_animation_player == null or animation_name.is_empty() or active_animation == animation_name:
		return
	character_animation_player.play(animation_name, 0.16)
	character_animation_player.speed_scale = 1.0
	active_animation = animation_name


func _configure_animation_loop(animation_name: String) -> void:
	var animation := character_animation_player.get_animation(animation_name)
	if animation == null:
		return
	# Blender/glTF currently imports both clips with LOOP_NONE. The controller
	# intentionally does not restart an already-active clip, so a non-looping
	# walk freezes after its first second while world movement continues.
	animation.loop_mode = Animation.LOOP_LINEAR


func _print_imported_animation_report() -> void:
	for animation_name in [idle_animation, walk_animation]:
		var animation := character_animation_player.get_animation(animation_name)
		if animation == null:
			continue
		print(
			"STEAMTEK_ANIMATION name=%s length=%.3f tracks=%d loop=%d" % [
				animation_name,
				animation.length,
				animation.get_track_count(),
				animation.loop_mode,
			]
		)


func _update_animation_telemetry() -> void:
	if diagnostics_label == null or character_animation_player == null:
		return
	var current := character_animation_player.current_animation
	var animation := character_animation_player.get_animation(current)
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if animation == null:
		diagnostics_label.text = "ANIMATION TELEMETRY\nNo active imported animation"
		return
	diagnostics_label.text = (
		"ANIMATION TELEMETRY\n"
		+ "Clip: %s\n" % current
		+ "Position: %.3f / %.3f sec\n" % [character_animation_player.current_animation_position, animation.length]
		+ "Playback speed: %.2f | Tracks: %d | Loop mode: %d\n" % [character_animation_player.speed_scale, animation.get_track_count(), animation.loop_mode]
		+ "Horizontal speed: %.3f / %.3f\n" % [horizontal_speed, WALK_SPEED]
		+ "Stationary walk test: %s (SPACE to toggle)" % ["ON" if force_stationary_walk else "OFF"]
	)


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.25, 0.28)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Instructions"
	add_child(canvas)

	var panel := ColorRect.new()
	panel.position = Vector2(24, 24)
	panel.size = Vector2(620, 134)
	panel.color = Color(0.015, 0.025, 0.04, 0.88)
	canvas.add_child(panel)

	var label := Label.new()
	label.position = Vector2(42, 38)
	label.text = "STEAMTEK - LIVE 3D HYBRID PROOF\nWASD: move the animated 3D rig\nLocked camera: 60 deg azimuth / 30 deg elevation / orthographic\nTest: walk in front of and behind the wall art and 3D structures"
	label.add_theme_color_override("font_color", Color("d7e9ff"))
	label.add_theme_font_size_override("font_size", 19)
	canvas.add_child(label)

	var badge := Label.new()
	badge.position = Vector2(24, 174)
	badge.text = "CYAN + MAGENTA: runtime lights | painted wall: existing Steamtek PNG | character: animated 3D rig proof"
	badge.add_theme_color_override("font_color", Color("50e8ff"))
	badge.add_theme_font_size_override("font_size", 16)
	canvas.add_child(badge)

	var diagnostics_panel := ColorRect.new()
	diagnostics_panel.position = Vector2(24, 214)
	diagnostics_panel.size = Vector2(620, 148)
	diagnostics_panel.color = Color(0.015, 0.025, 0.04, 0.90)
	canvas.add_child(diagnostics_panel)

	diagnostics_label = Label.new()
	diagnostics_label.position = Vector2(42, 228)
	diagnostics_label.text = "ANIMATION TELEMETRY\nWaiting for imported animation data..."
	diagnostics_label.add_theme_color_override("font_color", Color("f4d58a"))
	diagnostics_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(diagnostics_label)
