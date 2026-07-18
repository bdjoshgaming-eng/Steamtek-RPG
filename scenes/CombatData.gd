extends Node

# ============================================================
# CombatData.gd -- autoload singleton (combat DATA layer)
# ============================================================
# The DATA half of the combat data/logic split (see
# Steamtek_Combat_Overhaul_Outline.md, Decision Log bullet 5). Holds the
# combat stat-block schema, the Combat Level anchor table, and the
# starting definitions for enemies. LOGIC (the damage formula, CL
# derivation, mitigation) lives in Combat.gd; main.gd orchestrates and
# holds no combat math or combat data tables.
#
# Setup required once in the Godot editor:
#   Project Settings -> Autoload -> add this file, Node Name "CombatData"
# ============================================================


# Hidden Combat Level anchor table (Steamtek scale, Phase 2). Enemy core
# stats are interpolated between these anchors by
# Combat.derive_stats_from_cl(). These are Steamtek's OWN numbers (the SWG
# framework growth curve rescaled to the current game), CL1-40; CL41-100
# to be added later. "damage" is the CENTER of the enemy's attack roll;
# the min/max spread (x0.55 .. x1.45) is applied when the enemy attacks.
# "armor" is the Armor Rating (Phase 4a); Combat converts it to a Damage
# Reduction %% and to Effective Health.
const CL_ANCHORS: Dictionary = {
	1: {"health": 50, "action": 50, "damage": 27, "defense": -2, "armor": 0},
	5: {"health": 110, "action": 90, "damage": 48, "defense": 16, "armor": 15},
	10: {"health": 250, "action": 190, "damage": 85, "defense": 35, "armor": 30},
	15: {"health": 600, "action": 440, "damage": 146, "defense": 55, "armor": 48},
	20: {"health": 1365, "action": 980, "damage": 238, "defense": 75, "armor": 66},
	25: {"health": 2940, "action": 2100, "damage": 374, "defense": 100, "armor": 93},
	30: {"health": 5800, "action": 4100, "damage": 578, "defense": 130, "armor": 120},
	35: {"health": 10920, "action": 7700, "damage": 867, "defense": 165, "armor": 152},
	40: {"health": 21000, "action": 14700, "damage": 1241, "defense": 200, "armor": 193},
}


# The shared 15-field combat stat block (framework spec 3.1). Returns a
# FRESH dictionary each call so no two combatants share a reference.
# Defaults are placeholders; later phases populate them.
func new_combat_stats() -> Dictionary:
	return {
		"base_health": 0,
		"effective_health": 0,
		"armor_rating": 0,
		"damage_reduction": 0.0,
		"accuracy": 0,
		"defense": 0,
		"critical_chance": 0.0,
		"critical_damage": 0.0,
		"critical_resistance": 0.0,
		"dodge": 0.0,
		"block": 0.0,
		"armor_penetration": 0.0,
		"heat": 0,
		"pressure_capacity": 0,
		"movement_speed": 0.0,
	}


# Fresh copy of the two test enemies' full runtime entries, keyed by the
# ids main.gd already uses. Each carries a hidden Combat Level ("cl"); the
# health/action/damage/defense fields start at 0 and are filled from the
# CL anchor table at startup by main._apply_cl_derivation(). Identity and
# state defaults are set here.
# Canonical Steamtek damage types (Phase 4b). Every weapon deals exactly
# one of these, and armor resists each independently. Kinetic = melee
# impact (blades/blunt/fists), Ballistic = projectiles, Thermal = fire/
# heat/steam-burn, Pressure = steam blast/concussion/explosive, Arc =
# electricity, Chemical = acid/toxin, EMP = anti-electronic. Chemical and
# EMP have no weapons yet -- reserved for later families.
const DAMAGE_TYPES: Array = ["Kinetic", "Ballistic", "Thermal", "Pressure", "Arc", "Chemical", "EMP"]


# Builds a per-type resistance dictionary. Phase 4b uses it UNIFORMLY --
# every type gets the same rating (the enemy's derived Armor Rating) -- so
# combat still feels like 4a. Phase 4c gives armor classes varied per-type
# values, at which point damage type starts to matter.
func new_resistances(armor_rating: int) -> Dictionary:
	var r: Dictionary = {}
	for dtype in DAMAGE_TYPES:
		r[dtype] = armor_rating
	return r


func default_enemies() -> Dictionary:
	return {
		"dummy": {
			"name": "Scrap Thief",
			"difficulty": 5,
			"cl": 1,
			"max_health": 0,
			"current_health": 0,
			"max_action": 0,
			"current_action": 0,
			"attack_min_damage": 0,
			"attack_max_damage": 0,
			"defense": 0,
			"armor_rating": 0,
			"resistances": {},
			"alive": true,
			"attack_ready": true,
			"damage_debuff": 0.0,
			"accuracy_debuff": 0.0,
			"attack_speed_debuff": 0.0,
			"bleed_ticks_remaining": 0,
			"bleed_damage_per_tick": 0,
			"taunted_until_msec": 0,
			"damage_by_weapon_class": {},
			"stats": new_combat_stats(),
		},
		"enemy2": {
			"name": "Rust Marauder",
			"difficulty": 8,
			"cl": 5,
			"max_health": 0,
			"current_health": 0,
			"max_action": 0,
			"current_action": 0,
			"attack_min_damage": 0,
			"attack_max_damage": 0,
			"defense": 0,
			"armor_rating": 0,
			"resistances": {},
			"alive": true,
			"attack_ready": true,
			"damage_debuff": 0.0,
			"accuracy_debuff": 0.0,
			"attack_speed_debuff": 0.0,
			"bleed_ticks_remaining": 0,
			"bleed_damage_per_tick": 0,
			"taunted_until_msec": 0,
			"damage_by_weapon_class": {},
			"stats": new_combat_stats(),
		},
	}
