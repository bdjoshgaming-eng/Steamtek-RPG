extends SteamtekTransitionLevel3D

const TUTORIAL_STATE_META := "steamtek_opening_tutorial_state"
const BUILDING_OCCLUSION_MASK := 4
const OCCLUSION_SHADER_SOURCE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_back;
uniform vec4 body_color : source_color = vec4(0.18, 0.31, 0.40, 0.26);
uniform vec4 rim_color : source_color = vec4(0.10, 0.70, 0.82, 0.72);
uniform float rim_power = 2.6;
uniform float rim_strength = 0.78;
void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, rim_power) * rim_strength;
	ALBEDO = mix(body_color.rgb, rim_color.rgb, rim);
	ALPHA = mix(body_color.a, rim_color.a, rim);
}
"""

@onready var objective_label: Label = $TransitionUI/Objective
@onready var bonus_label: Label = $TransitionUI/BonusObjective
@onready var message_label: Label = $TransitionUI/Message
@onready var resources_label: Label = $TransitionUI/Resources
@onready var combat_label: Label = $TransitionUI/CombatStatus
@onready var skill_panel: Control = $TransitionUI/FirstSkillPanel
@onready var skill_status_label: Label = $TransitionUI/FirstSkillPanel/Status
@onready var lift_door: SteamtekZoneDoor3D = $MaintenanceLiftDoor
@onready var culdesac_reward_cache: Node = $TutorialInteractables/CuldesacRewardCache

var tutorial_state: Dictionary = {}
var player_health := 100
var enemy_attack_cooldown := 1.2
var message_serial := 0
var character_meshes: Array[MeshInstance3D] = []
var original_material_overlays: Dictionary = {}
var occlusion_material: ShaderMaterial
var character_is_occluded := false
var objective_waypoints: Dictionary = {}


func _ready() -> void:
	super._ready()
	$DistrictAssembly/ReviewLabels.visible = false
	tutorial_state = _load_state()
	if not bool(tutorial_state.get("note_found", false)):
		tutorial_state["note_found"] = true
		tutorial_state["quest_stage"] = 1
		tutorial_state["quest_title"] = "A Light in the Rain"
		tutorial_state["equipped_weapon"] = "Brass Knuckles"
		_save_state()
	_connect_tutorial_interactables()
	_connect_combat_targets()
	objective_waypoints = {
		"main_road": $ObjectiveWaypoints/MainStreet,
		"loot_alley": $ObjectiveWaypoints/CourtyardSalvage,
		"garage": $ObjectiveWaypoints/GarageWorkbench,
		"lantern": $ObjectiveWaypoints/LanternContact,
		"bonus_culdesac": $ObjectiveWaypoints/SideStreet,
		"lift": $ObjectiveWaypoints/MaintenanceLift,
	}
	_prepare_character_occlusion_overlay()
	_apply_state_to_scene()
	_update_hud()


func _process(delta: float) -> void:
	super._process(delta)
	_update_camera_occlusion()
	_update_enemy_attacks(delta)


func _unhandled_input(event: InputEvent) -> void:
	if transition_in_progress:
		return
	if skill_panel.visible:
		if event.is_action_pressed("skills_menu"):
			_set_skill_panel_open(false)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("slot_1"):
			_learn_first_skill()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("skills_menu") and bool(tutorial_state.get("first_skill_available", false)):
		_set_skill_panel_open(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("slot_1") and character.player_controlled:
		_attack_nearest_enemy()


func _load_state() -> Dictionary:
	var stored: Variant = get_tree().root.get_meta(TUTORIAL_STATE_META, {})
	if stored is Dictionary:
		return (stored as Dictionary).duplicate(true)
	return {}


func _save_state() -> void:
	get_tree().root.set_meta(TUTORIAL_STATE_META, tutorial_state.duplicate(true))


func _items() -> Dictionary:
	var value: Variant = tutorial_state.get("items")
	if tutorial_state.has("items") and value is Dictionary:
		return value as Dictionary
	var created: Dictionary = {}
	tutorial_state["items"] = created
	return created


func _connect_tutorial_interactables() -> void:
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_interactable_3d"):
		var interactable := node as Node
		if interactable != null and is_ancestor_of(interactable) and interactable.has_signal("tutorial_action_requested"):
			interactable.tutorial_action_requested.connect(_on_tutorial_action_requested)


func _connect_combat_targets() -> void:
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_enemy_3d"):
		var target := node as Node
		if target != null and is_ancestor_of(target) and target.has_signal("defeated"):
			target.defeated.connect(_on_combat_target_defeated)
			target.health_changed.connect(_on_combat_target_health_changed)


func _apply_state_to_scene() -> void:
	var defeated_targets: Dictionary = tutorial_state.get("defeated_targets", {})
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_enemy_3d"):
		var target := node as Node
		if target != null and is_ancestor_of(target):
			target.call("set_active", not bool(defeated_targets.get(target.name, false)))
	culdesac_reward_cache.set("interaction_enabled", bool(tutorial_state.get("bonus_culdesac_complete", false)))
	lift_door.interaction_enabled = (
		int(tutorial_state.get("quest_stage", 1)) >= 2
		and bool(tutorial_state.get("vendor_tutorial_complete", false))
	)


func _on_tutorial_action_requested(action_id: String, _actor: Node, _source: Node) -> void:
	match action_id:
		"loot_alley_container":
			_open_loot_alley_container()
		"culdesac_reward_cache":
			_open_culdesac_reward_cache()
		"garage_locked_bench":
			_inspect_locked_garage_bench()
	_update_hud()


func _open_loot_alley_container() -> void:
	if bool(tutorial_state.get("loot_alley_collected", false)):
		_show_message("The alley container is empty.")
		return
	var items := _items()
	items["Pistol Ammunition"] = int(items.get("Pistol Ammunition", 0)) + 12
	items["Black Iron"] = int(items.get("Black Iron", 0)) + 2
	tutorial_state["cogs"] = int(tutorial_state.get("cogs", 0)) + 8
	tutorial_state["loot_alley_collected"] = true
	tutorial_state["bonus_quest_active"] = true
	_save_state()
	_show_message("LOOT FOUND — 12 pistol rounds, 2 Black Iron, 8 Cogs.\nBONUS QUEST — Clear the nearby cul-de-sac.")


func _open_culdesac_reward_cache() -> void:
	if not bool(tutorial_state.get("bonus_culdesac_complete", false)):
		_show_message("Enemies still control this cache.")
		return
	if bool(tutorial_state.get("culdesac_reward_collected", false)):
		_show_message("The cul-de-sac cache is empty.")
		return
	var items := _items()
	items["Field Ration"] = int(items.get("Field Ration", 0)) + 1
	items["Water Flask"] = int(items.get("Water Flask", 0)) + 1
	tutorial_state["cogs"] = int(tutorial_state.get("cogs", 0)) + 12
	tutorial_state["culdesac_reward_collected"] = true
	_save_state()
	_show_message("BONUS LOOT — Field Ration, Water Flask, 12 Cogs.")


func _inspect_locked_garage_bench() -> void:
	tutorial_state["garage_inspected"] = true
	_save_state()
	_show_message("CRAFTING BENCH LOCKED — Requires an Undertown workbench calibration. Return after reaching the silo.")


func _attack_nearest_enemy() -> void:
	var nearest: Node
	var nearest_distance := 3.1
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_enemy_3d"):
		var target := node as Node
		if target == null or not is_ancestor_of(target) or not bool(target.call("is_alive")):
			continue
		var distance := character.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	if nearest == null:
		_show_message("No combat target in range.")
		return
	var weapon_name := String(tutorial_state.get("equipped_weapon", "Brass Knuckles"))
	var base_damage := 13 if weapon_name == "Service Pistol" else 9
	if bool(tutorial_state.get("first_skill_learned", false)):
		base_damage += 3
	var result: Dictionary = nearest.call("receive_player_attack", {
		"base_damage": base_damage,
		"damage_multiplier": 1.0,
		"conditioning_nodes": 0,
		"max_conditioning_nodes": 0,
		"profession_certified": true,
		"equipped_weapon_name": weapon_name,
		"professions_unlocked": {"Street Thug": true},
		"damage_type": "Kinetic",
		"armor_penetration": 0,
	})
	_show_message("%s hit %s for %d%s." % [
		weapon_name,
		String(nearest.get("display_name")),
		result["damage"],
		" CRITICAL" if bool(result["crit"]) else "",
	])


func _update_enemy_attacks(delta: float) -> void:
	if transition_in_progress or skill_panel.visible:
		return
	enemy_attack_cooldown -= delta
	if enemy_attack_cooldown > 0.0:
		return
	var attacker: Node
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_enemy_3d"):
		var target := node as Node3D
		if target != null and is_ancestor_of(target) and bool(target.call("is_alive")) and character.global_position.distance_to(target.global_position) <= 3.2:
			attacker = target
			break
	if attacker == null:
		enemy_attack_cooldown = 0.25
		return
	enemy_attack_cooldown = 1.6
	var damage := int(attacker.call("roll_enemy_attack"))
	player_health = maxi(0, player_health - damage)
	_show_message("%s strikes for %d damage." % [String(attacker.get("display_name")), damage])
	if player_health == 0:
		player_health = 100
		character.global_position = $SurfaceEntryWest.global_position
		character.velocity = Vector3.ZERO
		_snap_camera_to_character()
		_show_message("Tutorial recovery engaged. Return to the encounter when ready.")
	_update_hud()


func _on_combat_target_defeated(target: Node) -> void:
	var defeated_targets: Dictionary = tutorial_state.get("defeated_targets", {})
	defeated_targets[target.name] = true
	tutorial_state["defeated_targets"] = defeated_targets
	var encounter_id := String(target.get_meta("encounter_id", ""))
	if encounter_id == "bonus_culdesac" and _encounter_is_clear(encounter_id):
		tutorial_state["bonus_culdesac_complete"] = true
		tutorial_state["combat_xp"] = int(tutorial_state.get("combat_xp", 0)) + 5
		culdesac_reward_cache.set("interaction_enabled", true)
		_show_message("BONUS QUEST COMPLETE — Cul-de-sac cleared. Cache unlocked. +5 Combat XP")
	elif encounter_id == "main_road" and _encounter_is_clear(encounter_id):
		tutorial_state["main_combat_complete"] = true
		tutorial_state["first_skill_available"] = true
		tutorial_state["combat_xp"] = int(tutorial_state.get("combat_xp", 0)) + 10
		_show_message("MAIN ROAD CLEAR — +10 Combat XP. Press [J] to learn your first skill.")
	_save_state()
	_update_hud()


func _encounter_is_clear(encounter_id: String) -> bool:
	for node in get_tree().get_nodes_in_group("steamtek_tutorial_enemy_3d"):
		var target := node as Node
		if target != null and is_ancestor_of(target) and String(target.get_meta("encounter_id", "")) == encounter_id and bool(target.call("is_alive")):
			return false
	return true


func _on_combat_target_health_changed(_target: Node, _current: int, _maximum: int) -> void:
	_update_hud()


func _set_skill_panel_open(open: bool) -> void:
	skill_panel.visible = open
	character.set_player_controlled(not open)
	_update_skill_panel()


func _learn_first_skill() -> void:
	if bool(tutorial_state.get("first_skill_learned", false)):
		_show_message("Pressure Jab is already learned.")
		return
	if int(tutorial_state.get("combat_xp", 0)) < 10:
		_show_message("You need 10 Combat XP to learn Pressure Jab.")
		return
	tutorial_state["combat_xp"] = int(tutorial_state.get("combat_xp", 0)) - 10
	tutorial_state["first_skill_learned"] = true
	_save_state()
	_update_skill_panel()
	_update_hud()
	_show_message("SKILL LEARNED — Pressure Jab. Weapon attacks gain +3 tutorial damage.")


func _update_skill_panel() -> void:
	if not is_instance_valid(skill_status_label):
		return
	var learned := bool(tutorial_state.get("first_skill_learned", false))
	skill_status_label.text = (
		"COMBAT XP: %d\n\nPRESSURE JAB\nYour first close-combat technique.\nTutorial effect: +3 weapon damage.\n\n%s\n\n[J] Close skills"
		% [int(tutorial_state.get("combat_xp", 0)), "LEARNED" if learned else "[1] Spend 10 Combat XP to learn"]
	)


func _update_hud() -> void:
	var stage := int(tutorial_state.get("quest_stage", 1))
	if stage >= 2 and not bool(tutorial_state.get("vendor_tutorial_complete", false)):
		objective_label.text = "OBJECTIVE  •  Return to The Lantern and complete the bartender vendor lesson"
	elif stage >= 2:
		objective_label.text = "OBJECTIVE  •  Continue east and use the Maintenance Lift"
	elif not bool(tutorial_state.get("main_combat_complete", false)):
		objective_label.text = "OBJECTIVE  •  Walk east toward The Lantern  •  Explore side roads or confront the Main Road thugs"
	elif not bool(tutorial_state.get("first_skill_learned", false)):
		objective_label.text = "OBJECTIVE  •  Press [J] and spend Combat XP on your first skill"
	elif not bool(tutorial_state.get("garage_inspected", false)):
		objective_label.text = "OBJECTIVE  •  Inspect the Garage, then continue east to The Lantern"
	else:
		objective_label.text = "OBJECTIVE  •  Enter The Lantern and turn in A Light in the Rain"
	if bool(tutorial_state.get("bonus_quest_active", false)) and not bool(tutorial_state.get("bonus_culdesac_complete", false)):
		bonus_label.visible = true
		bonus_label.text = "BONUS  •  Clear the north cul-de-sac and loot its cache"
	elif bool(tutorial_state.get("bonus_culdesac_complete", false)) and not bool(tutorial_state.get("culdesac_reward_collected", false)):
		bonus_label.visible = true
		bonus_label.text = "BONUS COMPLETE  •  Collect the unlocked cul-de-sac cache"
	else:
		bonus_label.visible = false
	var items := _items()
	resources_label.text = "GEAR  •  %s  •  Ammo %d  •  Cogs %d  •  Combat XP %d" % [
		String(tutorial_state.get("equipped_weapon", "Brass Knuckles")),
		int(items.get("Pistol Ammunition", 0)),
		int(tutorial_state.get("cogs", 0)),
		int(tutorial_state.get("combat_xp", 0)),
	]
	combat_label.text = "HEALTH %d / 100  •  [1] Attack  •  [J] Skills" % player_health
	_refresh_objective_waypoint()


func _refresh_objective_waypoint() -> void:
	for waypoint in objective_waypoints.values():
		waypoint.call("set_active", false)
	var active_key := "main_road"
	var stage := int(tutorial_state.get("quest_stage", 1))
	if stage >= 2 and not bool(tutorial_state.get("vendor_tutorial_complete", false)):
		active_key = "lantern"
	elif stage >= 2:
		active_key = "lift"
	elif not bool(tutorial_state.get("main_combat_complete", false)):
		active_key = "main_road"
	elif not bool(tutorial_state.get("first_skill_learned", false)):
		active_key = "main_road"
	elif not bool(tutorial_state.get("garage_inspected", false)):
		active_key = "garage"
	else:
		active_key = "lantern"
	var active_waypoint: Node = objective_waypoints.get(active_key)
	if active_waypoint != null:
		active_waypoint.call("set_active", true)


func _show_message(text: String) -> void:
	message_serial += 1
	var serial := message_serial
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(3.6).timeout
	if serial == message_serial:
		message_label.visible = false


func _prepare_character_occlusion_overlay() -> void:
	_collect_character_meshes(character)
	if character_meshes.is_empty():
		return
	var shader := Shader.new()
	shader.code = OCCLUSION_SHADER_SOURCE
	occlusion_material = ShaderMaterial.new()
	occlusion_material.shader = shader
	occlusion_material.render_priority = 1


func _collect_character_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		character_meshes.append(mesh_instance)
		original_material_overlays[mesh_instance.get_instance_id()] = mesh_instance.material_overlay
	for child in node.get_children():
		_collect_character_meshes(child)


func _update_camera_occlusion() -> void:
	var query := PhysicsRayQueryParameters3D.create(
		camera.global_position,
		character.global_position + Vector3(0.0, 1.0, 0.0),
		BUILDING_OCCLUSION_MASK
	)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_set_character_occluded(not hit.is_empty())


func _set_character_occluded(is_occluded: bool) -> void:
	if character_is_occluded == is_occluded:
		return
	character_is_occluded = is_occluded
	for mesh_instance in character_meshes:
		if not is_instance_valid(mesh_instance):
			continue
		mesh_instance.material_overlay = occlusion_material if is_occluded else original_material_overlays.get(mesh_instance.get_instance_id()) as Material
