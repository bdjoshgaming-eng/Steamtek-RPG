extends Node

# ============================================================
# GameData.gd -- autoload singleton
# ============================================================
# Pulled out of main.gd (Pass 1 of splitting the file apart) so the
# huge static data tables -- recipes, professions, abilities, weapon
# certs, elite prereqs, and display-name lookups -- live in one place
# separate from all the runtime game logic. Everything here is still
# read AND written at runtime exactly like before (e.g.
# GameData.novice_professions[...]["unlocked_nodes"] += 1 still works
# the same way it did as a plain script variable) -- this is a location
# change, not a behavior change.
#
# Every reference to these identifiers throughout main.gd (and any
# other script) must be prefixed with "GameData." -- e.g.
# `novice_professions` became `GameData.novice_professions`.
#
# Setup required once in the Godot editor:
#   Project Settings -> Autoload -> add this file, Node Name "GameData"
# ============================================================

# --- Weapon/Item Recipes ---
# --- Item definitions (what an item IS) ---
# SPLIT FROM `recipes`: a recipe describes how to MAKE something; this
# describes what the thing IS once it exists. Combat, equipment and the
# inventory read from here and never touch recipes, so the crafting
# system can be replaced wholesale without weapons disappearing from
# the game.
#
# Keyed by item name (recipe "name" and "output" are always equal).
const ITEM_DEFINITIONS: Dictionary = {
	"Crate of Bandages": {"item_class": "Medicine", "max_charges": 5},
	"Antiseptic Salve": {"item_class": "Medicine"},
	"Vitality Tonic": {"item_class": "Medicine"},
	"Adrenaline Shot": {"item_class": "Medicine"},
	"Rusty Pistol": {"item_class": "Pistol", "item_subclass": "Pistol", "weapon_stat_ranges": {"Speed": [1.2, 0.6], "Damage Rating": [6, 14], "Range": [15, 25], "Ammo Capacity": [8, 15], "Reload Speed": [3.0, 1.5], "Accuracy": [65, 85]}},
	"Pneumatic Rifle": {"item_class": "Assault Rifle", "item_subclass": "Assault Rifle", "weapon_stat_ranges": {"Speed": [0.4, 0.15], "Damage Rating": [8, 18], "Range": [40, 70], "Ammo Capacity": [20, 35], "Reload Speed": [3.5, 2.0], "Accuracy": [45, 65]}},
	"Pneumatic Longrifle": {"item_class": "Sniper Rifle", "item_subclass": "Sniper Rifle", "weapon_stat_ranges": {"Speed": [3.0, 1.8], "Damage Rating": [30, 55], "Range": [100, 160], "Ammo Capacity": [4, 8], "Reload Speed": [4.0, 2.5], "Accuracy": [70, 90]}},
	"Pressure Scattergun": {"item_class": "Shotgun", "item_subclass": "Shotgun", "weapon_stat_ranges": {"Speed": [3.5, 2.5], "Damage Rating": [22, 38], "Range": [8, 15], "Ammo Capacity": [4, 8], "Reload Speed": [5.0, 3.5], "Accuracy": [35, 55]}},
	"Canister Launcher": {"item_class": "Grenade Launcher", "item_subclass": "Grenade Launcher", "weapon_stat_ranges": {"Speed": [0.8, 0.5], "Damage Rating": [50, 90], "Range": [30, 60], "Ammo Capacity": [4, 8], "Reload Speed": [2.0, 1.2], "Accuracy": [35, 55]}},
	"Oil Burner": {"item_class": "Flame Thrower", "item_subclass": "Flame Thrower", "weapon_stat_ranges": {"Speed": [0.3, 0.1], "Damage Rating": [5, 10], "Range": [5, 12], "Ammo Capacity": [50, 100], "Reload Speed": [4.5, 3.0], "Accuracy": [50, 70]}},
	"Vented Long-Rifle": {"item_class": "Sniper Rifle", "item_subclass": "Sniper Rifle", "weapon_stat_ranges": {"Speed": [2.6, 1.5], "Damage Rating": [45, 75], "Range": [120, 190], "Ammo Capacity": [5, 10], "Reload Speed": [3.5, 2.2], "Accuracy": [75, 95]}},
	"Double-Bore Scattergun": {"item_class": "Shotgun", "item_subclass": "Shotgun", "weapon_stat_ranges": {"Speed": [4.5, 3.2], "Damage Rating": [35, 60], "Range": [10, 18], "Ammo Capacity": [2, 4], "Reload Speed": [6.0, 4.5], "Accuracy": [35, 55]}},
	"Copper Lined Gun": {"item_class": "Pistol", "item_subclass": "Pistol", "weapon_stat_ranges": {"Speed": [1.0, 0.5], "Damage Rating": [10, 22], "Range": [20, 32], "Ammo Capacity": [10, 18], "Reload Speed": [2.5, 1.2], "Accuracy": [70, 90]}},
	"Pressure-Fed Launcher": {"item_class": "Grenade Launcher", "item_subclass": "Grenade Launcher", "weapon_stat_ranges": {"Speed": [1.0, 0.65], "Damage Rating": [65, 105], "Range": [35, 65], "Ammo Capacity": [5, 10], "Reload Speed": [2.5, 1.5], "Accuracy": [40, 60]}},
}


# Returns the definition for an item name, or an empty Dictionary if
# the item has no definition (raw materials, intermediates).
func get_item_definition(item_name: String) -> Dictionary:
	return ITEM_DEFINITIONS.get(item_name, {})


# Sums the "amount" of every PURCHASED keystone node across every
# profession/keystone whose "stat" field matches stat_name (e.g. "Grit").
# Generic on purpose: any profession could add more nodes for the same
# stat later without this needing to change.
func total_purchased_stat(stat_name: String) -> float:
	var total := 0.0
	for profession_data in novice_professions.values():
		var keystones: Dictionary = profession_data.get("keystones", {})
		for keystone_data in keystones.values():
			var nodes: Dictionary = keystone_data.get("nodes", {})
			for node_data in nodes.values():
				if String(node_data.get("type", "")) != "stat":
					continue
				if String(node_data.get("stat", "")) != stat_name:
					continue
				if not bool(node_data.get("purchased", false)):
					continue
				total += float(node_data.get("amount", 0))
	return total


# How a weapon class resolves its target, keyed by item_class (not by
# individual item name -- every weapon sharing a class fires the same
# way). "aim_hitscan" fires instantly at whatever's under the aim-fire
# raycast (see steamtek_humanoid_character_3d.gd's _aim_fire_target()).
# "ground_target" shows a telegraph circle at the mouse (clamped to the
# weapon's Range) that confirms on a second click. splash_radius_for_
# class() sizes that circle for every ground_target weapon, but only
# actually SPLASHES damage for instant-detonate blast weapons (Rocket
# Launcher/Arc Cannon, once they exist) -- Grenade Launcher instead
# throws a real projectile that deals a direct hit on contact
# (GRENADE_CONTACT_RADIUS in steamtek_humanoid_character_3d.gd), not an
# AoE check at the splash radius. "cone" is not implemented yet (Flame
# Thrower still fires as aim_hitscan).
# Data-driven so a future weapon (Rocket Launcher, Arc Cannon, grenade
# abilities) just needs an entry here, not a new code branch.
const WEAPON_TARGETING_MODES: Dictionary = {
	"Pistol": "aim_hitscan",
	"Assault Rifle": "aim_hitscan",
	"Sniper Rifle": "aim_hitscan",
	"Shotgun": "aim_hitscan",
	"Grenade Launcher": "ground_target",
	"Flame Thrower": "cone",
}

func targeting_mode_for_class(weapon_class: String) -> String:
	return WEAPON_TARGETING_MODES.get(weapon_class, "aim_hitscan")


# Splash radius (meters) for weapon classes that deal area damage on
# confirm rather than hitting a single raycast target. Keyed by
# item_class, same convention as WEAPON_TARGETING_MODES.
const WEAPON_SPLASH_RADIUS: Dictionary = {
	"Grenade Launcher": 0.49,
}

func splash_radius_for_class(weapon_class: String) -> float:
	return float(WEAPON_SPLASH_RADIUS.get(weapon_class, 3.0))


# Cone half-spread (full angle, degrees) for weapon classes that deal
# area damage in a wedge in front of the player. Cone LENGTH uses the
# weapon's own weapon_stat_ranges Range[0], same convention as
# ground_target's max click distance -- only the angle is class-level.
const WEAPON_CONE_ANGLE_DEGREES: Dictionary = {
	"Flame Thrower": 50.0,
}

func cone_angle_for_class(weapon_class: String) -> float:
	return float(WEAPON_CONE_ANGLE_DEGREES.get(weapon_class, 45.0))


const WEAPON_CERT_REQUIREMENTS: Dictionary = {
	"Rusty Pistol": {"profession": "Street Thug", "box": "Novice"},
	"Pneumatic Rifle": {"profession": "Street Thug", "box": "Novice"},
	"Pneumatic Longrifle": {"profession": "Street Thug", "box": "Novice"},
	"Pressure Scattergun": {"profession": "Street Thug", "box": "Novice"},
	"Vented Long-Rifle": {"profession": "Street Thug", "keystone": "Ranged", "points_required": 5},
	"Double-Bore Scattergun": {"profession": "Street Thug", "keystone": "Ranged", "points_required": 5},
	"Copper Lined Gun": {"profession": "Street Thug", "keystone": "Ranged", "points_required": 5},
	"Canister Launcher": {"profession": "Ordnance Specialist", "box": "Novice"},
	"Oil Burner": {"profession": "Ordnance Specialist", "box": "Novice"},
	"Pressure-Fed Launcher": {"profession": "Ordnance Specialist", "box": "Novice"}
}


# --- Ability Definitions ---
var ability_definitions: Dictionary = {
	"Aimed Shot": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	# Hold-to-charge: tap fires the "damage_multiplier" tier below, holding
	# past charge_partial_time/charge_full_time steps up to the partial/full
	# multiplier. "chargeable" is the generic flag any future ability can
	# set to reuse this same hold/release handling in main.gd -- Charged
	# Shot is just the first (and, for now, only) ability using it.
	"Charged Shot": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 40, "damage_multiplier": 1.0, "chargeable": true, "charge_partial_time": 1.0, "charge_full_time": 2.0, "charge_partial_multiplier": 1.75, "charge_full_multiplier": 2.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Suppressing Fire": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Piercing Round": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 50, "damage_multiplier": 2.5, "requires_profession": "Street Thug", "requires_box": "Ranged III"},
	"Point-Blank Burst": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 50, "damage_multiplier": 2.5, "requires_profession": "Street Thug", "requires_box": "Ranged II"},
	"Suppressive Volley": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 60, "damage_multiplier": 4.0, "aoe": true, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Buckshot Barrage": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 60, "damage_multiplier": 4.0, "aoe": true, "requires_profession": "Street Thug", "requires_box": "Master"}
}


# --- Profession Talent Trees ---
var novice_professions: Dictionary = {
	"Street Thug": {
		"xp_type": "Combat XP",
		"point_type": "Thug Points",
		# New keystone/node system. Each profession has a "keystones" dict
		# instead of "paths". Each keystone is a named cluster (Melee,
		# Ranged, Crafting, Auxiliary) containing individual purchasable
		# nodes. Nodes have a "type" (stat or ability), a "cost" in points,
		# a "stat" or "ability" they grant, and a "purchased" flag.
		# "points_spent" tracks how many points have been spent in the
		# keystone. "points_max" is the cap. "mastered" flips true when
		# points_spent == points_max AND all purchased abilities have their
		# upgrade applied.
		# "unlocked" starts false -- you unlock a keystone with XP, then
		# spend node points freely within it.
		"keystones": {
			"Ranged": {
				"unlocked": false,
				"xp_type": "Combat XP",
				"xp_cost": 500,
				"points_spent": 0,
				"points_max": 10,
				"nodes": {
					# --- Ranged Accuracy nodes (5) ---
					"Ranged Accuracy 1": {"type": "stat", "cost": 1, "stat": "Ranged Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Accuracy 2": {"type": "stat", "cost": 1, "stat": "Ranged Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Accuracy 3": {"type": "stat", "cost": 1, "stat": "Ranged Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Accuracy 4": {"type": "stat", "cost": 1, "stat": "Ranged Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Accuracy 5": {"type": "stat", "cost": 1, "stat": "Ranged Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					# --- Ranged Speed nodes (5) ---
					"Ranged Speed 1": {"type": "stat", "cost": 1, "stat": "Ranged Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Speed 2": {"type": "stat", "cost": 1, "stat": "Ranged Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Speed 3": {"type": "stat", "cost": 1, "stat": "Ranged Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Speed 4": {"type": "stat", "cost": 1, "stat": "Ranged Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Speed 5": {"type": "stat", "cost": 1, "stat": "Ranged Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					# --- Ranged Crit Damage nodes (5) ---
					"Ranged Crit Damage 1": {"type": "stat", "cost": 1, "stat": "Ranged Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Crit Damage 2": {"type": "stat", "cost": 1, "stat": "Ranged Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Crit Damage 3": {"type": "stat", "cost": 1, "stat": "Ranged Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Crit Damage 4": {"type": "stat", "cost": 1, "stat": "Ranged Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Ranged Crit Damage 5": {"type": "stat", "cost": 1, "stat": "Ranged Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					# --- Ability nodes (3, cost 2 each) ---
					"Aimed Shot": {
						"type": "ability", "cost": 2, "ability": "Aimed Shot", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Aimed Shot gains +20% damage and ignores 10% of target defense"
					},
					"Charged Shot": {
						"type": "ability", "cost": 2, "ability": "Charged Shot", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Charged Shot's full-charge tier gains +20% damage"
					},
					"Suppressing Fire": {
						"type": "ability", "cost": 2, "ability": "Suppressing Fire", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Suppressing Fire reduces target accuracy by 15% for 3s"
					}
				}
			},
			"Auxiliary": {
				"unlocked": false,
				"xp_type": "Combat XP",
				"xp_cost": 500,
				"points_spent": 0,
				"points_max": 12,
				"nodes": {
					# --- Melee Defense nodes (3) ---
					"Melee Defense 1": {"type": "stat", "cost": 3, "stat": "Melee Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Melee Defense 2": {"type": "stat", "cost": 3, "stat": "Melee Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Melee Defense 3": {"type": "stat", "cost": 3, "stat": "Melee Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Ranged Defense nodes (3) ---
					"Ranged Defense 1": {"type": "stat", "cost": 3, "stat": "Ranged Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Ranged Defense 2": {"type": "stat", "cost": 3, "stat": "Ranged Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Ranged Defense 3": {"type": "stat", "cost": 3, "stat": "Ranged Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Grit nodes (3) -- resists DoT damage and CC duration/potency ---
					"Grit 1": {"type": "stat", "cost": 3, "stat": "Grit", "amount": 5, "purchased": false, "xp_cost": 150},
					"Grit 2": {"type": "stat", "cost": 3, "stat": "Grit", "amount": 5, "purchased": false, "xp_cost": 150},
					"Grit 3": {"type": "stat", "cost": 3, "stat": "Grit", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Loot Chance nodes (3) ---
					"Loot Chance 1": {"type": "stat", "cost": 3, "stat": "Loot Chance", "amount": 5, "purchased": false, "xp_cost": 150},
					"Loot Chance 2": {"type": "stat", "cost": 3, "stat": "Loot Chance", "amount": 5, "purchased": false, "xp_cost": 150},
					"Loot Chance 3": {"type": "stat", "cost": 3, "stat": "Loot Chance", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Cog Bonus nodes (3) ---
					"Cog Bonus 1": {"type": "stat", "cost": 3, "stat": "Cog Bonus", "amount": 5, "purchased": false, "xp_cost": 150},
					"Cog Bonus 2": {"type": "stat", "cost": 3, "stat": "Cog Bonus", "amount": 5, "purchased": false, "xp_cost": 150},
					"Cog Bonus 3": {"type": "stat", "cost": 3, "stat": "Cog Bonus", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Movement Speed nodes (3) ---
					"Movement Speed 1": {"type": "stat", "cost": 3, "stat": "Movement Speed", "amount": 5, "purchased": false, "xp_cost": 150},
					"Movement Speed 2": {"type": "stat", "cost": 3, "stat": "Movement Speed", "amount": 5, "purchased": false, "xp_cost": 150},
					"Movement Speed 3": {"type": "stat", "cost": 3, "stat": "Movement Speed", "amount": 5, "purchased": false, "xp_cost": 150}
				}
			}
		}
	},

	"Enforcer": {
		"xp_type": "Combat XP",
		"point_type": "Enforcer Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Specialist": {
		"xp_type": "Combat XP",
		"point_type": "Specialist Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Ranger": {
		"xp_type": "Combat XP",
		"point_type": "Ranger Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Commando": {
		"xp_type": "Combat XP",
		"point_type": "Commando Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Engineer": {
		"xp_type": "Combat XP",
		"point_type": "Engineer Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Medic": {
		"xp_type": "Combat XP",
		"point_type": "Medic Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Sniper": {
		"xp_type": "Combat XP",
		"point_type": "Sniper Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Bombardier": {
		"xp_type": "Combat XP",
		"point_type": "Bombardier Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Demolitionist": {
		"xp_type": "Combat XP",
		"point_type": "Demolitionist Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Bioforge Tech": {
		"xp_type": "Combat XP",
		"point_type": "Bioforge Tech Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Deadeye": {
		"xp_type": "Combat XP",
		"point_type": "Deadeye Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Siege Operator": {
		"xp_type": "Combat XP",
		"point_type": "Siege Operator Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Wrecker": {
		"xp_type": "Combat XP",
		"point_type": "Wrecker Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Phantom": {
		"xp_type": "Combat XP",
		"point_type": "Phantom Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Huntsman": {
		"xp_type": "Combat XP",
		"point_type": "Huntsman Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Warlord": {
		"xp_type": "Combat XP",
		"point_type": "Warlord Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Saboteur": {
		"xp_type": "Combat XP",
		"point_type": "Saboteur Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Venomcaster": {
		"xp_type": "Combat XP",
		"point_type": "Venomcaster Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Stalker": {
		"xp_type": "Combat XP",
		"point_type": "Stalker Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Razorback": {
		"xp_type": "Combat XP",
		"point_type": "Razorback Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Blastmaster": {
		"xp_type": "Combat XP",
		"point_type": "Blastmaster Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Plague Engineer": {
		"xp_type": "Combat XP",
		"point_type": "Plague Engineer Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Ghost Medic": {
		"xp_type": "Combat XP",
		"point_type": "Ghost Medic Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Warchemist": {
		"xp_type": "Combat XP",
		"point_type": "Warchemist Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Toxinsmith": {
		"xp_type": "Combat XP",
		"point_type": "Toxinsmith Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	},
	"Plague Doctor": {
		"xp_type": "Combat XP",
		"point_type": "Plague Doctor Points",
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},
			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Combat XP", "xp_cost": 50, "point_cost": 5, "cogs_cost": 200, "requires": "Novice"}
		}
	}
}



# --- Weapon Category Groupings ---
var chrome_gunner_weapons = ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"]
var rifle_weapons = ["Assault Rifle", "Sniper Rifle"]
var shotgun_weapons = ["Shotgun"]
var heavy_weapon_types = ["Grenade Launcher", "Flame Thrower"]


# --- Elite Profession Prerequisites ---
# a real, already-existing profession/box pair. Checked in
# _on_choose_profession_pressed before a profession can be selected;
# these are the only gates on Elite Professions right now (no
# abilities/stats/certs have been designed for them yet).
# --- Profession Advancement Tree ---
# Defines the unlock prerequisites for each profession tier.
# "requires_mastered" = list of professions the player must have
# fully mastered (every box unlocked) before the unlock quest
# for this profession becomes available.
# "tier" = 1 (base), 2 (intermediate), 3 (advanced), 4 (elite), 5 (mastery)
# "branch" = which side of the tree this belongs to
#   "enforcer" = Enforcer/Ranger/Commando/Sniper/Bombardier side
#   "specialist" = Specialist/Engineer/Medic/Demolitionist/Bioforge side
#   "mastery" = cross-class mastery profession
# "mastery_pair" = for mastery professions, [primary, secondary] elite classes
const PROFESSION_TREE: Dictionary = {
	"Street Thug":       {"tier": 1, "branch": "base",       "requires_mastered": []},
	"Enforcer":          {"tier": 2, "branch": "enforcer",    "requires_mastered": ["Street Thug"]},
	"Specialist":        {"tier": 2, "branch": "specialist",  "requires_mastered": ["Street Thug"]},
	"Ranger":            {"tier": 3, "branch": "enforcer",    "requires_mastered": ["Enforcer"]},
	"Commando":          {"tier": 3, "branch": "enforcer",    "requires_mastered": ["Enforcer"]},
	"Engineer":          {"tier": 3, "branch": "specialist",  "requires_mastered": ["Specialist"]},
	"Medic":             {"tier": 3, "branch": "specialist",  "requires_mastered": ["Specialist"]},
	"Sniper":            {"tier": 4, "branch": "enforcer",    "requires_mastered": ["Ranger"]},
	"Bombardier":        {"tier": 4, "branch": "enforcer",    "requires_mastered": ["Commando"]},
	"Demolitionist":     {"tier": 4, "branch": "specialist",  "requires_mastered": ["Engineer"]},
	"Bioforge Tech":     {"tier": 4, "branch": "specialist",  "requires_mastered": ["Medic"]},
	# --- Mastery Professions (require 2 mastered elite classes + quest) ---
	"Deadeye":           {"tier": 5, "branch": "mastery", "mastery_pair": ["Sniper", "Sniper"]},
	"Siege Operator":    {"tier": 5, "branch": "mastery", "mastery_pair": ["Sniper", "Bombardier"]},
	"Wrecker":           {"tier": 5, "branch": "mastery", "mastery_pair": ["Sniper", "Demolitionist"]},
	"Phantom":           {"tier": 5, "branch": "mastery", "mastery_pair": ["Sniper", "Bioforge Tech"]},
	"Huntsman":          {"tier": 5, "branch": "mastery", "mastery_pair": ["Bombardier", "Sniper"]},
	"Warlord":           {"tier": 5, "branch": "mastery", "mastery_pair": ["Bombardier", "Bombardier"]},
	"Saboteur":          {"tier": 5, "branch": "mastery", "mastery_pair": ["Bombardier", "Demolitionist"]},
	"Venomcaster":       {"tier": 5, "branch": "mastery", "mastery_pair": ["Bombardier", "Bioforge Tech"]},
	"Stalker":           {"tier": 5, "branch": "mastery", "mastery_pair": ["Demolitionist", "Sniper"]},
	"Razorback":         {"tier": 5, "branch": "mastery", "mastery_pair": ["Demolitionist", "Bombardier"]},
	"Blastmaster":       {"tier": 5, "branch": "mastery", "mastery_pair": ["Demolitionist", "Demolitionist"]},
	"Plague Engineer":   {"tier": 5, "branch": "mastery", "mastery_pair": ["Demolitionist", "Bioforge Tech"]},
	"Ghost Medic":       {"tier": 5, "branch": "mastery", "mastery_pair": ["Bioforge Tech", "Sniper"]},
	"Warchemist":        {"tier": 5, "branch": "mastery", "mastery_pair": ["Bioforge Tech", "Bombardier"]},
	"Toxinsmith":        {"tier": 5, "branch": "mastery", "mastery_pair": ["Bioforge Tech", "Demolitionist"]},
	"Plague Doctor":     {"tier": 5, "branch": "mastery", "mastery_pair": ["Bioforge Tech", "Bioforge Tech"]}
}



# --- Talent Box Display Names ---

# Structured "what this box grants" data. No tier/rank names appear in
# the UI anywhere -- only ability/weapon names and flat, numeric stat
# numbers (e.g. "+5 Attack Speed", not "+5% Attack Speed").
# Cosmetic display names only -- the underlying path_name keys (used for
# prereqs, weapon certs, ability requires_box, TALENT_SKILL_REWARDS,
# save data, etc.) are untouched. Kept deliberately plain/grounded for
# now; the flashier naming is reserved for future advanced/elite
# professions. Falls back to the raw path_name if a box isn't listed
# here (e.g. Novice/Master, which already display fine as-is).
const TALENT_BOX_DISPLAY_NAMES: Dictionary = {
	"Street Thug": {
		"Melee I": "Dirty Fighting",
		"Melee II": "Brawler's Instinct",
		"Melee III": "Iron Knuckles",
		"Ranged I": "Quickdraw Basics",
		"Ranged II": "Close Quarters",
		"Ranged III": "Steady Aim",
		"Combat Training I": "Combat Drills",
		"Combat Training II": "Target Acquisition",
		"Combat Training III": "Tactical Sense",
		"Weapons Crafting I": "Workbench Basics",
		"Weapons Crafting II": "Fine Tuning",
		"Weapons Crafting III": "Quality Assembly",
		"Medicine Crafting I": "Basic Remedies",
		"Medicine Crafting II": "Refined Formulas",
		"Medicine Crafting III": "Potent Mixtures"
	}
}


# --- Talent Skill Rewards (Talent Viewer "what this grants" data) ---
const TALENT_SKILL_REWARDS: Dictionary = {
	"Street Thug": {
		"Novice": {"type": "novice_grants", "names": [
			"Quick Hit", "Overhead Swing", "Backhand",
			"Ranged Attack",
			"Weapon Cert - Riveted Knuckles",
			"Weapon Cert - Rusty Pistol",
			"Mineral Survey Tool", "Rusty Crafting Kit"
		]},
		"Melee I": {"type": "passive", "stats": [["Unarmed Accuracy", 4], ["Unarmed Speed", 2], ["One Hand Accuracy", 2], ["Two Hand Accuracy", 2]]},
		"Melee II": {"type": "passive", "stats": [["One Hand Accuracy", 4], ["One Hand Speed", 2], ["Unarmed Accuracy", 2], ["Two Hand Accuracy", 2]], "abilities": ["Slap", "Thrust", "Bludgeon"], "weapons": ["Hydraulic Saber", "Steam Baton"]},
		"Melee III": {"type": "passive", "stats": [["Two Hand Accuracy", 4], ["Two Hand Speed", 2], ["One Hand Speed", 2], ["Unarmed Speed", 2]], "weapon": "Compression Sledge"},
		"Ranged I": {"type": "passive", "stats": [["Pistol Accuracy", 4], ["Pistol Speed", 2]], "abilities": ["Aimed Shot"], "weapons": ["Rusty Pistol", "Pneumatic Longrifle", "Pressure Scattergun"]},
		"Ranged II": {"type": "passive", "stats": [["Shotgun Accuracy", 4], ["Shotgun Speed", 2]], "abilities": ["Scatter Blast", "Point-Blank Burst"], "weapons": ["Pneumatic Rifle", "Pneumatic Longrifle"]},
		"Ranged III": {"type": "passive", "stats": [["Rifle Accuracy", 4], ["Rifle Speed", 2]], "abilities": ["Suppressing Fire", "Piercing Round"], "weapons": ["Vented Long-Rifle", "Double-Bore Scattergun", "Copper Lined Gun"]},
		"Combat Training I": {"type": "passive", "stats": [["Attack Speed", 5], ["Crit Chance", 2]], "ability": "Subdue"},
		"Combat Training II": {"type": "passive", "stats": [["Attack Speed", 5], ["Crit Chance", 3]], "ability": "Disorient"},
		"Combat Training III": {"type": "passive", "stats": [["Attack Speed", 5], ["Crit Chance", 3], ["Unarmed Accuracy", 2], ["One Hand Accuracy", 2], ["Two Hand Accuracy", 2]]},
		"Weapons Crafting I": {"type": "passive", "stats": [["Crafting Quality", 3]], "recipe_unlocks": ["Hydraulic Saber", "Steam Baton", "Compression Sledge", "Pneumatic Knuckles"]},
		"Weapons Crafting II": {"type": "passive", "stats": [["Crafting Quality", 3]], "recipe_unlocks": ["Vented Long-Rifle", "Double-Bore Scattergun", "Copper Lined Gun"]},
		"Weapons Crafting III": {"type": "passive", "stats": [["Crafting Quality", 3]], "recipe_unlocks": ["Weapon Muzzle"]},
		"Medicine Crafting I": {"type": "passive", "stats": [["Medicinal Knowledge", 4]], "recipe_unlocks": ["Antiseptic Salve", "Vitality Tonic"]},
		"Medicine Crafting II": {"type": "passive", "stats": [["Medicinal Knowledge", 4]], "recipe_unlocks": ["Syringe", "Adrenaline Shot", "Empty IV Bag"]},
		"Medicine Crafting III": {"type": "passive", "stats": [["Medicinal Knowledge", 4]]},
		"Master": {"type": "passive", "stats": [
			["Unarmed Speed", 4], ["Unarmed Accuracy", 4],
			["One Hand Speed", 4], ["One Hand Accuracy", 4],
			["Two Hand Speed", 4], ["Two Hand Accuracy", 4],
			["Attack Speed", 5], ["Crit Chance", 5]
		], "abilities": ["Roundhouse", "Flourish", "Power Swing", "Bleed", "Bruise", "Anger"]}
	},
	"Enforcer": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Specialist": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Ranger": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Commando": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Engineer": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Medic": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Sniper": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Bombardier": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Demolitionist": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Bioforge Tech": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Deadeye": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Siege Operator": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Wrecker": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Phantom": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Huntsman": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Warlord": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Saboteur": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Venomcaster": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Stalker": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Razorback": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Blastmaster": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Plague Engineer": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Ghost Medic": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Warchemist": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Toxinsmith": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	},
	"Plague Doctor": {
		"Novice": {"type": "novice_grants", "names": []},
		"Master": {"type": "passive", "stats": []}
	}
}
