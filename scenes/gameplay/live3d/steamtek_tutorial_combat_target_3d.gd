class_name SteamtekTutorialCombatTarget3D
extends Area3D

signal health_changed(target: Node, current_health: int, max_health: int)
signal defeated(target: Node)

@export var display_name := "Scrap Thief"
@export_range(1, 40, 1) var combat_level := 1
@export var starts_active := true

@onready var collision: CollisionShape3D = $Collision
@onready var status_label: Label3D = $StatusLabel

var max_health := 1
var current_health := 1
var attack_min_damage := 1
var attack_max_damage := 1
var resistances: Dictionary = {}
var active := true
var combat_runtime: Node
var combat_data_runtime: Node


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
	set_active(starts_active)
	_refresh_label()


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
	set_active(true)
	_refresh_label()
	health_changed.emit(self, current_health, max_health)


func _refresh_label() -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = "%s  %d / %d" % [display_name, current_health, max_health]
