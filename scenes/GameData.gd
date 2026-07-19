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
var recipes = [
	{
		"name": "Piston Blade",
		"requires": {"Black Iron": 2, "Gunmetal Steel": 4},
		"slot_names": {"Black Iron": "Hilt", "Gunmetal Steel": "Blade"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Piston Blade",
		"item_class": "Sword",
		"item_subclass": "1 Handed",
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Bleed"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Bleed"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Crush"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Arc", "Wound Type": "Stun"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Bruise"},
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
		"requires_profession": "Street Thug"
	},
	{
		"name": "Antiseptic Salve",
		"requires": {"Antiseptic Moss": 2, "Spring Water": 1},
		"output": "Antiseptic Salve",
		"item_class": "Medicine",
		"requires_profession": "Street Thug",
		"requires_box": "Medicine Crafting I"
	},
	{
		"name": "Vitality Tonic",
		"requires": {"Bloomwort": 1, "Torn Cloth": 5},
		"output": "Vitality Tonic",
		"item_class": "Medicine",
		"requires_profession": "Street Thug",
		"requires_box": "Medicine Crafting I"
	},
	{
		"name": "Syringe",
		"requires": {"Plastic": 2},
		"output": "Syringe",
		"item_class": "Component",
		"requires_profession": "Street Thug",
		"requires_box": "Medicine Crafting II"
	},
	{
		"name": "Adrenaline Shot",
		"requires": {"Syringe": 1, "Water": 2, "Healroot": 1},
		"quality_ingredients": ["Water", "Healroot"],
		"output": "Adrenaline Shot",
		"item_class": "Medicine",
		"requires_profession": "Street Thug",
		"requires_box": "Medicine Crafting II"
	},
	{
		"name": "Empty IV Bag",
		"requires": {"Plastic": 3},
		"output": "Empty IV Bag",
		"item_class": "Component",
		"requires_profession": "Street Thug",
		"requires_box": "Medicine Crafting II"
	},
	{
		"name": "Rusty Pistol",
		"requires": {"Gunmetal Steel": 4, "Copper": 2},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Trigger"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Rusty Pistol",
		"item_class": "Pistol",
		"item_subclass": "Pistol",
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Puncture"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Puncture"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Puncture"},
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
		"requires_profession": "Street Thug",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Laceration"},
		"weapon_stat_ranges": {"Speed": [3.5, 2.5], "Damage Rating": [22, 38], "Range": [8, 15], "Ammo Capacity": [4, 8], "Reload Speed": [5.0, 3.5], "Accuracy": [35, 55]}
	},
	{
		"name": "Canister Launcher",
		"requires": {"Gunmetal Steel": 10, "Aluminum": 4, "Crude Oil": 2},
		"slot_names": {"Gunmetal Steel": "Barrel", "Aluminum": "Frame", "Crude Oil": "Propellant"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Canister Launcher",
		"item_class": "Grenade Launcher",
		"item_subclass": "Grenade Launcher",
		"requires_profession": "Ordnance Specialist",
		"weapon_categorical_stats": {"Damage Type": "Pressure", "Wound Type": "Blast"},
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
		"requires_profession": "Ordnance Specialist",
		"weapon_categorical_stats": {"Damage Type": "Thermal", "Wound Type": "Burn"},
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
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting I",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Bleed"},
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
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting I",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Crush"},
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
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting I",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Bruise"},
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
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting I",
		"weapon_categorical_stats": {"Damage Type": "Kinetic", "Wound Type": "Bruise"},
		"weapon_stat_ranges": {"Speed": [2.2, 1.4], "Damage Rating": [12, 22], "Accuracy": [60, 80]}
	},
	{
		"name": "Vented Long-Rifle",
		"requires": {"Gunmetal Steel": 12, "Copper": 4, "Quartz": 3},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Trigger", "Quartz": "Scope"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Vented Long-Rifle",
		"item_class": "Sniper Rifle",
		"item_subclass": "Sniper Rifle",
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting II",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Puncture"},
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
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting II",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Laceration"},
		"weapon_stat_ranges": {"Speed": [4.5, 3.2], "Damage Rating": [35, 60], "Range": [10, 18], "Ammo Capacity": [2, 4], "Reload Speed": [6.0, 4.5], "Accuracy": [35, 55]}
	},
	{
		"name": "Copper Lined Gun",
		"requires": {"Gunmetal Steel": 6, "Copper": 4, "Titanium": 1},
		"slot_names": {"Gunmetal Steel": "Frame", "Copper": "Lining", "Titanium": "Barrel Coating"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Copper Lined Gun",
		"item_class": "Pistol",
		"item_subclass": "Pistol",
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting II",
		"weapon_categorical_stats": {"Damage Type": "Ballistic", "Wound Type": "Puncture"},
		"weapon_stat_ranges": {"Speed": [1.0, 0.5], "Damage Rating": [10, 22], "Range": [20, 32], "Ammo Capacity": [10, 18], "Reload Speed": [2.5, 1.2], "Accuracy": [70, 90]}
	},
	{
		"name": "Pressure-Fed Launcher",
		"requires": {"Gunmetal Steel": 12, "Aluminum": 5, "Crude Oil": 3},
		"slot_names": {"Gunmetal Steel": "Barrel", "Aluminum": "Frame", "Crude Oil": "Propellant"},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.6, "Pliability": 0.4}},
		"output": "Pressure-Fed Launcher",
		"item_class": "Grenade Launcher",
		"item_subclass": "Grenade Launcher",
		"requires_profession": "Ordnance Specialist",
		"weapon_categorical_stats": {"Damage Type": "Pressure", "Wound Type": "Blast"},
		"weapon_stat_ranges": {"Speed": [3.0, 1.8], "Damage Rating": [65, 105], "Range": [35, 65], "Ammo Capacity": [2, 5], "Reload Speed": [4.5, 2.8], "Accuracy": [40, 60]}
	},
	{
		"name": "Mineral Survey Tool",
		"requires": {"Metal": 5},
		"output": "Mineral Survey Tool",
		"item_class": "Tool",
		"requires_profession": "Street Thug"
	},
	{
		"name": "Flora Tool",
		"requires": {"Metal": 5},
		"output": "Flora Tool",
		"item_class": "Tool",
		"requires_profession": "Street Thug"
	},
	{
		"name": "Liquid and Chem Tool",
		"requires": {"Metal": 5},
		"output": "Liquid and Chem Tool",
		"item_class": "Tool",
		"requires_profession": "Street Thug"
	},
	{
		"name": "Rusty Crafting Kit",
		"requires": {"Black Iron": 5, "Copper": 2},
		"output": "Rusty Crafting Kit",
		"item_class": "Tool",
		"requires_profession": "Street Thug"
	},
	{
		"name": "Med Crafting Kit",
		"requires": {"Black Iron": 5, "Copper": 2},
		"output": "Med Crafting Kit",
		"item_class": "Tool",
		"requires_profession": "Street Thug"
	},
	{
		"name": "Weapon Muzzle",
		"requires": {"Gunmetal Steel": 4, "Copper": 1},
		"stat_weights": {"Gunmetal Steel": {"Toughness": 0.5, "Pliability": 0.5}},
		"output": "Weapon Muzzle",
		"item_class": "Component",
		"item_subclass": "Muzzle",
		"requires_profession": "Street Thug",
		"requires_box": "Weapons Crafting III",
		"weapon_stat_ranges": {"Damage Rating Bonus": [2, 6], "Range Bonus": [2, 8]}
	}
]


# --- Weapon Certification Requirements ---
# Novice-tier weapons are certified as soon as Street Thug is learned.
# Advanced weapons require a points investment in the matching keystone
# ("keystone" + "points_required"): spend that many points in the Melee
# or Ranged keystone and every weapon of that type becomes certified.
# Uncertified weapons deal half damage. The 5-point threshold is a
# temporary blanket gate -- later these will be split out so individual
# weapons certify at their own specific nodes/point counts.
const WEAPON_CERT_REQUIREMENTS: Dictionary = {
	"Piston Blade": {"profession": "Street Thug", "box": "Novice"},
	"Piston Greatblade": {"profession": "Street Thug", "box": "Novice"},
	"Pressure Maul": {"profession": "Street Thug", "box": "Novice"},
	"Arc Rod": {"profession": "Street Thug", "box": "Novice"},
	"Riveted Knuckles": {"profession": "Street Thug", "box": "Novice"},
	"Hydraulic Saber": {"profession": "Street Thug", "keystone": "Melee", "points_required": 5},
	"Steam Baton": {"profession": "Street Thug", "keystone": "Melee", "points_required": 5},
	"Compression Sledge": {"profession": "Street Thug", "keystone": "Melee", "points_required": 5},
	"Pneumatic Knuckles": {"profession": "Street Thug", "keystone": "Melee", "points_required": 5},
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
	"Quick Hit": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Overhead Swing": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Bash": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Backhand": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Slap": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 50, "damage_multiplier": 2.5, "requires_profession": "Street Thug", "requires_box": "Melee II"},
	"Thrust": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 50, "damage_multiplier": 2.5, "requires_profession": "Street Thug", "requires_box": "Melee II"},
	"Bludgeon": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 50, "damage_multiplier": 2.5, "requires_profession": "Street Thug", "requires_box": "Melee II"},
	"Roundhouse": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 60, "damage_multiplier": 4.0, "aoe": true, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Flourish": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 60, "damage_multiplier": 4.0, "aoe": true, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Power Swing": {"weapons": ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick", "Baton"], "action_cost": 60, "damage_multiplier": 4.0, "aoe": true, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Subdue": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0.25, "debuff": "damage", "debuff_amount": 0.10, "debuff_duration": 3.0, "requires_profession": "Street Thug", "requires_box": "Combat Training I"},
	"Disorient": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0.25, "debuff": "accuracy", "debuff_amount": 0.05, "debuff_duration": 3.0, "requires_profession": "Street Thug", "requires_box": "Combat Training II"},
	"Bleed": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0.25, "dot_damage_per_tick": 8, "dot_duration_ticks": 3, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Bruise": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0.25, "debuff": "attack_speed", "debuff_amount": 0.20, "debuff_duration": 3.0, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Anger": {"weapons": ["Sword", "Axe", "Baton", "Hammer", "Brass Knuckles", "Stun Stick"], "action_cost": 30, "damage_multiplier": 0.25, "taunt_duration": 3.0, "requires_profession": "Street Thug", "requires_box": "Master"},
	"Aimed Shot": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
	"Scatter Blast": {"weapons": ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"], "action_cost": 35, "damage_multiplier": 1.5, "requires_profession": "Street Thug", "requires_box": "Novice"},
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
			"Melee": {
				"unlocked": false,
				"xp_type": "Combat XP",
				"xp_cost": 500,
				"points_spent": 0,
				"points_max": 10,
				"nodes": {
					# --- Melee Accuracy nodes (5) ---
					"Melee Accuracy 1": {"type": "stat", "cost": 1, "stat": "Melee Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Accuracy 2": {"type": "stat", "cost": 1, "stat": "Melee Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Accuracy 3": {"type": "stat", "cost": 1, "stat": "Melee Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Accuracy 4": {"type": "stat", "cost": 1, "stat": "Melee Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Accuracy 5": {"type": "stat", "cost": 1, "stat": "Melee Accuracy", "amount": 3, "purchased": false, "xp_cost": 150},
					# --- Melee Speed nodes (5) ---
					"Melee Speed 1": {"type": "stat", "cost": 1, "stat": "Melee Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Speed 2": {"type": "stat", "cost": 1, "stat": "Melee Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Speed 3": {"type": "stat", "cost": 1, "stat": "Melee Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Speed 4": {"type": "stat", "cost": 1, "stat": "Melee Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Speed 5": {"type": "stat", "cost": 1, "stat": "Melee Speed", "amount": 3, "purchased": false, "xp_cost": 150},
					# --- Melee Crit Damage nodes (5) ---
					"Melee Crit Damage 1": {"type": "stat", "cost": 1, "stat": "Melee Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Crit Damage 2": {"type": "stat", "cost": 1, "stat": "Melee Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Crit Damage 3": {"type": "stat", "cost": 1, "stat": "Melee Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Crit Damage 4": {"type": "stat", "cost": 1, "stat": "Melee Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					"Melee Crit Damage 5": {"type": "stat", "cost": 1, "stat": "Melee Crit Damage", "amount": 3, "purchased": false, "xp_cost": 150},
					# --- Ability nodes (3, cost 2 each) ---
					"Quick Hit": {
						"type": "ability", "cost": 2, "ability": "Quick Hit", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Quick Hit gains +15% damage and applies a 1s slow"
					},
					"Overhead Swing": {
						"type": "ability", "cost": 2, "ability": "Overhead Swing", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Overhead Swing becomes an AoE hit striking all enemies in melee range"
					},
					"Bash": {
						"type": "ability", "cost": 2, "ability": "Bash", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Bash gains a stun component -- target is stunned for 2s"
					}
				}
			},
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
					"Scatter Blast": {
						"type": "ability", "cost": 2, "ability": "Scatter Blast", "purchased": false, "xp_cost": 300,
						"mastery_upgrade": "Scatter Blast becomes an AoE hitting all enemies in shotgun range"
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
				"points_max": 24,
				"nodes": {
					# --- Melee Defense nodes (3) ---
					"Melee Defense 1": {"type": "stat", "cost": 3, "stat": "Melee Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Melee Defense 2": {"type": "stat", "cost": 3, "stat": "Melee Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Melee Defense 3": {"type": "stat", "cost": 3, "stat": "Melee Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Ranged Defense nodes (3) ---
					"Ranged Defense 1": {"type": "stat", "cost": 3, "stat": "Ranged Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Ranged Defense 2": {"type": "stat", "cost": 3, "stat": "Ranged Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					"Ranged Defense 3": {"type": "stat", "cost": 3, "stat": "Ranged Defense", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Toughness nodes (3) ---
					"Toughness 1": {"type": "stat", "cost": 3, "stat": "Toughness", "amount": 5, "purchased": false, "xp_cost": 150},
					"Toughness 2": {"type": "stat", "cost": 3, "stat": "Toughness", "amount": 5, "purchased": false, "xp_cost": 150},
					"Toughness 3": {"type": "stat", "cost": 3, "stat": "Toughness", "amount": 5, "purchased": false, "xp_cost": 150},
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
					"Movement Speed 3": {"type": "stat", "cost": 3, "stat": "Movement Speed", "amount": 5, "purchased": false, "xp_cost": 150},
					# --- Crafting nodes (16), relocated from the retired
					# Crafting keystone. They keep their own xp_type so they
					# still cost Crafting XP while living inside an otherwise
					# Combat XP keystone. INTERIM: these move again when the
					# universal crafting tree is built.
					# --- Survey Rate nodes (4) ---
					"Survey Rate 1": {"type": "stat", "cost": 3, "stat": "Survey Rate", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Survey Rate 2": {"type": "stat", "cost": 3, "stat": "Survey Rate", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Survey Rate 3": {"type": "stat", "cost": 3, "stat": "Survey Rate", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Survey Rate 4": {"type": "stat", "cost": 3, "stat": "Survey Rate", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					# --- Gear Customization nodes (4) ---
					"Gear Customization 1": {"type": "stat", "cost": 3, "stat": "Gear Customization", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Gear Customization 2": {"type": "stat", "cost": 3, "stat": "Gear Customization", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Gear Customization 3": {"type": "stat", "cost": 3, "stat": "Gear Customization", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Gear Customization 4": {"type": "stat", "cost": 3, "stat": "Gear Customization", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					# --- Crafting Assembly nodes (4) ---
					"Crafting Assembly 1": {"type": "stat", "cost": 3, "stat": "Crafting Assembly", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Crafting Assembly 2": {"type": "stat", "cost": 3, "stat": "Crafting Assembly", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Crafting Assembly 3": {"type": "stat", "cost": 3, "stat": "Crafting Assembly", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Crafting Assembly 4": {"type": "stat", "cost": 3, "stat": "Crafting Assembly", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					# --- Crafting Experimentation nodes (4) ---
					"Crafting Experimentation 1": {"type": "stat", "cost": 3, "stat": "Crafting Experimentation", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Crafting Experimentation 2": {"type": "stat", "cost": 3, "stat": "Crafting Experimentation", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Crafting Experimentation 3": {"type": "stat", "cost": 3, "stat": "Crafting Experimentation", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"},
					"Crafting Experimentation 4": {"type": "stat", "cost": 3, "stat": "Crafting Experimentation", "amount": 5, "purchased": false, "xp_cost": 40, "xp_type": "Crafting XP"}
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
