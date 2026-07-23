class_name SteamtekTutorialCombatTarget3D
extends Area3D

signal health_changed(target: Node, current_health: int, max_health: int)
signal defeated(target: Node)

enum AiState { IDLE, CHASE, LEASH }

@export var display_name := "Scrap Thief"
@export_range(1, 40, 1) var combat_level := 1
@export var starts_active := true
@export var sprite_tint := Color(1, 1, 1, 1)
@export var aggro_range := 6.0
@export var chase_speed := 3.2
@export var leash_range := 11.0
@export var patrol_radius := 1.6
@export var patrol_pause_min := 1.5
@export var patrol_pause_max := 3.5
@export var attack_cooldown := 2.5
@export var attack_contact_distance := 1.1

const LEASH_SPEED_MULTIPLIER := 1.6
const LEASH_ARRIVE_DISTANCE := 0.35
const PATROL_ARRIVE_DISTANCE := 0.2
const PATROL_SPEED_FACTOR := 0.35

@onready var collision: CollisionShape3D = $Collision
@onready var status_label: Label3D = $StatusLabel
@onready var enemy_sprite: Sprite3D = $EnemySprite

var max_health := 1
var current_health := 1
var attack_min_damage := 1
var attack_max_damage := 1
var resistances: Dictionary = {}
var active := true
var combat_runtime: Node
var combat_data_runtime: Node

var player_ref: Node3D
var ai_state: AiState = AiState.IDLE
var home_position: Vector3
var patrol_target: Vector3
var patrol_pause_timer := 0.0
var attack_timer := 0.0


func _ready() -> void:
	combat_runtime = get_node("/root/Combat")
	combat_data_runtime = get_node("/root/CombatData")
	var derived: Dictionary = combat_runtime.call("derive_stats_from_cl", combat_level)
	max_health = int(derived["health"])
	current_health = max_health
	var center_damage := int(derived["damage"])
	attack_min_damage = maxi(1, int(round(center_damage * 0.55)))
	attack_max_damage = maxi(attack_min_damage, int(round(center_damage * 1.45)))
	resistances = combat_data_runtime.call("new_resistances", int(derived["armor"]))
	enemy_sprite.modulate = sprite_tint
	home_position = global_position
	patrol_target = home_position
	set_active(starts_active)
	_refresh_label()


func set_player_reference(player: Node3D) -> void:
	player_ref = player


func _process(delta: float) -> void:
	if not is_alive() or player_ref == null:
		return
	match ai_state:
		AiState.IDLE:
			_idle_tick(delta)
		AiState.CHASE:
			_chase_tick(delta)
		AiState.LEASH:
			_leash_tick(delta)


func _idle_tick(delta: float) -> void:
	if global_position.distance_to(player_ref.global_position) <= aggro_range:
		ai_state = AiState.CHASE
		return
	var to_target := patrol_target - global_position
	to_target.y = 0.0
	if to_target.length() <= PATROL_ARRIVE_DISTANCE:
		patrol_pause_timer -= delta
		if patrol_pause_timer <= 0.0:
			_pick_patrol_target()
		return
	var step := to_target.normalized() * chase_speed * PATROL_SPEED_FACTOR * delta
	global_position += step


func _chase_tick(delta: float) -> void:
	var to_player := player_ref.global_position - global_position
	to_player.y = 0.0
	var distance_to_home := global_position.distance_to(home_position)
	if distance_to_home > leash_range:
		ai_state = AiState.LEASH
		return
	if to_player.length() <= attack_contact_distance:
		attack_timer -= delta
		if attack_timer <= 0.0:
			_attack_player()
			attack_timer = attack_cooldown
		return
	var step := to_player.normalized() * chase_speed * delta
	global_position += step


func _attack_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref) or not player_ref.has_method("apply_damage"):
		return
	if player_ref.has_method("is_alive") and not player_ref.call("is_alive"):
		return
	player_ref.call("apply_damage", roll_enemy_attack())


func _leash_tick(delta: float) -> void:
	var to_home := home_position - global_position
	to_home.y = 0.0
	if to_home.length() <= LEASH_ARRIVE_DISTANCE:
		current_health = max_health
		ai_state = AiState.IDLE
		patrol_pause_timer = randf_range(patrol_pause_min, patrol_pause_max)
		attack_timer = 0.0
		_refresh_label()
		health_changed.emit(self, current_health, max_health)
		return
	var step := to_home.normalized() * chase_speed * LEASH_SPEED_MULTIPLIER * delta
	global_position += step


func _pick_patrol_target() -> void:
	var angle := randf_range(0.0, TAU)
	var radius := randf_range(0.0, patrol_radius)
	patrol_target = home_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	patrol_pause_timer = randf_range(patrol_pause_min, patrol_pause_max)


func is_alive() -> bool:
	return active and current_health > 0


func set_active(enabled: bool) -> void:
	active = enabled
	visible = enabled
	monitoring = enabled
	monitorable = enabled
	if is_instance_valid(collision):
		collision.set_deferred("disabled", not enabled)


func receive_player_attack(attack_parameters: Dictionary) -> Dictionary:
	if not is_alive():
		return {"damage": 0, "crit": false, "uncertified": false}
	if ai_state == AiState.LEASH:
		return {"damage": 0, "crit": false, "uncertified": false}
	var result: Dictionary = combat_runtime.call("compute_player_attack_damage", attack_parameters)
	var damage: int = combat_runtime.call(
		"apply_typed_mitigation",
		int(result["damage"]),
		resistances,
		String(attack_parameters.get("damage_type", "Kinetic")),
		int(attack_parameters.get("armor_penetration", 0))
	)
	current_health = maxi(0, current_health - damage)
	result["damage"] = damage
	_refresh_label()
	health_changed.emit(self, current_health, max_health)
	if current_health == 0:
		set_active(false)
		defeated.emit(self)
	return result


func roll_enemy_attack() -> int:
	if not is_alive():
		return 0
	return int(combat_runtime.call("compute_enemy_attack_damage", attack_min_damage, attack_max_damage, 0.0))


func reset_target() -> void:
	current_health = max_health
	ai_state = AiState.IDLE
	global_position = home_position
	attack_timer = 0.0
	set_active(true)
	_refresh_label()
	health_changed.emit(self, current_health, max_health)


func _refresh_label() -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = "%s  %d / %d" % [display_name, current_health, max_health]
