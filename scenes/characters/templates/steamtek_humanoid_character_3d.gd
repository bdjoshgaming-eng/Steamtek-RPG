class_name SteamtekHumanoidCharacter3D
extends CharacterBody3D

signal interaction_focus_changed(prompt_text: String, target: Node)
signal interaction_performed(target: Node)
signal attack_performed(target: Node, result: Dictionary)

## Reusable Steamtek humanoid wrapper for the fixed-camera 2.5D pipeline.
## Character art is supplied as an imported GLB; collision, movement, facing,
## interaction anchors, and animation selection remain shared infrastructure.

@export var character_scene: PackedScene
@export var character_instance_name := "SteamtekHumanoidVisual"
@export var player_controlled := true
@export var walk_speed := 4.2
@export var run_speed := 6.4
@export var movement_acceleration := 18.0
@export var movement_deceleration := 24.0
@export var stop_immediately := true
@export var turn_response := 36.0
@export var turn_snap_threshold_degrees := 0.75
@export var locomotion_blend_seconds := 0.1
@export var gravity_strength := 18.0
@export var step_height := 0.25
@export var model_forward_yaw_offset_degrees := 40.0
@export var idle_animation_key := "STK_IDLE"
@export var walk_animation_key := "STK_WALK"
@export var run_animation_key := "STK_RUN"
@export var interaction_action := "interact"
@export var attack_action := "primary_fire"
@export var default_attack_range := 14.0

const COMBAT_TARGET_COLLISION_MASK := 16
const ENEMY_GROUP := "steamtek_tutorial_enemy_3d"
const GROUND_TELEGRAPH_SCENE := preload("res://scenes/effects/live3d/SteamtekGroundTelegraph3D.tscn")
const GRENADE_PROJECTILE_SCENE := preload("res://scenes/effects/live3d/SteamtekGrenadeProjectile3D.tscn")
const CONE_TELEGRAPH_SCENE := preload("res://scenes/effects/live3d/SteamtekConeTelegraph3D.tscn")
const GRENADE_EXPLOSION_SCENE := preload("res://scenes/effects/live3d/SteamtekGrenadeExplosion3D.tscn")
const PLAYER_CHAT_BUBBLE_SCENE := preload("res://scenes/gameplay/live3d/SteamtekPlayerChatBubble3D.tscn")
const CHAT_BUBBLE_HEIGHT := 2.0

# Grenade Launcher "bounce" tuning: real ballistic simulation (Junkrat-
# style frag grenade), not fixed hop distances. The reticle position is
# the LAUNCH TARGET, not necessarily the detonation point -- launch
# velocity is solved from throw distance/height via the standard height-
# adjusted projectile range equation, then steamtek_grenade_projectile_
# 3d.gd integrates gravity + bounce restitution/friction frame by frame.
#
# DAMAGE IS A DIRECT HIT, NOT A SPLASH CHECK. Splash radius (GameData.
# WEAPON_SPLASH_RADIUS) is reserved for actual blast weapons (Rocket
# Launcher/Arc Cannon, once they exist) that detonate instantly at the
# reticle with no bounce. A thrown grenade instead checks, every physics
# frame of its ENTIRE flight (arc + bounce), whether it has come within
# GRENADE_CONTACT_RADIUS of a live enemy, and detonates the instant it
# does. Checking only the final settled position (the original design)
# meant a chasing enemy that moved during the ~0.5-1.5s flight, or plain
# aim imprecision, made most throws miss even when they looked close --
# continuous contact detection is what actually fixes that.
#
# Because of that, bounce/friction no longer need to be kept tight to
# protect hit reliability (an earlier tuning pass shrank them for
# exactly that reason, before contact detection existed) -- they're free
# to bounce and skid generously now for the Junkrat feel, since nothing
# about where it ends up affects whether it already hit something.
#
# Flat + fast on purpose: a low launch angle keeps the arc from ballooning
# into a mortar lob at range (was 50 deg, way too high from a distance),
# and a low angle also means more of the launch speed goes into forward
# velocity, so it reaches the target faster (was reading as slow at 50
# deg).
const GRENADE_THROW_HEIGHT := 1.0
# Lowering gravity alone (with launch velocity re-solved from it) slows
# the whole flight down in TIME while leaving the spatial trajectory --
# angle, apex height, bounce distance -- exactly unchanged, since v0
# scales with sqrt(gravity) and the path shape depends only on
# gravity/v0^2, which stays constant. Slowed again here (was 7.5) --
# reference: Junkrat's frag grenade is explicitly slow-flying as its
# whole balance tradeoff, and burst-firing 3 at once made the existing
# speed read as faster still.
const GRENADE_GRAVITY := 5.5
const GRENADE_LAUNCH_ANGLE_DEGREES := 20.0
const GRENADE_BOUNCE_RESTITUTION := 0.45
const GRENADE_BOUNCE_FRICTION := 0.55
const GRENADE_MAX_BOUNCES := 3
const GRENADE_SETTLE_SPEED := 0.6
const GRENADE_MAX_FLIGHT_TIME := 2.5
# How close the flight path has to pass to a live enemy to count as a
# direct hit. Independent of the ground-target ring's visual size
# (GameData.splash_radius_for_class, still used for the reticle) -- this
# is a gameplay-feel tolerance, not a cosmetic one.
const GRENADE_CONTACT_RADIUS := 0.5

# Durability wear per shot (Phase 8). Only applies to weapons that have
# a crafted instance (see _get_weapon_crafted_item) -- a plain starter
# weapon has no durability to track and never breaks. Flame ticks fire
# many times a second so their per-tick cost is much smaller than a
# single hitscan/grenade shot. Placeholder tuning, needs a balance pass.
const DURABILITY_DRAIN_PER_SHOT := 2.0
const DURABILITY_DRAIN_PER_FLAME_TICK := 0.3

# Flame Thrower is hold-to-channel, not click-confirm: damage ticks
# repeatedly while primary_fire is held, draining a heat resource that
# forces the weapon to stop and lock out briefly if it hits max. Heat
# gain is intentionally slow -- sustained fire is meant to be the
# cheapest resource drain in the kit, not a fast burst-then-lockout
# weapon. At 8/sec it takes ~12.5s of continuous fire to overheat.
# Tick damage is a fraction of the weapon's Damage Rating stat since it
# fires many times a second instead of once -- placeholder ratio, needs
# a balance pass.
const FLAME_TICK_INTERVAL := 0.15
const FLAME_TICK_DAMAGE_FRACTION := 0.4
const FLAME_MAX_HEAT := 100.0
const FLAME_HEAT_PER_SECOND := 8.0
const FLAME_HEAT_REGEN_PER_SECOND := 12.0
const FLAME_OVERHEAT_LOCKOUT_SECONDS := 1.5

@onready var visual_pivot: Node3D = $VisualPivot
@onready var camera_target: Marker3D = $CameraTarget
@onready var interaction_origin: Marker3D = $VisualPivot/InteractionOrigin
@onready var interaction_detector: Area3D = $VisualPivot/InteractionDetector
@onready var ground_contact: Marker3D = $GroundContact

var character_instance: Node3D
var chat_bubble: SteamtekPlayerChatBubble3D
var animation_player: AnimationPlayer
var idle_animation := ""
var walk_animation := ""
var run_animation := ""
var active_animation := ""
var target_facing_yaw := 0.0
var focused_interactable: Area3D
var focused_prompt_text := ""

var combat_blocked := false
var combat_state: Dictionary = {}
var inventory: Dictionary = {}
var _combat_save_callback: Callable

var _ground_target_active := false
var _ground_target_telegraph: Node3D
var _ground_target_weapon_name := ""
var _ground_target_weapon_class := ""
var _ground_target_max_range := 0.0
var _ground_target_splash_radius := 0.0

var _flame_channel_active := false
var _flame_channel_telegraph: Node3D
var _flame_channel_weapon_name := ""
var _flame_channel_length := 0.0
var _flame_channel_angle_degrees := 0.0
var _flame_tick_timer := 0.0
var _flame_overheat_lockout_timer := 0.0

# --- DoT / CC status effects, mitigated by the player's Grit total
# (Combat.gd's grit_dot_reduction()/grit_cc_duration_mult(), previously
# unconsumed). Applied by enemy abilities via apply_dot_effect() /
# apply_cc_slow() below.
var _dot_ticks_remaining := 0
var _dot_damage_per_tick := 0.0
var _dot_tick_interval := 1.0
var _dot_tick_timer := 0.0
var _cc_slow_timer := 0.0
var _cc_slow_speed_multiplier := 1.0

# Weapon Speed applied as an actual attack cooldown -- previously purely
# decorative (only shown in the inventory Details panel's DPS line).
# Speed is "seconds between shots" (lower = faster), same convention
# that DPS calc already assumed. Covers hitscan tap-fire, Charged Shot
# (both starting a charge and the shot it releases), and ground_target
# confirm (grenade throw / future blast weapons) -- everything EXCEPT
# Flame Thrower, whose tick rate is its own already-tuned system
# (FLAME_TICK_INTERVAL) and Buttstroke/Dodge Roll, which are fixed-
# cooldown abilities unrelated to the equipped weapon.
const MIN_ATTACK_COOLDOWN := 0.1
var _attack_cooldown_timer := 0.0

# Magazine / reload: Ammo Capacity and Reload Speed were also previously
# decorative (never read by anything). current_ammo is tracked per
# weapon name, session-local (not persisted, matching the project's no-
# save rule) and refilled to the effective magazine size the first time
# that weapon is fired or after a reload finishes. Applies to every
# weapon that fires through attempt_attack/_fire_hitscan/
# _confirm_ground_target (hitscan + ground_target) -- excludes Flame
# Thrower, whose heat system already plays this role.
var _weapon_ammo: Dictionary = {}
var _reloading_weapon_name := ""
var _reload_timer := 0.0

# Charged Shot: hold-to-charge on aim_hitscan weapons only (Grenade
# Launcher/Flame Thrower already have their own dedicated hold
# mechanics). Tap-release fires at the ability's base multiplier;
# holding past the partial/full thresholds (GameData.ability_definitions
# ["Charged Shot"]) steps the multiplier up. A full charge also burns an
# extra round of ammo -- its "cost" is a weapon resource now, not Action.
const CHARGED_SHOT_FULL_AMMO_COST := 2
var _charging_shot := false
var _charge_weapon_name := ""
var _charge_timer := 0.0

# Buttstroke: universal melee "get off me" disengage, always available
# regardless of equipped weapon. Numbers match the archived 2D design
# (commit 31122e5) exactly -- deliberately weak damage, it's a stagger +
# knockback tool, not a DPS option.
const BUTTSTROKE_ACTION := "buttstroke"
const BUTTSTROKE_COOLDOWN := 4.0
const BUTTSTROKE_STUN_DURATION := 1.5
const BUTTSTROKE_KNOCKBACK_DISTANCE := 1.0
const BUTTSTROKE_RANGE := 1.2
const BUTTSTROKE_DAMAGE := 5
var _buttstroke_cooldown_timer := 0.0

# Dodge Roll: active defensive burst (replaces the old passive per-hit
# Dodge stat). Speed/duration/cooldown match the archived 2D design
# (commit 31122e5) 1:1 on time, with DODGE_SPEED retuned from 2D pixels
# to 3D meters/sec. Pure movement + i-frames -- no animation dependency,
# so this works before a dedicated dodge animation exists; a later
# animation just needs to play alongside the existing velocity override.
const DODGE_ROLL_ACTION := "dodge_roll"
const DODGE_SPEED := 11.0
const DODGE_DURATION := 0.3
const DODGE_COOLDOWN := 2.0
# Action is the stamina pool now -- sprinting and dodging draw from it,
# weapon/ability resources are ammo/heat/durability instead (see
# _fire_hitscan/_confirm_ground_target, which no longer call
# spend_action at all). Placeholder tuning against the existing 850-ish
# max_action pool; needs a balance pass once it's actually played.
const DODGE_STAMINA_COST := 150.0
const SPRINT_STAMINA_DRAIN_PER_SECOND := 100.0
var is_invulnerable := false
var _dodge_timer := 0.0
var _dodge_cooldown_timer := 0.0
var _dodge_direction := Vector3.ZERO


func _ready() -> void:
	_instantiate_character()
	chat_bubble = PLAYER_CHAT_BUBBLE_SCENE.instantiate()
	chat_bubble.position = Vector3(0, CHAT_BUBBLE_HEIGHT, 0)
	add_child(chat_bubble)


# Shows a single brief line in the player's head bubble as SPEECH
# (pointed tail) -- talking to another character. Distinct from quest
# item text, which stays in the modal SteamtekDialogueBox.
func say(text: String) -> void:
	if is_instance_valid(chat_bubble):
		chat_bubble.say(text)


# Shows a sequence of speech lines, one at a time -- each advances on
# the interact key, not a timer.
func say_sequence(lines: Array) -> void:
	if is_instance_valid(chat_bubble):
		chat_bubble.say_sequence(lines)


# Shows a single brief line in the player's head bubble as an INNER
# THOUGHT (trailing dots, no tail) -- the player reacting/thinking to
# themselves, not talking to anyone.
func think(text: String) -> void:
	if is_instance_valid(chat_bubble):
		chat_bubble.think(text)


# Shows a sequence of thought lines, one at a time -- each advances on
# the interact key, not a timer.
func think_sequence(lines: Array) -> void:
	if is_instance_valid(chat_bubble):
		chat_bubble.think_sequence(lines)


func _exit_tree() -> void:
	_cancel_ground_target()
	_stop_flame_channel()


func _physics_process(delta: float) -> void:
	_regen_combat_state(delta)
	_process_status_effects(delta)
	_process_weapon_reload(delta)
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)
	if not player_controlled:
		return
	_refresh_interaction_focus()
	if InputMap.has_action(interaction_action) and Input.is_action_just_pressed(interaction_action):
		attempt_interaction()
	if _ground_target_active and (combat_blocked or not is_alive()):
		_cancel_ground_target()
	if _ground_target_active:
		_update_ground_target_telegraph()
		if Input.is_action_just_pressed("ui_cancel"):
			_cancel_ground_target()
	var equipped_targeting_mode := GameData.targeting_mode_for_class(_current_weapon_class())
	if equipped_targeting_mode == "cone":
		_process_flame_channel(delta)
	elif _flame_channel_active:
		_stop_flame_channel()
	if equipped_targeting_mode == "aim_hitscan":
		_process_charged_shot(delta)
	elif _charging_shot:
		_cancel_charged_shot()
	if (
		not combat_blocked
		and equipped_targeting_mode == "ground_target"
		and InputMap.has_action(attack_action)
		and Input.is_action_just_pressed(attack_action)
	):
		if _ground_target_active:
			_confirm_ground_target()
		else:
			attempt_attack()
	if _buttstroke_cooldown_timer > 0.0:
		_buttstroke_cooldown_timer = maxf(0.0, _buttstroke_cooldown_timer - delta)
	if (
		not combat_blocked
		and InputMap.has_action(BUTTSTROKE_ACTION)
		and Input.is_action_just_pressed(BUTTSTROKE_ACTION)
	):
		_perform_buttstroke()
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := _camera_relative_direction(input_vector)
	if _dodge_cooldown_timer > 0.0:
		_dodge_cooldown_timer = maxf(0.0, _dodge_cooldown_timer - delta)
	if (
		not combat_blocked
		and is_alive()
		and _dodge_timer <= 0.0
		and _dodge_cooldown_timer <= 0.0
		and get_action() >= DODGE_STAMINA_COST
		and InputMap.has_action(DODGE_ROLL_ACTION)
		and Input.is_action_just_pressed(DODGE_ROLL_ACTION)
	):
		_dodge_direction = (
			move_direction.normalized()
			if move_direction.length_squared() > 0.001
			else _camera_relative_direction(Vector2(0, 1))
		)
		_dodge_timer = DODGE_DURATION
		_dodge_cooldown_timer = DODGE_COOLDOWN
		is_invulnerable = true
		spend_action(int(DODGE_STAMINA_COST))
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		velocity.x = _dodge_direction.x * DODGE_SPEED
		velocity.z = _dodge_direction.z * DODGE_SPEED
		if _dodge_timer <= 0.0:
			is_invulnerable = false
	elif move_direction.length_squared() > 0.001:
		move_direction = move_direction.normalized()
		var wants_to_run := Input.is_key_pressed(KEY_SHIFT) and get_action() > 0.0
		if wants_to_run:
			combat_state["current_action"] = maxf(
				0.0, float(combat_state.get("current_action", 0)) - SPRINT_STAMINA_DRAIN_PER_SECOND * delta
			)
		var movement_speed := run_speed if wants_to_run else walk_speed
		if _cc_slow_timer > 0.0:
			movement_speed *= _cc_slow_speed_multiplier
		var target_velocity := move_direction * movement_speed * clampf(input_vector.length(), 0.0, 1.0)
		velocity.x = move_toward(velocity.x, target_velocity.x, movement_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, movement_acceleration * delta)
		# Movement is authored in world space. Convert its world-facing yaw into
		# VisualPivot-local space so an accidental rotation on the character root
		# cannot make the model strafe sideways relative to its velocity.
		var target_world_facing_yaw := (
			atan2(move_direction.x, move_direction.z)
			+ deg_to_rad(model_forward_yaw_offset_degrees)
		)
		target_facing_yaw = _world_yaw_to_visual_local_yaw(target_world_facing_yaw)
		var turn_weight := 1.0 - exp(-turn_response * delta)
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_facing_yaw, turn_weight)
		if absf(angle_difference(visual_pivot.rotation.y, target_facing_yaw)) <= deg_to_rad(turn_snap_threshold_degrees):
			visual_pivot.rotation.y = target_facing_yaw
		_play_animation(run_animation if wants_to_run else walk_animation)
	else:
		if stop_immediately:
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, movement_deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, movement_deceleration * delta)
		_play_animation(idle_animation)

	var was_on_floor := is_on_floor()
	if not was_on_floor:
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = -0.2
	var saved_velocity := velocity
	move_and_slide()
	if is_on_wall() and was_on_floor:
		_try_step_up(saved_velocity, delta)


func _try_step_up(saved_velocity: Vector3, _delta: float) -> void:
	var h_vel := Vector3(saved_velocity.x, 0, saved_velocity.z)
	if h_vel.length_squared() < 0.01:
		return
	var step_up_xform := global_transform
	step_up_xform.origin.y += step_height
	if test_move(step_up_xform, h_vel.normalized() * 0.15):
		return
	var forward_xform := step_up_xform
	forward_xform.origin += h_vel.normalized() * 0.15
	if not test_move(forward_xform, Vector3(0, -step_height * 1.5, 0)):
		return
	global_position.y += step_height
	velocity = Vector3(h_vel.x, -0.2, h_vel.z)


func set_player_controlled(enabled: bool) -> void:
	player_controlled = enabled
	if not enabled:
		velocity = Vector3.ZERO
		_play_animation(idle_animation)


func play_idle() -> void:
	_play_animation(idle_animation)


func play_walk() -> void:
	_play_animation(walk_animation)


func play_run() -> void:
	_play_animation(run_animation)


func get_character_animation_player() -> AnimationPlayer:
	return animation_player


func attempt_interaction() -> bool:
	_refresh_interaction_focus()
	if focused_interactable == null or not is_instance_valid(focused_interactable):
		return false
	if not focused_interactable.has_method("interact"):
		return false
	focused_interactable.call("interact", self)
	interaction_performed.emit(focused_interactable)
	_refresh_interaction_focus()
	return true


func get_interaction_prompt() -> String:
	return focused_prompt_text


func get_focused_interactable() -> Area3D:
	return focused_interactable


func set_combat_state(state: Dictionary, save_fn: Callable) -> void:
	combat_state = state
	_combat_save_callback = save_fn


func set_inventory(inv: Dictionary) -> void:
	inventory = inv


func is_alive() -> bool:
	return not combat_state.is_empty() and int(combat_state.get("current_health", 1)) > 0


func get_health() -> int:
	return int(combat_state.get("current_health", 0))


func get_max_health() -> int:
	return int(combat_state.get("max_health", 1))


func get_action() -> int:
	return int(combat_state.get("current_action", 0))


func get_max_action() -> int:
	return int(combat_state.get("max_action", 1))


func apply_damage(amount: int) -> void:
	if combat_state.is_empty() or not is_alive() or is_invulnerable:
		return
	combat_state["current_health"] = maxf(0.0, float(combat_state.get("current_health", 0)) - amount)
	save_combat_state()


func spend_action(amount: int) -> bool:
	if combat_state.is_empty() or float(combat_state.get("current_action", 0)) < amount:
		return false
	combat_state["current_action"] = float(combat_state["current_action"]) - amount
	save_combat_state()
	return true


# Applies a damage-over-time effect, softened by the player's Grit total
# (Combat.grit_dot_reduction). raw_total_damage is the UNMITIGATED total
# across the whole duration; Grit reduces that total before it's split
# into ticks. A new call replaces whatever DoT was already running
# rather than stacking.
func apply_dot_effect(raw_total_damage: float, duration: float, tick_interval: float = 1.0) -> void:
	if not is_alive() or is_invulnerable or raw_total_damage <= 0.0 or duration <= 0.0:
		return
	var combat_runtime := get_node_or_null("/root/Combat")
	var reduction := 0.0
	if combat_runtime != null:
		reduction = float(combat_runtime.call("grit_dot_reduction", GameData.total_purchased_stat("Grit")))
	var mitigated_total := raw_total_damage * (1.0 - reduction)
	var tick_count := maxi(1, int(round(duration / tick_interval)))
	_dot_damage_per_tick = mitigated_total / float(tick_count)
	_dot_ticks_remaining = tick_count
	_dot_tick_interval = tick_interval
	_dot_tick_timer = tick_interval


# Applies a movement-slow CC effect, shortened by the player's Grit total
# (Combat.grit_cc_duration_mult). speed_multiplier applies on top of
# whatever speed movement would otherwise use (e.g. 0.5 = half speed).
# A new call refreshes to the longer of the current/new remaining
# duration rather than stacking multipliers.
func apply_cc_slow(raw_duration: float, speed_multiplier: float) -> void:
	if not is_alive() or is_invulnerable or raw_duration <= 0.0:
		return
	var combat_runtime := get_node_or_null("/root/Combat")
	var duration_mult := 1.0
	if combat_runtime != null:
		duration_mult = float(combat_runtime.call("grit_cc_duration_mult", GameData.total_purchased_stat("Grit")))
	var mitigated_duration := raw_duration * duration_mult
	_cc_slow_timer = maxf(_cc_slow_timer, mitigated_duration)
	_cc_slow_speed_multiplier = speed_multiplier


func _process_status_effects(delta: float) -> void:
	if _cc_slow_timer > 0.0:
		_cc_slow_timer = maxf(0.0, _cc_slow_timer - delta)
		if _cc_slow_timer <= 0.0:
			_cc_slow_speed_multiplier = 1.0
	if _dot_ticks_remaining <= 0:
		return
	_dot_tick_timer -= delta
	if _dot_tick_timer > 0.0:
		return
	_dot_tick_timer = _dot_tick_interval
	_dot_ticks_remaining -= 1
	apply_damage(int(round(_dot_damage_per_tick)))


func attempt_attack() -> bool:
	if combat_blocked or not is_alive() or _attack_cooldown_timer > 0.0:
		return false
	var weapon_name := String(inventory.get("equipped_weapon", ""))
	if weapon_name.is_empty() or _is_weapon_broken(weapon_name):
		return false
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	if _is_weapon_reloading(weapon_name):
		return false
	if _get_weapon_ammo(weapon_name, weapon_def) <= 0:
		_start_weapon_reload(weapon_name, weapon_def)
		return false
	var weapon_class := String(weapon_def.get("item_class", ""))
	if GameData.targeting_mode_for_class(weapon_class) == "ground_target":
		_begin_ground_target(weapon_name, weapon_def)
		return true
	return _fire_hitscan(weapon_name, weapon_def)


func _current_weapon_class() -> String:
	var weapon_name := String(inventory.get("equipped_weapon", ""))
	if weapon_name.is_empty():
		return ""
	return String(GameData.ITEM_DEFINITIONS.get(weapon_name, {}).get("item_class", ""))


# Resolves a weapon's crafted instance dict, if the player owns one.
# Most weapons never get a crafted instance (it's created lazily, only
# when a mod is first installed via the inventory UI) -- in that case
# this returns {}, and every combat helper below treats that as "no
# durability to track, no mods installed, always usable."
func _get_weapon_crafted_item(weapon_name: String) -> Dictionary:
	var crafted_weapon_instances: Dictionary = inventory.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	if weapon_instance_id.is_empty():
		return {}
	var crafted_items: Dictionary = inventory.get("crafted_items", {})
	return crafted_items.get(weapon_instance_id, {})


# Resolves the installed mod INSTANCE dicts (not ids) for a weapon name.
func _get_installed_mods_for_weapon(weapon_name: String) -> Array:
	var item := _get_weapon_crafted_item(weapon_name)
	if item.is_empty():
		return []
	var mod_instances: Dictionary = inventory.get("mod_instances", {})
	var installed_mods: Array = []
	for mod_instance_id in item.get("installed_mod_instance_ids", []):
		var mod: Dictionary = mod_instances.get(String(mod_instance_id), {})
		if not mod.is_empty():
			installed_mods.append(mod)
	return installed_mods


# Durability wear from firing: a weapon with no crafted instance (the
# common case) has no durability to track and this is a no-op. Amount is
# scaled by mod_instability_total so a heavily-modded weapon wears out
# faster (Phase 6's mod instability_cost, previously unconsumed).
func _drain_weapon_durability(weapon_name: String, base_amount: float) -> void:
	var item := _get_weapon_crafted_item(weapon_name)
	if item.is_empty():
		return
	var instability := CraftingService.mod_instability_total(_get_installed_mods_for_weapon(weapon_name))
	CraftingService.drain_durability(item, base_amount * (1.0 + instability))


# A weapon with no crafted instance can never be broken (nothing is
# tracking its durability). One with an instance stops firing at 0
# durability until repaired/rebuilt via the inventory UI.
func _is_weapon_broken(weapon_name: String) -> bool:
	var item := _get_weapon_crafted_item(weapon_name)
	if item.is_empty():
		return false
	return CraftingService.is_broken(item)


# THE hook point every combat stat read goes through: base stats (same
# [0]-of-range convention as before) combined with any installed mods'
# deltas, via CraftingService.compute_final_weapon_stats(). An un-modded
# weapon (the common case today) gets back exactly the same numbers the
# old direct [0] reads produced -- this is additive, not a behavior
# change for anything that hasn't had a mod installed.
func _get_effective_weapon_stats(weapon_name: String, weapon_def: Dictionary) -> Dictionary:
	var base_stat_ranges: Dictionary = weapon_def.get("weapon_stat_ranges", {})
	var installed_mods := _get_installed_mods_for_weapon(weapon_name)
	return CraftingService.compute_final_weapon_stats(base_stat_ranges, installed_mods)


# Damage type for attack_parameters: the installed Core mod's type if
# one exists, else Kinetic (the game-wide default -- see Combat.gd's
# apply_typed_mitigation, which already defaults to "Kinetic" too).
func _get_weapon_damage_type(weapon_name: String) -> String:
	return CraftingService.resolve_damage_type(_get_installed_mods_for_weapon(weapon_name))


# Effective Speed stat as an attack cooldown in seconds, clamped to a
# sane minimum so a heavily speed-buffed weapon can't collapse toward
# an infinite fire rate.
func _get_weapon_attack_cooldown(weapon_name: String, weapon_def: Dictionary) -> float:
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	return maxf(MIN_ATTACK_COOLDOWN, float(effective_stats.get("Speed", 1.0)))


func _get_weapon_magazine_size(weapon_name: String, weapon_def: Dictionary) -> int:
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	return maxi(1, int(round(float(effective_stats.get("Ammo Capacity", 6.0)))))


func _get_weapon_reload_time(weapon_name: String, weapon_def: Dictionary) -> float:
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	return maxf(0.3, float(effective_stats.get("Reload Speed", 1.5)))


func _is_weapon_reloading(weapon_name: String) -> bool:
	return _reloading_weapon_name == weapon_name


# Non-mutating peek at current ammo, clamped to the (possibly mod-
# changed) magazine size so a mod that shrinks capacity mid-session
# can't leave a stale over-full count around.
func _get_weapon_ammo(weapon_name: String, weapon_def: Dictionary) -> int:
	var magazine_size := _get_weapon_magazine_size(weapon_name, weapon_def)
	return mini(int(_weapon_ammo.get(weapon_name, magazine_size)), magazine_size)


func _start_weapon_reload(weapon_name: String, weapon_def: Dictionary) -> void:
	_reloading_weapon_name = weapon_name
	_reload_timer = _get_weapon_reload_time(weapon_name, weapon_def)


func _process_weapon_reload(delta: float) -> void:
	if _reloading_weapon_name.is_empty():
		return
	_reload_timer -= delta
	if _reload_timer > 0.0:
		return
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(_reloading_weapon_name, {})
	_weapon_ammo[_reloading_weapon_name] = _get_weapon_magazine_size(_reloading_weapon_name, weapon_def)
	_reloading_weapon_name = ""


func _fire_hitscan(
	weapon_name: String,
	weapon_def: Dictionary,
	ammo_cost: int = 1,
	damage_multiplier: float = 1.0
) -> bool:
	if _is_weapon_reloading(weapon_name):
		return false
	var current_ammo := _get_weapon_ammo(weapon_name, weapon_def)
	if current_ammo < ammo_cost:
		_start_weapon_reload(weapon_name, weapon_def)
		return false
	_weapon_ammo[weapon_name] = current_ammo - ammo_cost
	_drain_weapon_durability(weapon_name, DURABILITY_DRAIN_PER_SHOT)
	_attack_cooldown_timer = _get_weapon_attack_cooldown(weapon_name, weapon_def)
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	var target := _aim_fire_target(float(effective_stats.get("Range", default_attack_range)))
	if target == null:
		return false
	var attack_parameters := {
		"base_damage": float(effective_stats.get("Damage Rating", 5.0)),
		"damage_multiplier": damage_multiplier,
		"conditioning_nodes": 0,
		"max_conditioning_nodes": 0,
		"equipped_weapon_name": weapon_name,
		"damage_type": _get_weapon_damage_type(weapon_name),
		"professions_unlocked": {},
	}
	var result: Dictionary = target.call("receive_player_attack", attack_parameters)
	attack_performed.emit(target, result)
	return true


func _process_charged_shot(delta: float) -> void:
	if combat_blocked or not is_alive():
		if _charging_shot:
			_cancel_charged_shot()
		return
	var weapon_name := String(inventory.get("equipped_weapon", ""))
	if weapon_name.is_empty():
		if _charging_shot:
			_cancel_charged_shot()
		return
	if not InputMap.has_action(attack_action):
		return
	if Input.is_action_just_pressed(attack_action) and _attack_cooldown_timer <= 0.0:
		var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
		if _is_weapon_reloading(weapon_name):
			pass
		elif _get_weapon_ammo(weapon_name, weapon_def) <= 0:
			_start_weapon_reload(weapon_name, weapon_def)
		else:
			_charging_shot = true
			_charge_weapon_name = weapon_name
			_charge_timer = 0.0
	if not _charging_shot:
		return
	if weapon_name != _charge_weapon_name:
		_cancel_charged_shot()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		_cancel_charged_shot()
		return
	if Input.is_action_just_released(attack_action):
		_release_charged_shot()
		return
	if Input.is_action_pressed(attack_action):
		_charge_timer += delta


func _release_charged_shot() -> void:
	var weapon_name := _charge_weapon_name
	var held_time := _charge_timer
	_charging_shot = false
	_charge_weapon_name = ""
	_charge_timer = 0.0
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	if weapon_def.is_empty():
		return
	var ability_def: Dictionary = GameData.ability_definitions.get("Charged Shot", {})
	var partial_time := float(ability_def.get("charge_partial_time", 1.0))
	var full_time := float(ability_def.get("charge_full_time", 2.0))
	var damage_multiplier := float(ability_def.get("damage_multiplier", 1.0))
	# A held/partial or full charge burns extra ammo instead of extra
	# Action -- Action no longer gates abilities at all (see the stamina
	# rework below), weapon resources are ammo/heat/durability now.
	var ammo_cost := 1
	if held_time >= full_time:
		damage_multiplier = float(ability_def.get("charge_full_multiplier", 2.5))
		ammo_cost = CHARGED_SHOT_FULL_AMMO_COST
	elif held_time >= partial_time:
		damage_multiplier = float(ability_def.get("charge_partial_multiplier", 1.75))
	_fire_hitscan(weapon_name, weapon_def, ammo_cost, damage_multiplier)


func _cancel_charged_shot() -> void:
	_charging_shot = false
	_charge_weapon_name = ""
	_charge_timer = 0.0


func _perform_buttstroke() -> void:
	if not is_alive() or _buttstroke_cooldown_timer > 0.0:
		return
	_buttstroke_cooldown_timer = BUTTSTROKE_COOLDOWN
	var origin := global_position
	for enemy_node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy_node) or not enemy_node.has_method("receive_player_attack"):
			continue
		if enemy_node.has_method("is_alive") and not enemy_node.call("is_alive"):
			continue
		var enemy_position: Vector3 = (enemy_node as Node3D).global_position
		var to_enemy := enemy_position - origin
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > BUTTSTROKE_RANGE:
			continue
		var attack_parameters := {
			"base_damage": float(BUTTSTROKE_DAMAGE),
			"damage_multiplier": 1.0,
			"conditioning_nodes": 0,
			"max_conditioning_nodes": 0,
			"equipped_weapon_name": "Buttstroke",
			"damage_type": "Kinetic",
			"professions_unlocked": {},
		}
		var result: Dictionary = enemy_node.call("receive_player_attack", attack_parameters)
		attack_performed.emit(enemy_node, result)
		if enemy_node.has_method("apply_stagger"):
			enemy_node.call("apply_stagger", BUTTSTROKE_STUN_DURATION)
		if enemy_node.has_method("apply_knockback"):
			var push_direction := to_enemy.normalized() if distance > 0.001 else Vector3.FORWARD
			enemy_node.call("apply_knockback", push_direction, BUTTSTROKE_KNOCKBACK_DISTANCE)


func _begin_ground_target(weapon_name: String, weapon_def: Dictionary) -> void:
	if _ground_target_active:
		return
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	var weapon_class := String(weapon_def.get("item_class", ""))
	_ground_target_weapon_name = weapon_name
	_ground_target_weapon_class = weapon_class
	_ground_target_max_range = float(effective_stats.get("Range", default_attack_range))
	_ground_target_splash_radius = GameData.splash_radius_for_class(weapon_class)
	_ground_target_telegraph = GROUND_TELEGRAPH_SCENE.instantiate()
	get_tree().current_scene.add_child(_ground_target_telegraph)
	_ground_target_telegraph.call("set_radius", _ground_target_splash_radius)
	_ground_target_active = true
	_update_ground_target_telegraph()


func _update_ground_target_telegraph() -> void:
	if not is_instance_valid(_ground_target_telegraph):
		return
	var aim_point := _get_mouse_aim_point()
	var origin := global_position
	var to_aim := aim_point - origin
	to_aim.y = 0.0
	if to_aim.length() > _ground_target_max_range:
		to_aim = to_aim.normalized() * _ground_target_max_range
	var placement := origin + to_aim
	placement.y = origin.y
	_ground_target_telegraph.global_position = placement


func _confirm_ground_target() -> void:
	if not _ground_target_active:
		return
	var impact_position := global_position
	if is_instance_valid(_ground_target_telegraph):
		impact_position = _ground_target_telegraph.global_position
	var weapon_name := _ground_target_weapon_name
	var weapon_class := _ground_target_weapon_class
	var splash_radius := _ground_target_splash_radius
	var throw_origin := global_position + Vector3(0, GRENADE_THROW_HEIGHT, 0)
	_cancel_ground_target()
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	if _is_weapon_reloading(weapon_name):
		return
	var current_ammo := _get_weapon_ammo(weapon_name, weapon_def)
	if current_ammo <= 0:
		_start_weapon_reload(weapon_name, weapon_def)
		return
	_weapon_ammo[weapon_name] = current_ammo - 1
	_attack_cooldown_timer = _get_weapon_attack_cooldown(weapon_name, weapon_def)
	if weapon_class == "Grenade Launcher":
		# Lands exactly on the reticle -- accuracy-based random scatter
		# was tried and didn't feel right (took the landing spot out of
		# the player's control), reverted. Aim is what determines where
		# it goes, same as every other weapon.
		_launch_grenade(weapon_name, throw_origin, impact_position, 0.0, splash_radius)
	else:
		_resolve_aoe_damage(weapon_name, impact_position, splash_radius)


func _launch_grenade(
	weapon_name: String, throw_origin: Vector3, impact_position: Vector3, _max_range: float, _splash_radius: float
) -> void:
	var initial_velocity := _solve_grenade_launch_velocity(throw_origin, impact_position)
	var projectile := GRENADE_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.call(
		"launch",
		throw_origin,
		initial_velocity,
		GRENADE_GRAVITY,
		impact_position.y,
		GRENADE_BOUNCE_RESTITUTION,
		GRENADE_BOUNCE_FRICTION,
		GRENADE_MAX_BOUNCES,
		GRENADE_SETTLE_SPEED,
		GRENADE_MAX_FLIGHT_TIME,
		ENEMY_GROUP,
		GRENADE_CONTACT_RADIUS,
		func(final_position: Vector3, hit_enemy: Node) -> void:
			_resolve_grenade_impact(weapon_name, final_position, hit_enemy)
	)


# Solves the initial launch velocity vector for a projectile fired from
# throw_origin at GRENADE_LAUNCH_ANGLE_DEGREES so that, under
# GRENADE_GRAVITY alone, its first ground impact lands at
# impact_position (the reticle's marked spot). Standard height-adjusted
# projectile range equation: for horizontal distance D, launch angle th,
# gravity g, and drop height h (launch height above the landing height),
# v0 = sqrt(g*D^2 / (2*cos(th)^2*(D*tan(th) + h))).
func _solve_grenade_launch_velocity(throw_origin: Vector3, impact_position: Vector3) -> Vector3:
	var horizontal := impact_position - throw_origin
	horizontal.y = 0.0
	var horizontal_distance := horizontal.length()
	if horizontal_distance < 0.05:
		return Vector3(0, 1.5, 0)
	var horizontal_direction := horizontal.normalized()
	var drop_height := throw_origin.y - impact_position.y
	var angle := deg_to_rad(GRENADE_LAUNCH_ANGLE_DEGREES)
	var denominator := 2.0 * cos(angle) * cos(angle) * (horizontal_distance * tan(angle) + drop_height)
	var speed := sqrt(
		(GRENADE_GRAVITY * horizontal_distance * horizontal_distance) / maxf(denominator, 0.001)
	)
	return horizontal_direction * speed * cos(angle) + Vector3(0, speed * sin(angle), 0)


func _resolve_aoe_damage(weapon_name: String, impact_position: Vector3, splash_radius: float) -> void:
	_spawn_explosion_vfx(impact_position, splash_radius)
	_drain_weapon_durability(weapon_name, DURABILITY_DRAIN_PER_SHOT)
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	var attack_parameters := {
		"base_damage": float(effective_stats.get("Damage Rating", 5.0)),
		"damage_multiplier": 1.0,
		"conditioning_nodes": 0,
		"max_conditioning_nodes": 0,
		"equipped_weapon_name": weapon_name,
		"damage_type": _get_weapon_damage_type(weapon_name),
		"professions_unlocked": {},
	}
	for enemy_node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy_node) or not enemy_node.has_method("receive_player_attack"):
			continue
		if not (enemy_node as Node3D).global_position.distance_to(impact_position) <= splash_radius:
			continue
		var result: Dictionary = enemy_node.call("receive_player_attack", attack_parameters)
		attack_performed.emit(enemy_node, result)


# Grenade Launcher's damage path: a DIRECT HIT (full damage) on whichever
# enemy the projectile's flight actually touched (steamtek_grenade_
# projectile_3d.gd checks this continuously, not just at the final rest
# position) -- that's what makes the hit itself reliable regardless of
# target movement/aim precision. hit_enemy is null on a clean miss
# (grenade settled without ever coming within GRENADE_CONTACT_RADIUS of
# anyone). On TOP of that direct hit (or even on a miss), anything else
# within GRENADE_SPLASH_RADIUS of where it actually went off takes
# reduced splash damage -- a real explosion still hurts everyone nearby,
# not just whatever it touched.
const GRENADE_SPLASH_RADIUS := 2.0
const GRENADE_SPLASH_DAMAGE_FRACTION := 0.5


func _resolve_grenade_impact(weapon_name: String, impact_position: Vector3, hit_enemy: Node) -> void:
	_spawn_explosion_vfx(impact_position, GRENADE_SPLASH_RADIUS)
	_drain_weapon_durability(weapon_name, DURABILITY_DRAIN_PER_SHOT)
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	var damage_type := _get_weapon_damage_type(weapon_name)
	var base_damage := float(effective_stats.get("Damage Rating", 5.0))

	if hit_enemy != null and is_instance_valid(hit_enemy) and hit_enemy.has_method("receive_player_attack"):
		var direct_parameters := {
			"base_damage": base_damage,
			"damage_multiplier": 1.0,
			"conditioning_nodes": 0,
			"max_conditioning_nodes": 0,
			"equipped_weapon_name": weapon_name,
			"damage_type": damage_type,
			"professions_unlocked": {},
		}
		var direct_result: Dictionary = hit_enemy.call("receive_player_attack", direct_parameters)
		attack_performed.emit(hit_enemy, direct_result)

	var splash_parameters := {
		"base_damage": base_damage * GRENADE_SPLASH_DAMAGE_FRACTION,
		"damage_multiplier": 1.0,
		"conditioning_nodes": 0,
		"max_conditioning_nodes": 0,
		"equipped_weapon_name": weapon_name,
		"damage_type": damage_type,
		"professions_unlocked": {},
	}
	for enemy_node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy_node == hit_enemy:
			continue
		if not is_instance_valid(enemy_node) or not enemy_node.has_method("receive_player_attack"):
			continue
		if not (enemy_node as Node3D).global_position.distance_to(impact_position) <= GRENADE_SPLASH_RADIUS:
			continue
		var splash_result: Dictionary = enemy_node.call("receive_player_attack", splash_parameters)
		attack_performed.emit(enemy_node, splash_result)


func _spawn_explosion_vfx(impact_position: Vector3, splash_radius: float) -> void:
	var explosion := GRENADE_EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = impact_position
	explosion.call("play", splash_radius)


func _cancel_ground_target() -> void:
	if is_instance_valid(_ground_target_telegraph):
		_ground_target_telegraph.queue_free()
	_ground_target_telegraph = null
	_ground_target_active = false
	_ground_target_weapon_name = ""
	_ground_target_weapon_class = ""


func _process_flame_channel(delta: float) -> void:
	var weapon_name := String(inventory.get("equipped_weapon", ""))
	if weapon_name.is_empty():
		_stop_flame_channel()
		return
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	var current_heat := float(combat_state.get("current_heat", 0.0))
	var wants_to_fire := (
		not combat_blocked
		and is_alive()
		and not _is_weapon_broken(weapon_name)
		and _flame_overheat_lockout_timer <= 0.0
		and InputMap.has_action(attack_action)
		and Input.is_action_pressed(attack_action)
	)
	if wants_to_fire:
		if not _flame_channel_active:
			_start_flame_channel(weapon_name, weapon_def)
		_update_flame_channel_telegraph()
		_flame_tick_timer -= delta
		if _flame_tick_timer <= 0.0:
			_flame_tick_timer = FLAME_TICK_INTERVAL
			_fire_flame_tick(weapon_name, weapon_def)
		current_heat = minf(FLAME_MAX_HEAT, current_heat + FLAME_HEAT_PER_SECOND * delta)
		combat_state["current_heat"] = current_heat
		if current_heat >= FLAME_MAX_HEAT:
			_flame_overheat_lockout_timer = FLAME_OVERHEAT_LOCKOUT_SECONDS
			_stop_flame_channel()
		return
	if _flame_channel_active:
		_stop_flame_channel()
	if _flame_overheat_lockout_timer > 0.0:
		_flame_overheat_lockout_timer = maxf(0.0, _flame_overheat_lockout_timer - delta)
	if current_heat > 0.0:
		combat_state["current_heat"] = maxf(0.0, current_heat - FLAME_HEAT_REGEN_PER_SECOND * delta)


func _start_flame_channel(weapon_name: String, weapon_def: Dictionary) -> void:
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	var weapon_class := String(weapon_def.get("item_class", ""))
	_flame_channel_weapon_name = weapon_name
	_flame_channel_length = float(effective_stats.get("Range", default_attack_range))
	_flame_channel_angle_degrees = GameData.cone_angle_for_class(weapon_class)
	_flame_channel_telegraph = CONE_TELEGRAPH_SCENE.instantiate()
	get_tree().current_scene.add_child(_flame_channel_telegraph)
	_flame_channel_active = true
	_flame_tick_timer = 0.0
	_update_flame_channel_telegraph()


func _update_flame_channel_telegraph() -> void:
	if not is_instance_valid(_flame_channel_telegraph):
		return
	_flame_channel_telegraph.global_position = global_position
	_flame_channel_telegraph.call(
		"set_shape", _cone_aim_direction(), _flame_channel_length, _flame_channel_angle_degrees
	)


func _cone_aim_direction() -> Vector3:
	var aim_point := _get_mouse_aim_point()
	var aim_direction := aim_point - global_position
	aim_direction.y = 0.0
	if aim_direction.length_squared() < 0.0001:
		return Vector3.FORWARD
	return aim_direction.normalized()


func _fire_flame_tick(weapon_name: String, weapon_def: Dictionary) -> void:
	_drain_weapon_durability(weapon_name, DURABILITY_DRAIN_PER_FLAME_TICK)
	var effective_stats := _get_effective_weapon_stats(weapon_name, weapon_def)
	var attack_parameters := {
		"base_damage": float(effective_stats.get("Damage Rating", 5.0)) * FLAME_TICK_DAMAGE_FRACTION,
		"damage_multiplier": 1.0,
		"conditioning_nodes": 0,
		"max_conditioning_nodes": 0,
		"equipped_weapon_name": weapon_name,
		"damage_type": _get_weapon_damage_type(weapon_name),
		"professions_unlocked": {},
	}
	var origin := global_position
	var aim_direction := _cone_aim_direction()
	var half_angle_cos := cos(deg_to_rad(_flame_channel_angle_degrees) * 0.5)
	for enemy_node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy_node) or not enemy_node.has_method("receive_player_attack"):
			continue
		var enemy_position: Vector3 = (enemy_node as Node3D).global_position
		var to_enemy := enemy_position - origin
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > _flame_channel_length or distance < 0.001:
			continue
		if to_enemy.normalized().dot(aim_direction) < half_angle_cos:
			continue
		var result: Dictionary = enemy_node.call("receive_player_attack", attack_parameters)
		attack_performed.emit(enemy_node, result)


func _stop_flame_channel() -> void:
	if is_instance_valid(_flame_channel_telegraph):
		_flame_channel_telegraph.queue_free()
	_flame_channel_telegraph = null
	_flame_channel_active = false
	_flame_channel_weapon_name = ""


func _aim_fire_target(max_range: float) -> Node:
	var aim_point := _get_mouse_aim_point()
	var origin := global_position + Vector3(0, 1.0, 0)
	var direction := aim_point - origin
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return null
	direction = direction.normalized()
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_range)
	query.collision_mask = COMBAT_TARGET_COLLISION_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider")


func _get_mouse_aim_point() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return global_position
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var ground_plane := Plane(Vector3.UP, global_position.y)
	var hit: Variant = ground_plane.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		return global_position
	return hit as Vector3


func save_combat_state() -> void:
	if _combat_save_callback.is_valid():
		_combat_save_callback.call()


func _regen_combat_state(delta: float) -> void:
	if combat_state.is_empty():
		return
	var max_h := float(get_max_health())
	var max_a := float(get_max_action())
	var h := float(combat_state.get("current_health", max_h))
	var a := float(combat_state.get("current_action", max_a))
	if h > 0.0 and h < max_h:
		combat_state["current_health"] = minf(max_h, h + max_h * 0.02 * delta)
	if a < max_a:
		# 10/sec was tuned for the old action-per-shot economy (a slow
		# trickle since weapons no longer draw from this pool at all).
		# Now that it's stamina drained by sprinting (100/sec) and
		# dodging (150 flat), it needs to refill fast enough to matter --
		# placeholder tuning, needs a balance pass once it's played.
		combat_state["current_action"] = minf(max_a, a + 60.0 * delta)


func _refresh_interaction_focus() -> void:
	var best_area: Area3D
	var best_distance := INF
	var best_prompt := ""
	for candidate in interaction_detector.get_overlapping_areas():
		var area := candidate as Area3D
		if area == null or not area.has_method("interact"):
			continue
		if area.has_method("can_interact") and not bool(area.call("can_interact", self)):
			continue
		var distance := interaction_origin.global_position.distance_to(area.global_position)
		if distance >= best_distance:
			continue
		best_area = area
		best_distance = distance
		if area.has_method("get_interaction_prompt"):
			best_prompt = String(area.call("get_interaction_prompt"))
		else:
			best_prompt = "Interact"
	if best_area == focused_interactable and best_prompt == focused_prompt_text:
		return
	focused_interactable = best_area
	focused_prompt_text = best_prompt
	interaction_focus_changed.emit(focused_prompt_text, focused_interactable)


func _instantiate_character() -> void:
	character_instance = visual_pivot.get_node_or_null(character_instance_name) as Node3D
	if character_instance == null:
		if character_scene == null:
			push_warning("Steamtek humanoid has no character_scene assigned: %s" % name)
			return
		character_instance = character_scene.instantiate() as Node3D
		if character_instance == null:
			push_error("Assigned Steamtek character scene is not Node3D: %s" % name)
			return
		character_instance.name = character_instance_name
		visual_pivot.add_child(character_instance)
	animation_player = _find_animation_player(character_instance)
	if animation_player == null:
		push_error("No AnimationPlayer found in character scene: %s" % character_instance_name)
		return
	idle_animation = _find_animation_name(idle_animation_key)
	walk_animation = _find_animation_name(walk_animation_key)
	run_animation = _find_animation_name(run_animation_key)
	_configure_loop(idle_animation)
	_configure_loop(walk_animation)
	_configure_loop(run_animation)
	if idle_animation.is_empty() or walk_animation.is_empty() or run_animation.is_empty():
		push_warning(
			"Character is missing a required locomotion animation. Imported: %s"
			% str(animation_player.get_animation_list())
		)
	_play_animation(idle_animation)


func _camera_relative_direction(input_vector: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input_vector.x, 0.0, -input_vector.y)
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	return camera_right * input_vector.x + camera_forward * -input_vector.y


func _world_yaw_to_visual_local_yaw(world_yaw: float) -> float:
	var visual_parent := visual_pivot.get_parent_node_3d()
	if visual_parent == null:
		return world_yaw
	var parent_forward := visual_parent.global_transform.basis.z
	parent_forward.y = 0.0
	if parent_forward.length_squared() <= 0.000001:
		return world_yaw
	parent_forward = parent_forward.normalized()
	var parent_world_yaw := atan2(parent_forward.x, parent_forward.z)
	return wrapf(world_yaw - parent_world_yaw, -PI, PI)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_animation_name(required_key: String) -> String:
	if animation_player == null:
		return ""
	for animation_name in animation_player.get_animation_list():
		var candidate := String(animation_name)
		if candidate == required_key or candidate.ends_with("/" + required_key) or required_key in candidate:
			return candidate
	return ""


func _configure_loop(animation_name: String) -> void:
	if animation_player == null or animation_name.is_empty():
		return
	var animation := animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR


func _play_animation(animation_name: String) -> void:
	if animation_player == null or animation_name.is_empty() or active_animation == animation_name:
		return
	animation_player.play(animation_name, locomotion_blend_seconds)
	animation_player.speed_scale = 1.0
	active_animation = animation_name
