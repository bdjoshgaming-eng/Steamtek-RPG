extends Node

# ============================================================
# GameData.gd — autoload singleton
# ============================================================
# Pulled out of main.gd (Pass 1 of splitting the file apart) so the
# huge static data tables — recipes, professions, abilities, weapon
# certs, elite prereqs, and display-name lookups — live in one place
# separate from all the runtime game logic. Everything here is still
# read AND written at runtime exactly like before (e.g.
# GameData.novice_professions[...]["unlocked_nodes"] += 1 still works
# the same way it did as a plain script variable) — this is a location
# change, not a behavior change.
#
# Every reference to these identifiers throughout main.gd (and any
# other script) must be prefixed with "GameData." — e.g.
# `novice_professions` became `GameData.novice_professions`.
#
# Setup required once in the Godot editor:
#   Project Settings -> Autoload -> add this file, Node Name "GameData"
# ============================================================

# --- Weapon/Item Recipes ---
var recipes = [
	{
		"name": "Piston Blade",
		"requires": {"Black Iron": 2, "Gunmetal Steel": 4},
		"slot_names": {"Black Iron": "Hilt", "Gunmetal Steel": "Blade"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Piston Blade",
		"item_class": "Sword",
		"item_subclass": "1 Handed",
		"weapon_categorical_stats": {"Damage Type": "Slashing", "Wound Type": "Bleed"},
		"weapon_stat_ranges": {"Speed": [2.8, 1.8], "Damage Rating": [8, 16], "Accuracy": [55, 75]}
	},
	{
		"name": "Piston Greatblade",
		"requires": {"Black Iron": 3, "Gunmetal Steel": 8},
		"slot_names": {"Black Iron": "Hilt", "Gunmetal Steel": "Blade"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Piston Greatblade",
		"item_class": "Sword",
		"item_subclass": "2 Handed",
		"weapon_categorical_stats": {"Damage Type": "Slashing", "Wound Type": "Bleed"},
		"weapon_stat_ranges": {"Speed": [4.0, 3.0], "Damage Rating": [18, 32], "Accuracy": [40, 60]}
	},
	{
		"name": "Pressure Maul",
		"requires": {"Black Iron": 4, "Gunmetal Steel": 10},
		"slot_names": {"Black Iron": "Haft", "Gunmetal Steel": "Head"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Pressure Maul",
		"item_class": "Hammer",
		"item_subclass": "2 Handed",
		"weapon_categorical_stats": {"Damage Type": "Blunt", "Wound Type": "Crush"},
		"weapon_stat_ranges": {"Speed": [4.5, 3.2], "Damage Rating": [20, 36], "Accuracy": [35, 55]}
	},
	{
		"name": "Arc Rod",
		"requires": {"Black Iron": 2, "Copper": 3},
		"slot_names": {"Black Iron": "Shaft", "Copper": "Conductor Tip"},
		"stat_weights": {"Copper": {"Conductivity": 0.7, "Energy": 0.3}},
		"output": "Arc Rod",
		"item_class": "Stun Stick",
		"item_subclass": "1 Handed",
		"weapon_categorical_stats": {"Damage Type": "Blunt", "Wound Type": "Stun"},
		"weapon_stat_ranges": {"Speed": [2.4, 1.6], "Damage Rating": [6, 14], "Accuracy": [55, 75]}
	},
	{
		"name": "Riveted Knuckles",
		"requires": {"Black Iron": 3, "Copper": 2},
		"slot_names": {"Black Iron": "Knuckle Guard", "Copper": "Grip Plating"},
		"stat_weights": {"Black Iron": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Riveted Knuckles",
		"item_class": "Brass Knuckles",
		"item_subclass": "1 Handed",
		"weapon_categorical_stats": {"Damage Type": "Unarmed", "Wound Type": "Bruise"},
		"weapon_stat_ranges": {"Speed": [1.8, 1.0], "Damage Rating": [5, 12], "Accuracy": [65, 85]}
	},
	{
		"name": "Copper Wire",
		"requires": {"Copper": 3},
		"stat_weights": {"Copper": {"Conductivity": 1.0}},
		"output": "Copper Wire"
	},
	{
		"name": "Bread",
		"requires": {"Wheat": 4},
		"stat_weights": {"Wheat": {"Quality": 0.4, "Flavor": 0.4, "Decay": 0.2}},
		"output": "Bread"
	},
	{
		"name": "Bronze Ingot",
		"requires": {"Copper": 3, "Tin": 2},
		"stat_weights": {"Copper": {"Conductivity": 0.4, "Toughness": 0.6}, "Tin": {"Pliability": 0.5, "Toughness": 0.5}},
		"output": "Bronze Ingot"
	},
	{
		"name": "Gold Ring",
		"requires": {"Gold": 3},
		"stat_weights": {"Gold": {"Pliability": 1.0}},
		"output": "Gold Ring"
	},
	{
		"name": "Stone Wall",
		"requires": {"Limestone": 5, "Granite": 2},
		"stat_weights": {"Limestone": {"Density": 0.5, "Toughness": 0.5}, "Granite": {"Density": 0.6, "Toughness": 0.4}},
		"output": "Stone Wall"
	},
	{
		"name": "Rope",
		"requires": {"Weathered Wood": 4},
		"stat_weights": {"Weathered Wood": {"Hardiness": 0.7, "Quality": 0.3}},
		"output": "Rope"
	},
	{
		"name": "Cuprite Talisman",
		"requires": {"Cuprite": 2},
		"stat_weights": {"Cuprite": {"Energy": 0.7, "Conductivity": 0.3}},
		"output": "Cuprite Talisman"
	},
	{
		"name": "Crate of Bandages",
		"requires": {"Torn Cloth": 3, "Lichen": 2},
		"output": "Crate of Bandages",
		"max_charges": 5,
		"item_class": "Medicine",
		"requires_profession": "Apothecary"
	},
	{
		"name": "Antiseptic Salve",
		"requires": {"Antiseptic Moss": 2, "Spring Water": 1},
		"output": "Antiseptic Salve",
		"item_class": "Medicine"
	},
	{
		"name": "Vitality Tonic",
		"requires": {"Bloomwort": 1, "Torn Cloth": 5},
		"output": "Vitality Tonic",
		"item_class": "Medicine"
	},
	{
		"name": "Syringe",
		"requires": {"Plastic": 2},
		"output": "Syringe",
		"item_class": "Component"
	},
	{
		"name": "Adrenaline Shot",
		"requires": {"Syringe": 1, "Water": 2, "Healroot": 1},
		"quality_ingredients": ["Water", "Healroot"],
		"output": "Adrenaline Shot",
		"item_class": "Medicine"
	},
	{
		"name": "Empty IV Bag",
		"requires": {"Plastic": 3},
		"output": "Empty IV Bag",
		"item_class": "Component"
	},
	{
		"name": "Brass-and-Steel Pistol",
		"requires": {"Gunmetal Steel": 4, "Copper": 2},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Trigger"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Brass-and-Steel Pistol",
		"item_class": "Pistol",
		"item_subclass": "Pistol",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Puncture"},
		"weapon_stat_ranges": {"Speed": [1.2, 0.6], "Damage Rating": [6, 14], "Range": [15, 25], "Ammo Capacity": [8, 15], "Reload Speed": [3.0, 1.5], "Accuracy": [65, 85]}
	},
	{
		"name": "Pneumatic Rifle",
		"requires": {"Gunmetal Steel": 10, "Copper": 3, "Aluminum": 3},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Trigger", "Aluminum": "Barrel"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Pneumatic Rifle",
		"item_class": "Assault Rifle",
		"item_subclass": "Assault Rifle",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Puncture"},
		"weapon_stat_ranges": {"Speed": [0.4, 0.15], "Damage Rating": [8, 18], "Range": [40, 70], "Ammo Capacity": [20, 35], "Reload Speed": [3.5, 2.0], "Accuracy": [45, 65]}
	},
	{
		"name": "Pneumatic Longrifle",
		"requires": {"Gunmetal Steel": 9, "Copper": 2, "Quartz": 2},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Trigger", "Quartz": "Scope"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Pneumatic Longrifle",
		"item_class": "Sniper Rifle",
		"item_subclass": "Sniper Rifle",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Puncture"},
		"weapon_stat_ranges": {"Speed": [3.0, 1.8], "Damage Rating": [30, 55], "Range": [100, 160], "Ammo Capacity": [4, 8], "Reload Speed": [4.0, 2.5], "Accuracy": [70, 90]}
	},
	{
		"name": "Pressure Scattergun",
		"requires": {"Gunmetal Steel": 12, "Weathered Wood": 3},
		"slot_names": {"Gunmetal Steel": "Barrel", "Weathered Wood": "Stock"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Pressure Scattergun",
		"item_class": "Shotgun",
		"item_subclass": "Shotgun",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Laceration"},
		"weapon_stat_ranges": {"Speed": [1.8, 1.0], "Damage Rating": [25, 45], "Range": [8, 15], "Ammo Capacity": [4, 8], "Reload Speed": [4.0, 2.5], "Accuracy": [40, 60]}
	},
	{
		"name": "Canister Launcher",
		"requires": {"Gunmetal Steel": 10, "Aluminum": 4, "Crude Oil": 2},
		"slot_names": {"Gunmetal Steel": "Barrel", "Aluminum": "Frame", "Crude Oil": "Propellant"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Canister Launcher",
		"item_class": "Grenade Launcher",
		"item_subclass": "Grenade Launcher",
		"weapon_categorical_stats": {"Damage Type": "Explosive", "Wound Type": "Blast"},
		"weapon_stat_ranges": {"Speed": [3.5, 2.2], "Damage Rating": [50, 90], "Range": [30, 60], "Ammo Capacity": [1, 4], "Reload Speed": [5.0, 3.0], "Accuracy": [35, 55]}
	},
	{
		"name": "Oil Burner",
		"requires": {"Gunmetal Steel": 8, "Copper": 3, "Crude Oil": 5, "Kerosene": 3},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Ignition Coil", "Crude Oil": "Fuel Tank", "Kerosene": "Ignition Fluid"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Oil Burner",
		"item_class": "Flame Thrower",
		"item_subclass": "Flame Thrower",
		"weapon_categorical_stats": {"Damage Type": "Incendiary", "Wound Type": "Burn"},
		"weapon_stat_ranges": {"Speed": [0.3, 0.1], "Damage Rating": [5, 10], "Range": [5, 12], "Ammo Capacity": [50, 100], "Reload Speed": [4.5, 3.0], "Accuracy": [50, 70]}
	},
	{
		"name": "Hydraulic Saber",
		"requires": {"Gunmetal Steel": 6, "Copper": 3, "Titanium": 1},
		"slot_names": {"Gunmetal Steel": "Blade", "Copper": "Piston Line", "Titanium": "Edge Coating"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Hydraulic Saber",
		"item_class": "Sword",
		"item_subclass": "1 Handed",
		"weapon_categorical_stats": {"Damage Type": "Slashing", "Wound Type": "Bleed"},
		"weapon_stat_ranges": {"Speed": [2.4, 1.5], "Damage Rating": [14, 26], "Accuracy": [60, 80]}
	},
	{
		"name": "Compression Sledge",
		"requires": {"Gunmetal Steel": 8, "Black Iron": 3, "Rust": 2},
		"slot_names": {"Black Iron": "Haft", "Gunmetal Steel": "Head", "Rust": "Weighting"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Compression Sledge",
		"item_class": "Hammer",
		"item_subclass": "2 Handed",
		"weapon_categorical_stats": {"Damage Type": "Blunt", "Wound Type": "Crush"},
		"weapon_stat_ranges": {"Speed": [3.6, 2.4], "Damage Rating": [30, 50], "Accuracy": [40, 60]}
	},
	{
		"name": "Pneumatic Knuckles",
		"requires": {"Black Iron": 4, "Copper": 3, "Tin": 1},
		"slot_names": {"Black Iron": "Knuckle Guard", "Copper": "Pressure Line"},
		"stat_weights": {"Black Iron": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Pneumatic Knuckles",
		"item_class": "Brass Knuckles",
		"item_subclass": "1 Handed",
		"weapon_categorical_stats": {"Damage Type": "Unarmed", "Wound Type": "Bruise"},
		"weapon_stat_ranges": {"Speed": [1.5, 0.8], "Damage Rating": [9, 18], "Accuracy": [70, 90]}
	},
	{
		"name": "Steam Baton",
		"requires": {"Weathered Wood": 4, "Copper": 2, "Black Iron": 2},
		"slot_names": {"Weathered Wood": "Haft", "Copper": "Pressure Coil", "Black Iron": "Striking Head"},
		"stat_weights": {"Weathered Wood": {"Hardiness": 0.5, "Pliability": 0.5}},
		"output": "Steam Baton",
		"item_class": "Baton",
		"item_subclass": "1 Handed",
		"weapon_categorical_stats": {"Damage Type": "Blunt", "Wound Type": "Bruise"},
		"weapon_stat_ranges": {"Speed": [2.2, 1.4], "Damage Rating": [12, 22], "Accuracy": [60, 80]}
	},
	{
		"name": "Vented Longrifle",
		"requires": {"Gunmetal Steel": 12, "Copper": 4, "Quartz": 3},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Trigger", "Quartz": "Scope"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Vented Longrifle",
		"item_class": "Sniper Rifle",
		"item_subclass": "Sniper Rifle",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Puncture"},
		"weapon_stat_ranges": {"Speed": [2.6, 1.5], "Damage Rating": [45, 75], "Range": [120, 190], "Ammo Capacity": [5, 10], "Reload Speed": [3.5, 2.2], "Accuracy": [75, 95]}
	},
	{
		"name": "Double-Bore Scattergun",
		"requires": {"Gunmetal Steel": 15, "Weathered Wood": 4, "Aluminum": 2},
		"slot_names": {"Gunmetal Steel": "Barrels", "Weathered Wood": "Stock", "Aluminum": "Frame"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Double-Bore Scattergun",
		"item_class": "Shotgun",
		"item_subclass": "Shotgun",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Laceration"},
		"weapon_stat_ranges": {"Speed": [2.2, 1.3], "Damage Rating": [35, 60], "Range": [10, 18], "Ammo Capacity": [2, 4], "Reload Speed": [4.5, 3.0], "Accuracy": [45, 65]}
	},
	{
		"name": "Pressure-Fed Launcher",
		"requires": {"Gunmetal Steel": 12, "Aluminum": 5, "Crude Oil": 3},
		"slot_names": {"Gunmetal Steel": "Barrel", "Aluminum": "Frame", "Crude Oil": "Propellant"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Pressure-Fed Launcher",
		"item_class": "Grenade Launcher",
		"item_subclass": "Grenade Launcher",
		"weapon_categorical_stats": {"Damage Type": "Explosive", "Wound Type": "Blast"},
		"weapon_stat_ranges": {"Speed": [3.0, 1.8], "Damage Rating": [65, 105], "Range": [35, 65], "Ammo Capacity": [2, 5], "Reload Speed": [4.5, 2.8], "Accuracy": [40, 60]}
	},
	{
		"name": "Mineral Survey Tool",
		"requires": {"Metal": 5},
		"output": "Mineral Survey Tool",
		"item_class": "Tool"
	},
	{
		"name": "Flora Tool",
		"requires": {"Metal": 5},
		"output": "Flora Tool",
		"item_class": "Tool"
	},
	{
		"name": "Steam and Oil Sniffer",
		"requires": {"Metal": 5},
		"output": "Steam and Oil Sniffer",
		"item_class": "Tool"
	},
	{
		"name": "Rusty Crafting Kit",
		"requires": {"Black Iron": 5, "Copper": 2},
		"output": "Rusty Crafting Kit",
		"item_class": "Tool"
	},
	{
		"name": "Weapon Muzzle",
		"requires": {"Gunmetal Steel": 4, "Copper": 1},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Weapon Muzzle",
		"item_class": "Component",
		"item_subclass": "Muzzle",
		"weapon_stat_ranges": {"Damage Rating Bonus": [2, 6], "Range Bonus": [2, 8]}
	}
]


# --- Weapon Certification Requirements ---
# Tier-2 weapons deal half damage until the matching Rank II
# certification box is owned — gives "Weapon Cert" real mechanical
# weight instead of being purely cosmetic.
const WEAPON_CERT_REQUIREMENTS: Dictionary = {
	"Hydraulic Saber": {"profession": "Pressure Enforcer", "box": "One Hand III"},
	"Steam Baton": {"profession": "Pressure Enforcer", "box": "One Hand III"},
	"Compression Sledge": {"profession": "Pressure Enforcer", "box": "Two Hand III"},
	"Pneumatic Knuckles": {"profession": "Pressure Enforcer", "box": "Unarmed III"},
	"Vented Longrifle": {"profession": "Chrome Gunner", "box": "Rifles II"},
	"Double-Bore Scattergun": {"profession": "Chrome Gunner", "box": "Shotguns II"}
	# Pressure-Fed Launcher's cert requirement was removed here — its
	# "Heavy Weapons II" box no longer exists now that the Heavy Weapons
	# tree was retired in favor of Pistols. It's fully effective/
	# uncertified-penalty-free until it gets a new home (see
	# Ordinance Specialist below).
}


# --- Ability Definitions ---
var ability_definitions: Dictionary = {
	"Quick Hit": {"weapons": ["Sword", "Axe", "Baton"], "weapon_category": "One Hand", "action_cost": 35, "damage_multiplier": 1.05, "requires_profession": "Pressure Enforcer", "requires_box": "Novice"},
	"Overhead Swing": {"weapons": ["Sword", "Axe", "Hammer"], "weapon_category": "Two Hand", "action_cost": 35, "damage_multiplier": 1.05, "requires_profession": "Pressure Enforcer", "requires_box": "Novice"},
	"Backhand": {"weapons": ["Brass Knuckles"], "weapon_category": "Unarmed", "action_cost": 35, "damage_multiplier": 1.05, "requires_profession": "Pressure Enforcer", "requires_box": "Novice"},
	"Slap": {"weapons": ["Brass Knuckles"], "weapon_category": "Unarmed", "action_cost": 50, "damage_multiplier": 1.25, "requires_profession": "Pressure Enforcer", "requires_box": "Unarmed II"},
	"Thrust": {"weapons": ["Sword", "Axe", "Baton"], "weapon_category": "One Hand", "action_cost": 50, "damage_multiplier": 1.25, "requires_profession": "Pressure Enforcer", "requires_box": "One Hand II"},
	"Bludgeon": {"weapons": ["Sword", "Axe", "Hammer", "Stun Stick"], "weapon_category": "Two Hand", "action_cost": 50, "damage_multiplier": 1.25, "requires_profession": "Pressure Enforcer", "requires_box": "Two Hand II"},
	"Roundhouse": {"weapons": ["Brass Knuckles"], "weapon_category": "Unarmed", "action_cost": 60, "damage_multiplier": 1.5, "aoe": true, "requires_profession": "Pressure Enforcer", "requires_box": "Unarmed IV"},
	"Flourish": {"weapons": ["Sword", "Axe", "Baton"], "weapon_category": "One Hand", "action_cost": 60, "damage_multiplier": 1.5, "aoe": true, "requires_profession": "Pressure Enforcer", "requires_box": "One Hand IV"},
	"Power Swing": {"weapons": ["Sword", "Axe", "Hammer", "Stun Stick"], "weapon_category": "Two Hand", "action_cost": 60, "damage_multiplier": 1.5, "aoe": true, "requires_profession": "Pressure Enforcer", "requires_box": "Two Hand IV"},
	"Subdue": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0, "debuff": "damage", "debuff_amount": 0.10, "debuff_duration": 3.0, "requires_profession": "Pressure Enforcer", "requires_box": "Martial Training I"},
	"Disorient": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0, "debuff": "accuracy", "debuff_amount": 0.05, "debuff_duration": 3.0, "requires_profession": "Pressure Enforcer", "requires_box": "Martial Training III"},
	"Bleed": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0, "dot_damage_per_tick": 8, "dot_duration_ticks": 3, "requires_profession": "Pressure Enforcer", "requires_box": "Master"},
	"Bruise": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0, "debuff": "attack_speed", "debuff_amount": 0.20, "debuff_duration": 3.0, "requires_profession": "Pressure Enforcer", "requires_box": "Master"},
	"Anger": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0, "taunt_duration": 3.0, "requires_profession": "Pressure Enforcer", "requires_box": "Master"},
	"Aimed Shot": {"weapons": ["Assault Rifle", "Sniper Rifle"], "action_cost": 35, "damage_multiplier": 1.05, "requires_profession": "Chrome Gunner", "requires_box": "Novice"},
	"Scatter Blast": {"weapons": ["Shotgun"], "action_cost": 35, "damage_multiplier": 1.05, "requires_profession": "Chrome Gunner", "requires_box": "Novice"},
	"Suppressing Fire": {"weapons": ["Grenade Launcher", "Flame Thrower"], "action_cost": 35, "damage_multiplier": 1.05, "requires_profession": "Chrome Gunner", "requires_box": "Novice"},
	"Piercing Round": {"weapons": ["Assault Rifle", "Sniper Rifle"], "action_cost": 50, "damage_multiplier": 1.25, "requires_profession": "Chrome Gunner", "requires_box": "Rifles I"},
	"Point-Blank Burst": {"weapons": ["Shotgun"], "action_cost": 50, "damage_multiplier": 1.25, "requires_profession": "Chrome Gunner", "requires_box": "Shotguns I"},
	"Suppressive Volley": {"weapons": ["Assault Rifle", "Sniper Rifle"], "action_cost": 60, "damage_multiplier": 1.5, "aoe": true, "requires_profession": "Chrome Gunner", "requires_box": "Rifles III"},
	"Buckshot Barrage": {"weapons": ["Shotgun"], "action_cost": 60, "damage_multiplier": 1.5, "aoe": true, "requires_profession": "Chrome Gunner", "requires_box": "Shotguns III"}
}


# --- Profession Talent Trees ---
var novice_professions: Dictionary = {
	"Pressure Enforcer": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Martial XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Unarmed I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Unarmed XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Unarmed II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Unarmed XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Unarmed I"},
			"Unarmed III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Unarmed XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Unarmed II"},
			"Unarmed IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Unarmed XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Unarmed III"},

			"One Hand I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "One Hand XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"One Hand II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "One Hand XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "One Hand I"},
			"One Hand III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "One Hand XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "One Hand II"},
			"One Hand IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "One Hand XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "One Hand III"},

			"Two Hand I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Two Hand XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Two Hand II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Two Hand XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Two Hand I"},
			"Two Hand III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Two Hand XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Two Hand II"},
			"Two Hand IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Two Hand XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Two Hand III"},

			"Martial Training I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Martial XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Martial Training II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Martial XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Martial Training I"},
			"Martial Training III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Martial XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Martial Training II"},
			"Martial Training IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Martial XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Martial Training III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Pressure Enforcer Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},
	"Chrome Gunner": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ranged Weapon", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Pistols I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Pistol XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Pistols II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Pistol XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Pistols I"},
			"Pistols III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Pistol XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Pistols II"},
			"Pistols IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Pistol XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Pistols III"},

			"Shotguns I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Shotgun XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Shotguns II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Shotgun XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Shotguns I"},
			"Shotguns III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Shotgun XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Shotguns II"},
			"Shotguns IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Shotgun XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Shotguns III"},

			"Rifles I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Rifle XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Rifles II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Rifle XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Rifles I"},
			"Rifles III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Rifle XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Rifles II"},
			"Rifles IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Rifle XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Rifles III"},

			"Ranged Training I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ranged Weapon", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Ranged Training II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ranged Weapon", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Ranged Training I"},
			"Ranged Training III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ranged Weapon", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Ranged Training II"},
			"Ranged Training IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ranged Weapon", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Ranged Training III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Chrome Gunner Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},
	"Scrap Tinkerer": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scanning", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Scanning I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scanning", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Scanning II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scanning", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Scanning I"},
			"Scanning III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scanning", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Scanning II"},
			"Scanning IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scanning", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Scanning III"},

			"Sampling I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sampling", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Sampling II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sampling", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Sampling I"},
			"Sampling III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sampling", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Sampling II"},
			"Sampling IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sampling", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Sampling III"},

			"Crafting I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Crafting", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Crafting II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Crafting", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Crafting I"},
			"Crafting III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Crafting", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Crafting II"},
			"Crafting IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Crafting", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Crafting III"},

			"Fabrication Mastery I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fabrication", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Fabrication Mastery II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fabrication", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Fabrication Mastery I"},
			"Fabrication Mastery III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fabrication", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Fabrication Mastery II"},
			"Fabrication Mastery IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fabrication", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Fabrication Mastery III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scrap Tinkerer Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},
	"Apothecary": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Healing XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Healing I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Healing XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Healing II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Healing XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Healing I"},
			"Healing III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Healing XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Healing II"},
			"Healing IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Healing XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Healing III"},

			"Medicine Crafting I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Medicine Crafting II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Medicine Crafting I"},
			"Medicine Crafting III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Medicine Crafting II"},
			"Medicine Crafting IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Medicine Crafting III"},

			"Medical Foraging I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scavenging XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Medical Foraging II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scavenging XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Medical Foraging I"},
			"Medical Foraging III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scavenging XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Medical Foraging II"},
			"Medical Foraging IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Scavenging XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Medical Foraging III"},

			"Stims I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Stims II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Stims I"},
			"Stims III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Stims II"},
			"Stims IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Medicine Crafting XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Stims III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Apothecary Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},

	# --- Elite Professions ---
	# Placeholder skeletons only, matching the base four professions'
	# shape exactly (Novice, 4 ranked columns, Master) so they show up
	# correctly in the Talent Viewer and are functionally purchasable
	# node-by-node — but no TALENT_SKILL_REWARDS entries exist for any
	# of these yet, so every box just displays "Not yet designed" /
	# "Reserved for future stats" until they're actually designed.
	# Entry into each is gated by ELITE_PROFESSION_PREREQS below.
	"Sniper": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sniper Training XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Optics I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Optics XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Optics II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Optics XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Optics I"},
			"Optics III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Optics XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Optics II"},
			"Optics IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Optics XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Optics III"},

			"Concealment I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Concealment XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Concealment II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Concealment XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Concealment I"},
			"Concealment III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Concealment XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Concealment II"},
			"Concealment IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Concealment XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Concealment III"},

			"Longshot I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Longshot XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Longshot II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Longshot XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Longshot I"},
			"Longshot III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Longshot XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Longshot II"},
			"Longshot IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Longshot XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Longshot III"},

			"Sniper Training I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sniper Training XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Sniper Training II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sniper Training XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Sniper Training I"},
			"Sniper Training III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sniper Training XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Sniper Training II"},
			"Sniper Training IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sniper Training XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Sniper Training III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Sniper Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},
	"Ordnance Specialist": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ordnance Training XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Explosives I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Explosives XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Explosives II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Explosives XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Explosives I"},
			"Explosives III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Explosives XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Explosives II"},
			"Explosives IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Explosives XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Explosives III"},

			"Incendiaries I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Incendiaries XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Incendiaries II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Incendiaries XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Incendiaries I"},
			"Incendiaries III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Incendiaries XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Incendiaries II"},
			"Incendiaries IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Incendiaries XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Incendiaries III"},

			"Deployment I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Deployment XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Deployment II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Deployment XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Deployment I"},
			"Deployment III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Deployment XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Deployment II"},
			"Deployment IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Deployment XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Deployment III"},

			"Ordnance Training I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ordnance Training XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Ordnance Training II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ordnance Training XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Ordnance Training I"},
			"Ordnance Training III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ordnance Training XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Ordnance Training II"},
			"Ordnance Training IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ordnance Training XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Ordnance Training III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Ordnance Specialist Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},
	"Quickdraw Technician": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Quickdraw Training XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Trigger Discipline I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Trigger Discipline XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Trigger Discipline II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Trigger Discipline XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Trigger Discipline I"},
			"Trigger Discipline III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Trigger Discipline XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Trigger Discipline II"},
			"Trigger Discipline IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Trigger Discipline XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Trigger Discipline III"},

			"Dual Wielding I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Dual Wielding XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Dual Wielding II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Dual Wielding XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Dual Wielding I"},
			"Dual Wielding III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Dual Wielding XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Dual Wielding II"},
			"Dual Wielding IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Dual Wielding XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Dual Wielding III"},

			"Fast Draw I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fast Draw XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Fast Draw II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fast Draw XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Fast Draw I"},
			"Fast Draw III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fast Draw XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Fast Draw II"},
			"Fast Draw IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Fast Draw XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Fast Draw III"},

			"Quickdraw Training I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Quickdraw Training XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Quickdraw Training II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Quickdraw Training XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Quickdraw Training I"},
			"Quickdraw Training III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Quickdraw Training XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Quickdraw Training II"},
			"Quickdraw Training IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Quickdraw Training XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Quickdraw Training III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Quickdraw Technician Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	},
	"Toxinsmith": {
		"paths": {
			"Novice": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxinsmith Training XP", "xp_cost": 0, "point_cost": 0, "cogs_cost": 0, "requires": ""},

			"Toxins I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxins XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Toxins II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxins XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Toxins I"},
			"Toxins III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxins XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Toxins II"},
			"Toxins IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxins XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Toxins III"},

			"Compounds I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Compounds XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Compounds II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Compounds XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Compounds I"},
			"Compounds III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Compounds XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Compounds II"},
			"Compounds IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Compounds XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Compounds III"},

			"Delivery Systems I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Delivery Systems XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Delivery Systems II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Delivery Systems XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Delivery Systems I"},
			"Delivery Systems III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Delivery Systems XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Delivery Systems II"},
			"Delivery Systems IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Delivery Systems XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Delivery Systems III"},

			"Toxinsmith Training I": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxinsmith Training XP", "xp_cost": 1, "point_cost": 1, "cogs_cost": 1, "requires": ""},
			"Toxinsmith Training II": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxinsmith Training XP", "xp_cost": 1, "point_cost": 2, "cogs_cost": 1, "requires": "Toxinsmith Training I"},
			"Toxinsmith Training III": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxinsmith Training XP", "xp_cost": 1, "point_cost": 3, "cogs_cost": 1, "requires": "Toxinsmith Training II"},
			"Toxinsmith Training IV": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxinsmith Training XP", "xp_cost": 1, "point_cost": 4, "cogs_cost": 1, "requires": "Toxinsmith Training III"},

			"Master": {"unlocked_nodes": 0, "max_nodes": 1, "xp_type": "Toxinsmith Mastery XP", "xp_cost": 0, "point_cost": 5, "cogs_cost": 5, "requires": "__ALL__"}
		}
	}
}


# --- Weapon Category Groupings ---
var pressure_enforcer_weapons = ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"]
var chrome_gunner_weapons = ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"]
var rifle_weapons = ["Assault Rifle", "Sniper Rifle"]
var shotgun_weapons = ["Shotgun"]
var heavy_weapon_types = ["Grenade Launcher", "Flame Thrower"]


# --- Elite Profession Prerequisites ---
# a real, already-existing profession/box pair. Checked in
# _on_choose_profession_pressed before a profession can be selected;
# these are the only gates on Elite Professions right now (no
# abilities/stats/certs have been designed for them yet).
const ELITE_PROFESSION_PREREQS: Dictionary = {
	"Sniper": [
		{"profession": "Chrome Gunner", "box": "Rifles IV"},
		{"profession": "Chrome Gunner", "box": "Ranged Training IV"}
	],
	"Ordnance Specialist": [
		{"profession": "Chrome Gunner", "box": "Master"}
	],
	"Quickdraw Technician": [
		{"profession": "Chrome Gunner", "box": "Pistols IV"},
		{"profession": "Chrome Gunner", "box": "Ranged Training IV"}
	],
	"Toxinsmith": [
		{"profession": "Apothecary", "box": "Master"},
		{"profession": "Chrome Gunner", "box": "Shotguns IV"}
	]
}


# --- Talent Box Display Names ---

# Structured "what this box grants" data. No tier/rank names appear in
# the UI anywhere — only ability/weapon names and flat, numeric stat
# numbers (e.g. "+5 Attack Speed", not "+5% Attack Speed").
# Cosmetic display names only — the underlying path_name keys (used for
# prereqs, weapon certs, ability requires_box, TALENT_SKILL_REWARDS,
# save data, etc.) are untouched. Kept deliberately plain/grounded for
# now; the flashier naming is reserved for future advanced/elite
# professions. Falls back to the raw path_name if a box isn't listed
# here (e.g. Novice/Master, which already display fine as-is).
const TALENT_BOX_DISPLAY_NAMES: Dictionary = {
	"Pressure Enforcer": {
		"Unarmed I": "Dirty Fighting", "Unarmed II": "Brawler's Instinct", "Unarmed III": "Iron Knuckles", "Unarmed IV": "Unarmed Mastery",
		"One Hand I": "Balanced Grip", "One Hand II": "Practiced Strikes", "One Hand III": "Precision Training", "One Hand IV": "One Handed Mastery",
		"Two Hand I": "Heavy Hands", "Two Hand II": "Crushing Grip", "Two Hand III": "Sledge Work", "Two Hand IV": "Two Hand Mastery",
		"Martial Training I": "Combat Drills", "Martial Training II": "Battle Focus", "Martial Training III": "Tactical Sense", "Martial Training IV": "Martial Mastery"
	},
	"Chrome Gunner": {
		"Pistols I": "Quickdraw Basics", "Pistols II": "Suppressor Fit", "Pistols III": "Rapid Cycling", "Pistols IV": "Pistol Mastery",
		"Shotguns I": "Close Quarters", "Shotguns II": "Wide Spread", "Shotguns III": "Breach Tactics", "Shotguns IV": "Shotgun Mastery",
		"Rifles I": "Steady Aim", "Rifles II": "Long Sightlines", "Rifles III": "Marksmanship", "Rifles IV": "Rifle Mastery",
		"Ranged Training I": "Weapon Handling", "Ranged Training II": "Target Acquisition", "Ranged Training III": "Combat Reflexes", "Ranged Training IV": "Ranged Mastery"
	},
	"Scrap Tinkerer": {
		"Scanning I": "Basic Readings", "Scanning II": "Signal Tracing", "Scanning III": "Deep Scan", "Scanning IV": "Scanning Mastery",
		"Sampling I": "Quick Extraction", "Sampling II": "Steady Hands", "Sampling III": "Efficient Harvest", "Sampling IV": "Sampling Mastery",
		"Crafting I": "Workbench Basics", "Crafting II": "Fine Tuning", "Crafting III": "Quality Assembly", "Crafting IV": "Crafting Mastery",
		"Fabrication Mastery I": "Parts Efficiency", "Fabrication Mastery II": "Waste Reduction", "Fabrication Mastery III": "Efficient Output", "Fabrication Mastery IV": "Master Fabricator"
	},
	"Apothecary": {
		"Healing I": "Basic Salves", "Healing II": "Steady Drip", "Healing III": "Advanced Compounds", "Healing IV": "Vapor Therapy",
		"Medicine Crafting I": "Basic Remedies", "Medicine Crafting II": "Refined Formulas", "Medicine Crafting III": "Potent Mixtures", "Medicine Crafting IV": "Master Chemist",
		"Medical Foraging I": "Herb Sense", "Medical Foraging II": "Keen Eye", "Medical Foraging III": "Efficient Gathering", "Medical Foraging IV": "Foraging Mastery",
		"Stims I": "Quick Boost", "Stims II": "Focused Dose", "Stims III": "Sustained Boost", "Stims IV": "Stim Mastery"
	}
}


# --- Talent Skill Rewards (Talent Viewer "what this grants" data) ---
const TALENT_SKILL_REWARDS: Dictionary = {
	"Pressure Enforcer": {
		"Novice": {"type": "novice_grants", "names": ["Quick Hit", "Overhead Swing", "Backhand", "Weapon Cert - Piston Blade", "Weapon Cert - Piston Greatblade", "Weapon Cert - Pressure Maul", "Weapon Cert - Arc Rod", "Weapon Cert - Riveted Knuckles"]},
		"Unarmed I": {"type": "passive", "stats": [["Unarmed Accuracy", 4], ["Unarmed Speed", 2]]},
		"Unarmed II": {"type": "passive", "stats": [["Unarmed Accuracy", 4], ["Unarmed Speed", 2]], "ability": "Slap"},
		"Unarmed III": {"type": "passive", "stats": [["Unarmed Accuracy", 4], ["Unarmed Speed", 2]], "weapon": "Pneumatic Knuckles"},
		"Unarmed IV": {"type": "passive", "stats": [["Unarmed Accuracy", 4], ["Unarmed Speed", 2]], "ability": "Roundhouse"},
		"One Hand I": {"type": "passive", "stats": [["One Hand Accuracy", 4], ["One Hand Speed", 2]]},
		"One Hand II": {"type": "passive", "stats": [["One Hand Accuracy", 4], ["One Hand Speed", 2]], "ability": "Thrust"},
		"One Hand III": {"type": "passive", "stats": [["One Hand Accuracy", 4], ["One Hand Speed", 2]], "weapons": ["Hydraulic Saber", "Steam Baton"]},
		"One Hand IV": {"type": "passive", "stats": [["One Hand Accuracy", 4], ["One Hand Speed", 2]], "ability": "Flourish"},
		"Two Hand I": {"type": "passive", "stats": [["Two Hand Accuracy", 4], ["Two Hand Speed", 2]]},
		"Two Hand II": {"type": "passive", "stats": [["Two Hand Accuracy", 4], ["Two Hand Speed", 2]], "ability": "Bludgeon"},
		"Two Hand III": {"type": "passive", "stats": [["Two Hand Accuracy", 4], ["Two Hand Speed", 2]], "weapon": "Compression Sledge"},
		"Two Hand IV": {"type": "passive", "stats": [["Two Hand Accuracy", 4], ["Two Hand Speed", 2]], "ability": "Power Swing"},
		"Martial Training I": {"type": "passive", "stats": [], "ability": "Subdue"},
		"Martial Training II": {"type": "passive", "stats": []},
		"Martial Training III": {"type": "passive", "stats": [], "ability": "Disorient"},
		"Martial Training IV": {"type": "passive", "stats": []},
		"Master": {"type": "passive", "stats": [["Unarmed Speed", 2], ["Unarmed Accuracy", 4], ["One Hand Speed", 2], ["One Hand Accuracy", 4], ["Two Hand Speed", 2], ["Two Hand Accuracy", 4]], "abilities": ["Bleed", "Bruise", "Anger"]}
	},
	"Chrome Gunner": {
		"Novice": {"type": "novice_grants", "names": ["Aimed Shot", "Scatter Blast", "Suppressing Fire"]},
		"Pistols I": {"type": "passive", "stats": []},
		"Pistols II": {"type": "passive", "stats": []},
		"Pistols III": {"type": "passive", "stats": []},
		"Pistols IV": {"type": "passive", "stats": []},
		"Shotguns I": {"type": "ability", "name": "Point-Blank Burst"},
		"Shotguns II": {"type": "weapon", "name": "Double-Bore Scattergun"},
		"Shotguns III": {"type": "ability", "name": "Buckshot Barrage"},
		"Rifles I": {"type": "ability", "name": "Piercing Round"},
		"Rifles II": {"type": "weapon", "name": "Vented Longrifle"},
		"Rifles III": {"type": "ability", "name": "Suppressive Volley"},
		"Ranged Training I": {"type": "passive", "stats": [["Attack Speed", 5], ["Crit Chance", 3]]},
		"Ranged Training II": {"type": "passive", "stats": [["Attack Speed", 5], ["Crit Chance", 3]]},
		"Ranged Training III": {"type": "passive", "stats": [["Attack Speed", 5], ["Crit Chance", 3]]},
		"Master": {"type": "ability", "name": "Bleeding"}
	},
	"Scrap Tinkerer": {
		"Novice": {"type": "novice_grants", "names": ["Mineral Survey Tool", "Flora Tool", "Steam and Oil Sniffer", "Rusty Crafting Kit"]},
		"Scanning I": {"type": "passive", "stats": [["Scan Concentration", 5]]},
		"Scanning II": {"type": "passive", "stats": [["Scan Concentration", 5]]},
		"Scanning III": {"type": "passive", "stats": [["Scan Concentration", 5]]},
		"Sampling I": {"type": "passive", "stats": [["Sample Speed", 10]]},
		"Sampling II": {"type": "passive", "stats": [["Sample Speed", 10]]},
		"Sampling III": {"type": "passive", "stats": [["Sample Speed", 10]]},
		"Crafting I": {"type": "passive", "stats": [["Crafting Quality", 3]]},
		"Crafting II": {"type": "passive", "stats": [["Crafting Quality", 3]]},
		"Crafting III": {"type": "passive", "stats": [["Crafting Quality", 3]]},
		"Fabrication Mastery I": {"type": "passive", "stats": [["Scan Concentration", 2], ["Sample Speed", 5], ["Crafting Quality", 1]]},
		"Fabrication Mastery II": {"type": "passive", "stats": [["Scan Concentration", 2], ["Sample Speed", 5], ["Crafting Quality", 1]]},
		"Fabrication Mastery III": {"type": "passive", "stats": [["Scan Concentration", 2], ["Sample Speed", 5], ["Crafting Quality", 1]]},
		"Master": {"type": "ability", "name": "Overclock"}
	},
	"Apothecary": {
		"Novice": {"type": "novice_grants", "names": ["Apply Bandage"]},
		"Healing I": {"type": "passive", "stats": [["Healing Speed", 2], ["Healing Knowledge", 2]]},
		"Healing II": {"type": "passive", "stats": [["Wound Care", 4]], "ability": "IV Drip"},
		"Healing III": {"type": "passive", "stats": [["Wound Care", 4]]},
		"Healing IV": {"type": "passive", "stats": [["Wound Care", 2]], "ability": "Healing Vapor"},
		"Medicine Crafting I": {"type": "passive", "stats": [["Medicinal Knowledge", 4]]},
		"Medicine Crafting II": {"type": "passive", "stats": [["Medicinal Knowledge", 4]]},
		"Medicine Crafting III": {"type": "passive", "stats": [["Medicinal Knowledge", 4]]},
		"Medicine Crafting IV": {"type": "passive", "stats": [["Medicine Potency", 2]]},
		"Medical Foraging I": {"type": "passive", "stats": [["Foraging Chance", 1]]},
		"Medical Foraging II": {"type": "passive", "stats": [["Foraging Chance", 1]]},
		"Medical Foraging III": {"type": "passive", "stats": [["Foraging Chance", 1]]},
		"Medical Foraging IV": {"type": "passive", "stats": [["Foraging Chance", 1]]},
		"Stims I": {"type": "passive", "stats": [], "ability": "Adrenaline Boost"},
		"Stims II": {"type": "passive", "stats": []},
		"Stims III": {"type": "passive", "stats": [], "ability": "Blood Bag"},
		"Stims IV": {"type": "passive", "stats": []},
		"Master": {"type": "ability", "name": "Panacea"}
	}
}
