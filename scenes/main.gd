extends Node2D

# ============================================================
# Static game data (recipes, professions, abilities, weapon certs,
# elite prereqs, talent display names/rewards) now lives in
# GameData.gd, an autoload singleton (Pass 1 of splitting this file
# apart). Every reference to those tables below is prefixed with
# 'GameData.' -- e.g. GameData.novice_professions.
# ============================================================

@onready var resource_tree: Tree = $UILayer/SurveyUI/ResourceTree
@onready var sample_message_label: Label = $UILayer/SurveyUI/SampleMessageLabel
@onready var inventory_label: Label = $UILayer/InventoryLabel
@onready var player: CharacterBody2D = %Player
@onready var player_hud: Node2D = %PlayerHUD
@onready var enemy_hud: Node2D = %EnemyHUD
@onready var enemy_hud_health_bar_bg: Polygon2D = %EnemyHUDHealthBarBg
@onready var enemy_hud_health_bar_fill: Polygon2D = %EnemyHUDHealthBarFill
@onready var enemy_hud_action_bar_bg: Polygon2D = %EnemyHUDActionBarBg
@onready var enemy_hud_action_bar_fill: Polygon2D = %EnemyHUDActionBarFill
@onready var player_hud_health_label: Label = %PlayerHUDHealthLabel
@onready var player_hud_action_label: Label = %PlayerHUDActionLabel
@onready var enemy_hud_health_label: Label = %EnemyHUDHealthLabel
@onready var enemy_hud_action_label: Label = %EnemyHUDActionLabel


# --- Phase 6b: enemy node registry ---
# Maps each enemy id to its scene nodes, timers and per-enemy constants.
# Built once in _ready() by _build_enemy_node_registry() so every enemy
# code path can be written ONCE against an enemy_id instead of being
# duplicated per enemy. Phase 6c replaces these hand-wired scene nodes
# with runtime-instanced ones; until then this is the seam that lets the
# rest of main.gd stop caring which enemy it is dealing with.
var enemy_nodes: Dictionary = {}

# --- Runtime enemy spawning (Phase 6c) ------------------------------
# Enemies are no longer hand-placed nodes in main.tscn. Each entry here
# is instantiated from Enemy.tscn at startup and wired up in code, so
# adding an enemy is a TABLE ENTRY, not editor work plus a dozen
# @onready declarations.
const ENEMY_SCENE_PATH := "res://scenes/enemy.tscn"
const ENEMY_SPRITE_PATH := "res://pipo-enemy018.png"

# AI defaults. Per-enemy overrides in the spawn table take priority.
const DEFAULT_AGGRO_RANGE := 300.0
const DEFAULT_CHASE_SPEED := 80.0
const DEFAULT_LEASH_RANGE := 500.0
const DEFAULT_PATROL_RADIUS := 60.0
const LEASH_HEAL_RATE := 0.15

const ENEMY_SPAWN_TABLE: Dictionary = {
	"dummy": {
		"display_name": "Scrap Thief",
		"cl": 1,
		"archetype": "brawler",
		"faction": "rust_syndicate",
		"position": Vector2(400, 300),
		"sprite_scale": Vector2(0.16875005, 0.18072915),
		"tint": Color(1, 1, 1, 1),
		"kill_xp": 50,
		"loot_key": "Dummy",
		"attack_cooldown": 2.5,
		"respawn_time": 8.0,
		"aggro_range": 280.0,
		"chase_speed": 70.0,
		"nm": {
			"display_name": "Ironjaw",
			"cl": 5,
			"tint": Color(1.0, 0.45, 0.0, 1),
			"kill_xp": 250,
			"loot_key": "NM_Ironjaw",
			"spawn_chance": 0.05,
		},
	},
	"enemy2": {
		"display_name": "Rust Marauder",
		"cl": 5,
		"archetype": "assault",
		"faction": "rust_syndicate",
		"position": Vector2(800, 125),
		"sprite_scale": Vector2(0.181, 0.181),
		"tint": Color(0.09019608, 0.5019608, 1, 1),
		"kill_xp": 67,
		"loot_key": "Enemy2",
		"attack_cooldown": 2.5,
		"respawn_time": 8.0,
		"aggro_range": 320.0,
		"chase_speed": 90.0,
	},
	"heavy_cl12": {
		"display_name": "Blackline Enforcer",
		"cl": 12,
		"archetype": "Heavy",
		"faction": "Blackline Security",
		"position": Vector2(1100, 300),
		"sprite_scale": Vector2(0.181, 0.181),
		"tint": Color(0.85, 0.2, 0.2, 1),
		"kill_xp": 200,
		"loot_key": "Enemy2",
		"attack_cooldown": 2.5,
		"respawn_time": 8.0,
		"aggro_range": 350.0,
		"chase_speed": 60.0,
		"leash_range": 600.0,
	},
}

const LAIR_SPAWN_TABLE: Dictionary = {
	"rust_outpost": {
		"lair_type": "rust_outpost",
		"display_name": "Rust Syndicate Outpost",
		"center": Vector2(250, 600),
		"spawn_radius": 100.0,
		"respawn_time": 30.0,
		"nm": {
			"display_name": "Rusty Pete",
			"cl": 6,
			"archetype": "Brawler",
			"faction": "Rust Syndicate",
			"tint": Color(1.0, 0.3, 0.1, 1),
			"kill_xp": 300,
			"loot_key": "NM_RustyPete",
			"spawn_chance": 0.05,
			"replaces_index": 0,
		},
		"members": [
			{
				"display_name": "Rust Scrapper",
				"cl": 2,
				"archetype": "Brawler",
				"faction": "Rust Syndicate",
				"sprite_scale": Vector2(0.155, 0.165),
				"tint": Color(0.85, 0.75, 0.55, 1),
				"kill_xp": 35,
				"loot_key": "Dummy",
				"attack_cooldown": 2.8,
				"aggro_range": 250.0,
				"chase_speed": 65.0,
			},
			{
				"display_name": "Rust Scrapper",
				"cl": 2,
				"archetype": "Brawler",
				"faction": "Rust Syndicate",
				"sprite_scale": Vector2(0.155, 0.165),
				"tint": Color(0.85, 0.75, 0.55, 1),
				"kill_xp": 35,
				"loot_key": "Dummy",
				"attack_cooldown": 2.8,
				"aggro_range": 250.0,
				"chase_speed": 65.0,
			},
			{
				"display_name": "Rust Scrapper",
				"cl": 2,
				"archetype": "Brawler",
				"faction": "Rust Syndicate",
				"sprite_scale": Vector2(0.155, 0.165),
				"tint": Color(0.85, 0.75, 0.55, 1),
				"kill_xp": 35,
				"loot_key": "Dummy",
				"attack_cooldown": 2.8,
				"aggro_range": 250.0,
				"chase_speed": 65.0,
			},
			{
				"display_name": "Rust Foreman",
				"cl": 4,
				"archetype": "Assault",
				"faction": "Rust Syndicate",
				"sprite_scale": Vector2(0.175, 0.185),
				"tint": Color(0.7, 0.55, 0.35, 1),
				"kill_xp": 60,
				"loot_key": "Dummy",
				"attack_cooldown": 2.3,
				"aggro_range": 300.0,
				"chase_speed": 75.0,
			},
		],
	},
	"blackline_checkpoint": {
		"lair_type": "blackline_checkpoint",
		"display_name": "Blackline Checkpoint",
		"center": Vector2(1400, 400),
		"spawn_radius": 90.0,
		"respawn_time": 45.0,
		"nm": {
			"display_name": "Sergeant Volkov",
			"cl": 14,
			"archetype": "Commander",
			"faction": "Blackline Security",
			"tint": Color(0.8, 0.1, 0.1, 1),
			"kill_xp": 500,
			"loot_key": "NM_Volkov",
			"spawn_chance": 0.04,
			"replaces_index": 0,
		},
		"members": [
			{
				"display_name": "Blackline Sentry",
				"cl": 8,
				"archetype": "Rifleman",
				"faction": "Blackline Security",
				"sprite_scale": Vector2(0.17, 0.18),
				"tint": Color(0.4, 0.45, 0.55, 1),
				"kill_xp": 120,
				"loot_key": "Enemy2",
				"attack_cooldown": 2.2,
				"aggro_range": 350.0,
				"chase_speed": 75.0,
			},
			{
				"display_name": "Blackline Sentry",
				"cl": 8,
				"archetype": "Rifleman",
				"faction": "Blackline Security",
				"sprite_scale": Vector2(0.17, 0.18),
				"tint": Color(0.4, 0.45, 0.55, 1),
				"kill_xp": 120,
				"loot_key": "Enemy2",
				"attack_cooldown": 2.2,
				"aggro_range": 350.0,
				"chase_speed": 75.0,
			},
			{
				"display_name": "Blackline Lieutenant",
				"cl": 10,
				"archetype": "Commander",
				"faction": "Blackline Security",
				"sprite_scale": Vector2(0.185, 0.195),
				"tint": Color(0.3, 0.35, 0.5, 1),
				"kill_xp": 180,
				"loot_key": "Enemy2",
				"attack_cooldown": 2.0,
				"aggro_range": 380.0,
				"chase_speed": 80.0,
				"leash_range": 550.0,
			},
		],
	},
}

@onready var player_health_bar_bg: Polygon2D = %PlayerHealthBarBg
@onready var player_health_bar_fill: Polygon2D = %PlayerHealthBarFill
@onready var player_action_bar_bg: Polygon2D = %PlayerActionBarBg
@onready var player_action_bar_fill: Polygon2D = %PlayerActionBarFill


@onready var trainer: Node2D = %Trainer
@onready var trainer_sprite: CanvasItem = %Trainer/CharacterVisual/Visual
@onready var trainer_name_label: Label = %Trainer/NameLabel
@onready var trainer2: Node2D = %Trainer2
@onready var trainer2_sprite: Sprite2D = %Trainer2Sprite
@onready var trainer2_name_label: Label = %Trainer2NameLabel
@onready var trainer3: Node2D = %Trainer3
@onready var trainer3_sprite: Sprite2D = %Trainer3Sprite
@onready var trainer3_name_label: Label = %Trainer3NameLabel
@onready var trainer4: Node2D = %Trainer4
@onready var trainer4_sprite: Sprite2D = %Trainer4Sprite
@onready var trainer4_name_label: Label = %Trainer4NameLabel
@onready var trainer_ui: Control = $TrainerUI
@onready var dialogue_layout: VBoxContainer = $TrainerUI/DialogueLayout
@onready var train_info_label: Label = $TrainerUI/DialogueLayout/TrainInfoLabel
@onready var trainer_options: VBoxContainer = $TrainerUI/DialogueLayout/TrainerOptions
@onready var train_result_label: Label = $TrainerUI/DialogueLayout/TrainResultLabel
@onready var dumpster: Node2D = %Dumpster
@onready var dumpster_visual: Polygon2D = %DumpsterVisual
@onready var quest_book: Node2D = %QuestBook
@onready var quest_book_visual: Polygon2D = %QuestBookVisual

var quest_system: Node
@onready var dumpster_cooldown_timer: Timer = $DumpsterCooldownTimer
@onready var bandage_cooldown_timer: Timer = $BandageCooldownTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var player_respawn_timer: Timer = $PlayerRespawnTimer
@onready var player_regen_timer: Timer = $PlayerRegenTimer
@onready var player_action_regen_timer: Timer = $PlayerActionRegenTimer
@onready var combat_message_label: Label = $UILayer/CombatMessageLabel
var enemy_combat_message_label: Label
@onready var message_clear_timer: Timer = $MessageClearTimer
@onready var xp_gain_label: Label = $UILayer/XPGainLabel
@onready var xp_gain_clear_timer: Timer = $XPGainClearTimer
@onready var cogs_label: Label = $UILayer/CogsLabel

@onready var action_bar: HBoxContainer = $UILayer/ActionBar
@onready var slot_1: ActionBarSlot = $UILayer/ActionBar/Slot1
@onready var slot_2: ActionBarSlot = $UILayer/ActionBar/Slot2
@onready var slot_3: ActionBarSlot = $UILayer/ActionBar/Slot3
@onready var slot_4: ActionBarSlot = $UILayer/ActionBar/Slot4
@onready var slot_5: ActionBarSlot = $UILayer/ActionBar/Slot5
@onready var slot_6: ActionBarSlot = $UILayer/ActionBar/Slot6
@onready var slot_7: ActionBarSlot = $UILayer/ActionBar/Slot7
@onready var slot_8: ActionBarSlot = $UILayer/ActionBar/Slot8

@onready var inventory_ui: Control = $UILayer/InventoryUI
@onready var inv_slot_1: InventorySlot = $UILayer/InventoryUI/InvSlot1
@onready var inv_slot_2: InventorySlot = $UILayer/InventoryUI/InvSlot2
@onready var inv_slot_3: InventorySlot = $UILayer/InventoryUI/InvSlot3
@onready var inv_slot_4: InventorySlot = $UILayer/InventoryUI/InvSlot4
@onready var inv_slot_5: InventorySlot = $UILayer/InventoryUI/InvSlot5
@onready var inv_slot_6: InventorySlot = $UILayer/InventoryUI/InvSlot6
@onready var inv_slot_7: InventorySlot = $UILayer/InventoryUI/InvSlot7
@onready var inv_slot_8: InventorySlot = $UILayer/InventoryUI/InvSlot8
@onready var inv_slot_9: InventorySlot = $UILayer/InventoryUI/InvSlot9
@onready var inv_slot_10: InventorySlot = $UILayer/InventoryUI/InvSlot10
@onready var inv_slot_11: InventorySlot = $UILayer/InventoryUI/InvSlot11
@onready var inv_slot_12: InventorySlot = $UILayer/InventoryUI/InvSlot12
@onready var inv_slot_13: InventorySlot = $UILayer/InventoryUI/InvSlot13
@onready var inv_slot_14: InventorySlot = $UILayer/InventoryUI/InvSlot14
@onready var inv_slot_15: InventorySlot = $UILayer/InventoryUI/InvSlot15
@onready var inv_slot_16: InventorySlot = $UILayer/InventoryUI/InvSlot16
@onready var inv_slot_17: InventorySlot = $UILayer/InventoryUI/InvSlot17
@onready var inv_slot_18: InventorySlot = $UILayer/InventoryUI/InvSlot18
@onready var inv_slot_19: InventorySlot = $UILayer/InventoryUI/InvSlot19
@onready var inv_slot_20: InventorySlot = $UILayer/InventoryUI/InvSlot20
@onready var inv_slot_21: InventorySlot = $UILayer/InventoryUI/InvSlot21
@onready var inv_slot_22: InventorySlot = $UILayer/InventoryUI/InvSlot22
@onready var inv_slot_23: InventorySlot = $UILayer/InventoryUI/InvSlot23
@onready var inv_slot_24: InventorySlot = $UILayer/InventoryUI/InvSlot24

@onready var profession_select_ui: Control = $UILayer/ProfessionSelectUI
@onready var profession_options_list: ItemList = $UILayer/ProfessionSelectUI/ProfessionOptionsList
@onready var choose_profession_button: Button = $UILayer/ProfessionSelectUI/ChooseProfessionButton
@onready var profession_select_result_label: Label = $UILayer/ProfessionSelectUI/ProfessionSelectResultLabel

@onready var skill_ui: Control = $UILayer/SkillUI
@onready var skill_tree: Tree = $UILayer/SkillUI/SkillTree
@onready var skill_info_label: Label = $UILayer/SkillUI/SkillInfoLabel
@onready var spend_point_button: Button = $UILayer/SkillUI/SpendPointButton
@onready var skill_result_label: Label = $UILayer/SkillUI/SkillResultLabel

@onready var crafting_ui: Control = $UILayer/CraftingUI
@onready var recipe_info_label: Label = $UILayer/CraftingUI/RecipeInfoLabel
@onready var enhancement_slot_label: Label = $UILayer/CraftingUI/EnhancementSlotLabel



var resource_stat_definitions = {
	"Metal": ["Energy", "Conductivity", "Pliability", "Toughness"],
	"Mineral": ["Quality", "Energy", "Toughness", "Density"],
	"Flora - Fungal": ["Potency", "Quality", "Decay", "Spore Density"],
	"Flora - Wood": ["Hardiness", "Rot Resistance", "Density", "Quality"],
	"Water": ["Purity", "Mineral Content", "Clarity", "Hardness"],
	"Gas": ["Volatility", "Purity", "Pressure", "Energy"],
	"Oil": ["Viscosity", "Purity", "Energy", "Flammability"]
}

var resource_stat_ranges = {
	"Copper": {"Conductivity": [700, 1000]},
	"Gold": {"Pliability": [800, 1000]},
	"Gunmetal Steel": {"Pliability": [100, 500]},
	"Black Iron": {"Pliability": [100, 500]}
}


var gem_gated_subclasses = ["Amethyst", "Diamond", "Sapphire", "Ruby", "Emerald"]

func _get_profession_rank_count(base_name: String) -> int:
	# Returns count of unlocked rank boxes for path-based professions.
	# Keystone-based professions (Street Thug) have no rank columns
	# so this always returns 0 for them -- scanning/sampling bonuses
	# will be driven by keystone nodes in a future pass.
	var prof_data = GameData.novice_professions["Street Thug"]
	if not prof_data.has("paths"):
		return 0
	var total = 0
	for suffix in [" I", " II", " III", " IV"]:
		var path_name = base_name + suffix
		if prof_data["paths"].has(path_name):
			total += prof_data["paths"][path_name]["unlocked_nodes"]
	return total


func _get_rank_unlocked(path_name: String) -> bool:
	# For keystone-based professions, "rank unlocked" means the
	# corresponding keystone is unlocked. For path-based professions,
	# checks unlocked_nodes on the path.
	var prof_data = GameData.novice_professions["Street Thug"]
	if prof_data.has("keystones"):
		return prof_data["keystones"].get(path_name, {}).get("unlocked", false)
	if not prof_data.has("paths"):
		return false
	var path_data = prof_data["paths"].get(path_name, null)
	if path_data == null:
		return false
	return path_data["unlocked_nodes"] >= path_data.get("max_nodes", NODES_PER_PATH)


func _get_healing_speed_bonus() -> int:
	return 2 if _get_rank_unlocked("Healing I") else 0

func _get_healing_knowledge_bonus() -> int:
	return 2 if _get_rank_unlocked("Healing I") else 0

# Wound Care stacks across ranks II-IV: +4 at II, +4 more at III, +2 more at IV.
func _get_wound_care_bonus() -> int:
	var bonus = 0
	if _get_rank_unlocked("Healing II"):
		bonus += 4
	if _get_rank_unlocked("Healing III"):
		bonus += 4
	if _get_rank_unlocked("Healing IV"):
		bonus += 2
	return bonus

# Medicinal Knowledge stacks across ranks I-III (+4 each); Rank IV
# grants Medicine Potency instead, plus unlocks new recipes later.
func _get_medicinal_knowledge_bonus() -> int:
	var bonus = 0
	if _get_rank_unlocked("Medicine Crafting I"):
		bonus += 4
	if _get_rank_unlocked("Medicine Crafting II"):
		bonus += 4
	if _get_rank_unlocked("Medicine Crafting III"):
		bonus += 4
	return bonus

func _get_medicine_potency_bonus() -> int:
	return 2 if _get_rank_unlocked("Medicine Crafting IV") else 0

# Foraging Chance stacks +1 per rank, I through IV (max +4).
func _get_foraging_chance_bonus() -> int:
	var bonus = 0
	for rank_name in ["Medical Foraging I", "Medical Foraging II", "Medical Foraging III", "Medical Foraging IV"]:
		if _get_rank_unlocked(rank_name):
			bonus += 1
	return bonus

func _has_bandages_for_salve() -> bool:
	for instance_name in inventory.keys():
		if consumable_base_name.get(instance_name, "") == "Crate of Bandages" and inventory[instance_name] > 0:
			return true
	return false

# Consumes one charge off the first available Crate of Bandages stack --
# same depletion pattern as _attempt_use_bandage, reused here since
# Healing abilities are fueled by the same item.
func _consume_one_bandage_charge() -> void:
	for instance_name in inventory.keys():
		if consumable_base_name.get(instance_name, "") == "Crate of Bandages" and inventory[instance_name] > 0:
			var stats = inventory_stats.get(instance_name, {})
			var charges = stats.get("Charges", 1)
			charges -= 1
			if charges <= 0:
				inventory.erase(instance_name)
				inventory_stats.erase(instance_name)
				consumable_base_name.erase(instance_name)
				crafted_item_class.erase(instance_name)
			else:
				inventory_stats[instance_name]["Charges"] = charges
			_update_inventory_display()
			return




var name_starts = [
	"Zar", "Vex", "Thal", "Kro", "Fen", "Bri", "Dra", "Mor", "Syl", "Nyx",
	"Grim", "Aur", "Vel", "Cyr", "Ith", "Quon", "Rax", "Yun", "Wyr", "Ash",
	"Ozz", "Ebb", "Ull", "Ohn", "Skar", "Plith", "Nur", "Haw", "Jorv", "Ecc"
]
var name_connectors = [
	"a", "e", "i", "o", "u", "ae", "io", "ux", "oo", "ar", "en", "ol", "yr", "ith"
]
var name_endings = [
	"dor", "lyn", "rax", "mir", "thas", "gorn", "ven", "zil", "kor", "nath",
	"ryx", "voss", "quil", "wyn", "dral", "mos", "kesh", "ash", "vun", "threl"
]
var name_single_letters = ["x", "z", "q", "v", "k", "j", "w", "y", "b", "d", "g", "n", "r", "s", "t"]
var used_resource_names: Dictionary = {}

var resource_subclass_of: Dictionary = {}
var resource_type_of: Dictionary = {}

var resource_stats: Dictionary = {}


var inventory: Dictionary = {}
var inventory_stats: Dictionary = {}

var item_classes = {
	"Sword": ["1 Handed", "2 Handed"],
	"Axe": ["1 Handed", "2 Handed"],
	"Hammer": ["2 Handed"],
	"Brass Knuckles": ["1 Handed"],
	"Stun Stick": ["1 Handed"],
	"Shotgun": ["Shotgun"],
	"Assault Rifle": ["Assault Rifle"],
	"Sniper Rifle": ["Sniper Rifle"],
	"Pistol": ["Pistol"],
	"Grenade Launcher": ["Grenade Launcher"],
	"Flame Thrower": ["Flame Thrower"]
}

var weapon_stat_names = ["Speed", "Damage Rating", "Damage Per Second"]


var enhancement_definitions = {
	"Overcharged Coil": {"Damage Rating Bonus": 8, "Range Bonus": 5}
}

var crafted_item_class: Dictionary = {}
# inventory item_key -> crafted instance_id, so the inventory detail
# panel can look up sockets, traits and flaws for a crafted item.
var crafted_item_instance_of: Dictionary = {}

# --- Mods (crafting Phase 6) ----------------------------------------
# Mod instances the player owns, keyed by instance_id. A mod that is
# INSTALLED still lives here; the owning weapon's crafted instance lists
# it in installed_mod_instance_ids.
var mod_instances: Dictionary = {}

# Inventory item_key -> mod instance_id, for UNINSTALLED mods only. This
# is what makes a mod a draggable inventory item. Installing removes the
# inventory entry, because mods are PERMANENT once fitted.
var mod_instance_of: Dictionary = {}

# Socket UI state. Mods dropped into a socket are PENDING until Apply --
# nothing is committed without an explicit confirmation, because fitting
# a mod is irreversible. Cleared whenever the selected item changes.
const MOD_DRAG_SOURCE_SCRIPT_PATH = "res://scenes/mod_drag_source.gd"
const MOD_SOCKET_SLOT_SCRIPT_PATH = "res://scenes/mod_socket_slot.gd"
var pending_mod_installs: Dictionary = {}
var inventory_book_selected_key: String = ""
var inventory_book_socket_area: VBoxContainer
var mod_confirm_dialog: ConfirmationDialog
var crafted_item_subclass: Dictionary = {}
var consumable_base_name: Dictionary = {}

# --- Combat ---
var equipped_weapon_name: String = ""
const MELEE_RANGE = 180.0
# Hit-chance formula constants -- our own numbers/scale, not copied
# from any external source. See _perform_attack() for the formula.
const BASE_HIT_CHANCE = 50.0
const MIN_HIT_CHANCE = 10.0
const MAX_HIT_CHANCE = 95.0

# Range-based accuracy modifiers (SWG-inspired).
# Each weapon category has an OPTIMAL band, a REDUCED band, and anything
# outside both is WAY_LESS_OPTIMAL. Scale: ~45px per "foot" based on
# existing MELEE_RANGE (180px = ~4ft touching range).
# OPTIMAL = +0 accuracy penalty, REDUCED = -20, WAY_LESS = -45.
# These subtract from the hit_chance BEFORE clamping to MIN_HIT_CHANCE.
const RANGE_PENALTY_REDUCED = 20.0
const RANGE_PENALTY_WAY_LESS = 45.0

# Per-weapon-class max ENGAGEMENT range -- each class gets its own ceiling.
# A sniper rifle that can only reach 650px but has an optimal band at 1125px+
# is nonsensical, so engagement range is now weapon-class-aware.
const ENGAGE_RANGE_PISTOL = 1125.0
const ENGAGE_RANGE_RIFLE = 1575.0
const ENGAGE_RANGE_SNIPER = 2250.0
const ENGAGE_RANGE_SHOTGUN = 450.0
const ENGAGE_RANGE_HEAVY = 675.0

# Shotgun: optimal 0-180px (0-4ft), reduced 180-450px (4-10ft)
const SHOTGUN_OPTIMAL_MAX = 180.0
const SHOTGUN_REDUCED_MAX = 450.0

# Pistol: optimal 225-675px (5-15ft), reduced outside that up to 1125px
const PISTOL_OPTIMAL_MIN = 225.0
const PISTOL_OPTIMAL_MAX = 675.0
const PISTOL_REDUCED_MAX = 1125.0

# Rifle: optimal 720-1125px (16-25ft), reduced outside that up to 1575px
const RIFLE_OPTIMAL_MIN = 720.0
const RIFLE_OPTIMAL_MAX = 1125.0
const RIFLE_REDUCED_MAX = 1575.0

# Sniper: optimal 1125-2250px (25-50ft), reduced at 675-1125 (too close)
const SNIPER_OPTIMAL_MIN = 1125.0
const SNIPER_OPTIMAL_MAX = 2250.0
const SNIPER_REDUCED_MIN = 675.0

# Heavy Weapons (Grenade Launcher, Flame Thrower): SWG-inspired -- close range,
# high damage, AoE/DoT. Flame thrower basically extended melee, grenade launcher
# arcs close-to-mid. Small penalty beyond optimal so they can not snipe at range,
# but no massive falloff since AoE makes precision less critical.
const HEAVY_OPTIMAL_MAX = 450.0
# Tuned so a brand-new, untrained character (Quality-0 Piston Blade,
# 55 Accuracy, no trained Accuracy bonuses) lands at ~85% hit chance
# against the training Dummy -- solidly likely to land a hit, with just
# a small chance to whiff, since it's meant to feel like a low-stakes
# practice target rather than a real fight. Other starting weapons
# (Pressure Scattergun, Pneumatic Rifle) have their own Accuracy
# ranges, so they'll land close to but not necessarily exactly 85% --
# that variance across weapon types is expected, not a bug.
# Light Action cost for the basic Attack -- like walking burning a few
# calories, not meant to be draining. Tune this one number to adjust.
const BASIC_ATTACK_ACTION_COST = 20
# Basic Attack's real Action cost now scales with the equipped
# weapon's Speed stat instead of using this flat value -- fast/light
# weapons (knuckles, stun sticks) cost less Action per swing, slow/
# heavy weapons (hammers, greatblades) cost more. This constant is
# now only the fallback when no weapon Speed stat is available.
func _get_dynamic_attack_action_cost() -> int:
	var weapon_stats = inventory_stats.get(equipped_weapon_name, {})
	if not weapon_stats.has("Speed"):
		return BASIC_ATTACK_ACTION_COST
	var speed = weapon_stats["Speed"]
	return max(5, int(round(speed * 10.0)))

# Returns an accuracy PENALTY (positive = worse) based on weapon class
# and current distance to target. Inspired by SWG's range-based accuracy
# system -- each weapon type has an optimal band; outside that band the
# penalty increases, making it significantly harder to land hits at
# wrong ranges. Added directly to the hit_chance formula as a subtraction.
func _get_range_accuracy_penalty(weapon_class: String, dist: float) -> float:
	if weapon_class == "Shotgun":
		if dist <= SHOTGUN_OPTIMAL_MAX:
			return 0.0
		elif dist <= SHOTGUN_REDUCED_MAX:
			return RANGE_PENALTY_REDUCED
		else:
			return RANGE_PENALTY_WAY_LESS

	elif weapon_class == "Pistol":
		if dist >= PISTOL_OPTIMAL_MIN and dist <= PISTOL_OPTIMAL_MAX:
			return 0.0
		elif dist <= PISTOL_REDUCED_MAX:
			return RANGE_PENALTY_REDUCED
		else:
			return RANGE_PENALTY_WAY_LESS

	elif weapon_class == "Sniper Rifle":
		if dist >= SNIPER_OPTIMAL_MIN and dist <= SNIPER_OPTIMAL_MAX:
			return 0.0
		elif dist > SNIPER_OPTIMAL_MAX:
			return RANGE_PENALTY_WAY_LESS
		elif dist >= SNIPER_REDUCED_MIN:
			# Close but not optimal -- reduced accuracy
			return RANGE_PENALTY_REDUCED
		else:
			# Point-blank with a sniper -- nearly impossible to aim
			return RANGE_PENALTY_WAY_LESS

	elif GameData.rifle_weapons.has(weapon_class):
		if dist >= RIFLE_OPTIMAL_MIN and dist <= RIFLE_OPTIMAL_MAX:
			return 0.0
		elif dist <= RIFLE_REDUCED_MAX:
			return RANGE_PENALTY_REDUCED
		else:
			return RANGE_PENALTY_WAY_LESS

	elif GameData.heavy_weapon_types.has(weapon_class):
		# SWG-inspired: heavy weapons hit hard close up with AoE/DoT.
		# Small penalty beyond optimal to stop them from sniping, but
		# no massive falloff -- area effect makes precision less critical.
		if dist <= HEAVY_OPTIMAL_MAX:
			return 0.0
		else:
			return RANGE_PENALTY_REDUCED

	# Melee, Unarmed, Brass Knuckles -- no range check applies here
	# since melee already can't attack outside MELEE_RANGE.
	return 0.0

const HEALTH_BAR_WIDTH = 60.0
const HEALTH_BAR_HEIGHT = 8.0
const ACTION_BAR_GAP = 10.0
# Player HUD bars are bigger/thicker than the enemy world-space bars
# above, for easier readability as a fixed screen element.
const HUD_BAR_WIDTH = 160.0
const HUD_BAR_HEIGHT = 16.0
const HUD_BAR_GAP = 6.0
const NAME_LABEL_WIDTH = 150.0
# ActionBar and PlayerHUD are both positioned automatically at runtime
# by _layout_hud() (called once from _ready()) rather than a fixed
# guessed position -- the ActionBar is centered horizontally near the
# bottom of the screen, and PlayerHUD aligns its left edge with the
# ActionBar's left edge, sitting just above it. Adjust these two
# constants to change the bottom margin / gap between them.
const ACTION_BAR_BOTTOM_MARGIN = 70.0
const HUD_GAP_ABOVE_ACTION_BAR = 15.0

var player_max_health: int = 500
var player_current_health: int = 500
var player_max_action: int = 850
var player_current_action: int = 850
var player_alive: bool = true
var player_spawn_position: Vector2 = Vector2.ZERO

const DUMMY_ATTACK_COOLDOWN = 2.5
const ENEMY_ATTACK_RANGE = 180.0


# ------------------------------------------------------------------
# Enemy combat state (Phase 1: shared stat block).
# The dummy and enemy2 test enemies each live as an entry in this
# dictionary instead of loose dummy_*/enemy2_* variables. Each entry
# holds identity (name, faction, archetype), live state (health/action, alive,
# attack_ready), status trackers, and a nested "stats" block (the
# 15-field combat stat schema -- defaults for now, populated by later
# phases: CL derivation, armor, combat rolls). Filled once in _ready()
# from CombatData.default_enemies().
#
# Status-tracker notes carried over from the old loose vars:
#   damage_debuff        Subdue -- reduces this enemy's outgoing damage.
#   accuracy_debuff      Disorient -- tracked; no live effect yet.
#   attack_speed_debuff  Bruise -- multiplier on this enemy's attack cadence.
#   bleed_*              Bleed DoT -- ticks with player regen.
#   taunted_until_msec   Anger -- scaffolding for co-op aggro redirect.
#   damage_by_weapon_class  cumulative damage per weapon class, for the
#                        proportional kill-XP split; reset on respawn.
var enemies: Dictionary = {}
var nm_active_by_type: Dictionary = {}
const ENEMY2_ATTACK_COOLDOWN = 2.5
const ENEMY2_KILL_XP = 67

const COGS_MIN_DROP = 1
const COGS_MAX_DROP = 5

# --- Trainer ---
const TRAINER_INTERACT_RANGE = 150.0
var trainers: Array = []

# Central interactables registry. Every object the player can press E
# on registers itself here at startup. Each entry is a Dictionary:
#   "node"     Node2D  -- used to measure distance
#   "range"    float   -- how close the player must be
#   "type"     String  -- "trainer" | "quest" | "dumpster" | "door" | etc.
#   "callback" Callable -- what happens when the player interacts
# _attempt_interact() finds the closest in-range entry and fires it.
var interactables: Array = []
var active_trainer_index: int = -1
var trainer_dialogue_state: String = "GREETING"
var trainer_result_text: String = ""
const COGS_COST_TIER_1 = 50
const COGS_COST_TIER_2 = 150
const COGS_COST_TIER_3 = 500
const skill_cogs_costs = [1, 1, 1, 1]

# --- Scavenging XP ---
const FORAGE_XP = 10

# --- Dumpster (Scavenging) ---
# Fixed, non-moving scavenge point -- the only scavenge point in the
# game right now (the earlier test herb patch has been removed).
var dumpster_available: bool = true
const DUMPSTER_RANGE = 150.0
# TESTING VALUE -- was 45.0. Dropped to 5s so material scavenging can
# be tested quickly. RESTORE TO 45.0 before any real balance pass or
# release; at 5s the surface salvage economy is meaningless.
const DUMPSTER_RESPAWN_TIME = 5.0
const DUMPSTER_COGS_MIN = 2
const DUMPSTER_COGS_MAX = 2

# --- Crate of Bandages / Medicine Usage ---
const BANDAGE_HEAL_AMOUNT = 100
const BANDAGE_HEALING_XP = 15
const BANDAGE_COOLDOWN = 6.0
const BANDAGE_ACTION_COST = 50
var bandage_ready: bool = true
var attack_ready: bool = true
var targeted_enemy: String = ""
const ENEMY_CLICK_RADIUS = 60.0

# --- Healing abilities (IV Drip, Healing Vapor) ---
# Duration assumptions (not specified by design yet -- flagged for review):
# IV Drip ticks once per second via the existing health regen tick, for
# 10 seconds (10 total HP). Healing Vapor is a single instant AoE burst.
const IV_DRIP_HEAL_PER_TICK = 1
const IV_DRIP_DURATION_TICKS = 10
const IV_DRIP_COOLDOWN_MSEC = 20000
const HEALING_VAPOR_HEAL_AMOUNT = 150
const HEALING_VAPOR_COOLDOWN_MSEC = 30000
var iv_drip_ticks_remaining: int = 0
var iv_drip_ready_at_msec: int = 0
var healing_vapor_ready_at_msec: int = 0

# --- Stims (Adrenaline Boost only -- II/III/IV intentionally not built yet) ---
# Temporarily raises max Action (not a heal) -- e.g. 850 max + a 50
# bonus = 900 max, with current Action rising by the same amount so
# the new headroom is immediately usable. Bonus scales with the
# consumed Adrenaline Shot's Quality (30 at Quality 0, up to 100 at
# Quality 1000). Lasts 10 minutes, then reverts automatically. Cooldown
# matches the duration, so a new Boost can't be applied -- and therefore
# can't stack -- until the current one has fully worn off.
const ADRENALINE_BOOST_MIN_ACTION = 30
const ADRENALINE_BOOST_MAX_ACTION = 100
const ADRENALINE_BOOST_DURATION_SEC = 600.0
const ADRENALINE_BOOST_COOLDOWN_SEC = 600.0
var adrenaline_boost_bonus_amount: int = 0
var adrenaline_boost_expires_at_unix: float = 0.0
var adrenaline_boost_ready_at_unix: float = 0.0

# Blood Bag (Stims III) -- same structure as Adrenaline Boost, but
# raises max Health instead of max Action. Same 10-minute duration and
# matching cooldown, for the same non-stacking reason. Bonus scales
# with the consumed Empty IV Bag's Quality the same way (30-100).
const BLOOD_BAG_MIN_HEAL = 30
const BLOOD_BAG_MAX_HEAL = 100
const BLOOD_BAG_DURATION_SEC = 600.0
const BLOOD_BAG_COOLDOWN_SEC = 600.0
var blood_bag_bonus_amount: int = 0
var blood_bag_expires_at_unix: float = 0.0
var blood_bag_ready_at_unix: float = 0.0

# --- Skills ---

var xp_pools: Dictionary = {
	"Combat XP": 0,
	"Crafting XP": 0
}



const LOOT_TIER_CHANCES = {
	"Common": 0.85,
	"Uncommon": 0.13,
	"Rare": 0.02
}

var loot_tables: Dictionary = {
	"Dummy": {
		"Common": [{"item": "Scrap Metal Chunk", "min_amount": 1, "max_amount": 3}],
		"Uncommon": [{"item": "Damaged Circuit", "min_amount": 1, "max_amount": 2}],
		"Rare": [{"item": "Overcharged Coil", "min_amount": 1, "max_amount": 1}],
		"UltraRare": [{"item": "Piston Blade (Exceptional)", "chance": 0.00005, "min_amount": 1, "max_amount": 1}]
	},
	"Enemy2": {
		"Common": [{"item": "Rusted Gear", "min_amount": 1, "max_amount": 3}],
		"Uncommon": [{"item": "Damaged Circuit", "min_amount": 1, "max_amount": 3}],
		"Rare": [{"item": "Overcharged Coil", "min_amount": 1, "max_amount": 2}]
	},
	"ForageSpot": {
		"Common": [{"item": "Torn Cloth", "min_amount": 1, "max_amount": 3}, {"item": "Plastic", "min_amount": 1, "max_amount": 3}],
		"Uncommon": [{"item": "Antiseptic Moss", "min_amount": 1, "max_amount": 2}, {"item": "Healroot", "min_amount": 1, "max_amount": 2}],
		"Rare": [{"item": "Bloomwort", "min_amount": 1, "max_amount": 1}]
	}
}
# Grenade Launcher/Flame Thrower are no longer tied to a live Chrome
# Gunner talent column (Heavy Weapons was retired in favor of Pistols).
# Kills with these still earn "Heavy Weapons XP" (see xp_pools above),
# but that pool has nowhere to spend until something like Ordinance
# Specialist gets built out.

const XP_PER_POINT = 100
const skill_xp_thresholds = [1, 1, 1, 1]
const skill_point_costs = [1, 2, 3, 4]

# Combat professions draw from Militant Points; crafting/sampling
# professions draw from Engineer Points. This split exists so a solo/
# co-op player never has to choose between "being good at combat" and
# "being good at crafting" -- crafting is too central to the game to be
# gated behind the same currency as fighting. Toxinsmith is a judgment
# call (it needs both Master Apothecary AND Chrome Gunner Shotguns IV)
# -- filed under Engineer since Apothecary is its thematic home; revisit
# if that feels wrong once it's actually designed.
const STREET_THUG_PROFESSIONS: Array = ["Street Thug"]

var thug_points_available: int = 100
var cogs: int = 0

func _points_pool_label(_profession_name: String) -> String:
	return "Thug Points"

func _get_points_available(_profession_name: String) -> int:
	return thug_points_available

func _spend_points(_profession_name: String, amount: int) -> void:
	thug_points_available -= amount

var professions_unlocked: Dictionary = {
	"Street Thug": false,
	"Enforcer": false, "Specialist": false,
	"Ranger": false, "Commando": false, "Engineer": false, "Medic": false,
	"Sniper": false, "Bombardier": false, "Demolitionist": false, "Bioforge Tech": false,
	"Deadeye": false, "Siege Operator": false, "Wrecker": false, "Phantom": false,
	"Huntsman": false, "Warlord": false, "Saboteur": false, "Venomcaster": false,
	"Stalker": false, "Razorback": false, "Blastmaster": false, "Plague Engineer": false,
	"Ghost Medic": false, "Warchemist": false, "Toxinsmith": false, "Plague Doctor": false
}
var has_chosen_starting_profession: bool = false

# --- Crafting system state (Phase 3) --------------------------------
# The campaign resource map is generated ONCE from campaign_seed when a new
# game starts, then saved WHOLE and never regenerated. That permanence is
# what makes a deposit stay where you found it (spec s2.4/s4.4).
var campaign_seed: int = 0
var campaign_map: Dictionary = {}
var surface_sources: Dictionary = {}

# Material batches the player is carrying, keyed by batch_id. Batches are
# NOT plain inventory entries -- each carries quality, trait, instability
# and provenance, so they live in their own store.
var material_batches: Dictionary = {}

# Crafted item instances, keyed by item_id, and the player's crafting
# profile (blueprint familiarity, selected keystone nodes).
var crafted_items: Dictionary = {}
var crafting_profile: Dictionary = {}
const PROFESSION_ENTRY_COST = 5
const ADDITIONAL_PROFESSION_COGS_COST = 1
const NODES_PER_PATH = 4
const DUMMY_KILL_XP = 50

var selected_profession: String = ""
var selected_path: String = ""


func _ready() -> void:
	enemies = CombatData.default_enemies()
	for lair_id in LAIR_SPAWN_TABLE.keys():
		var lair = LAIR_SPAWN_TABLE[lair_id]
		for i in range(lair["members"].size()):
			var m = lair["members"][i]
			var eid = lair_id + "_" + str(i)
			enemies[eid] = CombatData.generate_enemy(
				String(m["display_name"]),
				int(m["cl"]),
				String(m["archetype"]),
				String(m["faction"])
			)
	_build_enemy_node_registry()
	for _eid in enemies.keys():
		_apply_cl_derivation(_eid)

	# Force the real target resolution at runtime. This is a stopgap --
	# ideally also update Project Settings > Display > Window >
	# Viewport Width/Height to 1920x1080 directly in the editor so the
	# project's own default matches this everywhere, not just here.
	get_window().size = Vector2i(1920, 1080)
	get_window().move_to_center()


	_update_inventory_display()
	inventory_label.visible = false
	inventory_ui.visible = false
	_update_cogs_display()

	_grant_starting_bandages()

	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_finished)
	player_respawn_timer.timeout.connect(_on_player_respawn)
	player_regen_timer.timeout.connect(_on_player_regen_tick)
	player_regen_timer.start()
	player_action_regen_timer.timeout.connect(_on_player_action_regen_tick)
	player_action_regen_timer.start()

	player_spawn_position = player.position
	dumpster_cooldown_timer.timeout.connect(_on_dumpster_cooldown_finished)
	bandage_cooldown_timer.timeout.connect(_on_bandage_cooldown_finished)

	# Dumpster placeholder visual -- a plain brownish rectangle until real
	# art exists. Deliberately does NOT move on respawn, unlike the herb
	# patch, since this is meant to be a fixed, static scavenge point.
	dumpster_visual.color = Color(0.45, 0.35, 0.25)
	dumpster_visual.polygon = PackedVector2Array([
		Vector2(-25, -20), Vector2(25, -20), Vector2(25, 20), Vector2(-25, 20)
	])

	# Quest book placeholder -- red rectangle, 100px left of spawn.
	# Replace with real art later; position set in the scene node itself.
	quest_book_visual.color = Color(0.85, 0.1, 0.1)
	quest_book_visual.polygon = PackedVector2Array([
		Vector2(-15, -20), Vector2(15, -20), Vector2(15, 20), Vector2(-15, 20)
	])

	quest_system = preload("res://scenes/Quest.gd").new()
	quest_system.main = self
	add_child(quest_system)
	quest_system.setup()

	var trainer_gold = Color(1.0, 0.85, 0.3)

	trainers = [
		{"node": trainer, "sprite": trainer_sprite, "name_label": trainer_name_label, "name": "Foreman Brassguard", "profession": "Street Thug"},
		{"node": trainer2, "sprite": trainer2_sprite, "name_label": trainer2_name_label, "name": "Sergeant Chromewell", "profession": "Street Thug"},
		{"node": trainer3, "sprite": trainer3_sprite, "name_label": trainer3_name_label, "name": "Tinker Wrenfield", "profession": "Street Thug"},
		{"node": trainer4, "sprite": trainer4_sprite, "name_label": trainer4_name_label, "name": "Doctor Vellum", "profession": "Street Thug"}
	]

	for t in trainers:
		t["sprite"].modulate = trainer_gold
		t["name_label"].text = t["name"]
		t["name_label"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t["name_label"].custom_minimum_size = Vector2(NAME_LABEL_WIDTH, 0)
		t["name_label"].modulate = trainer_gold

	# Register all interactables. Order doesn't matter -- _attempt_interact
	# always picks the closest one in range, not the first match.
	for t in trainers:
		interactables.append({
			"node": t["node"],
			"range": TRAINER_INTERACT_RANGE,
			"type": "trainer",
			"callback": func(): _attempt_talk_to_trainer()
		})
	interactables.append({
		"node": quest_book,
		"range": 150.0,
		"type": "quest",
		"callback": func(): quest_system.try_interact("QuestBook")
	})
	interactables.append({
		"node": dumpster,
		"range": 120.0,
		"type": "dumpster",
		"callback": func(): _scavenge_dumpster()
	})

	message_clear_timer.timeout.connect(_on_message_clear_timer_timeout)
	xp_gain_clear_timer.timeout.connect(_on_xp_gain_clear_timer_timeout)

	skill_tree.item_selected.connect(_on_skill_tree_item_selected)
	skill_tree.focus_mode = Control.FOCUS_NONE
	spend_point_button.pressed.connect(_on_spend_point_pressed)
	spend_point_button.focus_mode = Control.FOCUS_NONE
	spend_point_button.visible = false
	_refresh_skill_tree_ui()

	trainer_ui.visible = false
	dialogue_layout.add_theme_constant_override("separation", 10)
	train_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	train_info_label.custom_minimum_size = Vector2(340, 0)

	for profession_name in GameData.novice_professions.keys():
		var tree_entry = GameData.PROFESSION_TREE.get(profession_name, {})
		if tree_entry.get("tier", 99) == 1:
			profession_options_list.add_item(profession_name)
	profession_options_list.focus_mode = Control.FOCUS_NONE
	choose_profession_button.pressed.connect(_on_choose_profession_pressed)
	choose_profession_button.focus_mode = Control.FOCUS_NONE

	profession_select_ui.visible = false

	crafting_ui.visible = false
	skill_ui.visible = false

	# The old Survey/sampling system was deleted, but its SurveyUI node is
	# still in the scene and its hide-line went with the cut, leaving the
	# Sample panel permanently on screen. Hidden defensively via has_node
	# so this is safe whether or not the node is eventually removed.
	if has_node("UILayer/SurveyUI"):
		get_node("UILayer/SurveyUI").visible = false

	_setup_health_bars()
	call_deferred("_layout_hud")
	var hud_layout_retry_timer = get_tree().create_timer(0.2)
	hud_layout_retry_timer.timeout.connect(_layout_hud)
	call_deferred("_setup_enemy_combat_message_label")
	_build_talent_ui()
	_build_crafting_panel_ui()
	_build_ability_book_ui()
	_build_inventory_book_ui()

	# Auto-assign Street Thug as the starting profession -- it is currently
	# the only starting profession, so there is nothing to choose. Additional
	# professions are still learned from trainers. A loaded save that already
	# set a starting profession skips this.
	_init_crafting_campaign()

	if not has_chosen_starting_profession:
		professions_unlocked["Street Thug"] = true
		has_chosen_starting_profession = true
		_grant_novice_unlock("Street Thug")
		_grant_profession_starting_kit("Street Thug")
		profession_select_ui.visible = false
		_refresh_skill_tree_ui()
	# Data integrity check -- see _run_startup_validation().
	_run_startup_validation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_viewport().gui_release_focus()

	if event.is_action_pressed("equip_menu"):
		inventory_book_ui.visible = not inventory_book_ui.visible
		if inventory_book_ui.visible:
			_refresh_inventory_book()

	if event.is_action_pressed("inventory_menu"):
		_cycle_target()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world = get_viewport().get_canvas_transform().affine_inverse() * event.position
		_try_click_target(mouse_world)

	if event.is_action_pressed("interact"):
		_attempt_interact()

	if event.is_action_pressed("profession_menu"):
		if not has_chosen_starting_profession:
			profession_select_ui.visible = not profession_select_ui.visible

	if event.is_action_pressed("skills_menu"):
		skill_ui.visible = not skill_ui.visible
		if skill_ui.visible:
			_refresh_skill_tree_ui()

	if event.is_action_pressed("abilities_menu"):
		ability_book_ui.visible = not ability_book_ui.visible
		if ability_book_ui.visible:
			_refresh_ability_book()

	if event.is_action_pressed("slot_1"):
		_trigger_slot(slot_1)
	if event.is_action_pressed("slot_2"):
		_trigger_slot(slot_2)
	if event.is_action_pressed("slot_3"):
		_trigger_slot(slot_3)
	if event.is_action_pressed("slot_4"):
		_trigger_slot(slot_4)
	if event.is_action_pressed("slot_5"):
		_trigger_slot(slot_5)
	if event.is_action_pressed("slot_6"):
		_trigger_slot(slot_6)
	if event.is_action_pressed("slot_7"):
		_trigger_slot(slot_7)
	if event.is_action_pressed("slot_8"):
		_trigger_slot(slot_8)

	if event.is_action_pressed("save_game"):
		_save_game()

	if event.is_action_pressed("load_game"):
		_load_game()

	if event.is_action_pressed("talent_view"):
		talent_ui.visible = not talent_ui.visible
		if talent_ui.visible and keystone_viewer != null:
			keystone_viewer._rebuild_graph()
			keystone_viewer._refresh()

	# Escape always closes the talent panel. Safety net: the panel is
	# full-screen, so if its close button is ever off-screen (small
	# window, odd resolution) there is still a guaranteed way out.
	if event.is_action_pressed("ui_cancel"):
		var _banner = get_node_or_null("UILayer/DataValidationBanner")
		if _banner != null:
			_banner.queue_free()
	if event.is_action_pressed("ui_cancel") and talent_ui != null and talent_ui.visible:
		talent_ui.visible = false

	# Crafting panel. Guarded by InputMap.has_action so the game still runs
	# if the "crafting_menu" action has not been added yet.
	if InputMap.has_action("crafting_menu") and event.is_action_pressed("crafting_menu"):
		if crafting_panel_ui != null:
			crafting_panel_ui.visible = not crafting_panel_ui.visible
			if crafting_panel_ui.visible and crafting_panel != null:
				crafting_panel.refresh()

	if event.is_action_pressed("ui_cancel") and crafting_panel_ui != null and crafting_panel_ui.visible:
		crafting_panel_ui.visible = false

	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_debug_grant_core_mods()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		get_tree().quit()

func _generate_unique_resource_name() -> String:
	var new_name = ""
	while true:
		var parts = []
		parts.append(name_starts[randi_range(0, name_starts.size() - 1)])
		parts.append(name_connectors[randi_range(0, name_connectors.size() - 1)])
		parts.append(name_endings[randi_range(0, name_endings.size() - 1)])

		if randi_range(1, 100) <= 30:
			parts.append(name_endings[randi_range(0, name_endings.size() - 1)])

		if randi_range(1, 100) <= 50:
			var random_letter = name_single_letters[randi_range(0, name_single_letters.size() - 1)]
			var insert_position = randi_range(0, parts.size())
			parts.insert(insert_position, random_letter)

		new_name = ""
		for part in parts:
			new_name += part

		if not used_resource_names.has(new_name):
			break

	used_resource_names[new_name] = true
	return new_name









func _get_yield_for_concentration(concentration: int) -> int:
	if concentration <= 25:
		return 1
	elif concentration <= 50:
		return 2
	elif concentration <= 74:
		return 4
	else:
		return 5

func _add_to_inventory(instance_name: String, amount: int) -> void:
	if inventory.has(instance_name):
		inventory[instance_name] += amount
	else:
		inventory[instance_name] = amount

func _add_to_inventory_with_instance(instance_name: String, amount: int) -> void:
	if not inventory_stats.has(instance_name):
		inventory_stats[instance_name] = resource_stats[instance_name].duplicate()

	_add_to_inventory(instance_name, amount)

func _update_inventory_display() -> void:
	var display_text = "Inventory:\n"
	for instance_name in inventory.keys():
		var display_name = _get_inventory_display_name(instance_name)
		display_text += display_name + ": " + str(inventory[instance_name])

		var stats = inventory_stats.get(instance_name, {})
		if stats.has("Charges"):
			display_text += " (" + str(stats["Charges"]) + " charges left)"

		display_text += "\n"
	inventory_label.text = display_text

	_refresh_inventory_slots()

func _refresh_inventory_slots() -> void:
	var slots = [
		inv_slot_1, inv_slot_2, inv_slot_3, inv_slot_4, inv_slot_5, inv_slot_6,
		inv_slot_7, inv_slot_8, inv_slot_9, inv_slot_10, inv_slot_11, inv_slot_12,
		inv_slot_13, inv_slot_14, inv_slot_15, inv_slot_16, inv_slot_17, inv_slot_18,
		inv_slot_19, inv_slot_20, inv_slot_21, inv_slot_22, inv_slot_23, inv_slot_24
	]

	var keys = inventory.keys()

	for i in range(slots.size()):
		if i < keys.size():
			var key = keys[i]
			var display_name = _get_inventory_display_name(key)
			var amount = inventory[key]
			var stats = inventory_stats.get(key, {})

			var label_text = display_name + " (" + str(amount) + ")"
			if stats.has("Charges"):
				label_text = display_name + " (" + str(stats["Charges"]) + " charges)"

			slots[i].item_key = key
			slots[i].display_name = display_name
			slots[i].text = label_text
		else:
			slots[i].item_key = ""
			slots[i].display_name = ""
			slots[i].text = "(empty)"

func _update_cogs_display() -> void:
	cogs_label.text = "Cogs: " + str(cogs)

func _get_inventory_display_name(instance_name: String) -> String:
	if consumable_base_name.has(instance_name):
		return consumable_base_name[instance_name]

	if not resource_subclass_of.has(instance_name):
		return instance_name

	var subclass_name = resource_subclass_of[instance_name]
	var type_name = resource_type_of[instance_name]

	if type_name == subclass_name:
		return subclass_name
	else:
		return subclass_name + " (" + type_name + ")"













func _cleanup_empty_inventory_stacks() -> void:
	var empty_keys = []
	for instance_name in inventory.keys():
		if inventory[instance_name] <= 0:
			empty_keys.append(instance_name)

	for instance_name in empty_keys:
		inventory.erase(instance_name)
		if inventory_stats.has(instance_name):
			inventory_stats.erase(instance_name)

func _get_article(word: String) -> String:
	if word.length() == 0:
		return "a"

	var first_letter = word[0].to_upper()
	if ["A", "E", "I", "O", "U"].has(first_letter):
		return "an"
	return "a"

func _format_number(value):
	if typeof(value) == TYPE_STRING:
		return value
	if typeof(value) == TYPE_FLOAT and float(value) == int(value):
		return str(int(value))
	return str(value)

func _save_game() -> void:
	var save_data = {
		"inventory": inventory,
		"inventory_stats": inventory_stats,
		"resource_subclass_of": resource_subclass_of,
		"resource_type_of": resource_type_of,
		"resource_stats": resource_stats,
		"used_resource_names": used_resource_names,
		"crafted_item_class": crafted_item_class,
		"crafted_item_instance_of": crafted_item_instance_of,
		"mod_instances": mod_instances,
		"mod_instance_of": mod_instance_of,
		"consumable_base_name": consumable_base_name,
		"equipped_weapon_name": equipped_weapon_name,
		"novice_professions": GameData.novice_professions,
		"xp_pools": xp_pools,
		"thug_points_available": thug_points_available,
		"professions_unlocked": professions_unlocked,
		"has_chosen_starting_profession": has_chosen_starting_profession,
		"campaign_seed": campaign_seed,
		"campaign_map": CraftingResourceGenerator.to_save_dict(campaign_map),
		"surface_sources": surface_sources,
		"crafting": CraftingService.to_save_dict(material_batches, crafted_items, crafting_profile),
		"quest_data": quest_system.get_save_data(),
		"player_position": {"x": player.position.x, "y": player.position.y},
		"player_current_health": player_current_health,
		"player_current_action": player_current_action,
		"player_max_health": player_max_health,
		"player_max_action": player_max_action,
		"adrenaline_boost_bonus_amount": adrenaline_boost_bonus_amount,
		"adrenaline_boost_expires_at_unix": adrenaline_boost_expires_at_unix,
		"adrenaline_boost_ready_at_unix": adrenaline_boost_ready_at_unix,
		"blood_bag_bonus_amount": blood_bag_bonus_amount,
		"blood_bag_expires_at_unix": blood_bag_expires_at_unix,
		"blood_bag_ready_at_unix": blood_bag_ready_at_unix,
		"player_alive": player_alive,
		"cogs": cogs,
		"action_bar_assignments": [
			slot_1.assigned_ability, slot_2.assigned_ability, slot_3.assigned_ability, slot_4.assigned_ability,
			slot_5.assigned_ability, slot_6.assigned_ability, slot_7.assigned_ability, slot_8.assigned_ability
		]
	}

	var json_text = JSON.stringify(save_data)

	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(json_text)
	file.close()

	_show_combat_message("Game saved!")

func _load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		_show_combat_message("No save file found!")
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var save_data = JSON.parse_string(json_text)
	if save_data == null:
		_show_combat_message("Save file could not be read!")
		return

	inventory = {}
	for key in save_data["inventory"].keys():
		inventory[key] = int(save_data["inventory"][key])

	inventory_stats = save_data["inventory_stats"]
	resource_subclass_of = save_data.get("resource_subclass_of", {})
	resource_type_of = save_data.get("resource_type_of", {})
	resource_stats = save_data.get("resource_stats", {})
	used_resource_names = save_data.get("used_resource_names", [])

	crafted_item_class = save_data.get("crafted_item_class", {})
	crafted_item_instance_of = save_data.get("crafted_item_instance_of", {})
	mod_instances = save_data.get("mod_instances", {})
	mod_instance_of = save_data.get("mod_instance_of", {})
	_reapply_all_mod_stats()
	consumable_base_name = save_data.get("consumable_base_name", {})
	equipped_weapon_name = save_data.get("equipped_weapon_name", "")

	var loaded_professions = save_data.get("novice_professions", null)
	if loaded_professions != null:
		for profession_name in loaded_professions.keys():
			if not GameData.novice_professions.has(profession_name):
				continue
			var prof_data = GameData.novice_professions[profession_name]
			var loaded_prof = loaded_professions[profession_name]
			# Path-based professions (shell classes)
			if prof_data.has("paths") and loaded_prof.has("paths"):
				var loaded_paths = loaded_prof["paths"]
				for path_name in loaded_paths.keys():
					if prof_data["paths"].has(path_name):
						var loaded_nodes = int(loaded_paths[path_name]["unlocked_nodes"])
						prof_data["paths"][path_name]["unlocked_nodes"] = loaded_nodes
			# Keystone-based professions (Street Thug)
			elif prof_data.has("keystones") and loaded_prof.has("keystones"):
				for ks_name in loaded_prof["keystones"].keys():
					if prof_data["keystones"].has(ks_name):
						var loaded_ks = loaded_prof["keystones"][ks_name]
						prof_data["keystones"][ks_name]["unlocked"] = loaded_ks.get("unlocked", false)
						# Clamp to the CURRENT budget. A save written while a
						# keystone allowed more points (Auxiliary briefly held
						# 24 during the crafting-node interim) would otherwise
						# load in a permanently over-budget state.
						var _ks_max = int(prof_data["keystones"][ks_name].get("points_max", 0))
						prof_data["keystones"][ks_name]["points_spent"] = clamp(int(loaded_ks.get("points_spent", 0)), 0, _ks_max)
						for node_name in loaded_ks.get("nodes", {}).keys():
							if prof_data["keystones"][ks_name]["nodes"].has(node_name):
								prof_data["keystones"][ks_name]["nodes"][node_name]["purchased"] = loaded_ks["nodes"][node_name].get("purchased", false)

	var loaded_xp_pools = save_data.get("xp_pools", null)
	if loaded_xp_pools != null:
		for xp_type in loaded_xp_pools.keys():
			if xp_pools.has(xp_type):
				xp_pools[xp_type] = int(loaded_xp_pools[xp_type])

	thug_points_available = int(save_data.get("thug_points_available", thug_points_available))

	has_chosen_starting_profession = save_data.get("has_chosen_starting_profession", false)
	_load_crafting_state(save_data)
	if save_data.has("quest_data"):
		quest_system.load_save_data(save_data["quest_data"])
	var loaded_unlocks = save_data.get("professions_unlocked", null)
	if loaded_unlocks != null:
		for profession_name in loaded_unlocks.keys():
			if professions_unlocked.has(profession_name):
				professions_unlocked[profession_name] = loaded_unlocks[profession_name]

	profession_select_ui.visible = not has_chosen_starting_profession

	_refresh_skill_tree_ui()

	player.position = Vector2(save_data["player_position"]["x"], save_data["player_position"]["y"])
	player_max_health = int(save_data.get("player_max_health", player_max_health))
	player_max_action = int(save_data.get("player_max_action", player_max_action))
	adrenaline_boost_bonus_amount = int(save_data.get("adrenaline_boost_bonus_amount", adrenaline_boost_bonus_amount))
	adrenaline_boost_expires_at_unix = float(save_data.get("adrenaline_boost_expires_at_unix", adrenaline_boost_expires_at_unix))
	adrenaline_boost_ready_at_unix = float(save_data.get("adrenaline_boost_ready_at_unix", adrenaline_boost_ready_at_unix))
	blood_bag_bonus_amount = int(save_data.get("blood_bag_bonus_amount", blood_bag_bonus_amount))
	blood_bag_expires_at_unix = float(save_data.get("blood_bag_expires_at_unix", blood_bag_expires_at_unix))
	blood_bag_ready_at_unix = float(save_data.get("blood_bag_ready_at_unix", blood_bag_ready_at_unix))
	player_current_health = int(save_data.get("player_current_health", player_max_health))
	player_current_action = int(save_data.get("player_current_action", player_max_action))
	player_alive = save_data.get("player_alive", true)
	cogs = int(save_data.get("cogs", 0))
	_update_cogs_display()

	var loaded_assignments = save_data.get("action_bar_assignments", null)
	if loaded_assignments != null:
		var slots = [slot_1, slot_2, slot_3, slot_4, slot_5, slot_6, slot_7, slot_8]
		for i in range(slots.size()):
			if i < loaded_assignments.size():
				slots[i].assigned_ability = loaded_assignments[i]
				slots[i].text = loaded_assignments[i] if loaded_assignments[i] != "" else "(empty)"

	_update_inventory_display()

	_show_combat_message("Game loaded!")

# --- Combat ---

func _attempt_attack() -> void:
	_perform_attack(1.0, _get_dynamic_attack_action_cost(), "Attack")

func _attempt_ranged_attack() -> void:
	# Legacy alias -- everything routes through the unified Attack now.
	_attempt_attack()

func _attempt_ability(ability_name: String) -> void:
	var ability = GameData.ability_definitions[ability_name]
	var weapon_class = crafted_item_class.get(equipped_weapon_name, "")

	# No more One Hand/Two Hand distinction -- an ability only cares
	# about the equipped weapon's class (Sword/Axe/Hammer/etc), not
	# whether that weapon happens to be 1- or 2-handed. Bare hands
	# still resolve to Brass Knuckles for Unarmed abilities.
	var effective_weapon_class = weapon_class
	if effective_weapon_class == "" and ability["weapons"].has("Brass Knuckles"):
		effective_weapon_class = "Brass Knuckles"

	if not ability["weapons"].has(effective_weapon_class):
		_show_combat_message(ability_name + " only works with " + ", ".join(ability["weapons"]) + " weapons.")
		return

	var required_box = ability["requires_box"]
	var required_profession = ability["requires_profession"]

	if not professions_unlocked.get(required_profession, false):
		_show_combat_message("You need to be a " + required_profession + " to use " + ability_name + "!")
		return

	var _rp_data = GameData.novice_professions.get(required_profession, {})

	# Keystone-based professions (Street Thug): the ability is usable
	# once its matching node has been purchased in any keystone --
	# same check _is_ability_learned uses for the Ability Book/action
	# bar, so a listed ability and an actually-usable one can never
	# drift apart.
	if _rp_data.has("keystones"):
		var node_purchased = false
		for ks_name in _rp_data["keystones"].keys():
			var ks = _rp_data["keystones"][ks_name]
			if ks["nodes"].has(ability_name) and ks["nodes"][ability_name].get("purchased", false):
				node_purchased = true
				break
		if not node_purchased:
			_show_combat_message("You haven't learned " + ability_name + " yet!")
			return
	elif required_box != "":
		if not _rp_data.has("paths") or not _rp_data["paths"].has(required_box):
			return
		var box_data = _rp_data["paths"][required_box]
		if box_data["unlocked_nodes"] < 1:
			_show_combat_message("You haven't learned " + ability_name + " yet! Unlock " + required_box + " first.")
			return

	_perform_attack(ability["damage_multiplier"], ability["action_cost"], ability_name)

# Maps a weapon's item_class + item_subclass to its Pressure Enforcer
# weapon-type label ("One Hand"/"Two Hand"/"Unarmed"), used to look up
# the matching per-type stat (e.g. "One Hand Speed") for whichever
# weapon is currently equipped. Subclass (not just class) matters here
# since some classes span both -- a Sword can be "1 Handed" (Piston
# Blade) or "2 Handed" (Piston Greatblade), so item_class alone can't
# tell them apart.
func _get_pressure_weapon_type_label(weapon_class: String, weapon_subclass: String) -> String:
	if weapon_class == "Brass Knuckles" or weapon_class == "":
		return "Unarmed"
	elif GameData.pressure_enforcer_weapons.has(weapon_class):
		return "Two Hand" if weapon_subclass == "2 Handed" else "One Hand"
	return ""

# Sums a named passive stat (e.g. "One Hand Speed") across every owned
# skill box in a profession, reading directly from GameData.TALENT_SKILL_REWARDS --
# the same data that drives the Talent Viewer -- so gameplay math and
# what's shown on screen can never drift out of sync.
func _get_total_passive_stat(profession_name: String, stat_name: String) -> float:
	var total = 0.0

	var _paths_data = GameData.novice_professions[profession_name].get("paths", {})
	for path_name in _paths_data.keys():
		var path_data = _paths_data[path_name]
		var owned = path_data["unlocked_nodes"] >= path_data.get("max_nodes", NODES_PER_PATH)
		if not owned:
			continue

		var reward = GameData.TALENT_SKILL_REWARDS.get(profession_name, {}).get(path_name, null)
		if reward == null or reward.get("type", "") != "passive":
			continue

		for stat_pair in reward["stats"]:
			if stat_pair[0] == stat_name:
				total += stat_pair[1]

	return total

# Applies a timed debuff to a target. "damage" reduces their outgoing
# damage (fully functional, applied in the enemy attack functions
# below). "accuracy" is tracked but currently has no live effect --
# there's no hit/miss system yet for reduced accuracy to act on.
# "attack_speed" (Bruise) is fully functional -- it lengthens this
# target's own attack cooldown while active, applied in the enemy
# attack functions below alongside the damage debuff.
# Phase 6b: debuff keys map straight off debuff_type, and the target is
# addressed by id, so this no longer branches per enemy.
const DEBUFF_FIELDS: Dictionary = {
	"damage": "damage_debuff",
	"accuracy": "accuracy_debuff",
	"attack_speed": "attack_speed_debuff",
}


func _apply_debuff(target_id: String, debuff_type: String, amount: float, duration: float) -> void:
	if not enemies.has(target_id) or not DEBUFF_FIELDS.has(debuff_type):
		return
	var field: String = DEBUFF_FIELDS[debuff_type]
	enemies[target_id][field] = amount

	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if enemies.has(target_id):
			enemies[target_id][field] = 0.0
	)


func _apply_dot(target_id: String, damage_per_tick: int, duration_ticks: int) -> void:
	if not enemies.has(target_id):
		return
	enemies[target_id]["bleed_damage_per_tick"] = damage_per_tick
	enemies[target_id]["bleed_ticks_remaining"] = duration_ticks


func _apply_taunt(target_id: String, duration: float) -> void:
	if not enemies.has(target_id):
		return
	enemies[target_id]["taunted_until_msec"] = Time.get_ticks_msec() + int(duration * 1000.0)


func _perform_attack(damage_multiplier: float, action_cost: int, ability_name: String) -> void:
	if not player_alive:
		_show_combat_message("You are defeated! Waiting to respawn...")
		return

	# Bare-hands check: if nothing is equipped and the ability requires
	# a specific weapon, block it. The universal "Attack" always works
	# bare-handed (counts as Brass Knuckles).
	if equipped_weapon_name == "" and ability_name != "Attack":
		var allows_bare_handed = GameData.ability_definitions.has(ability_name) and GameData.ability_definitions[ability_name]["weapons"].has("Brass Knuckles")
		if not allows_bare_handed:
			_show_combat_message("No weapon equipped! Press I to equip one.")
			return

	if not attack_ready:
		return

	var target_id = _get_nearest_enemy_in_range()
	if target_id == "":
		if targeted_enemy == "":
			_show_combat_message("No target! Press Tab or click an enemy to target.")
		else:
			_show_combat_message("Target out of range! Move closer.")
		return

	if action_cost > 0 and player_current_action < action_cost:
		_show_combat_message("Not enough Action! Need " + str(action_cost) + ", have " + str(player_current_action) + ".")
		return

	var weapon_stats = inventory_stats.get(equipped_weapon_name, {})
	var base_damage = weapon_stats.get("Damage Rating", 5)
	var speed = weapon_stats.get("Speed", 2.0)


	var weapon_class = crafted_item_class.get(equipped_weapon_name, "")
	var weapon_subclass = crafted_item_subclass.get(equipped_weapon_name, "")

	# Melee item_class alone can't tell a one-handed weapon from a
	# two-handed one of the same class (e.g. Piston Blade vs Piston
	# Greatblade are both "Sword") -- item_subclass ("1 Handed"/
	# "2 Handed") is what actually distinguishes them, so that's what
	# determines the XP-tracking category for melee weapons. Brass
	# Knuckles stay Unarmed regardless of subclass; ranged weapon
	# classes are unaffected since their subclass always matches their
	# class 1:1 already.
	var xp_class_key = weapon_class
	if weapon_class == "Brass Knuckles" or equipped_weapon_name == "":
		xp_class_key = "Brass Knuckles"
	elif GameData.pressure_enforcer_weapons.has(weapon_class):
		xp_class_key = "Two Hand" if weapon_subclass == "2 Handed" else "One Hand"

	var profession_name = "Street Thug"
	var conditioning_paths = ["Combat Training I", "Combat Training II", "Combat Training III"]

	var conditioning_nodes = 0
	var max_conditioning_nodes = 0
	for path_name in conditioning_paths:
		var _pdata = GameData.novice_professions[profession_name].get("paths", {})
		var path_data = _pdata.get(path_name, null)
		if path_data == null:
			continue
		conditioning_nodes += path_data["unlocked_nodes"]
		max_conditioning_nodes += path_data.get("max_nodes", NODES_PER_PATH)

	# Phase 10: weapon families + proficiency. The governing keystone
	# (Melee or Ranged) sets the proficiency tier for this weapon's family,
	# which grants an accuracy bonus and a faster swing. Certification is
	# resolved HERE rather than inside the damage call, because an
	# uncertified wielder also pays more Action and loses special
	# multipliers -- both needed before the attack resolves.
	var is_uncertified = Combat.is_weapon_uncertified(equipped_weapon_name, professions_unlocked)
	var family_points = Combat.keystone_points_for_family(weapon_class, GameData.novice_professions, profession_name)
	var proficiency = Combat.proficiency_for_family(weapon_class, family_points)

	speed = speed * (1.0 - float(proficiency["speed_pct"]))

	# Uncertified attacks cost more Action.
	action_cost = Combat.adjusted_action_cost(action_cost, is_uncertified)
	if action_cost > 0 and player_current_action < action_cost:
		_show_combat_message("Not enough Action! Uncertified weapons cost more. Need " + str(action_cost) + ", have " + str(player_current_action) + ".")
		return

	# Uncertified wielders cannot land special multipliers.
	damage_multiplier = Combat.adjusted_ability_coefficient(damage_multiplier, is_uncertified)

	# Central damage number: variance roll, crit, profession cert (1.10)
	# and the Phase 10 graded uncertified damage penalty all live in
	# Combat.gd, so the whole damage formula is tuned in one place.
	var weapon_damage_type = "Kinetic"
	var core_effect_strength = 0.0
	for _mod in _installed_mods_for(equipped_weapon_name):
		var _mdef = CraftingData.get_mod(String(_mod.get("mod_id", "")))
		if String(_mdef.get("mod_type", "")) == "core":
			weapon_damage_type = String(_mdef.get("damage_type", "Kinetic"))
			core_effect_strength = float(_mod.get("effect_strength", 0.5))
			break
	var weapon_armor_pen = int(weapon_stats.get("Armor Penetration", 0))
	if weapon_damage_type == "Ballistic" and core_effect_strength > 0.0:
		var ballistic_def = CombatData.SECONDARY_EFFECTS.get("Ballistic", {})
		weapon_armor_pen += int(float(ballistic_def.get("base_amount", 15.0)) * core_effect_strength)

	var attack_result = Combat.compute_player_attack_damage({
		"base_damage": base_damage,
		"damage_multiplier": damage_multiplier,
		"conditioning_nodes": conditioning_nodes,
		"max_conditioning_nodes": max_conditioning_nodes,
		"profession_certified": professions_unlocked.get(profession_name, false),
		"equipped_weapon_name": equipped_weapon_name,
		"professions_unlocked": professions_unlocked,
		"target_crit_resistance": enemies[target_id].get("crit_resist", 0.0)
	})
	var damage = attack_result["damage"]
	var crit_hit = attack_result["crit"]

	# Hit-chance roll: our own formula, weapon Accuracy + player Accuracy
	# bonus (Pressure Enforcer only, for now) vs a flat per-enemy Defense
	# value. BASE_HIT_CHANCE keeps a bare, unskilled attacker landing
	# hits close to half the time; weapon quality and trained Accuracy
	# stats push that up meaningfully from there.
	var weapon_accuracy = weapon_stats.get("Accuracy", 50)
	# Phase 10: accuracy now comes from family proficiency, plus the
	# uncertified penalty if the character isn't certified for this weapon.
	var player_accuracy_bonus = float(proficiency["accuracy"]) + float(Combat.uncertified_accuracy_penalty(is_uncertified))

	var target_defense = enemies[target_id]["defense"]
	var target_node_for_range = enemy_nodes[target_id]["body"]
	var dist_to_target = player.global_position.distance_to(target_node_for_range.global_position)
	var range_penalty = _get_range_accuracy_penalty(weapon_class, dist_to_target)

	var hit_chance = clamp(BASE_HIT_CHANCE + (weapon_accuracy * 0.6) + player_accuracy_bonus - target_defense - range_penalty, MIN_HIT_CHANCE, MAX_HIT_CHANCE)

	if action_cost > 0:
		player_current_action -= action_cost

	# Phase 5: hit -> dodge -> block resolved in Combat.gd. Miss and dodge
	# both end the attack; a block lets it through at half damage.
	var roll = Combat.resolve_defensive_rolls(hit_chance, enemies[target_id].get("dodge", 0.0), enemies[target_id].get("block", 0.0))

	if not roll["hit"] or roll["dodged"]:
		var miss_target_name = enemies[target_id]["name"]
		var miss_message = ""
		if ability_name != "":
			miss_message = ability_name + "! "
		if roll["dodged"]:
			miss_message += miss_target_name + " dodges your attack!"
		else:
			miss_message += "You miss " + miss_target_name + "!"
			if range_penalty >= RANGE_PENALTY_WAY_LESS:
				miss_message += " (Way out of optimal range!)"
			elif range_penalty >= RANGE_PENALTY_REDUCED:
				miss_message += " (Out of optimal range)"
		if action_cost > 0:
			miss_message += " (-" + str(action_cost) + " Action)"
		_show_combat_message(miss_message)

		attack_ready = false
		attack_cooldown_timer.wait_time = speed
		attack_cooldown_timer.start()
		return

	var was_blocked = roll["blocked"]

	var target_name = enemies[target_id]["name"]

	var is_aoe = false
	if ability_name != "" and GameData.ability_definitions.has(ability_name):
		is_aoe = GameData.ability_definitions[ability_name].get("aoe", false)

	var targets_to_hit: Array = []
	if is_aoe:
		for eid in enemies.keys():
			if not enemies[eid]["alive"] or not enemy_nodes.has(eid):
				continue
			if player.global_position.distance_to(enemy_nodes[eid]["body"].global_position) <= MELEE_RANGE:
				targets_to_hit.append(eid)
	else:
		targets_to_hit.append(target_id)

	# Phase 4a/4c: post-armor damage for the primary target (shown in the
	# hit message). Each target is mitigated individually in the apply loop
	# below. Phase 5: the primary target's block (if any) is folded in here
	# for display; other AoE targets roll their own block in the loop.
	var primary_block_mult = roll["damage_mult"] if was_blocked else 1.0
	var primary_damage = Combat.apply_typed_mitigation(int(round(float(damage) * primary_block_mult)), enemies[target_id]["resistances"], weapon_damage_type, weapon_armor_pen)

	var hit_message = ""
	if ability_name != "":
		hit_message = ability_name + "! "
	if was_blocked:
		hit_message += "BLOCKED! "
	if crit_hit:
		hit_message += "CRITICAL HIT! "

	var type_label = "" if weapon_damage_type == "Kinetic" and core_effect_strength <= 0.0 else " " + weapon_damage_type
	if is_aoe and targets_to_hit.size() > 1:
		hit_message += "You hit all nearby enemies for " + str(int(primary_damage)) + type_label + " damage each!"
	else:
		hit_message += "You hit " + target_name + " for " + str(int(primary_damage)) + type_label + " damage!"

	if action_cost > 0:
		hit_message += " (-" + str(action_cost) + " Action)"
	if is_uncertified:
		hit_message += " (Uncertified weapon -- reduced effectiveness)"

	var action_drain_amount = 0
	var debuff_type = ""
	var debuff_amount = 0.0
	var debuff_duration = 0.0
	var dot_damage_per_tick = 0
	var dot_duration_ticks = 0
	var taunt_duration = 0.0
	if ability_name != "" and GameData.ability_definitions.has(ability_name):
		var ability_data = GameData.ability_definitions[ability_name]
		action_drain_amount = ability_data.get("action_drain", 0)
		debuff_type = ability_data.get("debuff", "")
		debuff_amount = ability_data.get("debuff_amount", 0.0)
		debuff_duration = ability_data.get("debuff_duration", 0.0)
		dot_damage_per_tick = ability_data.get("dot_damage_per_tick", 0)
		dot_duration_ticks = ability_data.get("dot_duration_ticks", 0)
		taunt_duration = ability_data.get("taunt_duration", 0.0)

	var defeat_messages: Array = []
	var secondary_procced := ""

	var sec_def = CombatData.SECONDARY_EFFECTS.get(weapon_damage_type, {})
	var sec_effect = String(sec_def.get("effect", ""))

	for hit_target_id in targets_to_hit:
		if String(enemies[hit_target_id].get("ai_state", "idle")) == "leash":
			continue
		var target_block_mult = 1.0
		if hit_target_id == target_id:
			target_block_mult = roll["damage_mult"]
		else:
			var block_pct = enemies[hit_target_id].get("block", 0.0)
			if block_pct > 0.0 and randf() * 100.0 < block_pct:
				target_block_mult = CombatData.BLOCK_DAMAGE_MULTIPLIER
		var dealt = Combat.apply_typed_mitigation(int(round(float(damage) * target_block_mult)), enemies[hit_target_id]["resistances"], weapon_damage_type, weapon_armor_pen)
		var te = enemies[hit_target_id]
		te["current_health"] -= int(dealt)
		te["damage_by_weapon_class"][xp_class_key] = te["damage_by_weapon_class"].get(xp_class_key, 0) + int(dealt)
		if action_drain_amount > 0:
			te["current_action"] = max(0, te["current_action"] - action_drain_amount)
		if debuff_type != "":
			_apply_debuff(hit_target_id, debuff_type, debuff_amount, debuff_duration)
		if dot_duration_ticks > 0:
			_apply_dot(hit_target_id, dot_damage_per_tick, dot_duration_ticks)
		if taunt_duration > 0.0:
			_apply_taunt(hit_target_id, taunt_duration)

		if core_effect_strength > 0.0 and sec_effect != "" and sec_effect != "armor_pierce":
			var chance = float(sec_def.get("base_chance", 0.0)) * core_effect_strength
			if randf() * 100.0 < chance:
				var amt = float(sec_def.get("base_amount", 0.0)) * core_effect_strength
				var dur = float(sec_def.get("duration", 0.0))
				secondary_procced = String(sec_def.get("label", ""))
				if sec_effect == "damage_debuff":
					_apply_debuff(hit_target_id, "damage", amt, dur)
				elif sec_effect == "attack_speed_debuff":
					_apply_debuff(hit_target_id, "attack_speed", amt, dur)
				elif sec_effect == "burn_dot":
					te["burn_damage_per_tick"] = int(round(amt))
					te["burn_ticks_remaining"] = int(round(dur))
				elif sec_effect == "poison_dot":
					te["poison_damage_per_tick"] = int(round(amt))
					te["poison_ticks_remaining"] = int(round(dur))
				elif sec_effect == "stagger":
					te["stagger_until_msec"] = Time.get_ticks_msec() + int(dur * 1000.0)

		if te["current_health"] <= 0 or te["current_action"] <= 0:
			defeat_messages.append(_defeat_enemy(hit_target_id))

	if action_drain_amount > 0:
		hit_message += " (-" + str(action_drain_amount) + " Enemy Action)"
	if debuff_type == "damage":
		hit_message += " (" + ability_name + " applied -- target deals reduced damage)"
	elif debuff_type == "accuracy":
		hit_message += " (" + ability_name + " applied -- target accuracy reduced)"
	elif debuff_type == "attack_speed":
		hit_message += " (" + ability_name + " applied -- target attacks slower)"
	if dot_duration_ticks > 0:
		hit_message += " (" + ability_name + " applied -- " + str(dot_damage_per_tick) + " damage/sec for " + str(dot_duration_ticks) + " seconds)"
	if taunt_duration > 0.0:
		hit_message += " (" + ability_name + " applied -- target is enraged)"
	if secondary_procced != "":
		hit_message += " [" + secondary_procced + "!]"

	# Combine damage-dealt text with any defeat/loot messages into ONE
	# message instead of two competing _show_combat_message() calls --
	# previously the defeat message was shown first, then immediately
	# overwritten by the damage message before it could ever be seen.
	for defeat_message in defeat_messages:
		hit_message += "\n" + defeat_message

	_show_combat_message(hit_message)

	attack_ready = false
	attack_cooldown_timer.wait_time = speed
	attack_cooldown_timer.start()

func _on_attack_cooldown_finished() -> void:
	attack_ready = true

func _get_nearest_enemy_in_range() -> String:
	var weapon_class = crafted_item_class.get(equipped_weapon_name, "")
	var attack_range: float
	if weapon_class == "Pistol":
		attack_range = ENGAGE_RANGE_PISTOL
	elif weapon_class == "Sniper Rifle":
		attack_range = ENGAGE_RANGE_SNIPER
	elif GameData.rifle_weapons.has(weapon_class):
		attack_range = ENGAGE_RANGE_RIFLE
	elif weapon_class == "Shotgun":
		attack_range = ENGAGE_RANGE_SHOTGUN
	elif GameData.heavy_weapon_types.has(weapon_class):
		attack_range = ENGAGE_RANGE_HEAVY
	else:
		attack_range = MELEE_RANGE

	# Single-target attacks REQUIRE an explicit target (set via Tab or
	# click). No auto-targeting nearest -- you have to consciously pick
	# who you're attacking. AoE abilities bypass this entirely and hit
	# everything in range from _perform_attack's own AoE block.
	if targeted_enemy == "":
		return ""

	var target_node = enemy_nodes[targeted_enemy]["body"]
	var target_alive = enemies[targeted_enemy]["alive"] if enemies.has(targeted_enemy) else false

	if not target_alive:
		targeted_enemy = ""
		return ""

	var d = player.global_position.distance_to(target_node.global_position)
	if d <= attack_range:
		return targeted_enemy

	return ""

func _build_enemy_node_registry() -> void:
	enemy_nodes.clear()
	for enemy_id in ENEMY_SPAWN_TABLE.keys():
		_spawn_enemy(String(enemy_id))
	_spawn_lair_enemies()


func _spawn_lair_enemies() -> void:
	for lair_id in LAIR_SPAWN_TABLE.keys():
		var lair = LAIR_SPAWN_TABLE[lair_id]
		var center: Vector2 = lair["center"]
		var radius = float(lair.get("spawn_radius", 80.0))
		var count = lair["members"].size()
		for i in range(count):
			var m = lair["members"][i]
			var eid = lair_id + "_" + str(i)
			var angle = (float(i) / float(count)) * TAU
			var offset = Vector2(cos(angle), sin(angle)) * radius * 0.5
			var spawn = m.duplicate(true)
			spawn["position"] = center + offset
			spawn["lair_id"] = lair_id
			_spawn_enemy(eid, spawn)
		var nm_def = lair.get("nm", {})
		if not nm_def.is_empty():
			var replace_idx = int(nm_def.get("replaces_index", 0))
			var target_eid = lair_id + "_" + str(replace_idx)
			if enemy_nodes.has(target_eid):
				enemy_nodes[target_eid]["nm_def"] = nm_def


# Instantiates one enemy and registers its nodes. Safe to call again for
# the same id -- the previous instance is freed first.
func _spawn_enemy(enemy_id: String, spawn_override: Dictionary = {}) -> void:
	var spawn: Dictionary = spawn_override if not spawn_override.is_empty() else ENEMY_SPAWN_TABLE.get(enemy_id, {})
	if spawn.is_empty():
		push_error("[ENEMY] No spawn entry for id: " + enemy_id)
		return

	var scene = load(ENEMY_SCENE_PATH)
	if scene == null:
		push_error("[ENEMY] Could not load " + ENEMY_SCENE_PATH)
		return

	var parent = get_node_or_null("World/YSortLayer/Enemies")
	if parent == null:
		parent = get_node_or_null("World/YSortLayer")
	if parent == null:
		push_error("[ENEMY] No World/YSortLayer to spawn into.")
		return

	if enemy_nodes.has(enemy_id) and is_instance_valid(enemy_nodes[enemy_id]["body"]):
		enemy_nodes[enemy_id]["body"].queue_free()

	var body: Node2D = scene.instantiate()
	body.name = enemy_id
	body.position = spawn.get("position", Vector2.ZERO)
	parent.add_child(body)

	var visual: Sprite2D = body.get_node("Visual")
	var tex = load(ENEMY_SPRITE_PATH)
	if tex != null:
		visual.texture = tex
	visual.scale = spawn.get("sprite_scale", Vector2.ONE)
	visual.modulate = spawn.get("tint", Color(1, 1, 1, 1))

	var health_bg: Polygon2D = body.get_node("HealthBarBg")
	var health_fill: Polygon2D = body.get_node("HealthBarFill")
	var action_bg: Polygon2D = body.get_node("ActionBarBg")
	var action_fill: Polygon2D = body.get_node("ActionBarFill")
	var name_label: Label = body.get_node("NameLabel")
	var indicator: Line2D = body.get_node("TargetIndicator")
	var attack_timer: Timer = body.get_node("AttackCooldownTimer")
	var respawn_timer: Timer = body.get_node("RespawnTimer")

	# Bars are children now, so these local offsets are set ONCE and the
	# bars track the enemy for free.
	var bar_offset = Vector2(-HEALTH_BAR_WIDTH / 2.0, -60.0)
	health_bg.position = bar_offset
	health_fill.position = bar_offset
	action_bg.position = bar_offset + Vector2(0, ACTION_BAR_GAP)
	action_fill.position = bar_offset + Vector2(0, ACTION_BAR_GAP)

	name_label.position = Vector2(-NAME_LABEL_WIDTH / 2.0, bar_offset.y - 24.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(NAME_LABEL_WIDTH, 0)

	_style_target_indicator(indicator)
	indicator.position = bar_offset
	indicator.visible = false

	attack_timer.one_shot = true
	attack_timer.wait_time = float(spawn.get("attack_cooldown", 2.5))
	attack_timer.timeout.connect(_on_enemy_attack_cooldown_finished.bind(enemy_id))

	respawn_timer.one_shot = true
	respawn_timer.wait_time = float(spawn.get("respawn_time", 8.0))
	respawn_timer.timeout.connect(_on_enemy_respawn.bind(enemy_id))

	enemy_nodes[enemy_id] = {
		"body": body,
		"health_bg": health_bg,
		"health_fill": health_fill,
		"action_bg": action_bg,
		"action_fill": action_fill,
		"name_label": name_label,
		"indicator": indicator,
		"attack_timer": attack_timer,
		"respawn_timer": respawn_timer,
		"kill_xp": int(spawn.get("kill_xp", 0)),
		"loot_key": String(spawn.get("loot_key", enemy_id)),
		"attack_cooldown": float(spawn.get("attack_cooldown", 2.5)),
		"home_position": spawn.get("position", Vector2.ZERO),
		"aggro_range": float(spawn.get("aggro_range", DEFAULT_AGGRO_RANGE)),
		"chase_speed": float(spawn.get("chase_speed", DEFAULT_CHASE_SPEED)),
		"leash_range": float(spawn.get("leash_range", DEFAULT_LEASH_RANGE)),
		"patrol_radius": float(spawn.get("patrol_radius", DEFAULT_PATROL_RADIUS)),
		"lair_id": String(spawn.get("lair_id", "")),
		"spawn_data": spawn.duplicate(true),
		"nm_def": spawn.get("nm", {}),
	}

func _set_enemy_visible(enemy_id: String, is_visible: bool) -> void:
	if not enemy_nodes.has(enemy_id):
		return
	var n = enemy_nodes[enemy_id]
	n["body"].visible = is_visible
	n["health_bg"].visible = is_visible
	n["health_fill"].visible = is_visible
	n["action_bg"].visible = is_visible
	n["action_fill"].visible = is_visible
	n["name_label"].visible = is_visible


# Replaces the old per-enemy defeat functions. Awards kill XP split by
# the weapon classes that contributed damage, rolls loot and cogs, hides
# the enemy and starts its respawn timer.
func _defeat_enemy(enemy_id: String) -> String:
	if not enemies.has(enemy_id) or not enemy_nodes.has(enemy_id):
		return ""
	var e = enemies[enemy_id]
	var n = enemy_nodes[enemy_id]

	e["alive"] = false
	if targeted_enemy == enemy_id:
		targeted_enemy = ""
	quest_system.on_enemy_killed()
	_set_enemy_visible(enemy_id, false)

	var total_damage_dealt = 0
	for wc in e["damage_by_weapon_class"].keys():
		total_damage_dealt += e["damage_by_weapon_class"][wc]

	var xp_summary_parts: Array = []
	if total_damage_dealt > 0:
		for wc in e["damage_by_weapon_class"].keys():
			var damage_share = float(e["damage_by_weapon_class"][wc]) / float(total_damage_dealt)
			var share_xp = int(round(float(n["kill_xp"]) * damage_share))
			if share_xp <= 0:
				continue
			_add_skill_xp("Combat XP", share_xp)
			xp_summary_parts.append(str(share_xp) + " Combat XP")

	if xp_summary_parts.size() > 0:
		_show_xp_gain_message("You've gained " + ", ".join(xp_summary_parts) + "!")

	e["damage_by_weapon_class"] = {}

	var dropped_items = _roll_loot(n["loot_key"], int(e.get("cl", 1)))
	_update_inventory_display()

	var cogs_dropped = randi_range(COGS_MIN_DROP, COGS_MAX_DROP)
	cogs += cogs_dropped
	_update_cogs_display()

	var defeat_message = ""
	if e.get("is_nm", false):
		defeat_message = "NOTORIOUS MONSTER " + e["name"] + " has been slain!\n"
	else:
		defeat_message = e["name"] + " has been defeated!\n"
	if dropped_items.size() > 0:
		defeat_message += "Loot: "
		for i in range(dropped_items.size()):
			defeat_message += dropped_items[i]
			if i < dropped_items.size() - 1:
				defeat_message += ", "
		defeat_message += ", " + str(cogs_dropped) + " Cogs"
	else:
		defeat_message += "Loot: " + str(cogs_dropped) + " Cogs"

	var lair_id = String(n.get("lair_id", ""))
	if e.get("is_nm", false) and lair_id != "":
		var lair_def = LAIR_SPAWN_TABLE.get(lair_id, {})
		var lair_type = String(lair_def.get("lair_type", lair_id))
		nm_active_by_type[lair_type] = false

	if lair_id == "":
		n["respawn_timer"].start()
	else:
		_check_lair_cleared(lair_id)
	return defeat_message


func _reset_enemy(enemy_id: String) -> void:
	if not enemies.has(enemy_id):
		return
	var e = enemies[enemy_id]
	e["alive"] = true
	e["is_nm"] = false
	e["damage_debuff"] = 0.0
	e["accuracy_debuff"] = 0.0
	e["attack_speed_debuff"] = 0.0
	e["bleed_ticks_remaining"] = 0
	e["bleed_damage_per_tick"] = 0
	e["burn_ticks_remaining"] = 0
	e["burn_damage_per_tick"] = 0
	e["poison_ticks_remaining"] = 0
	e["poison_damage_per_tick"] = 0
	e["stagger_until_msec"] = 0
	e["taunted_until_msec"] = 0
	e["damage_by_weapon_class"] = {}
	e["ai_state"] = "idle"
	e["ai_target"] = ""
	if enemy_nodes.has(enemy_id):
		var n = enemy_nodes[enemy_id]
		var base = n.get("spawn_data", {})
		if not base.is_empty():
			e["name"] = String(base.get("display_name", e["name"]))
			e["cl"] = int(base.get("cl", e["cl"]))
			e["archetype"] = String(base.get("archetype", e["archetype"]))
			e["faction"] = String(base.get("faction", e["faction"]))
			n["kill_xp"] = int(base.get("kill_xp", n["kill_xp"]))
			n["loot_key"] = String(base.get("loot_key", n["loot_key"]))
			var visual: Sprite2D = n["body"].get_node("Visual")
			visual.modulate = base.get("tint", Color(1, 1, 1, 1))
		_apply_cl_derivation(enemy_id)
		n["name_label"].text = e["name"]
		n["body"].position = n["home_position"]
	else:
		e["current_health"] = e["max_health"]
		e["current_action"] = e["max_action"]
	_set_enemy_visible(enemy_id, true)


func _on_enemy_respawn(enemy_id: String) -> void:
	if not enemies.has(enemy_id):
		return
	_reset_enemy(enemy_id)
	_show_combat_message(enemies[enemy_id]["name"] + " has respawned.")
	if enemy_nodes.has(enemy_id):
		var nm_def = enemy_nodes[enemy_id].get("nm_def", {})
		if not nm_def.is_empty():
			if randf() < float(nm_def.get("spawn_chance", 0.0)):
				_promote_to_nm(enemy_id)


func _check_lair_cleared(lair_id: String) -> void:
	for eid in enemies.keys():
		if not enemy_nodes.has(eid):
			continue
		if String(enemy_nodes[eid].get("lair_id", "")) != lair_id:
			continue
		if enemies[eid]["alive"]:
			return
	var lair_def = LAIR_SPAWN_TABLE.get(lair_id, {})
	_show_combat_message(String(lair_def.get("display_name", lair_id)) + " has been cleared!")
	get_tree().create_timer(3.5).timeout.connect(_on_lair_nm_roll.bind(lair_id))


func _on_lair_nm_roll(lair_id: String) -> void:
	var lair_def = LAIR_SPAWN_TABLE.get(lair_id, {})
	var lair_type = String(lair_def.get("lair_type", lair_id))
	if nm_active_by_type.get(lair_type, false):
		return
	var nm_def = lair_def.get("nm", {})
	if nm_def.is_empty():
		return
	if randf() >= float(nm_def.get("spawn_chance", 0.0)):
		return
	var replace_idx = int(nm_def.get("replaces_index", 0))
	var target_eid = lair_id + "_" + str(replace_idx)
	if not enemies.has(target_eid):
		return
	_reset_enemy(target_eid)
	_promote_to_nm(target_eid)
	nm_active_by_type[lair_type] = true


func _promote_to_nm(enemy_id: String) -> void:
	var e = enemies[enemy_id]
	var n = enemy_nodes[enemy_id]
	var nm_def = n.get("nm_def", {})
	e["name"] = String(nm_def.get("display_name", e["name"]))
	if nm_def.has("cl"):
		e["cl"] = int(nm_def["cl"])
	if nm_def.has("archetype"):
		e["archetype"] = String(nm_def["archetype"])
	if nm_def.has("faction"):
		e["faction"] = String(nm_def["faction"])
	n["kill_xp"] = int(nm_def.get("kill_xp", n["kill_xp"]))
	n["loot_key"] = String(nm_def.get("loot_key", n["loot_key"]))
	e["is_nm"] = true
	_apply_cl_derivation(enemy_id)
	n["name_label"].text = e["name"]
	if nm_def.has("tint"):
		var visual: Sprite2D = n["body"].get_node("Visual")
		visual.modulate = nm_def["tint"]
	_show_combat_message("A Notorious Monster has appeared: " + e["name"] + "!")



# --- Skills ---

# Maps a logical activity source to the XP pool it currently feeds.
# Before the player specializes, sources like Healing and Scavenging
# all funnel into the base Combat XP pool -- there is only one combat
# progression track at that stage. Once specializations are unlocked,
# this is the single place to branch a given source into its own XP
# type (e.g. Healing -> "Medical XP" for a medic specialization).
# Callers use the returned pool name for BOTH the _add_skill_xp call
# and the on-screen message, so the label and the destination always
# stay in sync automatically.
func _resolve_xp_pool(source: String) -> String:
	# TODO: branch by unlocked specialization once those trees exist.
	match source:
		"Healing":
			return "Combat XP"
		"Scavenging":
			return "Crafting XP"
		_:
			return "Combat XP"

func _add_skill_xp(xp_type: String, amount: int) -> void:
	if not xp_pools.has(xp_type):
		return

	# XP pools are UNCAPPED. _get_xp_type_cap() exists to scale a display
	# bar, and clamping earnings to it was silently destroying XP -- the
	# cap resolved to 15 (cheapest keystone cost x1.5) while a single
	# kill awards 50+, so most of every kill was thrown away.
	xp_pools[xp_type] = xp_pools[xp_type] + amount

func _get_box_cost(path_data: Dictionary) -> Dictionary:
	if path_data.has("xp_cost"):
		return {"xp_cost": path_data["xp_cost"], "point_cost": path_data["point_cost"], "cogs_cost": path_data["cogs_cost"]}

	var next_index = path_data["unlocked_nodes"]
	return {"xp_cost": skill_xp_thresholds[next_index], "point_cost": skill_point_costs[next_index], "cogs_cost": skill_cogs_costs[next_index]}

func _is_prereq_met(profession_name: String, path_data: Dictionary) -> bool:
	var prereq_name = path_data.get("requires", "")
	if prereq_name == "":
		return true

	if prereq_name == "__ALL__":
		var prof_paths = GameData.novice_professions[profession_name].get("paths", {})
		for other_path_name in prof_paths.keys():
			if other_path_name == "Master":
				continue
			var other_path_data = prof_paths[other_path_name]
			var other_max = other_path_data.get("max_nodes", NODES_PER_PATH)
			if other_path_data["unlocked_nodes"] < other_max:
				return false
		return true

	var _pp = GameData.novice_professions[profession_name].get("paths", {})
	if not _pp.has(prereq_name):
		return true
	var prereq_data = _pp[prereq_name]
	var prereq_max = prereq_data.get("max_nodes", NODES_PER_PATH)
	return prereq_data["unlocked_nodes"] >= prereq_max

func _get_xp_type_cap(xp_type: String) -> int:
	# For keystone professions: find the cheapest keystone not yet
	# unlocked that uses this XP type, and return its cost * 1.5
	# as the "cap" (used to scale the XP gain display bar).
	# For path professions: original logic.
	var lowest_ks_cost = -1
	var highest_path_cost = 0
	var has_path_style = false

	for profession_name in GameData.novice_professions.keys():
		var prof_data = GameData.novice_professions[profession_name]
		if prof_data.has("keystones"):
			for ks_name in prof_data["keystones"].keys():
				var ks = prof_data["keystones"][ks_name]
				if ks.get("xp_type", "Combat XP") != xp_type:
					continue
				if ks.get("unlocked", false):
					continue
				var cost = ks.get("xp_cost", 10)
				if lowest_ks_cost == -1 or cost < lowest_ks_cost:
					lowest_ks_cost = cost
		elif prof_data.has("paths"):
			for path_name in prof_data["paths"].keys():
				var path_data = prof_data["paths"][path_name]
				if path_data.get("xp_type", "") != xp_type:
					continue
				has_path_style = true
				if path_data.has("xp_cost"):
					highest_path_cost = max(highest_path_cost, path_data["xp_cost"])

	if lowest_ks_cost != -1:
		return int(lowest_ks_cost * 1.5)
	if has_path_style:
		return int(highest_path_cost * 1.5)
	# Nothing left to save toward -- every keystone (and path, if any)
	# using this XP type is already unlocked. Falling back to the old
	# pre-keystone skill_xp_thresholds[0] here used to collapse the cap
	# to 1, silently freezing the pool forever. Once everything is
	# unlocked there's no purchase left to scale a progress bar toward,
	# so just stop capping.
	return 999999999


func _refresh_skill_tree_ui() -> void:
	# Legacy debug skill tree -- replaced by the new keystone/node
	# system. Stubbed out to prevent crashes while the new Talent
	# Viewer UI is being built.
	skill_tree.clear()
	var root = skill_tree.create_item()
	skill_tree.hide_root = true
	var notice = skill_tree.create_item(root)
	notice.set_text(0, "Talent system redesigned -- use the Talent Viewer (T)")
	notice.set_selectable(0, false)

func _on_skill_tree_item_selected() -> void:
	var selected = skill_tree.get_selected()
	if selected == null:
		return

	var metadata = selected.get_metadata(0)
	if metadata == null:
		return

	var parts = metadata.split("|")
	selected_profession = parts[0]
	selected_path = parts[1]

	_update_skill_info_display()

func _xp_label(xp_type: String) -> String:
	if xp_type.ends_with("XP"):
		return xp_type
	return xp_type + " XP"

func _build_skill_info_text(profession_name: String, path_name: String) -> String:
	var _pdata = GameData.novice_professions[profession_name].get("paths", {})
	var path_data = _pdata.get(path_name, null)
	if path_data == null:
		return profession_name + " uses the new keystone system."
	var xp_type = path_data["xp_type"]
	var xp = xp_pools[xp_type]
	var unlocked = path_data["unlocked_nodes"]
	var max_nodes = path_data.get("max_nodes", NODES_PER_PATH)
	var cap = _get_xp_type_cap(xp_type)

	var info = _points_pool_label(profession_name) + ": " + str(_get_points_available(profession_name)) + "\nCogs: " + str(cogs) + "\n\n"
	info += profession_name + " - " + path_name
	info += "\nNodes Unlocked: " + str(unlocked) + " / " + str(max_nodes)
	info += "\n" + _xp_label(xp_type) + ": " + str(xp) + " / " + str(cap) + " cap"

	if unlocked < max_nodes:
		if not _is_prereq_met(profession_name, path_data):
			info += "\n\nLocked -- requires " + path_data["requires"] + " first."
		else:
			var costs = _get_box_cost(path_data)
			var xp_cost = costs["xp_cost"]
			var point_cost = costs["point_cost"]
			var cogs_cost = costs["cogs_cost"]

			info += "\n\nCost:"
			info += "\n  " + str(xp_cost) + " " + _xp_label(xp_type)
			info += " (have enough)" if xp >= xp_cost else " (need " + str(xp_cost - xp) + " more)"
			info += "\n  " + str(point_cost) + " " + _points_pool_label(profession_name).trim_suffix("s") + (("s" if point_cost != 1 else ""))
			info += " (have enough)" if _get_points_available(profession_name) >= point_cost else " (need more)"
			info += "\n  " + str(cogs_cost) + " Cogs"
			info += " (have enough)" if cogs >= cogs_cost else " (need " + str(cogs_cost - cogs) + " more)"
	else:
		info += "\n\nFully unlocked!"

	return info

func _update_skill_info_display() -> void:
	skill_info_label.text = _build_skill_info_text(selected_profession, selected_path)

func _on_spend_point_pressed() -> void:
	if selected_profession == "" or selected_path == "":
		skill_result_label.text = "Select a path first!"
		return

	if not professions_unlocked.get(selected_profession, false):
		skill_result_label.text = "You haven't unlocked " + selected_profession + " yet!"
		return

	var nearby_trainer_index = _get_nearest_trainer_in_range()
	if nearby_trainer_index == -1:
		skill_result_label.text = "You must be near a trainer to learn this!"
		return

	var nearby_trainer = trainers[nearby_trainer_index]
	if selected_profession != nearby_trainer["profession"]:
		skill_result_label.text = nearby_trainer["name"] + " only trains " + nearby_trainer["profession"] + " skills!"
		return

	var prof_data = GameData.novice_professions[selected_profession]
	if not prof_data.has("paths"):
		skill_result_label.text = selected_profession + " uses the new keystone system -- use the Talent Viewer instead."
		return

	var path_data = prof_data["paths"][selected_path]
	var xp_type = path_data["xp_type"]
	var max_nodes = path_data.get("max_nodes", NODES_PER_PATH)

	if path_data["unlocked_nodes"] >= max_nodes:
		skill_result_label.text = selected_path + " is already fully unlocked!"
		return

	if not _is_prereq_met(selected_profession, path_data):
		skill_result_label.text = "You must complete " + path_data["requires"] + " first!"
		return

	var costs = _get_box_cost(path_data)
	var xp_cost = costs["xp_cost"]
	var point_cost = costs["point_cost"]
	var cogs_cost = costs["cogs_cost"]
	var current_xp = xp_pools[xp_type]

	if current_xp < xp_cost:
		skill_result_label.text = "Not enough " + _xp_label(xp_type) + "! Need " + str(xp_cost) + ", have " + str(current_xp) + "."
		return

	if _get_points_available(selected_profession) < point_cost:
		var pool_label = _points_pool_label(selected_profession)
		skill_result_label.text = "Not enough " + pool_label + "! Need " + str(point_cost) + ", have " + str(_get_points_available(selected_profession)) + "."
		return

	if cogs < cogs_cost:
		skill_result_label.text = "Not enough Cogs! Need " + str(cogs_cost) + ", have " + str(cogs) + "."
		return

	xp_pools[xp_type] -= xp_cost
	_spend_points(selected_profession, point_cost)
	cogs -= cogs_cost
	_update_cogs_display()
	path_data["unlocked_nodes"] += 1

	skill_result_label.text = selected_path + " unlocked! (-" + str(point_cost) + " Skill Point" + ("s" if point_cost != 1 else "") + ", -" + str(cogs_cost) + " Cogs)"

	_refresh_skill_tree_ui()
	_update_skill_info_display()

func _show_combat_message(text: String) -> void:
	combat_message_label.text = text
	message_clear_timer.start()

func _on_message_clear_timer_timeout() -> void:
	combat_message_label.text = ""

# Separate display slot, positioned directly below the main combat
# message, so "the dummy hits you" text never competes with (and
# silently overwrites) "you hit the dummy" text -- they're two
# different channels now instead of one shared label.
func _setup_enemy_combat_message_label() -> void:
	enemy_combat_message_label = Label.new()
	enemy_combat_message_label.name = "EnemyCombatMessageLabel"
	$UILayer.add_child(enemy_combat_message_label)
	enemy_combat_message_label.horizontal_alignment = combat_message_label.horizontal_alignment
	enemy_combat_message_label.custom_minimum_size = combat_message_label.custom_minimum_size
	enemy_combat_message_label.modulate = combat_message_label.modulate
	enemy_combat_message_label.position = combat_message_label.position + Vector2(0, 28)
	enemy_combat_message_label.text = ""

func _show_enemy_combat_message(text: String) -> void:
	enemy_combat_message_label.text = text
	var timer = get_tree().create_timer(message_clear_timer.wait_time)
	timer.timeout.connect(func():
		if enemy_combat_message_label.text == text:
			enemy_combat_message_label.text = ""
	)

func _show_xp_gain_message(text: String) -> void:
	xp_gain_label.text = text
	xp_gain_clear_timer.start()

func _on_xp_gain_clear_timer_timeout() -> void:
	xp_gain_label.text = ""

# Entry requirements for Elite Professions -- each entry must reference

# Returns true if every box in the given profession's tree is fully
# unlocked. This is the definition of "mastered" -- required before
# the player can do the unlock quest for the next tier.
func _is_profession_mastered(profession_name: String) -> bool:
	if not professions_unlocked.get(profession_name, false):
		return false
	var prof_data = GameData.novice_professions[profession_name]
	# New keystone-based professions (Street Thug) use keystones not paths
	if prof_data.has("keystones"):
		for ks_name in prof_data["keystones"].keys():
			var ks = prof_data["keystones"][ks_name]
			if not ks.get("unlocked", false):
				return false
			if ks.get("points_spent", 0) < ks.get("points_max", 0):
				return false
		return true
	# Legacy path-based professions (shell classes)
	if not prof_data.has("paths"):
		return false
	var paths = prof_data["paths"]
	for path_name in paths.keys():
		var path_data = paths[path_name]
		if path_data["unlocked_nodes"] < path_data.get("max_nodes", NODES_PER_PATH):
			return false
	return true

# Returns a list of human-readable strings for any mastery prereqs not
# yet met. Empty array means the profession's unlock quest is available.
func _get_missing_profession_prereqs(profession_name: String) -> Array:
	var missing: Array = []
	var tree_entry = GameData.PROFESSION_TREE.get(profession_name, {})
	for required in tree_entry.get("requires_mastered", []):
		if not _is_profession_mastered(required):
			missing.append("Master " + required)
	# Mastery professions additionally require both elite classes mastered
	var pair = tree_entry.get("mastery_pair", [])
	if pair.size() == 2:
		for elite in pair:
			if not _is_profession_mastered(elite):
				missing.append("Master " + elite)
	return missing

# Given a profession and one of its box names, returns which higher-tier
# professions list that profession as a prerequisite -- used by the
# Talent Viewer to show "leads to X" labels above the Master box.
func _get_elites_requiring(profession_name: String, box_name: String) -> Array:
	if box_name != "Master":
		return []
	var result: Array = []
	for next_name in GameData.PROFESSION_TREE.keys():
		var entry = GameData.PROFESSION_TREE[next_name]
		if profession_name in entry.get("requires_mastered", []):
			result.append(next_name)
	return result

func _on_choose_profession_pressed() -> void:
	var selection = profession_options_list.get_selected_items()
	if selection.size() == 0:
		profession_select_result_label.text = "Select a profession first!"
		return

	var chosen_profession = profession_options_list.get_item_text(selection[0])

	var missing_prereqs = _get_missing_profession_prereqs(chosen_profession)
	if missing_prereqs.size() > 0:
		profession_select_result_label.text = "Requires: " + ", ".join(missing_prereqs)
		return

	if not has_chosen_starting_profession:
		professions_unlocked[chosen_profession] = true
		has_chosen_starting_profession = true
		_grant_novice_unlock(chosen_profession)
		_grant_profession_starting_kit(chosen_profession)

		profession_select_ui.visible = false
		_refresh_skill_tree_ui()

		_show_combat_message("You are now a " + chosen_profession + "!")
		return

	if professions_unlocked.get(chosen_profession, false):
		profession_select_result_label.text = "You've already learned " + chosen_profession + "!"
		return

	var nearby_trainer_index2 = _get_nearest_trainer_in_range()
	if nearby_trainer_index2 == -1:
		profession_select_result_label.text = "You must be near a trainer to learn this!"
		return

	var nearby_trainer2 = trainers[nearby_trainer_index2]
	if chosen_profession != nearby_trainer2["profession"]:
		profession_select_result_label.text = nearby_trainer2["name"] + " only trains " + nearby_trainer2["profession"] + "!"
		return

	if _get_points_available(chosen_profession) < PROFESSION_ENTRY_COST:
		profession_select_result_label.text = "Not enough " + _points_pool_label(chosen_profession) + "! Need " + str(PROFESSION_ENTRY_COST) + "."
		return

	if cogs < ADDITIONAL_PROFESSION_COGS_COST:
		profession_select_result_label.text = "Not enough Cogs! Need " + str(ADDITIONAL_PROFESSION_COGS_COST) + ", have " + str(cogs) + "."
		return

	_spend_points(chosen_profession, PROFESSION_ENTRY_COST)
	cogs -= ADDITIONAL_PROFESSION_COGS_COST
	_update_cogs_display()
	professions_unlocked[chosen_profession] = true
	_grant_novice_unlock(chosen_profession)

	_refresh_skill_tree_ui()

	_show_combat_message("You have learned " + chosen_profession + "! (-" + str(PROFESSION_ENTRY_COST) + " " + _points_pool_label(chosen_profession) + ", -" + str(ADDITIONAL_PROFESSION_COGS_COST) + " Cogs)")

# --- Health/Action Bars ---

func _make_bar_polygon(width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, 0),
		Vector2(width, 0),
		Vector2(width, height),
		Vector2(0, height)
	])

func _setup_health_bars() -> void:
	# Enemy bars are configured per-instance in _spawn_enemy now; this
	# handles the player HUD and the tracked-enemy HUD only.
	var bg_color = Color(0.1, 0.1, 0.1)
	var health_color = Color(0.8, 0.1, 0.1)
	var action_color = Color(0.1, 0.8, 0.1)

	for bar in [player_health_bar_bg, player_action_bar_bg, enemy_hud_health_bar_bg, enemy_hud_action_bar_bg]:
		bar.color = bg_color
		bar.polygon = _make_bar_polygon(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	player_health_bar_fill.color = health_color
	enemy_hud_health_bar_fill.color = health_color
	player_action_bar_fill.color = action_color
	enemy_hud_action_bar_fill.color = action_color

	for fill in [player_health_bar_fill, player_action_bar_fill, enemy_hud_health_bar_fill, enemy_hud_action_bar_fill]:
		fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	# Every spawned enemy's own bars.
	for enemy_id in enemy_nodes.keys():
		var n = enemy_nodes[enemy_id]
		n["health_bg"].color = bg_color
		n["action_bg"].color = bg_color
		n["health_fill"].color = health_color
		n["action_fill"].color = action_color
		for p in [n["health_bg"], n["health_fill"], n["action_bg"], n["action_fill"]]:
			p.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
		n["name_label"].text = _get_enemy_display_text(String(enemy_id))

	# Player bars live inside a single PlayerHUD node under UILayer.
	# Its actual screen position is calculated in _layout_hud(), relative
	# to the ActionBar, so the two always stay aligned automatically.
	player_health_bar_bg.position = Vector2.ZERO
	player_health_bar_fill.position = Vector2.ZERO
	player_action_bar_bg.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	player_action_bar_fill.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)

	enemy_hud_health_bar_bg.position = Vector2.ZERO
	enemy_hud_health_bar_fill.position = Vector2.ZERO
	enemy_hud_action_bar_bg.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	enemy_hud_action_bar_fill.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	enemy_hud.visible = false

	for label in [player_hud_health_label, player_hud_action_label, enemy_hud_health_label, enemy_hud_action_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)
		label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)
		label.add_theme_font_size_override("font_size", 11)

	player_hud_health_label.position = Vector2.ZERO
	player_hud_action_label.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	enemy_hud_health_label.position = Vector2.ZERO
	enemy_hud_action_label.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
func _make_target_indicator() -> Line2D:
	var line = Line2D.new()
	line.default_color = Color(0.95, 0.75, 0.2)
	line.width = 2.0
	line.closed = true
	line.points = PackedVector2Array([
		Vector2(-3.0, -3.0),
		Vector2(HEALTH_BAR_WIDTH + 3.0, -3.0),
		Vector2(HEALTH_BAR_WIDTH + 3.0, HEALTH_BAR_HEIGHT * 2 + ACTION_BAR_GAP + 3.0),
		Vector2(-3.0, HEALTH_BAR_HEIGHT * 2 + ACTION_BAR_GAP + 3.0)
	])
	line.visible = false
	return line

func _process(delta: float) -> void:
	_update_health_bars()
	for eid in enemies.keys():
		_update_enemy_ai(eid, delta)

func _update_health_bars() -> void:
	for t in trainers:
		var t_center_x = t["node"].global_position.x
		t["name_label"].position = Vector2(t_center_x - (NAME_LABEL_WIDTH / 2), t["node"].global_position.y - 60)

	if trainer_ui.visible and active_trainer_index != -1:
		var active_trainer_node = trainers[active_trainer_index]["node"]
		if player.global_position.distance_to(active_trainer_node.global_position) > TRAINER_INTERACT_RANGE:
			trainer_ui.visible = false
			active_trainer_index = -1

	if trainer_ui.visible and active_trainer_index != -1:
		trainer_ui.position = trainers[active_trainer_index]["node"].global_position + Vector2(-125, -220)

	var player_health_pct = clamp(float(player_current_health) / float(player_max_health), 0.0, 1.0)
	player_health_bar_fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH * player_health_pct, HUD_BAR_HEIGHT)
	player_hud_health_label.text = str(player_current_health) + " / " + str(player_max_health)
	player_hud_health_label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	var player_action_pct = clamp(float(player_current_action) / float(player_max_action), 0.0, 1.0)
	player_action_bar_fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH * player_action_pct, HUD_BAR_HEIGHT)
	player_hud_action_label.text = str(player_current_action) + " / " + str(player_max_action)
	player_hud_action_label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	# Bars are CHILDREN of each enemy now, so nothing needs repositioning
	# here -- only the fill widths, name text/colour and target highlight.
	for enemy_id in enemy_nodes.keys():
		var eid = String(enemy_id)
		if not enemies.has(eid):
			continue
		var n = enemy_nodes[eid]
		var e = enemies[eid]
		if not e["alive"]:
			n["indicator"].visible = false
			continue

		var health_pct = clamp(float(e["current_health"]) / float(max(1, e["max_health"])), 0.0, 1.0)
		n["health_fill"].polygon = _make_bar_polygon(HEALTH_BAR_WIDTH * health_pct, HEALTH_BAR_HEIGHT)

		var action_pct = clamp(float(e["current_action"]) / float(max(1, e["max_action"])), 0.0, 1.0)
		n["action_fill"].polygon = _make_bar_polygon(HEALTH_BAR_WIDTH * action_pct, HEALTH_BAR_HEIGHT)

		n["name_label"].modulate = _get_con_color(eid)
		n["name_label"].text = _get_enemy_display_text(eid)
		n["indicator"].visible = (targeted_enemy == eid)

	_update_enemy_hud()
# Mirrors the player's fixed HUD bars, but for whichever enemy is
# currently nearest to the player (alive). Hides itself entirely when
# no enemies are alive. This is separate from -- and doesn't replace --
# the floating health/action bars each enemy shows above its own head.
# Mirrors the player's fixed HUD bars, but for whichever enemy is
# currently nearest to the player (alive). Hides itself entirely when
# no enemies are alive. This is separate from -- and doesn't replace --
# the floating health/action bars each enemy shows above its own head.
func _update_enemy_hud() -> void:
	var tracked_id = _get_tracked_enemy_id()

	if tracked_id == "" or not enemies.has(tracked_id):
		enemy_hud.visible = false
		return

	enemy_hud.visible = true
	var e = enemies[tracked_id]

	var tracked_health_pct = clamp(float(e["current_health"]) / float(max(1, e["max_health"])), 0.0, 1.0)
	enemy_hud_health_bar_fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH * tracked_health_pct, HUD_BAR_HEIGHT)
	enemy_hud_health_label.text = str(e["current_health"]) + " / " + str(e["max_health"])
	enemy_hud_health_label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	var tracked_action_pct = clamp(float(e["current_action"]) / float(max(1, e["max_action"])), 0.0, 1.0)
	enemy_hud_action_bar_fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH * tracked_action_pct, HUD_BAR_HEIGHT)
	enemy_hud_action_label.text = str(e["current_action"]) + " / " + str(e["max_action"])
	enemy_hud_action_label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)
func _cycle_target() -> void:
	var ids: Array = []
	for enemy_id in enemy_nodes.keys():
		var eid = String(enemy_id)
		if enemies.has(eid) and enemies[eid]["alive"]:
			ids.append(eid)
	if ids.is_empty():
		targeted_enemy = ""
		_show_combat_message("No enemies to target.")
		return
	var current_index = ids.find(targeted_enemy)
	if current_index == -1 or current_index >= ids.size() - 1:
		targeted_enemy = ids[0]
	else:
		targeted_enemy = ids[current_index + 1]
	_show_combat_message("Target: " + _get_enemy_name(targeted_enemy))
func _try_click_target(world_pos: Vector2) -> void:
	var clicked: String = ""
	var closest_dist = INF
	for enemy_id in enemy_nodes.keys():
		var eid = String(enemy_id)
		if not enemies.has(eid) or not enemies[eid]["alive"]:
			continue
		var d = world_pos.distance_to(enemy_nodes[eid]["body"].global_position)
		if d <= ENEMY_CLICK_RADIUS and d < closest_dist:
			closest_dist = d
			clicked = eid
	if clicked != "":
		targeted_enemy = clicked
		_show_combat_message("Target: " + _get_enemy_name(targeted_enemy))
func _get_tracked_enemy_id() -> String:
	# Prefer the explicitly targeted enemy -- that's what the player
	# is looking at and expecting to see health bars for.
	if targeted_enemy != "":
		var target_alive = enemies[targeted_enemy]["alive"] if enemies.has(targeted_enemy) else false
		if target_alive:
			return targeted_enemy
		else:
			targeted_enemy = ""

	# No target set -- show nearest alive enemy as a passive indicator.
	var weapon_class = crafted_item_class.get(equipped_weapon_name, "")
	var track_range: float
	if weapon_class == "Pistol":
		track_range = ENGAGE_RANGE_PISTOL
	elif weapon_class == "Sniper Rifle":
		track_range = ENGAGE_RANGE_SNIPER
	elif GameData.rifle_weapons.has(weapon_class):
		track_range = ENGAGE_RANGE_RIFLE
	elif weapon_class == "Shotgun":
		track_range = ENGAGE_RANGE_SHOTGUN
	elif GameData.heavy_weapon_types.has(weapon_class):
		track_range = ENGAGE_RANGE_HEAVY
	else:
		track_range = MELEE_RANGE

	var candidates = []
	for enemy_id in enemy_nodes.keys():
		var eid = String(enemy_id)
		if not enemies.has(eid) or not enemies[eid]["alive"]:
			continue
		var d = player.global_position.distance_to(enemy_nodes[eid]["body"].global_position)
		if d <= track_range:
			candidates.append([eid, d])
	if candidates.is_empty():
		return ""
	candidates.sort_custom(func(a, b): return a[1] < b[1])
	return candidates[0][0]
func _apply_cl_derivation(enemy_id: String) -> void:
	# Fills an enemy's derived combat values from its hidden Combat Level.
	# Health/action/damage/defense/armor come from the CL anchor table via
	# Combat.derive_stats_from_cl(). Effective Health is Base Health seen
	# through the derived armor (Phase 4a); current/max_health stay Base
	# Health -- the raw pool combat depletes -- and armor mitigates each hit.
	if not enemies.has(enemy_id):
		return
	var e = enemies[enemy_id]
	# Phase 6a: archetype and faction shape the CL-derived stats. CL sets
	# the tier; identity sets the character within it.
	var d = Combat.derive_stats_from_cl(e["cl"], e.get("archetype", ""), e.get("faction", ""))
	e["stats"]["base_health"] = d["health"]
	e["stats"]["effective_health"] = Combat.effective_health(d["health"], d["armor"])
	e["stats"]["defense"] = d["defense"]
	e["stats"]["armor_rating"] = d["armor"]
	# Phase 5 defensive stats (percentages, CL-derived).
	e["stats"]["dodge"] = d.get("dodge", 0.0)
	e["stats"]["block"] = d.get("block", 0.0)
	e["stats"]["critical_resistance"] = d.get("crit_resist", 0.0)
	e["dodge"] = d.get("dodge", 0.0)
	e["block"] = d.get("block", 0.0)
	e["crit_resist"] = d.get("crit_resist", 0.0)
	e["max_health"] = d["health"]
	e["current_health"] = d["health"]
	e["max_action"] = d["action"]
	e["current_action"] = d["action"]
	e["defense"] = d["defense"]
	e["armor_rating"] = d["armor"]
	# Phase 4c: resistances are the derived Armor Rating shaped by the
	# enemy's archetype profile, so CL sets the magnitude and archetype
	# sets which damage types get through. An enemy with no archetype
	# falls back to uniform (Phase 4b) resistance.
	e["resistances"] = CombatData.new_resistances(d["armor"], e.get("archetype", ""))
	e["attack_min_damage"] = int(round(d["damage"] * 0.55))
	e["attack_max_damage"] = int(round(d["damage"] * 1.45))


func _update_enemy_ai(enemy_id: String, delta: float) -> void:
	if not enemies.has(enemy_id) or not enemy_nodes.has(enemy_id):
		return
	var e = enemies[enemy_id]
	var n = enemy_nodes[enemy_id]
	if not e["alive"]:
		return

	var body: Node2D = n["body"]
	var pos = body.global_position
	var player_pos = player.global_position
	var dist_to_player = pos.distance_to(player_pos)
	var home: Vector2 = n["home_position"]
	var dist_to_home = pos.distance_to(home)
	var state = String(e["ai_state"])

	if state == "leash":
		_ai_leash_tick(enemy_id, e, n, body, home, dist_to_home, delta)
		return

	if int(e.get("stagger_until_msec", 0)) > Time.get_ticks_msec():
		return

	if state == "idle":
		if player_alive and dist_to_player <= n["aggro_range"]:
			e["ai_state"] = "chase"
			e["ai_target"] = "player"
			_ai_call_for_help(enemy_id)
		else:
			_ai_patrol_tick(enemy_id, e, n, body, home, dist_to_home, delta)
		return

	if state == "chase":
		if not player_alive:
			e["ai_state"] = "leash"
			return
		if dist_to_home > n["leash_range"]:
			e["ai_state"] = "leash"
			return
		if dist_to_player > ENEMY_ATTACK_RANGE:
			var direction = (player_pos - pos).normalized()
			body.position += direction * n["chase_speed"] * delta
			var sprite: Sprite2D = body.get_node("Visual")
			sprite.flip_h = direction.x < 0
		else:
			_ai_try_attack(enemy_id, e, n)


func _ai_try_attack(_enemy_id: String, e: Dictionary, n: Dictionary) -> void:
	if not e["attack_ready"] or not player_alive:
		return

	var damage = Combat.compute_enemy_attack_damage(e["attack_min_damage"], e["attack_max_damage"], e["damage_debuff"])
	player_current_health -= damage
	player_current_health = max(player_current_health, 0)

	_show_enemy_combat_message(e["name"] + " hits you for " + str(damage) + " damage!")

	if player_current_health <= 0:
		_defeat_player()

	e["attack_ready"] = false
	n["attack_timer"].wait_time = float(n["attack_cooldown"]) * (1.0 + e["attack_speed_debuff"])
	n["attack_timer"].start()


func _ai_leash_tick(_enemy_id: String, e: Dictionary, n: Dictionary, body: Node2D, home: Vector2, dist_to_home: float, delta: float) -> void:
	if dist_to_home < 5.0:
		body.position = home
		e["current_health"] = e["max_health"]
		e["current_action"] = e["max_action"]
		e["damage_debuff"] = 0.0
		e["accuracy_debuff"] = 0.0
		e["attack_speed_debuff"] = 0.0
		e["bleed_ticks_remaining"] = 0
		e["burn_ticks_remaining"] = 0
		e["poison_ticks_remaining"] = 0
		e["ai_state"] = "idle"
		e["ai_target"] = ""
		return
	var direction = (home - body.global_position).normalized()
	body.position += direction * n["chase_speed"] * 1.5 * delta
	var heal_amt = int(round(float(e["max_health"]) * LEASH_HEAL_RATE * delta))
	e["current_health"] = min(e["max_health"], e["current_health"] + heal_amt)


func _ai_patrol_tick(_enemy_id: String, _e: Dictionary, n: Dictionary, body: Node2D, home: Vector2, dist_to_home: float, delta: float) -> void:
	if not n.has("patrol_target"):
		_ai_pick_patrol_target(n, home)
	var wait = float(n.get("patrol_wait", 0.0))
	if wait > 0.0:
		n["patrol_wait"] = wait - delta
		return
	var target: Vector2 = n["patrol_target"]
	var dist = body.global_position.distance_to(target)
	if dist < 5.0 or dist_to_home > n["patrol_radius"] * 1.5:
		_ai_pick_patrol_target(n, home)
		return
	var direction = (target - body.global_position).normalized()
	body.position += direction * n["chase_speed"] * 0.3 * delta


func _ai_pick_patrol_target(n: Dictionary, home: Vector2) -> void:
	var angle = randf() * TAU
	var radius = randf() * n["patrol_radius"]
	n["patrol_target"] = home + Vector2(cos(angle), sin(angle)) * radius
	n["patrol_wait"] = randf_range(2.0, 5.0)


func _ai_call_for_help(aggroed_id: String) -> void:
	if not enemy_nodes.has(aggroed_id):
		return
	var lair = String(enemy_nodes[aggroed_id].get("lair_id", ""))
	if lair == "":
		return
	var aggroed_pos = enemy_nodes[aggroed_id]["body"].global_position
	for eid in enemies.keys():
		if eid == aggroed_id:
			continue
		if not enemies[eid]["alive"] or enemies[eid]["ai_state"] != "idle":
			continue
		if not enemy_nodes.has(eid):
			continue
		if String(enemy_nodes[eid].get("lair_id", "")) != lair:
			continue
		var dist = enemy_nodes[eid]["body"].global_position.distance_to(aggroed_pos)
		if dist <= enemy_nodes[eid]["aggro_range"] * 1.5:
			enemies[eid]["ai_state"] = "chase"
			enemies[eid]["ai_target"] = "player"


func _on_enemy_attack_cooldown_finished(enemy_id: String) -> void:
	if enemies.has(enemy_id):
		enemies[enemy_id]["attack_ready"] = true


func _defeat_player() -> void:
	player_alive = false
	_show_combat_message("You have been defeated!")
	player_respawn_timer.start()

func _on_player_respawn() -> void:
	player_current_health = player_max_health
	player_current_action = player_max_action
	player_alive = true
	player.position = player_spawn_position
	_show_combat_message("You have respawned.")

func _on_player_regen_tick() -> void:
	if not player_alive:
		return

	var regen_amount = round(player_max_health * 0.02)
	player_current_health = min(player_max_health, player_current_health + regen_amount)

	if iv_drip_ticks_remaining > 0:
		player_current_health = min(player_max_health, player_current_health + IV_DRIP_HEAL_PER_TICK)
		iv_drip_ticks_remaining -= 1

	if blood_bag_bonus_amount > 0 and Time.get_unix_time_from_system() >= blood_bag_expires_at_unix:
		player_max_health -= blood_bag_bonus_amount
		player_current_health = min(player_current_health, player_max_health)
		blood_bag_bonus_amount = 0
		_show_combat_message("Your Blood Bag boost has worn off.")

	for eid in enemies.keys():
		var be = enemies[eid]
		if not be["alive"]:
			continue
		if String(be.get("ai_state", "idle")) == "leash":
			continue
		var defeated = false
		if be["bleed_ticks_remaining"] > 0:
			be["current_health"] -= be["bleed_damage_per_tick"]
			be["bleed_ticks_remaining"] -= 1
			_show_enemy_combat_message("Bleed deals " + str(be["bleed_damage_per_tick"]) + " damage to " + be["name"] + "!")
			if be["current_health"] <= 0:
				_show_combat_message(_defeat_enemy(eid))
				defeated = true
		if not defeated and be["burn_ticks_remaining"] > 0:
			be["current_health"] -= be["burn_damage_per_tick"]
			be["burn_ticks_remaining"] -= 1
			_show_enemy_combat_message("Burn deals " + str(be["burn_damage_per_tick"]) + " damage to " + be["name"] + "!")
			if be["current_health"] <= 0:
				_show_combat_message(_defeat_enemy(eid))
				defeated = true
		if not defeated and be["poison_ticks_remaining"] > 0:
			be["current_health"] -= be["poison_damage_per_tick"]
			be["poison_ticks_remaining"] -= 1
			_show_enemy_combat_message("Poison deals " + str(be["poison_damage_per_tick"]) + " damage to " + be["name"] + "!")
			if be["current_health"] <= 0:
				_show_combat_message(_defeat_enemy(eid))

func _on_player_action_regen_tick() -> void:
	if not player_alive:
		return

	var regen_amount = 10
	player_current_action = min(player_max_action, player_current_action + regen_amount)

	if adrenaline_boost_bonus_amount > 0 and Time.get_unix_time_from_system() >= adrenaline_boost_expires_at_unix:
		player_max_action -= adrenaline_boost_bonus_amount
		player_current_action = min(player_current_action, player_max_action)
		adrenaline_boost_bonus_amount = 0
		_show_combat_message("Your Adrenaline Boost has worn off.")

func _roll_loot(enemy_name: String, enemy_cl: int = 1) -> Array:
	var dropped_items = []

	if not loot_tables.has(enemy_name):
		return dropped_items

	# Phase 9: tier odds now scale with the enemy's hidden Combat Level --
	# tougher enemies roll the better tiers more often. Drop AMOUNTS are
	# deliberately untouched; CL raises loot grade, not quantity.
	var tier_chances = Combat.loot_tier_chances_for_cl(enemy_cl)

	var roll = randf()
	var chosen_tier = ""
	var cumulative = 0.0

	for tier_name in ["Common", "Uncommon", "Rare"]:
		cumulative += tier_chances[tier_name]
		if roll < cumulative:
			chosen_tier = tier_name
			break

	if chosen_tier != "":
		var tier_items = loot_tables[enemy_name].get(chosen_tier, [])
		if tier_items.size() > 0:
			var entry = tier_items[randi_range(0, tier_items.size() - 1)]
			var amount = randi_range(entry["min_amount"], entry["max_amount"])
			_add_to_inventory(entry["item"], amount)
			dropped_items.append(str(amount) + " " + entry["item"])

	var ultra_rare_items = loot_tables[enemy_name].get("UltraRare", [])
	for entry in ultra_rare_items:
		if randf() < entry["chance"]:
			var amount = randi_range(entry["min_amount"], entry["max_amount"])
			_add_to_inventory(entry["item"], amount)
			dropped_items.append(str(amount) + " " + entry["item"])

	return dropped_items

# --- CON (Consider) Color System ---

func _get_total_skill_points_spent() -> int:
	var total_spent = 0

	for profession_name in GameData.novice_professions.keys():
		var prof_data = GameData.novice_professions[profession_name]
		if prof_data.has("keystones"):
			for ks_name in prof_data["keystones"].keys():
				total_spent += prof_data["keystones"][ks_name].get("points_spent", 0)
		elif prof_data.has("paths"):
			for path_name in prof_data["paths"].keys():
				var unlocked = prof_data["paths"][path_name]["unlocked_nodes"]
				for i in range(unlocked):
					total_spent += skill_point_costs[i]

	if has_chosen_starting_profession:
		total_spent += PROFESSION_ENTRY_COST

	return total_spent

# Phase 7: threat colour now comes from the enemy's hidden Combat Level
# measured against the player's effective CL, replacing the old hand-set
# "difficulty" number. Same five-colour language as before.
func _get_effective_player_cl() -> int:
	return Combat.effective_player_cl(_get_total_skill_points_spent())


func _get_threat_for_enemy(enemy_id: String) -> Dictionary:
	if not enemies.has(enemy_id):
		return {"label": "Unknown", "color": Color(0.7, 0.7, 0.7)}
	return Combat.threat_for(enemies[enemy_id].get("cl", 1), _get_effective_player_cl())


# Player-facing label for an enemy: name plus rank mark, with faction on
# a second line. The Combat Level itself is never shown -- the mark is
# the only thing that hints at it.
func _get_enemy_display_text(enemy_id: String) -> String:
	if not enemies.has(enemy_id):
		return ""
	var e = enemies[enemy_id]
	var mark = Combat.rank_mark_for_cl(e.get("cl", 1))
	var faction = e.get("faction", "")
	var line = e["name"] + "  " + mark
	if faction != "":
		line += "\n" + faction
	return line


func _get_con_color(enemy_id: String) -> Color:
	return _get_threat_for_enemy(enemy_id)["color"]


# Realises an item's actual stats from its ITEM_DEFINITION at a given
# quality (0-1000). Shared by starting-weapon grants and crafted-item
# grants so the two can never drift apart -- crafted weapons were
# previously granted with ONLY a Quality value, which left them with no
# damage, speed, accuracy or damage type at all.
func _realise_item_stats(item_key: String, definition: Dictionary, quality: int) -> void:
	if not inventory_stats.has(item_key):
		inventory_stats[item_key] = {}
	var output_stats = inventory_stats[item_key]
	output_stats["Quality"] = quality

	if definition.has("item_class"):
		crafted_item_class[item_key] = definition["item_class"]
	if definition.has("item_subclass"):
		crafted_item_subclass[item_key] = definition["item_subclass"]

	if definition.has("weapon_stat_ranges"):
		for stat_name in definition["weapon_stat_ranges"].keys():
			var stat_range = definition["weapon_stat_ranges"][stat_name]
			var min_val = stat_range[0]
			var max_val = stat_range[1]
			var raw_value = min_val + (quality / 1000.0) * (max_val - min_val)

			var scaled_value
			if stat_name == "Speed" or stat_name == "Reload Speed":
				scaled_value = round(raw_value * 10.0) / 10.0
			else:
				scaled_value = round(raw_value)
			output_stats[stat_name] = scaled_value

		if output_stats.has("Speed") and output_stats.has("Damage Rating"):
			var speed_value = output_stats["Speed"]
			var damage_value = output_stats["Damage Rating"]
			if speed_value > 0:
				output_stats["Damage Per Second"] = round((damage_value / speed_value) * 10.0) / 10.0


func _grant_starting_weapon(weapon_name: String, quality: int) -> void:
	# Reads the ITEM definition, not a crafting recipe. A starting weapon
	# is granted outright, so it must not depend on the crafting system
	# existing at all.
	var definition: Dictionary = GameData.get_item_definition(weapon_name)
	if definition.is_empty():
		return

	# Unique per grant, same rule as crafted items -- even a starting
	# weapon has its own generated stats and shouldn't stack/share an
	# identity with another copy of the same weapon name.
	var item_key = _generate_unique_resource_name()
	consumable_base_name[item_key] = weapon_name
	_add_to_inventory(item_key, 1)
	_realise_item_stats(item_key, definition, quality)


# --- Scavenging ---

func _attempt_forage() -> void:
	var dumpster_distance = player.global_position.distance_to(dumpster.global_position)
	if dumpster_distance > DUMPSTER_RANGE:
		_show_combat_message("Too far away! Get closer to scavenge.")
		return

	_scavenge_dumpster()

# Fixed, guaranteed-drop scavenge point (a Dumpster) -- unlike the herb
# patch's probability-tiered loot, this always gives the same kind of
# find (Plastic + a flat Cogs amount), matching a simple "always has
# something in it" scavenge spot rather than a rare-resource patch.
func _scavenge_dumpster() -> void:
	if not dumpster_available:
		_show_combat_message("This dumpster has already been picked through. Check back later.")
		return

	# Phase 3: the dumpster now yields a real MaterialBatch pulled from the
	# Surface's synthetic salvage sources, instead of a flat Plastic drop.
	# Same call the Silo scavenging loop will use, just against surface
	# sources rather than a generated floor.
	# Draws from EVERY live Surface source, not just the bin itself.
	# All the surface salvage -- the dumpster, the stripped wiring, the
	# rusted railing -- sits in this same alley, but only the dumpster has
	# a physical prop, so the other sources were unreachable and their
	# materials (copper, black iron) could never be obtained. Until those
	# props exist, this one interactable works the whole alley.
	var live: Array = []
	for sid in surface_sources.keys():
		var src = surface_sources[sid]
		if int(src.get("remaining", 0)) > 0:
			live.append(src)

	if live.is_empty():
		_show_combat_message("This dumpster is stripped bare. Nothing usable left.")
		return

	var chosen = live[randi() % live.size()]
	var take = randi_range(1, 3)
	var foraging_chance_bonus = _get_foraging_chance_bonus()
	if foraging_chance_bonus > 0 and randf() < (foraging_chance_bonus * 0.10):
		take += randi_range(1, 3)

	var batch = CraftingResourceGenerator.extract_from_source(chosen, take)
	if batch.is_empty():
		_show_combat_message("This dumpster is stripped bare. Nothing usable left.")
		return

	_store_material_batch(batch)
	cogs += randi_range(DUMPSTER_COGS_MIN, DUMPSTER_COGS_MAX)
	_update_inventory_display()
	_update_cogs_display()

	_show_combat_message("You search the " + String(chosen.get("location_name", "alley"))
		+ " and find: " + str(int(batch.get("amount", 0))) + " " + String(batch.get("display_name", "material"))
		+ " (Quality " + str(int(batch.get("quality", 0))) + ")")

	dumpster_available = false
	dumpster.visible = false
	dumpster_cooldown_timer.wait_time = DUMPSTER_RESPAWN_TIME
	dumpster_cooldown_timer.start()
	quest_system.on_dumpster_looted()

func _on_dumpster_cooldown_finished() -> void:
	dumpster_available = true
	dumpster.visible = true
	_show_combat_message("The dumpster has filled back up.")

# --- Crate of Bandages / Medicine Usage ---

func _attempt_use_bandage() -> void:
	if not bandage_ready:
		var seconds_left = ceil(bandage_cooldown_timer.time_left)
		_show_combat_message("You must wait " + str(int(seconds_left)) + " seconds before you can use that again.")
		return

	if not professions_unlocked.get("Street Thug", false):
		_show_combat_message("You need Street Thug Medicine Crafting to use a Crate of Bandages!")
		return

	if not player_alive:
		_show_combat_message("You can't use items while defeated!")
		return

	var bandage_instance = ""
	for instance_name in inventory.keys():
		if consumable_base_name.get(instance_name, "") == "Crate of Bandages" and inventory[instance_name] > 0:
			bandage_instance = instance_name
			break

	if bandage_instance == "":
		_show_combat_message("You don't have any Crates of Bandages!")
		return

	var missing_health = player_max_health - player_current_health
	if missing_health <= 0:
		_show_combat_message("You are already at full health!")
		return

	if player_current_action < BANDAGE_ACTION_COST:
		_show_combat_message("Not enough Action! Need " + str(BANDAGE_ACTION_COST) + ", have " + str(player_current_action) + ".")
		return

	var heal_amount = min(BANDAGE_HEAL_AMOUNT, missing_health)
	player_current_health += heal_amount
	player_current_action -= BANDAGE_ACTION_COST

	var stats = inventory_stats.get(bandage_instance, {})
	var charges = stats.get("Charges", 1)
	charges -= 1

	if charges <= 0:
		inventory.erase(bandage_instance)
		inventory_stats.erase(bandage_instance)
		consumable_base_name.erase(bandage_instance)
		crafted_item_class.erase(bandage_instance)
	else:
		inventory_stats[bandage_instance]["Charges"] = charges

	_update_inventory_display()

	_show_combat_message("You use a Crate of Bandages and heal " + str(heal_amount) + " HP! (-" + str(BANDAGE_ACTION_COST) + " Action)")

	bandage_ready = false
	bandage_cooldown_timer.wait_time = BANDAGE_COOLDOWN
	bandage_cooldown_timer.start()

# Finds the first inventory stack matching a simple (non-charge-based)
# consumable by its base/output name and consumes exactly 1 of it,
# returning its Quality stat (0-1000) so the caller can scale its
# effect accordingly. Returns -1 if none was available. Used for
# Adrenaline Shot and Empty IV Bag, which are plain single-use items
# rather than Charges-tracked ones like Crate of Bandages.
# Scales a consumable's effect by its Quality stat (0-1000 scale),
# from a minimum at Quality 0 up to a maximum at Quality 1000 -- e.g.
# a rough Syringe gives a weaker Adrenaline Shot than a well-made one.
# Linear for now; easy to curve later if a flat scale doesn't feel
# right in practice.
func _scale_by_quality(quality: int, min_value: float, max_value: float) -> int:
	var quality_pct = clamp(float(quality) / 1000.0, 0.0, 1.0)
	return int(round(min_value + (max_value - min_value) * quality_pct))

func _consume_one_quantity_item(base_name: String) -> int:
	var instance_name = ""
	for candidate in inventory.keys():
		if consumable_base_name.get(candidate, "") == base_name and inventory[candidate] > 0:
			instance_name = candidate
			break

	if instance_name == "":
		return -1

	var quality = inventory_stats.get(instance_name, {}).get("Quality", 500)

	inventory[instance_name] -= 1
	if inventory[instance_name] <= 0:
		inventory.erase(instance_name)
		inventory_stats.erase(instance_name)
		consumable_base_name.erase(instance_name)
		crafted_item_class.erase(instance_name)

	_update_inventory_display()
	return quality

func _attempt_iv_drip() -> void:
	if not professions_unlocked.get("Street Thug", false):
		_show_combat_message("You need Street Thug Medicine Crafting to use IV Drip!")
		return
	if not _get_rank_unlocked("Healing II"):
		_show_combat_message("You need Healing Rank II to use IV Drip!")
		return
	if not player_alive:
		_show_combat_message("You can't use items while defeated!")
		return

	var now_msec = Time.get_ticks_msec()
	if now_msec < iv_drip_ready_at_msec:
		var seconds_left = ceil((iv_drip_ready_at_msec - now_msec) / 1000.0)
		_show_combat_message("IV Drip is on cooldown for " + str(int(seconds_left)) + " more seconds.")
		return

	if not _has_bandages_for_salve():
		_show_combat_message("You need a Crate of Bandages to use IV Drip!")
		return

	_consume_one_bandage_charge()
	iv_drip_ticks_remaining = IV_DRIP_DURATION_TICKS
	iv_drip_ready_at_msec = now_msec + IV_DRIP_COOLDOWN_MSEC
	_show_combat_message("You apply an IV Drip -- healing " + str(IV_DRIP_HEAL_PER_TICK) + " HP/sec for " + str(IV_DRIP_DURATION_TICKS) + " seconds.")

func _attempt_healing_vapor() -> void:
	if not professions_unlocked.get("Street Thug", false):
		_show_combat_message("You need Street Thug Medicine Crafting to use Healing Vapor!")
		return
	if not _get_rank_unlocked("Healing IV"):
		_show_combat_message("You need Healing Rank IV to use Healing Vapor!")
		return
	if not player_alive:
		_show_combat_message("You can't use items while defeated!")
		return

	var now_msec = Time.get_ticks_msec()
	if now_msec < healing_vapor_ready_at_msec:
		var seconds_left = ceil((healing_vapor_ready_at_msec - now_msec) / 1000.0)
		_show_combat_message("Healing Vapor is on cooldown for " + str(int(seconds_left)) + " more seconds.")
		return

	if not _has_bandages_for_salve():
		_show_combat_message("You need a Crate of Bandages to use Healing Vapor!")
		return

	_consume_one_bandage_charge()
	# AoE heal -- only the player is a valid target right now since
	# there are no other in-scene allies yet. Once co-op players or
	# companions exist, extend this to heal everyone in range.
	var missing_health = player_max_health - player_current_health
	var heal_amount = min(HEALING_VAPOR_HEAL_AMOUNT, missing_health)
	player_current_health += heal_amount
	healing_vapor_ready_at_msec = now_msec + HEALING_VAPOR_COOLDOWN_MSEC
	_show_combat_message("You release a cloud of Healing Vapor, restoring " + str(heal_amount) + " HP!")

func _attempt_adrenaline_boost() -> void:
	if not professions_unlocked.get("Street Thug", false):
		_show_combat_message("You need Street Thug Medicine Crafting to use Adrenaline Boost!")
		return
	if not _get_rank_unlocked("Stims I"):
		_show_combat_message("You need Stims Rank I to use Adrenaline Boost!")
		return
	if not player_alive:
		_show_combat_message("You can't use items while defeated!")
		return

	var now_unix = Time.get_unix_time_from_system()
	if now_unix < adrenaline_boost_ready_at_unix:
		var seconds_left = ceil(adrenaline_boost_ready_at_unix - now_unix)
		_show_combat_message("Adrenaline Boost is on cooldown for " + str(int(seconds_left)) + " more seconds.")
		return

	var quality = _consume_one_quantity_item("Adrenaline Shot")
	if quality < 0:
		_show_combat_message("You need an Adrenaline Shot to use Adrenaline Boost!")
		return

	# Defensive: if a previous boost's cooldown just cleared but its
	# periodic expiry-check hasn't caught up yet, revert it here first
	# so the old and new bonus can never both be added to max Action.
	if adrenaline_boost_bonus_amount > 0:
		player_max_action -= adrenaline_boost_bonus_amount
		player_current_action = min(player_current_action, player_max_action)
		adrenaline_boost_bonus_amount = 0

	var bonus_amount = _scale_by_quality(quality, ADRENALINE_BOOST_MIN_ACTION, ADRENALINE_BOOST_MAX_ACTION)
	player_max_action += bonus_amount
	player_current_action += bonus_amount
	adrenaline_boost_bonus_amount = bonus_amount
	adrenaline_boost_expires_at_unix = now_unix + ADRENALINE_BOOST_DURATION_SEC
	adrenaline_boost_ready_at_unix = now_unix + ADRENALINE_BOOST_COOLDOWN_SEC
	_show_combat_message("You inject an Adrenaline Shot -- +" + str(bonus_amount) + " Max Action for 10 minutes!")

func _attempt_blood_bag() -> void:
	if not professions_unlocked.get("Street Thug", false):
		_show_combat_message("You need Street Thug Medicine Crafting to use Blood Bag!")
		return
	if not _get_rank_unlocked("Stims III"):
		_show_combat_message("You need Stims Rank III to use Blood Bag!")
		return
	if not player_alive:
		_show_combat_message("You can't use items while defeated!")
		return

	var now_unix = Time.get_unix_time_from_system()
	if now_unix < blood_bag_ready_at_unix:
		var seconds_left = ceil(blood_bag_ready_at_unix - now_unix)
		_show_combat_message("Blood Bag is on cooldown for " + str(int(seconds_left)) + " more seconds.")
		return

	var quality = _consume_one_quantity_item("Empty IV Bag")
	if quality < 0:
		_show_combat_message("You need an Empty IV Bag to use Blood Bag!")
		return

	# Defensive: same non-stacking safeguard as Adrenaline Boost -- revert
	# any still-active bonus first so old and new can never both apply.
	if blood_bag_bonus_amount > 0:
		player_max_health -= blood_bag_bonus_amount
		player_current_health = min(player_current_health, player_max_health)
		blood_bag_bonus_amount = 0

	var bonus_amount = _scale_by_quality(quality, BLOOD_BAG_MIN_HEAL, BLOOD_BAG_MAX_HEAL)
	player_max_health += bonus_amount
	player_current_health += bonus_amount
	blood_bag_bonus_amount = bonus_amount
	blood_bag_expires_at_unix = now_unix + BLOOD_BAG_DURATION_SEC
	blood_bag_ready_at_unix = now_unix + BLOOD_BAG_COOLDOWN_SEC
	_show_combat_message("You use Blood Bag -- +" + str(bonus_amount) + " Max Health for 10 minutes!")

func _on_bandage_cooldown_finished() -> void:
	bandage_ready = true

# --- Action Bar ---

# Centers the ActionBar horizontally near the bottom of the screen, then
# aligns PlayerHUD's left edge with the ActionBar's left edge, positioned
# just above it. Called once via call_deferred() from _ready() so the
# ActionBar's real size (from its HBoxContainer children) is already
# calculated by the time we read action_bar.size.
func _layout_hud() -> void:
	var viewport_size = get_viewport_rect().size

	# Force Top-Left anchoring explicitly -- if ActionBar's anchors were
	# ever set to something else (in the editor or by a previous run),
	# Godot's own anchor system can silently reposition it after this
	# function sets .position, undoing this calculation entirely.
	action_bar.anchor_left = 0
	action_bar.anchor_top = 0
	action_bar.anchor_right = 0
	action_bar.anchor_bottom = 0

	# ActionBar's real size comes from its 8 child buttons; if this
	# runs before that layout settles, size can read as (0,0) or a
	# stale value, which would silently break everything below. This
	# is defensive -- the real fix is re-running via size_changed below.
	var action_bar_size = action_bar.size
	if action_bar_size.x < 10 or action_bar_size.y < 10:
		action_bar_size = Vector2(700, 40)

	var action_bar_position = Vector2(
		(viewport_size.x - action_bar_size.x) / 2.0,
		viewport_size.y - action_bar_size.y - ACTION_BAR_BOTTOM_MARGIN
	)
	action_bar.position = action_bar_position

	var hud_total_height = (HUD_BAR_HEIGHT * 2) + HUD_BAR_GAP
	var hud_y = action_bar_position.y - hud_total_height - HUD_GAP_ABOVE_ACTION_BAR

	player_hud.position = Vector2(action_bar_position.x, hud_y)

	# EnemyHUD mirrors PlayerHUD but right-aligned: its bars' right edge
	# lines up with the ActionBar's right edge.
	var action_bar_right_edge = action_bar_position.x + action_bar_size.x
	enemy_hud.position = Vector2(action_bar_right_edge - HUD_BAR_WIDTH, hud_y)

func _is_ability_learned(ability_name: String) -> bool:
	var ability = GameData.ability_definitions[ability_name]
	var required_profession = ability["requires_profession"]

	if not professions_unlocked.get(required_profession, false):
		return false

	var required_box = ability["requires_box"]
	if required_box == "":
		return true

	var prof_data = GameData.novice_professions.get(required_profession, {})

	# Keystone-based: ability is learned if its node is purchased
	# in the matching keystone
	if prof_data.has("keystones"):
		for ks_name in prof_data["keystones"].keys():
			var ks = prof_data["keystones"][ks_name]
			if ks["nodes"].has(ability_name) and ks["nodes"][ability_name].get("purchased", false):
				return true
		return false

	# Path-based: check unlocked_nodes
	if not prof_data.has("paths") or not prof_data["paths"].has(required_box):
		return false
	var box_data = prof_data["paths"][required_box]
	return box_data["unlocked_nodes"] >= 1

func _trigger_slot(slot: ActionBarSlot) -> void:
	if slot.assigned_ability != "":
		_use_ability_by_name(slot.assigned_ability)

func _use_ability_by_name(ability_name: String) -> void:
	if ability_name == "Attack":
		_attempt_attack()
	elif ability_name == "Ranged Attack":
		_attempt_ranged_attack()
	elif ability_name == "Apply Bandage":
		_attempt_use_bandage()
	elif ability_name == "IV Drip":
		_attempt_iv_drip()
	elif ability_name == "Healing Vapor":
		_attempt_healing_vapor()
	elif ability_name == "Adrenaline Boost":
		_attempt_adrenaline_boost()
	elif ability_name == "Blood Bag":
		_attempt_blood_bag()
	elif GameData.ability_definitions.has(ability_name):
		_attempt_ability(ability_name)
	else:
		_show_combat_message("Nothing to do with " + ability_name + ".")

func _use_inventory_item(_item_key: String, display_name: String) -> void:
	_use_ability_by_name(display_name)

# --- Trainer ---

# Finds the closest interactable within range and fires its callback.
# This is the single handler for the E key -- trainers, quest givers,
# dumpsters, doors, chests, NPCs all register in the interactables array
# at startup and this function handles all of them uniformly.
# Adding a new interactable = one append() call in _ready(), no new
# input handling code needed.
func _attempt_interact() -> void:
	var closest_dist = INF
	var closest_entry = null

	for entry in interactables:
		var node = entry["node"]
		if not is_instance_valid(node) or not node.visible:
			continue
		var dist = player.global_position.distance_to(node.global_position)
		if dist <= entry["range"] and dist < closest_dist:
			closest_dist = dist
			closest_entry = entry

	if closest_entry != null:
		closest_entry["callback"].call()

func _attempt_talk_to_trainer() -> bool:
	var nearest_index = _get_nearest_trainer_in_range()
	if nearest_index == -1:
		return false

	if trainer_ui.visible and active_trainer_index == nearest_index:
		trainer_ui.visible = false
		return true

	active_trainer_index = nearest_index
	trainer_ui.visible = true
	trainer_dialogue_state = "GREETING"
	_refresh_trainer_dialogue()
	return true

func _get_nearest_trainer_in_range() -> int:
	var nearest_index = -1
	var nearest_distance = TRAINER_INTERACT_RANGE

	for i in range(trainers.size()):
		var t = trainers[i]
		var distance = player.global_position.distance_to(t["node"].global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_index = i

	return nearest_index

# --- Trainer Dialogue (popup, SWG-style) ---
# Replaces the old Tree/Button pane. Rather than a static UI layout that
# can overflow with long labels, this drives a single Panel through three
# states -- GREETING, SKILL_LIST, CONFIRM -- clearing and rebuilding the
# option buttons in trainer_options each time the state changes.

func _clear_trainer_options() -> void:
	for child in trainer_options.get_children():
		child.queue_free()

func _add_trainer_option(label_text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = label_text
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callback)
	trainer_options.add_child(btn)

func _refresh_trainer_dialogue() -> void:
	_clear_trainer_options()

	if active_trainer_index == -1:
		return

	match trainer_dialogue_state:
		"GREETING":
			_show_trainer_greeting()
		"SKILL_LIST":
			_show_trainer_skill_list()
		"CONFIRM":
			_show_trainer_confirm()

func _show_trainer_greeting() -> void:
	var trainer_name = trainers[active_trainer_index]["name"]
	train_info_label.text = trainer_name + "\n\n\"I can teach you what I know, if you're interested.\""

	_add_trainer_option("I'm interested in learning a skill.", _on_trainer_option_start_learning)
	_add_trainer_option("Stop Conversing", _on_trainer_option_stop_conversing)

func _on_trainer_option_start_learning() -> void:
	trainer_dialogue_state = "SKILL_LIST"
	_refresh_trainer_dialogue()

func _on_trainer_option_stop_conversing() -> void:
	trainer_ui.visible = false
	active_trainer_index = -1

func _on_trainer_option_back_to_greeting() -> void:
	trainer_dialogue_state = "GREETING"
	_refresh_trainer_dialogue()

func _show_trainer_skill_list() -> void:
	var this_trainer_profession = trainers[active_trainer_index]["profession"]

	if not professions_unlocked.get(this_trainer_profession, false):
		var missing = _get_missing_profession_prereqs(this_trainer_profession)
		if missing.size() > 0:
			train_info_label.text = "You must " + ", ".join(missing) + " before training here."
		else:
			train_info_label.text = "Complete the unlock quest to begin training as " + this_trainer_profession + "."
		_add_trainer_option("Back", _on_trainer_option_back_to_greeting)
		return

	var prof_data = GameData.novice_professions[this_trainer_profession]

	if prof_data.has("keystones"):
		train_info_label.text = "I can show you techniques, but the real growth comes from experience in the field.\n\nOpen your Talent Viewer (T) to spend your earned XP on keystones."
		_add_trainer_option("Back", _on_trainer_option_back_to_greeting)
		return

	if not prof_data.has("paths"):
		train_info_label.text = "Nothing available to train right now."
		_add_trainer_option("Back", _on_trainer_option_back_to_greeting)
		return

	var anything_shown = false
	for path_name in prof_data["paths"].keys():
		var path_data = prof_data["paths"][path_name]
		var unlocked = path_data["unlocked_nodes"]
		var max_nodes = path_data.get("max_nodes", NODES_PER_PATH)
		if unlocked >= max_nodes:
			continue
		if not _is_prereq_met(this_trainer_profession, path_data):
			continue
		var costs = _get_box_cost(path_data)
		var xp_type = path_data["xp_type"]
		var current_xp = xp_pools[xp_type]
		if current_xp < costs["xp_cost"]:
			continue
		if _get_points_available(this_trainer_profession) < costs["point_cost"]:
			continue
		if cogs < costs["cogs_cost"]:
			continue
		var display_text = _get_talent_box_label(this_trainer_profession, path_name) + " (" + str(unlocked) + "/" + str(max_nodes) + ")"
		_add_trainer_option(display_text, _make_trainer_confirm_callback(this_trainer_profession, path_name))
		anything_shown = true

	if anything_shown:
		train_info_label.text = "What would you like to learn?"
	else:
		train_info_label.text = "Nothing available to train right now.\nEarn more XP, Points, or Cogs."

	_add_trainer_option("Back", _on_trainer_option_back_to_greeting)

# Returns a Callable bound to a specific profession/path so each skill-list
# button opens the confirm screen for that exact entry, without needing a
# Tree's selected-item metadata to look up afterward.
func _make_trainer_confirm_callback(profession_name: String, path_name: String) -> Callable:
	return func():
		selected_profession = profession_name
		selected_path = path_name
		trainer_dialogue_state = "CONFIRM"
		_refresh_trainer_dialogue()

func _show_trainer_confirm() -> void:
	if selected_path == "LEARN_PROFESSION":
		if has_chosen_starting_profession:
			train_info_label.text = "This will cost " + str(ADDITIONAL_PROFESSION_COGS_COST) + " Cogs. Are you sure?"
		else:
			train_info_label.text = "This is your free starting profession. Are you sure?"
	else:
		train_info_label.text = _build_trainer_confirm_text(selected_profession, selected_path)

	_add_trainer_option("Yes", _on_trainer_confirm_yes)
	_add_trainer_option("No", _on_trainer_confirm_no)

# Lean, SWG-style confirm line for the trainer popup -- just the cogs cost,
# no rank/node/XP detail. (The Talent Viewer's _build_skill_info_text still
# shows the full breakdown elsewhere -- this is a separate, simpler string
# used only for this one screen.)
func _build_trainer_confirm_text(profession_name: String, path_name: String) -> String:
	var _pdata = GameData.novice_professions[profession_name].get("paths", {})
	var path_data = _pdata.get(path_name, null)
	if path_data == null:
		return "This profession uses the new keystone system."
	var costs = _get_box_cost(path_data)
	return "This skill will cost " + str(costs["cogs_cost"]) + " Cogs. Are you sure?"

func _on_trainer_confirm_yes() -> void:
	if selected_path == "LEARN_PROFESSION":
		_learn_trainer_profession()
		trainer_result_text = train_result_label.text
	else:
		_on_spend_point_pressed()
		trainer_result_text = skill_result_label.text

	trainer_dialogue_state = "GREETING"
	_refresh_trainer_dialogue()
	_show_train_result(trainer_result_text)

func _on_trainer_confirm_no() -> void:
	trainer_dialogue_state = "SKILL_LIST"
	_refresh_trainer_dialogue()

func _learn_trainer_profession() -> void:
	if active_trainer_index == -1:
		return
	var this_trainer_profession = trainers[active_trainer_index]["profession"]

	if professions_unlocked.get(this_trainer_profession, false):
		_show_train_result("You've already learned " + this_trainer_profession + "!")
		return

	# TODO(cleanup): dead since Street Thug is auto-assigned at startup --
	# has_chosen_starting_profession is always true here, so this "first
	# profession via trainer" branch (and the profession-select UI /
	# _on_choose_profession_pressed that feed it) never runs. Remove in a
	# later cleanup pass.
	if not has_chosen_starting_profession:
		if _get_points_available(this_trainer_profession) < PROFESSION_ENTRY_COST:
			_show_train_result("Not enough " + _points_pool_label(this_trainer_profession) + "! Need " + str(PROFESSION_ENTRY_COST) + ".")
			return

		_spend_points(this_trainer_profession, PROFESSION_ENTRY_COST)
		professions_unlocked[this_trainer_profession] = true
		has_chosen_starting_profession = true
		_grant_novice_unlock(this_trainer_profession)
		_grant_profession_starting_kit(this_trainer_profession)
		_show_train_result("You are now a " + this_trainer_profession + "!")
	else:
		if _get_points_available(this_trainer_profession) < PROFESSION_ENTRY_COST:
			_show_train_result("Not enough " + _points_pool_label(this_trainer_profession) + "! Need " + str(PROFESSION_ENTRY_COST) + ".")
			return

		if cogs < ADDITIONAL_PROFESSION_COGS_COST:
			_show_train_result("Not enough Cogs! Need " + str(ADDITIONAL_PROFESSION_COGS_COST) + ", have " + str(cogs) + ".")
			return

		_spend_points(this_trainer_profession, PROFESSION_ENTRY_COST)
		cogs -= ADDITIONAL_PROFESSION_COGS_COST
		_update_cogs_display()
		professions_unlocked[this_trainer_profession] = true
		_grant_novice_unlock(this_trainer_profession)
		_show_train_result("You have learned " + this_trainer_profession + "!")

	_refresh_skill_tree_ui()

func _grant_novice_unlock(profession_name: String) -> void:
	var prof_data = GameData.novice_professions[profession_name]

	# Path-based professions: set Novice path unlocked_nodes to 1
	if prof_data.has("paths") and prof_data["paths"].has("Novice"):
		prof_data["paths"]["Novice"]["unlocked_nodes"] = 1

	# Keystone professions have no Novice path -- the profession
	# itself is marked unlocked via professions_unlocked, and
	# individual keystones are unlocked separately with XP.

# Grants the one-time starting weapons + 100 Cogs bonus. Only ever
# called for the very first profession a player picks -- subsequent
# additional professions get their Novice abilities (via
# _grant_novice_unlock) but no repeat weapon/cogs kit.
# Every new character starts with 2 Crates of Bandages, independent of
# profession -- each is its own generated instance with a full 5
# Charges, exactly like one fresh off the crafting bench.
func _grant_starting_bandages() -> void:
	for i in range(2):
		var item_key = _generate_unique_resource_name()
		consumable_base_name[item_key] = "Crate of Bandages"
		_add_to_inventory(item_key, 1)
		if not inventory_stats.has(item_key):
			inventory_stats[item_key] = {}
		inventory_stats[item_key]["Quality"] = 500
		inventory_stats[item_key]["Charges"] = 5
	_update_inventory_display()

func _grant_profession_starting_kit(_profession_name: String) -> void:
	# Every new character gets the same base kit regardless of which
	# profession they start as.
	_grant_starting_weapon("Riveted Knuckles", 0)
	_grant_starting_weapon("Rusty Pistol", 0)
	_add_to_inventory("Mineral Survey Tool", 1)
	_add_to_inventory("Rusty Crafting Kit", 1)

	cogs += 100
	_update_cogs_display()
	_update_inventory_display()

func _show_train_result(text: String) -> void:
	train_result_label.text = text
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if train_result_label.text == text:
			train_result_label.text = ""
	)

# --- Talent Tree Viewer ---
# A testing/reference-only overlay for visualizing the skill trees.
# Fully built here in code (no manual scene
# nodes needed) so it can be dropped in and iterated on freely.
# Toggle with the "talent_view" input action (map a key to it in
# Project Settings > Input Map). This does NOT replace the real
# functional Skill UI (skill_ui/skill_tree) -- it's a separate visual
# reference layered on top of the same underlying data.

var talent_ui: Control
var crafting_panel_ui: Control
var crafting_panel
var ability_book_ui: Control
var ability_book_list_container: VBoxContainer
var inventory_book_ui: Control
var inventory_book_list_container: VBoxContainer
var inventory_book_stats_label: Label
var crafting_result_ui: Control
var crafting_result_label: Label
var crafting_result_mod_slots_label: Label
# Path to the existing drag-source script, reused so abilities dragged
# from the Ability Book work identically to the old fixed menu -- if
# this path is wrong for your project, this is the one line to fix.
const ABILITY_DRAG_SOURCE_SCRIPT_PATH = "res://scenes/ability_drag_source.gd"
var talent_grid_container: HBoxContainer
var talent_details_label: Label
var talent_learned_label: Label
var talent_master_container: Panel
var talent_novice_container: Panel
var talent_points_label: Label
var talent_requirements_container: VBoxContainer
var talent_requirements_line: ColorRect
var talent_column_labels_container: HBoxContainer
var talent_prereq_line: ColorRect
var talent_prereq_container: VBoxContainer
var current_talent_profession: String = ""

# Skill box colors. TALENT_OWNED_COLOR is a softened version of #870146 --
# easier on the eyes for a color you'll be staring at a lot. To use
# the exact original hex instead, swap the line below for:
#   const TALENT_OWNED_COLOR = Color("870146")
const TALENT_OWNED_COLOR = Color("b5336e")
const TALENT_UNLEARNED_COLOR = Color(0.28, 0.28, 0.28)

func _get_talent_box_label(profession_name: String, path_name: String) -> String:
	return GameData.TALENT_BOX_DISPLAY_NAMES.get(profession_name, {}).get(path_name, path_name)


# Display text for a single box (left "Unlockable" panel) -- just the
# ability/weapon name, flat stat lines, or a not-yet-designed fallback
# for any profession not built out yet. No tier name, no path name.
func _get_talent_box_display(profession_name: String, path_name: String) -> String:
	var reward = GameData.TALENT_SKILL_REWARDS.get(profession_name, {}).get(path_name, null)
	if reward == null:
		return "Not yet designed"

	match reward.get("type", ""):
		"ability":
			return reward["name"]
		"weapon":
			return "Weapon Cert - " + reward["name"]
		"novice_grants":
			return "\n".join(reward["names"])
		"passive":
			var lines: Array = []
			for stat_pair in reward["stats"]:
				lines.append("+" + str(stat_pair[1]) + " " + stat_pair[0])
			if reward.has("ability"):
				lines.append(reward["ability"])
			if reward.has("abilities"):
				for granted_ability in reward["abilities"]:
					lines.append(granted_ability)
			if reward.has("weapon"):
				lines.append("Weapon Cert - " + reward["weapon"])
			if reward.has("weapons"):
				for granted_weapon in reward["weapons"]:
					lines.append("Weapon Cert - " + granted_weapon)
			if lines.size() == 0:
				return "Reserved for future stats"
			return "\n".join(lines)
		_:
			return "Not yet designed"

# Whole-profession summary (right "Learned" panel) -- lists every
# learned ability by name, then combined totals for passive stats
# (e.g. two owned Martial Training ranks that both grant One Hand Speed =
# one combined "+4 One Hand Speed" line, not two separate "+2" lines).
# Pending/undesigned boxes are skipped entirely.
func _get_talent_learned_summary(profession_name: String) -> String:
	var ability_lines: Array = []
	var passive_totals: Dictionary = {}

	var _paths_data = GameData.novice_professions[profession_name].get("paths", {})
	for path_name in _paths_data.keys():
		var path_data = _paths_data[path_name]
		var owned = path_data["unlocked_nodes"] >= path_data.get("max_nodes", NODES_PER_PATH)
		if not owned:
			continue

		var reward = GameData.TALENT_SKILL_REWARDS.get(profession_name, {}).get(path_name, null)
		if reward == null:
			continue

		match reward.get("type", ""):
			"ability":
				ability_lines.append(reward["name"])
			"weapon":
				ability_lines.append("Weapon Cert - " + reward["name"])
			"novice_grants":
				ability_lines.append_array(reward["names"])
			"passive":
				for stat_pair in reward["stats"]:
					var stat_name = stat_pair[0]
					var amount = stat_pair[1]
					passive_totals[stat_name] = passive_totals.get(stat_name, 0) + amount
				if reward.has("ability"):
					ability_lines.append(reward["ability"])
				if reward.has("abilities"):
					ability_lines.append_array(reward["abilities"])
				if reward.has("weapon"):
					ability_lines.append("Weapon Cert - " + reward["weapon"])
				if reward.has("weapons"):
					for granted_weapon in reward["weapons"]:
						ability_lines.append("Weapon Cert - " + granted_weapon)

	var lines: Array = []
	lines.append_array(ability_lines)
	for stat_name in passive_totals.keys():
		lines.append("+" + str(passive_totals[stat_name]) + " " + stat_name)

	if lines.size() == 0:
		return "Nothing learned yet."

	return "\n".join(lines)

func _make_flat_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = color.lightened(0.35)
	return style

func _make_talent_bar(bar_text: String, color: Color, bar_position: Vector2, bar_size: Vector2, parent: Node) -> Label:
	var panel = Panel.new()
	panel.position = bar_position
	panel.size = bar_size
	panel.add_theme_stylebox_override("panel", _make_flat_style(color))
	parent.add_child(panel)

	var label = Label.new()
	label.text = bar_text
	label.position = Vector2.ZERO
	label.size = bar_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0.05, 0.05, 0.05)
	panel.add_child(label)
	return label

var keystone_viewer: Node = null

func _build_talent_ui() -> void:
	talent_ui = Control.new()
	talent_ui.name = "TalentUI"
	talent_ui.anchor_right = 1
	talent_ui.anchor_bottom = 1
	talent_ui.visible = false
	talent_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UILayer.add_child(talent_ui)

	keystone_viewer = preload("res://scenes/KeystoneViewer.gd").new()
	keystone_viewer.main = self
	add_child(keystone_viewer)
	keystone_viewer.setup(talent_ui)


func _group_talent_paths(profession_name: String) -> Array:
	var columns: Array = []
	var lookup: Dictionary = {}

	# Keystone professions use a different UI -- return empty so the
	# old column grid renders nothing (new keystone UI replaces this).
	var prof_data = GameData.novice_professions.get(profession_name, {})
	if prof_data.has("keystones") or not prof_data.has("paths"):
		return columns

	for path_name in prof_data["paths"].keys():
		if path_name == "Master" or path_name == "Novice":
			continue

		var base_name = path_name
		var tier = 1

		if path_name.ends_with(" IV"):
			tier = 4
			base_name = path_name.substr(0, path_name.length() - 3)
		elif path_name.ends_with(" III"):
			tier = 3
			base_name = path_name.substr(0, path_name.length() - 4)
		elif path_name.ends_with(" II"):
			tier = 2
			base_name = path_name.substr(0, path_name.length() - 3)
		elif path_name.ends_with(" I"):
			tier = 1
			base_name = path_name.substr(0, path_name.length() - 2)

		if not lookup.has(base_name):
			var entry = {"base": base_name, "tiers": {}}
			columns.append(entry)
			lookup[base_name] = entry

		lookup[base_name]["tiers"][tier] = path_name

	return columns

# A profession name styled and colored like the plain requirement/
# prereq labels, but clickable -- jumps straight to that profession's
# tree. Used everywhere a profession name shows up as a "leads to" or
# "requires" indicator (above Master, above a column, below Novice).
func _make_profession_link_button(profession_name: String) -> Button:
	var btn = Button.new()
	btn.text = profession_name
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 16)
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.75, 0.9, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.75, 0.9, 1.0))
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_talent_select_profession.bind(profession_name))
	return btn

func _talent_select_profession(profession_name: String) -> void:
	_refresh_talent_grid(profession_name)

func _talent_select_node(profession_name: String, path_name: String) -> void:
	talent_details_label.text = _get_talent_box_display(profession_name, path_name)

func _refresh_talent_grid(profession_name: String) -> void:
	current_talent_profession = profession_name

	# Keystone professions (Street Thug) use a different UI -- clear
	# the old column grid and return. New keystone UI replaces this.
	var prof_data = GameData.novice_professions.get(profession_name, {})
	if prof_data.has("keystones") or not prof_data.has("paths"):
		for child in talent_grid_container.get_children():
			child.queue_free()
		for child in talent_master_container.get_children():
			child.queue_free()
		for child in talent_column_labels_container.get_children():
			child.queue_free()
		talent_details_label.text = "Select a keystone to view details. (New UI coming soon)"
		talent_learned_label.text = ""
		talent_points_label.text = "Thug Points: " + str(thug_points_available)
		return
	# THIS profession (i.e. its own Master box), with a connector line
	# down to the Master box (not touching it). This is the reverse of
	# a prereq list: a base profession's tree shows what it leads to,
	# not what leads to it (Apothecary's tree shows "Toxinsmith", not
	# the other way around).
	for child in talent_requirements_container.get_children():
		child.queue_free()

	var elites_requiring_master = _get_elites_requiring(profession_name, "Master")
	if elites_requiring_master.size() > 0:
		for elite_name in elites_requiring_master:
			var link_btn = _make_profession_link_button(elite_name)
			link_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			talent_requirements_container.add_child(link_btn)
		talent_requirements_line.visible = true
	else:
		talent_requirements_line.visible = false

	# Below Novice: shows which profession(s) must be mastered to
	# unlock this one -- sourced from PROFESSION_TREE.requires_mastered.
	for child in talent_prereq_container.get_children():
		child.queue_free()

	var required_profession_names: Array = GameData.PROFESSION_TREE.get(profession_name, {}).get("requires_mastered", [])
	if required_profession_names.size() > 0:
		for required_profession_name in required_profession_names:
			var prereq_link_btn = _make_profession_link_button(required_profession_name)
			prereq_link_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			talent_prereq_container.add_child(prereq_link_btn)
		talent_prereq_line.visible = true
	else:
		talent_prereq_line.visible = false

	for child in talent_grid_container.get_children():
		child.queue_free()

	for child in talent_master_container.get_children():
		child.queue_free()

	var master_path_data = GameData.novice_professions[profession_name]["paths"].get("Master", null)
	if master_path_data != null:
		var master_owned = master_path_data["unlocked_nodes"] >= master_path_data.get("max_nodes", NODES_PER_PATH)
		var master_color = Color(0.85, 0.7, 0.2) if master_owned else Color(0.35, 0.28, 0.08)

		var master_btn = Button.new()
		master_btn.text = "Master " + profession_name
		master_btn.anchor_right = 1
		master_btn.anchor_bottom = 1
		master_btn.focus_mode = Control.FOCUS_NONE
		var master_style = _make_flat_style(master_color)
		master_btn.add_theme_stylebox_override("normal", master_style)
		master_btn.add_theme_stylebox_override("hover", master_style)
		master_btn.add_theme_stylebox_override("pressed", master_style)
		master_btn.add_theme_stylebox_override("focus", master_style)
		master_btn.pressed.connect(_talent_select_node.bind(profession_name, "Master"))
		talent_master_container.add_child(master_btn)

	for child in talent_novice_container.get_children():
		child.queue_free()

	var novice_path_data = GameData.novice_professions[profession_name]["paths"].get("Novice", null)
	if novice_path_data != null:
		var novice_owned = novice_path_data["unlocked_nodes"] >= novice_path_data.get("max_nodes", NODES_PER_PATH)
		var novice_color = TALENT_OWNED_COLOR if novice_owned else TALENT_UNLEARNED_COLOR

		var novice_btn = Button.new()
		novice_btn.text = "Novice " + profession_name
		novice_btn.anchor_right = 1
		novice_btn.anchor_bottom = 1
		novice_btn.focus_mode = Control.FOCUS_NONE
		var novice_style = _make_flat_style(novice_color)
		novice_btn.add_theme_stylebox_override("normal", novice_style)
		novice_btn.add_theme_stylebox_override("hover", novice_style)
		novice_btn.add_theme_stylebox_override("pressed", novice_style)
		novice_btn.add_theme_stylebox_override("focus", novice_style)
		novice_btn.pressed.connect(_talent_select_node.bind(profession_name, "Novice"))
		talent_novice_container.add_child(novice_btn)

	talent_points_label.text = "Thug Points: " + str(thug_points_available)
	talent_details_label.text = "Select a skill box to view details."
	talent_learned_label.text = _get_talent_learned_summary(profession_name)

	for child in talent_column_labels_container.get_children():
		child.queue_free()

	var columns = _group_talent_paths(profession_name)

	# Column-header row, built in lockstep with the grid below so each
	# label lines up with its column. Shows "Leads to: X" (or just X,
	# kept short since horizontal space is tight) for any column whose
	# Rank IV is a listed Elite Profession prereq -- e.g. "Sniper" sits
	# above the Rifles column. Blank labels still take up the column's
	# width so unlinked columns just show empty space, keeping every
	# column's Rank IV box aligned regardless of which ones have a label.
	for column in columns:
		var top_tier_keys = column["tiers"].keys()
		top_tier_keys.sort()
		var top_tier_path_name = column["tiers"][top_tier_keys[-1]]
		var elites_requiring_column = _get_elites_requiring(profession_name, top_tier_path_name)

		var col_label_box = VBoxContainer.new()
		col_label_box.custom_minimum_size = Vector2(195, 30)
		col_label_box.add_theme_constant_override("separation", 2)
		talent_column_labels_container.add_child(col_label_box)

		for elite_name in elites_requiring_column:
			var col_link_btn = _make_profession_link_button(elite_name)
			col_link_btn.custom_minimum_size = Vector2(195, 15)
			col_label_box.add_child(col_link_btn)

	for column in columns:
		var col_box = VBoxContainer.new()
		col_box.custom_minimum_size = Vector2(195, 0)
		col_box.add_theme_constant_override("separation", 6)
		talent_grid_container.add_child(col_box)

		var tier_keys = column["tiers"].keys()
		tier_keys.sort()

		# The "next up" box is the lowest-tier one that isn't owned yet
		# and whose prereq is already met -- i.e. the one box in this
		# column you'd actually train next. Only this box gets an XP
		# progress bar, same as SWG only highlighting your next skill.
		var next_path_name = ""
		if professions_unlocked.get(profession_name, false):
			for tier in tier_keys:
				var candidate_path_name = column["tiers"][tier]
				var candidate_path_data = GameData.novice_professions[profession_name]["paths"][candidate_path_name]
				var candidate_owned = candidate_path_data["unlocked_nodes"] >= candidate_path_data.get("max_nodes", NODES_PER_PATH)
				if not candidate_owned and _is_prereq_met(profession_name, candidate_path_data):
					next_path_name = candidate_path_name
					break

		tier_keys.reverse()

		for tier in tier_keys:
			var path_name = column["tiers"][tier]
			var _pdata = GameData.novice_professions[profession_name].get("paths", {})
			var path_data = _pdata.get(path_name, null)
			if path_data == null:
				continue

			var owned = path_data["unlocked_nodes"] >= path_data.get("max_nodes", NODES_PER_PATH)

			var box_color: Color
			if owned:
				box_color = TALENT_OWNED_COLOR
			else:
				box_color = TALENT_UNLEARNED_COLOR

			var style = _make_flat_style(box_color)

			var btn = Button.new()
			btn.text = _get_talent_box_label(profession_name, path_name)
			btn.custom_minimum_size = Vector2(185, 70)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_stylebox_override("focus", style)
			btn.pressed.connect(_talent_select_node.bind(profession_name, path_name))
			col_box.add_child(btn)

			if path_name == next_path_name:
				var xp_type = path_data["xp_type"]
				var xp_cost = _get_box_cost(path_data)["xp_cost"]
				var current_xp = xp_pools[xp_type]
				var progress_fraction = clamp(float(current_xp) / float(max(xp_cost, 1)), 0.0, 1.0)

				const PROGRESS_BAR_HEIGHT = 9.0

				var progress_track = ColorRect.new()
				progress_track.color = Color(0, 0, 0, 0.45)
				progress_track.anchor_left = 0.0
				progress_track.anchor_right = 1.0
				progress_track.anchor_top = 1.0
				progress_track.anchor_bottom = 1.0
				progress_track.offset_top = -PROGRESS_BAR_HEIGHT
				progress_track.offset_bottom = 0.0
				progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(progress_track)

				var progress_fill = ColorRect.new()
				progress_fill.color = Color(0.3, 1.0, 0.4) if progress_fraction >= 1.0 else Color(1.0, 0.85, 0.3)
				progress_fill.anchor_left = 0.0
				progress_fill.anchor_right = progress_fraction
				progress_fill.anchor_top = 1.0
				progress_fill.anchor_bottom = 1.0
				progress_fill.offset_top = -PROGRESS_BAR_HEIGHT
				progress_fill.offset_bottom = 0.0
				progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(progress_fill)

		# Tree-name label -- sits below the Rank I box (the last one
		# added above, since tiers render highest-to-lowest top-to-
		# bottom) so it's still obvious which weapon/skill line this
		# column represents now that the boxes themselves have
		# flavorful names instead of "Blade I/II/III/IV".
		var tree_label = Label.new()
		tree_label.text = column["base"]
		tree_label.custom_minimum_size = Vector2(185, 0)
		tree_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tree_label.modulate = Color(0.6, 0.75, 0.75)
		tree_label.add_theme_font_size_override("font_size", 13)
		col_box.add_child(tree_label)

# --- Ability Book ---
# A testing/reference-quality replacement for the old fixed 8-button
# AbilityMenu, which could only ever show 6 hardcoded abilities and
# had no way to display anything added later (Cleave, Subdue, all of
# Chrome Gunner's abilities, etc.). This scans GameData.ability_definitions
# directly, so any future ability shows up automatically -- nothing
# to remember to wire up by hand. Fully built here in code, same
# approach as the Talent Viewer.

func _build_ability_book_ui() -> void:
	ability_book_ui = Control.new()
	ability_book_ui.name = "AbilityBookUI"
	ability_book_ui.anchor_right = 1
	ability_book_ui.anchor_bottom = 1
	ability_book_ui.visible = false
	ability_book_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UILayer.add_child(ability_book_ui)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.anchor_right = 1
	backdrop.anchor_bottom = 1
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_book_ui.add_child(backdrop)

	var main_panel = Panel.new()
	main_panel.position = Vector2(660, 230)
	main_panel.size = Vector2(600, 620)
	main_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.043, 0.086, 0.086)))
	ability_book_ui.add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Ability Book"
	title_label.position = Vector2(20, 8)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(560, 6)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): ability_book_ui.visible = false)
	main_panel.add_child(close_button)

	var hint_label = Label.new()
	hint_label.text = "Click to use once. Drag onto an action bar slot to assign it."
	hint_label.position = Vector2(20, 36)
	hint_label.modulate = Color(0.7, 0.75, 0.75)
	hint_label.add_theme_font_size_override("font_size", 12)
	main_panel.add_child(hint_label)

	var list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(20, 64)
	list_scroll.size = Vector2(560, 540)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_panel.add_child(list_scroll)

	ability_book_list_container = VBoxContainer.new()
	ability_book_list_container.custom_minimum_size = Vector2(540, 0)
	ability_book_list_container.add_theme_constant_override("separation", 4)
	list_scroll.add_child(ability_book_list_container)

func _make_ability_book_button(ability_name: String) -> Button:
	var btn = Button.new()
	btn.text = ability_name
	btn.custom_minimum_size = Vector2(540, 34)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_use_ability_by_name.bind(ability_name))

	var drag_script = load(ABILITY_DRAG_SOURCE_SCRIPT_PATH)
	if drag_script == null:
		push_warning("Ability Book: could not load drag script at " + ABILITY_DRAG_SOURCE_SCRIPT_PATH + " -- dragging will not work until this path is fixed.")
	else:
		btn.set_script(drag_script)
		btn.set("ability_name", ability_name)

	return btn

func _refresh_ability_book() -> void:
	for child in ability_book_list_container.get_children():
		child.queue_free()

	var available_names: Array = ["Attack"]

	if professions_unlocked.get("Street Thug", false):
		available_names.append("Apply Bandage")
		if _get_rank_unlocked("Healing II"):
			available_names.append("IV Drip")
		if _get_rank_unlocked("Healing IV"):
			available_names.append("Healing Vapor")
		if _get_rank_unlocked("Stims I"):
			available_names.append("Adrenaline Boost")
		if _get_rank_unlocked("Stims III"):
			available_names.append("Blood Bag")

	for profession_name in GameData.novice_professions.keys():
		if not professions_unlocked.get(profession_name, false):
			continue

		for ability_name in GameData.ability_definitions.keys():
			var ability_data = GameData.ability_definitions[ability_name]
			if ability_data.get("requires_profession", "") != profession_name:
				continue
			if _is_ability_learned(ability_name):
				available_names.append(ability_name)

	available_names.sort()

	for ability_name in available_names:
		ability_book_list_container.add_child(_make_ability_book_button(ability_name))

# --- Inventory Book ---
# A testing/reference UI for inventory, styled the same way as the
# Talent Viewer and Ability Book (fully built in code, scrollable, no
# fixed slot count). Clicking any item shows its actual stats -- this
# works generically for resources, crafted weapons, and tools alike,
# since they all already share the same inventory_stats dictionary.

func _build_inventory_book_ui() -> void:
	inventory_book_ui = Control.new()
	inventory_book_ui.name = "InventoryBookUI"
	inventory_book_ui.anchor_right = 1
	inventory_book_ui.anchor_bottom = 1
	inventory_book_ui.visible = false
	inventory_book_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UILayer.add_child(inventory_book_ui)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.anchor_right = 1
	backdrop.anchor_bottom = 1
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_book_ui.add_child(backdrop)

	var main_panel = Panel.new()
	main_panel.position = Vector2(510, 215)
	main_panel.size = Vector2(900, 650)
	main_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.043, 0.086, 0.086)))
	inventory_book_ui.add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Inventory"
	title_label.position = Vector2(20, 8)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(860, 6)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): inventory_book_ui.visible = false)
	main_panel.add_child(close_button)

	# Left panel -- details for whichever item was last clicked.
	var details_panel = Panel.new()
	details_panel.position = Vector2(20, 50)
	details_panel.size = Vector2(320, 560)
	details_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(details_panel)

	var details_header = Label.new()
	details_header.text = "Details"
	details_header.position = Vector2(10, 4)
	details_header.modulate = Color(0.6, 0.9, 0.9)
	details_panel.add_child(details_header)

	var details_scroll = ScrollContainer.new()
	details_scroll.position = Vector2(10, 28)
	details_scroll.size = Vector2(300, 522)
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_panel.add_child(details_scroll)

	# A VBox rather than the label directly, so the socket widgets can sit
	# beneath the stat text inside the same scroll region.
	var details_vbox = VBoxContainer.new()
	details_vbox.custom_minimum_size = Vector2(285, 0)
	details_vbox.add_theme_constant_override("separation", 6)
	details_scroll.add_child(details_vbox)

	inventory_book_stats_label = Label.new()
	inventory_book_stats_label.custom_minimum_size = Vector2(285, 0)
	inventory_book_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	inventory_book_stats_label.text = "Select an item to view its details."
	inventory_book_stats_label.modulate = Color(0.85, 0.95, 0.95)
	details_vbox.add_child(inventory_book_stats_label)

	inventory_book_socket_area = VBoxContainer.new()
	inventory_book_socket_area.custom_minimum_size = Vector2(285, 0)
	inventory_book_socket_area.add_theme_constant_override("separation", 4)
	details_vbox.add_child(inventory_book_socket_area)

	mod_confirm_dialog = ConfirmationDialog.new()
	mod_confirm_dialog.title = "Fit mods permanently?"
	mod_confirm_dialog.ok_button_text = "Fit permanently"
	mod_confirm_dialog.confirmed.connect(_on_mod_install_confirmed)
	inventory_book_ui.add_child(mod_confirm_dialog)

	# Right panel -- scrollable list of every item currently held.
	var list_panel = Panel.new()
	list_panel.position = Vector2(360, 50)
	list_panel.size = Vector2(520, 560)
	list_panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(list_panel)

	var list_header = Label.new()
	list_header.text = "Items"
	list_header.position = Vector2(10, 4)
	list_header.modulate = Color(0.6, 0.9, 0.9)
	list_panel.add_child(list_header)

	var list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(10, 28)
	list_scroll.size = Vector2(500, 522)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)

	inventory_book_list_container = VBoxContainer.new()
	inventory_book_list_container.custom_minimum_size = Vector2(485, 0)
	inventory_book_list_container.add_theme_constant_override("separation", 4)
	list_scroll.add_child(inventory_book_list_container)

func _format_quantity_tiered(qty: int) -> String:
	if qty < 1000:
		return str(qty)
	return str(int(qty / 1000)) + "k"

# Builds the label text for one inventory slot. Resources show a
# tiered quantity (1-999 plain, 1000+ as "10k"/"23k"/etc). Items with
# a Charges stat show that instead. Everything else (unique crafted
# equipment) shows just its name -- no "(1)" clutter, since each craft
# is its own slot now. Genuinely stacked non-resource items (like loot
# that dropped together and shares an ID) still show a plain count.
func _get_inventory_slot_label(item_key: String) -> String:
	var display_name = _get_inventory_display_name(item_key)
	var qty = inventory.get(item_key, 0)
	var stats = inventory_stats.get(item_key, {})

	if resource_subclass_of.has(item_key):
		return display_name + " (" + _format_quantity_tiered(qty) + ")"
	elif stats.has("Charges"):
		return display_name + " (" + str(stats["Charges"]) + " charges)"
	elif qty > 1:
		return display_name + " (" + str(qty) + ")"
	else:
		return display_name

func _is_equippable_item(item_key: String) -> bool:
	var item_class = crafted_item_class.get(item_key, "")
	return item_class != "" and item_class != "Component" and item_class != "Medicine" and item_class != "Tool"

func _on_inventory_book_item_double_clicked(item_key: String) -> void:
	if not _is_equippable_item(item_key):
		return

	if equipped_weapon_name == item_key:
		equipped_weapon_name = ""
	else:
		equipped_weapon_name = item_key

	_refresh_inventory_book()

func _refresh_inventory_book() -> void:
	for child in inventory_book_list_container.get_children():
		child.queue_free()

	inventory_book_stats_label.text = "Select an item to view its details."
	inventory_book_selected_key = ""
	pending_mod_installs.clear()
	_refresh_socket_area()

	for item_key in inventory.keys():
		if inventory[item_key] <= 0:
			continue

		var display_name = _get_inventory_display_name(item_key)

		var btn = Button.new()
		btn.text = _get_inventory_slot_label(item_key)
		btn.custom_minimum_size = Vector2(480, 32)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_select_inventory_book_item.bind(item_key))
		btn.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.double_click:
				_on_inventory_book_item_double_clicked(item_key)
		)

		# Equipped item gets a visible border so it's obvious which
		# weapon is currently active, without needing a separate
		# Equip window at all -- double-click toggles it on/off.
		if item_key == equipped_weapon_name:
			var equipped_style = _make_flat_style(Color(0.15, 0.15, 0.15))
			equipped_style.border_width_left = 3
			equipped_style.border_width_top = 3
			equipped_style.border_width_right = 3
			equipped_style.border_width_bottom = 3
			equipped_style.border_color = Color(0.95, 0.75, 0.2)
			btn.add_theme_stylebox_override("normal", equipped_style)
			btn.add_theme_stylebox_override("hover", equipped_style)
			btn.add_theme_stylebox_override("pressed", equipped_style)
			btn.add_theme_stylebox_override("focus", equipped_style)

		# Drag-and-drop uses the item's display name (e.g. "Mineral
		# Survey Tool"), not its internal instance key -- raw resources
		# have randomly-generated instance keys, but _use_ability_by_name
		# (called on drop) dispatches based on the recognizable display
		# name instead.
		# A mod drags with a DIFFERENT payload key than an ability, so
		# action-bar slots and socket slots each silently reject the other.
		if mod_instance_of.has(item_key):
			var mod_drag_script = load(MOD_DRAG_SOURCE_SCRIPT_PATH)
			if mod_drag_script != null:
				btn.set_script(mod_drag_script)
				btn.set("mod_item_key", item_key)
		else:
			var drag_script = load(ABILITY_DRAG_SOURCE_SCRIPT_PATH)
			if drag_script != null:
				btn.set_script(drag_script)
				btn.set("ability_name", display_name)

		inventory_book_list_container.add_child(btn)

# Real functional effect text for consumables whose Quality actually
# drives something (Adrenaline Shot, Empty IV Bag) -- shown in the
# Inventory Book instead of just hiding Quality with nothing to
# replace it. Returns [] for anything not specifically handled here.
func _get_consumable_effect_lines(base_name: String, quality: int) -> Array:
	match base_name:
		"Adrenaline Shot":
			var action_amount = _scale_by_quality(quality, ADRENALINE_BOOST_MIN_ACTION, ADRENALINE_BOOST_MAX_ACTION)
			return ["Max Action +" + str(action_amount), "10 min duration"]
		"Empty IV Bag":
			var heal_amount = _scale_by_quality(quality, BLOOD_BAG_MIN_HEAL, BLOOD_BAG_MAX_HEAL)
			return ["Max Health +" + str(heal_amount), "10 min duration"]
		"Crate of Bandages":
			return ["Heal +" + str(BANDAGE_HEAL_AMOUNT)]
		_:
			return []

func _select_inventory_book_item(item_key: String) -> void:
	# Changing selection abandons anything staged but not applied.
	if item_key != inventory_book_selected_key:
		pending_mod_installs.clear()
	inventory_book_selected_key = item_key
	var display_name = _get_inventory_display_name(item_key)
	var qty = inventory.get(item_key, 0)
	var stats = inventory_stats.get(item_key, {})

	var lines: Array = []
	lines.append(display_name)

	# For raw resources, the inventory key IS the resource's unique
	# generated name (e.g. "Thaliryxqven") -- show it as its own line,
	# since it's meaningful identity info, not just internal plumbing.
	if resource_subclass_of.has(item_key):
		lines.append(item_key)

	lines.append("Quantity: " + str(qty))
	lines.append("")

	if stats.size() == 0:
		lines.append("No additional stats.")
	else:
		var is_resource = resource_subclass_of.has(item_key)
		var stat_lines: Array = []

		var base_name = consumable_base_name.get(item_key, "")
		stat_lines.append_array(_get_consumable_effect_lines(base_name, stats.get("Quality", 500)))

		for stat_name in stats.keys():
			# Raw 0-1000 Quality stays hidden on gear -- it is an internal
			# scale. Crafted items show "Craft Quality" (0-100) instead,
			# which is the number the crafting UI actually used.
			if stat_name == "Quality" and not is_resource:
				continue
			stat_lines.append(stat_name + ": " + _format_number(stats[stat_name]))

		# --- crafted-item detail: traits, flaws, socket tags ---
		var instance_id = String(crafted_item_instance_of.get(item_key, ""))
		if instance_id != "" and crafted_items.has(instance_id):
			var inst: Dictionary = crafted_items[instance_id]

			var trait_names: Array = []
			for t in inst.get("inherited_trait_ids", []):
				trait_names.append(String(CraftingData.get_trait(String(t)).get("display_name", t)))
			if not trait_names.is_empty():
				stat_lines.append("")
				stat_lines.append("Traits: " + ", ".join(trait_names))

			var flaw_names: Array = []
			for f in inst.get("inherited_instability_ids", []):
				flaw_names.append(String(CraftingData.get_instability(String(f)).get("display_name", f)))
			if not flaw_names.is_empty():
				stat_lines.append("Flaws: " + ", ".join(flaw_names))

			var sc = int(inst.get("socket_count", 0))
			if sc > 0:
				stat_lines.append("Mod sockets: " + str(sc))

			var dur = float(inst.get("maximum_durability", 0.0))
			if dur > 0.0:
				stat_lines.append("Durability: " + str(int(round(float(inst.get("current_durability", dur)))))
					+ " / " + str(int(round(dur))))

		if stat_lines.size() == 0:
			lines.append("No additional stats.")
		else:
			lines.append_array(stat_lines)

	inventory_book_stats_label.text = "\n".join(lines)
	_refresh_socket_area()

const MELEE_WEAPON_CLASSES = ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick"]
const RANGED_WEAPON_CLASSES = ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"]

# Returns {"class": ..., "type": ..., "subclass": ...}. "type" and
# "subclass" come back as "" when they wouldn't add a meaningful
# extra level (e.g. Tools have no sub-type, and most ranged weapons'
# item_subclass just repeats item_class).


# Persists which category headers are currently collapsed, keyed by a
# unique path string per book so Crafting and Survey book state never
# collide (e.g. "craft:Melee Weapon" vs "survey:Material"). Survives
# refreshes since it's a top-level var, not rebuilt each time.
var book_category_collapsed: Dictionary = {}

func _toggle_book_category(category_key: String, refresh_callback: Callable) -> void:
	book_category_collapsed[category_key] = not book_category_collapsed.get(category_key, false)
	refresh_callback.call()

func _make_plain_header(text: String, indent: int, color: Color) -> Label:
	var header = Label.new()
	header.text = "  ".repeat(indent) + text
	header.modulate = color
	header.add_theme_font_size_override("font_size", 15 - indent)
	return header


# Determines whether a recipe is currently learned/craftable.
# Street Thug recipes are gated by the Crafting keystone: the keystone
# must be unlocked for Novice recipes, and 6 points must be spent in it
# for every non-Novice recipe (blanket gate for now -- to be split out
# per recipe later). Recipes for other professions keep the simpler
# "is the profession unlocked" rule.


# Builds the "Hilt: 2 Metal, 1 Torn Cloth" style breakdown, grouped by
# slot_names when a recipe has them (weapons), or a flat list when it
# doesn't (tools, medicine, simple materials).


# Finds the first inventory stack matching a requirement, used to
# pre-select a sensible default when entering Assembly for a slot.

# Switches the right panel from the schematic browser into the
# Assembly step for the currently selected recipe -- this is where the
# player picks exactly which resource stack fills each slot and sees
# a live projected-quality preview before committing, similar in
# spirit to SWG's assembly screen (not its exact formulas or look).



# Rebuilds the right panel's contents as the per-slot resource picker,
# and the left panel's contents as the live projected-quality preview.

# Live preview of what the current resource selections would produce
# -- our own version of "see how resources affect the build" before
# committing, not a copy of any specific game's exact formula/look.

# Commits the craft using the SPECIFIC resource stacks chosen in
# Assembly, rather than auto-picking from inventory like the old
# flow -- this is the actual "Assemble" action.

# --- Completed Item Popup ---
# Shows the finished item right after Assemble, with its full stats --
# separate from the Crafting Book itself so it reads as a clear
# "here's what you made" moment rather than just more list text.
# Includes a placeholder Mod Slots section now specifically so the
# layout already has a home for that feature when it's built later,
# rather than needing this window redesigned at that point.



# --- Survey Book ---
# A testing/reference UI for surveying, styled like the other books.
# Deliberately does NOT show resource stats (Conductivity, Toughness,
# etc.) anywhere on this screen -- those stay exclusive to the
# Inventory Book and Crafting Book, per request. This only shows
# concentration %, matching what a real survey tool would tell you.



# Scans a resource -- same math as the old resource_tree selection
# (nearest-hotspot concentration, Scanning XP, skill bonuses), just
# without ever displaying resource_stats anywhere on this screen.


# ============================================================
# STARTUP DATA VALIDATION (see Combat.validate_game_data)
# ============================================================
# Runs the cross-file data checks once at startup. Problems go to the
# console via push_error AND to an on-screen banner, because the whole
# point of this guard is that these failures are otherwise SILENT --
# a bad key returns a legal default and play continues looking normal.
#
# The banner is dismissible (click it, or press ESC) so it can never
# trap the player behind an overlay.
func _run_startup_validation() -> void:
	var issues: Array = Combat.validate_game_data()
	if issues.is_empty():
		return

	var real_problems: Array = []
	for issue in issues:
		if String(issue).begins_with("NOTE"):
			print("[DATA CHECK] " + String(issue))
		else:
			real_problems.append(issue)
			push_error("[DATA CHECK] " + String(issue))

	if real_problems.is_empty():
		return

	_show_validation_banner(real_problems)


func _show_validation_banner(problems: Array) -> void:
	var layer = get_node_or_null("UILayer")
	if layer == null:
		return

	var banner = Panel.new()
	banner.name = "DataValidationBanner"
	banner.anchor_left = 0.0
	banner.anchor_top = 0.0
	banner.anchor_right = 1.0
	banner.offset_left = 0
	banner.offset_top = 0
	banner.offset_right = 0
	banner.custom_minimum_size = Vector2(0, 0)
	banner.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.35, 0.05, 0.05, 0.94)
	sb.border_color = Color(1.0, 0.35, 0.35)
	sb.set_border_width_all(2)
	banner.add_theme_stylebox_override("panel", sb)

	var shown = min(problems.size(), 6)
	var body = "DATA VALIDATION: " + str(problems.size()) + " problem(s) found\n"
	for i in range(shown):
		body += "  - " + String(problems[i]) + "\n"
	if problems.size() > shown:
		body += "  ... and " + str(problems.size() - shown) + " more (see Output console)\n"
	body += "\n[ click this banner or press ESC to dismiss ]"

	var lbl = Label.new()
	lbl.text = body
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.anchor_right = 1.0
	lbl.offset_left = 14
	lbl.offset_top = 10
	lbl.offset_right = -14

	banner.add_child(lbl)
	banner.offset_bottom = 34 + (shown + 3) * 20
	layer.add_child(banner)

	banner.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			banner.queue_free()
	)


# ====================================================================
# CRAFTING INTEGRATION (Phase 3)
# ====================================================================

# Generates the campaign resource map ONCE, on a genuinely new game. A
# loaded save restores the map verbatim instead (see _load_crafting_state),
# which is what guarantees a deposit never rerolls between sessions.
func _init_crafting_campaign() -> void:
	if not campaign_map.is_empty():
		return
	if campaign_seed == 0:
		campaign_seed = int(Time.get_unix_time_from_system()) ^ (randi() & 0xFFFF)
	campaign_map = CraftingResourceGenerator.generate_campaign(campaign_seed)
	surface_sources = CraftingResourceGenerator.generate_surface_sources(campaign_seed)
	if crafting_profile.is_empty():
		crafting_profile = CraftingModels.new_player_profile()

	var problems = CraftingResourceGenerator.validate_campaign(campaign_map)
	for p in problems:
		push_error("[CRAFTING] Campaign map problem: " + String(p))


# Adds a batch to the player's material store. Batches of the SAME family,
# quality, trait and instability merge, so repeated scavenging of one
# deposit does not flood the store with near-identical entries. Anything
# that differs stays separate -- quality and provenance are meaningful.
func _store_material_batch(batch: Dictionary) -> void:
	if batch.is_empty():
		return
	for existing_id in material_batches.keys():
		var b = material_batches[existing_id]
		if String(b.get("family_id", "")) != String(batch.get("family_id", "")):
			continue
		if int(b.get("quality", -1)) != int(batch.get("quality", -2)):
			continue
		if String(b.get("primary_trait_id", "")) != String(batch.get("primary_trait_id", "")):
			continue
		if String(b.get("instability_id", "")) != String(batch.get("instability_id", "")):
			continue
		if String(b.get("source_id", "")) != String(batch.get("source_id", "")):
			continue
		b["amount"] = int(b.get("amount", 0)) + int(batch.get("amount", 0))
		return
	material_batches[String(batch.get("batch_id", ""))] = batch


# Every batch the player is carrying that a given blueprint slot accepts
# and has enough of. Used by the crafting UI to populate slot choices.
func _batches_for_slot(slot: Dictionary) -> Array:
	var accepts: Array = slot.get("accepts", [])
	var needed = int(slot.get("amount", 1))
	var out: Array = []
	for bid in material_batches.keys():
		var b = material_batches[bid]
		if not accepts.has(String(b.get("family_id", ""))):
			continue
		if int(b.get("amount", 0)) < needed:
			continue
		out.append(b)
	return out


# Consumes the materials a completed craft used.
func _consume_selection(blueprint_id: String, selection: Dictionary) -> void:
	var bp = CraftingData.get_blueprint(blueprint_id)
	for slot in bp.get("material_slots", []):
		var sid = String(slot.get("slot_id", ""))
		var batch = selection.get(sid, {})
		if batch.is_empty():
			continue
		var bid = String(batch.get("batch_id", ""))
		if not material_batches.has(bid):
			continue
		var left = int(material_batches[bid].get("amount", 0)) - int(slot.get("amount", 1))
		if left > 0:
			material_batches[bid]["amount"] = left
		else:
			material_batches.erase(bid)


# Bridges a crafted item instance into the ordinary inventory so it can be
# equipped and used by combat.
#
# SCALE WARNING: crafting quality is 0-100 (spec), but the legacy weapon
# stat model realises stats as min + (Quality / 1000) * (max - min). Writing
# the crafted 0-100 value straight through would peg every crafted weapon at
# the bottom of its range, so it is scaled x10 here. This is the ONE place
# the two scales are allowed to meet.
func _grant_crafted_item(crafted: Dictionary) -> String:
	if crafted.is_empty():
		return ""
	var item_name = String(crafted.get("display_name", ""))
	var definition: Dictionary = GameData.get_item_definition(item_name)
	if definition.is_empty():
		push_error("[CRAFTING] Crafted item has no ITEM_DEFINITION: " + item_name)
		return ""

	var item_key = _generate_unique_resource_name()
	consumable_base_name[item_key] = item_name
	_add_to_inventory(item_key, 1)

	# QUALITY SCALE BRIDGE: crafting works on 0-100, the legacy item model
	# on 0-1000. Without the x10 every crafted weapon would sit at the
	# very bottom of its stat ranges. Do not "simplify" this away.
	var realised = int(round(float(crafted.get("craft_quality_score", 0.0))))
	var legacy_quality = clampi(realised * 10, 0, 1000)

	# Realise the full stat block, exactly as a starting weapon would get.
	# Previously only Quality was set here, so crafted weapons had no
	# damage, speed, accuracy or damage type -- they were blank items.
	_realise_item_stats(item_key, definition, legacy_quality)

	# Crafting-specific detail, shown in the inventory and used later by
	# the mod system.
	var stats = inventory_stats[item_key]
	stats["Craft Quality"] = realised

	crafted_items[String(crafted.get("instance_id", item_key))] = crafted
	crafted_item_instance_of[item_key] = String(crafted.get("instance_id", ""))
	return item_key


# Runs a craft end to end: validate, build the item, consume materials,
# put the result in the player's hands.
# Phase 4: allocation and risk_mode_id carry the player's experimentation
# choices. Both default to "no experimentation", so an empty allocation
# produces exactly the Phase 3 result.
func _perform_craft(blueprint_id: String, selection: Dictionary,
		allocation: Dictionary = {}, risk_mode_id: String = "") -> Dictionary:
	var problems = CraftingService.validate_selection(blueprint_id, selection)
	if not problems.is_empty():
		_show_combat_message("Cannot craft: " + String(problems[0]))
		return {}

	var bp = CraftingData.get_blueprint(blueprint_id)

	if String(bp.get("output_type", "")) == "mod":
		return _perform_mod_craft(blueprint_id, selection)

	var points = CraftingService.generate_experimentation_points(blueprint_id, selection, crafting_profile)
	var alloc_problems = CraftingService.validate_allocation(blueprint_id, allocation, int(points["total"]))
	if not alloc_problems.is_empty():
		_show_combat_message("Cannot craft: " + String(alloc_problems[0]))
		return {}

	var crafted = CraftingService.craft(blueprint_id, selection, 0.0, allocation, risk_mode_id, crafting_profile)
	if crafted.is_empty():
		_show_combat_message("The craft failed.")
		return {}

	_consume_selection(blueprint_id, selection)
	var item_key = _grant_crafted_item(crafted)
	if item_key == "":
		return {}

	_update_inventory_display()
	var msg = "Crafted: " + String(crafted.get("display_name", "item")) + " (Quality " + str(int(round(float(crafted.get("craft_quality_score", 0.0))))) + ")"
	var results: Dictionary = crafted.get("experimentation_results", {})
	var failed: Array = []
	var flaws: Array = []
	for cid in results.keys():
		if bool(results[cid].get("failed", false)):
			failed.append(String(CraftingData.get_category(cid).get("display_name", cid)))
		var flaw = String(results[cid].get("gained_instability", ""))
		if flaw != "":
			flaws.append(String(CraftingData.get_instability(flaw).get("display_name", flaw)))
	if not failed.is_empty():
		msg += "\nFailed: " + ", ".join(failed)
	if not flaws.is_empty():
		msg += "\nGained flaw: " + ", ".join(flaws)
	var sockets = int(crafted.get("socket_count", 0))
	if sockets > 0:
		msg += "\nSockets: " + str(sockets)
	_show_combat_message(msg)
	return crafted


func _perform_mod_craft(blueprint_id: String, selection: Dictionary) -> Dictionary:
	var mod = CraftingService.craft_mod(blueprint_id, selection)
	if mod.is_empty():
		_show_combat_message("The craft failed.")
		return {}

	_consume_selection(blueprint_id, selection)
	var mod_id = String(mod.get("mod_id", ""))
	var grade_id = String(mod.get("grade_id", "standard"))
	var instance_id = String(mod.get("mod_instance_id", ""))
	mod_instances[instance_id] = mod

	var item_key = _generate_unique_resource_name()
	var mod_def = CraftingData.get_mod(mod_id)
	var grade = CraftingData.get_mod_grade(grade_id)
	consumable_base_name[item_key] = String(grade.get("display_name", grade_id)) + " " + String(mod_def.get("display_name", mod_id))
	mod_instance_of[item_key] = instance_id
	_add_to_inventory(item_key, 1)
	_update_inventory_display()

	var quality = int(round(float(mod.get("craft_quality", 0.0))))
	var msg = "Crafted: " + consumable_base_name[item_key] + " (Quality " + str(quality) + ")"
	_show_combat_message(msg)
	return mod


# Restores crafting state from a save. The campaign map is restored WHOLE
# and never regenerated -- that is the anti-reroll guarantee.
func _load_crafting_state(save_data: Dictionary) -> void:
	campaign_seed = int(save_data.get("campaign_seed", 0))
	campaign_map = CraftingResourceGenerator.from_save_dict(save_data.get("campaign_map", {}))
	surface_sources = save_data.get("surface_sources", {})
	_migrate_traitless_surface_sources()

	var restored = CraftingService.from_save_dict(save_data.get("crafting", {}))
	material_batches = restored.get("batches", {})
	crafted_items = restored.get("items", {})
	crafting_profile = restored.get("profile", {})
	if crafting_profile.is_empty():
		crafting_profile = CraftingModels.new_player_profile()


func _migrate_traitless_surface_sources() -> void:
	var dominated = false
	for sid in surface_sources.keys():
		if String(surface_sources[sid].get("primary_trait_id", "")) == "":
			dominated = true
			break
	if not dominated:
		return
	var rng = RandomNumberGenerator.new()
	var h: int = campaign_seed
	for i in range("surface".length()):
		h = (h * 31 + "surface".unicode_at(i)) & 0x7FFFFFFF
	rng.seed = h
	var families = CraftingData.all_families()
	var slot = 0
	for entry in CraftingData.SURFACE_SOURCES:
		var family_id = String(entry.get("family_id", ""))
		if not families.has(family_id):
			slot += 1
			continue
		rng.randi_range(CraftingData.SURFACE_QUALITY_MIN, CraftingData.SURFACE_QUALITY_MAX)
		var fam_traits: Array = families[family_id].get("eligible_traits", [])
		var trait_id = "" if fam_traits.is_empty() else String(fam_traits[rng.randi() % fam_traits.size()])
		var source_id = "src_surface_" + family_id + "_" + str(slot)
		if surface_sources.has(source_id) and String(surface_sources[source_id].get("primary_trait_id", "")) == "":
			surface_sources[source_id]["primary_trait_id"] = trait_id
			print("[MIGRATE] Backfilled trait '" + trait_id + "' onto " + source_id)
		rng.randi_range(55, 80)
		slot += 1


# Builds the blueprint crafting panel. Mirrors _build_talent_ui: a
# full-screen Control under UILayer, with the panel script building itself
# into it. A fresh Control is used rather than the scene's leftover
# CraftingUI node, which may still hold children from the deleted system.
func _build_crafting_panel_ui() -> void:
	crafting_panel_ui = Control.new()
	crafting_panel_ui.name = "CraftingPanelUI"
	crafting_panel_ui.anchor_right = 1
	crafting_panel_ui.anchor_bottom = 1
	crafting_panel_ui.visible = false
	$UILayer.add_child(crafting_panel_ui)

	crafting_panel = preload("res://scenes/CraftingPanel.gd").new()
	crafting_panel.main = self
	add_child(crafting_panel)
	crafting_panel.setup(crafting_panel_ui)


func close_crafting_panel() -> void:
	if crafting_panel_ui != null:
		crafting_panel_ui.visible = false


# ====================================================================
# MODS (crafting Phase 6 -- integration)
# ====================================================================

# The mod instances currently fitted to an inventory item.
func _installed_mods_for(item_key: String) -> Array:
	var out: Array = []
	var instance_id = String(crafted_item_instance_of.get(item_key, ""))
	if instance_id == "" or not crafted_items.has(instance_id):
		return out
	for mid in crafted_items[instance_id].get("installed_mod_instance_ids", []):
		if mod_instances.has(String(mid)):
			out.append(mod_instances[String(mid)])
	return out


# Recomputes an item's stats from scratch and then layers mod deltas on
# top. IDEMPOTENT by design: the base is always rebuilt from the item
# definition and quality, so calling this repeatedly can never
# double-count a mod or lose the base stats. Both grant paths still go
# through _realise_item_stats, so they cannot drift apart.
func _apply_item_stats_with_mods(item_key: String) -> void:
	var definition: Dictionary = {}
	var base_name = String(consumable_base_name.get(item_key, item_key))
	definition = GameData.get_item_definition(base_name)
	if definition.is_empty():
		return

	var quality = int(inventory_stats.get(item_key, {}).get("Quality", 500))
	_realise_item_stats(item_key, definition, quality)

	var mods = _installed_mods_for(item_key)
	if mods.is_empty():
		return

	var deltas = CraftingService.mod_stat_deltas(mods)
	var stats = inventory_stats[item_key]
	for stat_name in deltas.keys():
		var base_value = float(stats.get(stat_name, 0.0))
		var new_value = base_value + float(deltas[stat_name])
		if stat_name == "Speed" or stat_name == "Reload Speed":
			stats[stat_name] = max(0.1, round(new_value * 10.0) / 10.0)
		else:
			stats[stat_name] = max(0.0, round(new_value))

	# Damage Per Second is derived, so recompute it AFTER mods land.
	if stats.has("Speed") and stats.has("Damage Rating"):
		var spd = float(stats["Speed"])
		if spd > 0.0:
			stats["Damage Per Second"] = round((float(stats["Damage Rating"]) / spd) * 10.0) / 10.0


# Called after a load, since installed mods are restored but the stat
# values written into inventory_stats came from the save as-is.
func _reapply_all_mod_stats() -> void:
	for item_key in crafted_item_instance_of.keys():
		if inventory.has(item_key):
			_apply_item_stats_with_mods(String(item_key))


# Preview of what a mod would do to an item, WITHOUT installing it.
# Returns stat_name -> {"from": x, "to": y}. Drives the confirmation UI,
# which matters because installation cannot be undone.
func _preview_mod_install(item_key: String, mod_item_key: String) -> Dictionary:
	var out: Dictionary = {}
	var mod_id = String(mod_instance_of.get(mod_item_key, ""))
	if mod_id == "" or not mod_instances.has(mod_id):
		return out

	var current = _installed_mods_for(item_key)
	var proposed = current.duplicate()
	proposed.append(mod_instances[mod_id])

	var before = CraftingService.mod_stat_deltas(current)
	var after = CraftingService.mod_stat_deltas(proposed)
	var stats = inventory_stats.get(item_key, {})
	for stat_name in after.keys():
		var delta_before = float(before.get(stat_name, 0.0))
		var delta_after = float(after.get(stat_name, 0.0))
		if is_equal_approx(delta_before, delta_after):
			continue
		var shown = float(stats.get(stat_name, 0.0))
		out[stat_name] = {"from": shown, "to": shown + (delta_after - delta_before)}
	return out


# Why a mod cannot be fitted to an item, as player-facing strings.
func _mod_install_problems(item_key: String, mod_item_key: String) -> Array:
	var instance_id = String(crafted_item_instance_of.get(item_key, ""))
	if instance_id == "" or not crafted_items.has(instance_id):
		return ["This item cannot take mods."]
	var mod_id = String(mod_instance_of.get(mod_item_key, ""))
	if mod_id == "" or not mod_instances.has(mod_id):
		return ["That is not a mod."]
	var item_class = String(crafted_item_class.get(item_key, ""))
	var weapon_range = ""
	if MELEE_WEAPON_CLASSES.has(item_class):
		weapon_range = "Melee"
	elif RANGED_WEAPON_CLASSES.has(item_class):
		weapon_range = "Ranged"
	return CraftingService.mod_install_problems(
		crafted_items[instance_id], mod_instances[mod_id], _installed_mods_for(item_key), weapon_range)


# PERMANENTLY fits a mod. The mod's inventory entry is consumed: mods
# cannot be removed once installed, so there is nothing to give back.
# Callers MUST confirm with the player first.
func _install_mod(item_key: String, mod_item_key: String) -> bool:
	var problems = _mod_install_problems(item_key, mod_item_key)
	if not problems.is_empty():
		_show_combat_message(String(problems[0]))
		return false

	var instance_id = String(crafted_item_instance_of.get(item_key, ""))
	var mod_id = String(mod_instance_of.get(mod_item_key, ""))
	var installed: Array = crafted_items[instance_id].get("installed_mod_instance_ids", [])
	installed.append(mod_id)
	crafted_items[instance_id]["installed_mod_instance_ids"] = installed

	# Consume the mod's inventory entry -- it now lives in the weapon.
	mod_instance_of.erase(mod_item_key)
	if inventory.has(mod_item_key):
		inventory[mod_item_key] -= 1
		if inventory[mod_item_key] <= 0:
			inventory.erase(mod_item_key)
	consumable_base_name.erase(mod_item_key)
	_cleanup_empty_inventory_stacks()

	# Record the owning item on the mod instance itself.
	mod_instances[mod_id]["installed_in"] = instance_id

	_apply_item_stats_with_mods(item_key)
	_update_inventory_display()

	var mod_def = CraftingData.get_mod(String(mod_instances[mod_id].get("mod_id", "")))
	_show_combat_message("Fitted " + String(mod_def.get("display_name", "mod")) + " -- permanent.")
	return true


# Creates a mod and puts it in the player's inventory as a draggable
# item. Acquisition proper (vendor / craftable / drops) is a later batch;
# this is the grant path everything will funnel through.
func _grant_mod(mod_id: String, grade_id: String = "standard") -> String:
	var mod = CraftingService.create_mod(mod_id, grade_id)
	if mod.is_empty():
		return ""
	var instance_id = String(mod.get("mod_instance_id", ""))
	mod_instances[instance_id] = mod

	var item_key = _generate_unique_resource_name()
	var mod_def = CraftingData.get_mod(mod_id)
	var grade = CraftingData.get_mod_grade(grade_id)
	consumable_base_name[item_key] = String(grade.get("display_name", grade_id)) + " " + String(mod_def.get("display_name", mod_id))
	mod_instance_of[item_key] = instance_id
	_add_to_inventory(item_key, 1)
	_update_inventory_display()
	return item_key


func _debug_grant_core_mods() -> void:
	var weapon = CraftingModels.new_crafted_item(
		CraftingService._next_id("item"), "bp_piston_blade", "Piston Blade",
		[], {"Material Potential": 100.0, "Realised Quality": 100.0},
		[], [], "masterwork", 100.0, 200.0, 12345, 0.0)
	weapon["socket_count"] = 3
	var wkey = _grant_crafted_item(weapon)
	if wkey != "":
		_show_combat_message("DEBUG: Granted Piston Blade with 3 sockets.")

	var types = ["core_thermal", "core_arc", "core_chemical", "core_pressure", "core_ballistic", "core_kinetic"]
	for mod_id in types:
		var mod = CraftingService.create_mod(mod_id, "refined")
		if mod.is_empty():
			continue
		mod["effect_strength"] = 0.7
		mod["craft_quality"] = 60.0
		var iid = String(mod.get("mod_instance_id", ""))
		mod_instances[iid] = mod
		var item_key = _generate_unique_resource_name()
		var mdef = CraftingData.get_mod(mod_id)
		var grade = CraftingData.get_mod_grade("refined")
		consumable_base_name[item_key] = String(grade.get("display_name", "Refined")) + " " + String(mdef.get("display_name", mod_id))
		mod_instance_of[item_key] = iid
		_add_to_inventory(item_key, 1)
	_update_inventory_display()
	_show_combat_message("DEBUG: Granted 6 Core mods (one per damage type).")


# ====================================================================
# MOD SOCKET UI (crafting Phase 6 -- staging, preview, confirmation)
# ====================================================================

# Rebuilds the socket row for whichever item is selected. Called after
# selection changes, after staging, and after a successful install.
func _refresh_socket_area() -> void:
	if inventory_book_socket_area == null:
		return
	for child in inventory_book_socket_area.get_children():
		child.queue_free()

	var item_key = inventory_book_selected_key
	if item_key == "":
		return
	var instance_id = String(crafted_item_instance_of.get(item_key, ""))
	if instance_id == "" or not crafted_items.has(instance_id):
		return
	var inst: Dictionary = crafted_items[instance_id]
	var socket_count = int(inst.get("socket_count", 0))
	if socket_count <= 0:
		return

	var header = Label.new()
	header.text = "Mod Sockets"
	header.modulate = Color(0.6, 0.9, 0.9)
	inventory_book_socket_area.add_child(header)

	var installed = _installed_mods_for(item_key)

	for i in range(socket_count):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(280, 34)
		var slot_script = load(MOD_SOCKET_SLOT_SCRIPT_PATH)
		if slot_script != null:
			slot.set_script(slot_script)
			slot.set("main", self)
			slot.set("socket_index", i)

		var label = Label.new()
		label.position = Vector2(8, 6)

		if i < installed.size():
			# Permanently fitted.
			var def = CraftingData.get_mod(String(installed[i].get("mod_id", "")))
			var grade = CraftingData.get_mod_grade(String(installed[i].get("grade_id", "standard")))
			label.text = String(grade.get("display_name", "")) + " " + String(def.get("display_name", "Mod"))
			label.modulate = Color(0.65, 0.85, 0.65)
			if slot_script != null:
				slot.set("accepts_drop", false)
			slot.add_theme_stylebox_override("panel", _make_flat_style(Color(0.06, 0.12, 0.08)))
		elif pending_mod_installs.has(i):
			var pend_key = String(pending_mod_installs[i])
			label.text = _get_inventory_display_name(pend_key) + "  (pending)"
			label.modulate = Color(0.95, 0.8, 0.35)
			slot.add_theme_stylebox_override("panel", _make_flat_style(Color(0.15, 0.12, 0.04)))

			var clear_btn = Button.new()
			clear_btn.text = "x"
			clear_btn.position = Vector2(246, 4)
			clear_btn.custom_minimum_size = Vector2(26, 26)
			clear_btn.focus_mode = Control.FOCUS_NONE
			clear_btn.pressed.connect(_on_clear_pending_socket.bind(i))
			slot.add_child(clear_btn)
		else:
			label.text = "Empty"
			label.modulate = Color(0.55, 0.6, 0.62)
			slot.add_theme_stylebox_override("panel", _make_flat_style(Color(0.05, 0.08, 0.09)))

		slot.add_child(label)
		inventory_book_socket_area.add_child(slot)

	if not pending_mod_installs.is_empty():
		var preview = Label.new()
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD
		preview.custom_minimum_size = Vector2(280, 0)
		preview.text = _pending_change_summary(item_key)
		preview.modulate = Color(0.9, 0.85, 0.6)
		inventory_book_socket_area.add_child(preview)

		var apply_btn = Button.new()
		apply_btn.text = "Apply mods (permanent)"
		apply_btn.custom_minimum_size = Vector2(280, 34)
		apply_btn.focus_mode = Control.FOCUS_NONE
		apply_btn.pressed.connect(_on_apply_pending_mods)
		inventory_book_socket_area.add_child(apply_btn)


# Combined before/after for everything currently staged.
func _pending_change_summary(item_key: String) -> String:
	var lines: Array = []
	var totals: Dictionary = {}
	for idx in pending_mod_installs.keys():
		var preview = _preview_mod_install(item_key, String(pending_mod_installs[idx]))
		for stat_name in preview.keys():
			var d = float(preview[stat_name]["to"]) - float(preview[stat_name]["from"])
			totals[stat_name] = float(totals.get(stat_name, 0.0)) + d
	if totals.is_empty():
		return ""
	lines.append("Change if applied:")
	var stats = inventory_stats.get(item_key, {})
	for stat_name in totals.keys():
		var base_value = float(stats.get(stat_name, 0.0))
		var sign_text = "+" if float(totals[stat_name]) >= 0.0 else ""
		lines.append("  " + stat_name + ": " + _format_number(base_value)
			+ " -> " + _format_number(base_value + float(totals[stat_name]))
			+ "  (" + sign_text + _format_number(totals[stat_name]) + ")")
	return "\n".join(lines)


# Called by mod_socket_slot.gd before accepting a drop.
func can_stage_mod_in_socket(socket_index: int, mod_item_key: String) -> bool:
	var item_key = inventory_book_selected_key
	if item_key == "" or not mod_instance_of.has(mod_item_key):
		return false
	if pending_mod_installs.has(socket_index):
		return false
	# Already staged in another socket -- one mod cannot fill two.
	for idx in pending_mod_installs.keys():
		if String(pending_mod_installs[idx]) == mod_item_key:
			return false
	return _mod_install_problems(item_key, mod_item_key).is_empty()


# Called by mod_socket_slot.gd on a successful drop. Stages only.
func stage_mod_in_socket(socket_index: int, mod_item_key: String) -> void:
	if not can_stage_mod_in_socket(socket_index, mod_item_key):
		var problems = _mod_install_problems(inventory_book_selected_key, mod_item_key)
		if not problems.is_empty():
			_show_combat_message(String(problems[0]))
		return
	pending_mod_installs[socket_index] = mod_item_key
	_refresh_socket_area()


func _on_clear_pending_socket(socket_index: int) -> void:
	pending_mod_installs.erase(socket_index)
	_refresh_socket_area()


func _on_apply_pending_mods() -> void:
	if pending_mod_installs.is_empty() or mod_confirm_dialog == null:
		return
	var names: Array = []
	for idx in pending_mod_installs.keys():
		names.append(_get_inventory_display_name(String(pending_mod_installs[idx])))
	mod_confirm_dialog.dialog_text = (
		"Fit " + ", ".join(names) + "?\n\n"
		+ "THIS CANNOT BE UNDONE. Once fitted, a mod stays in the item "
		+ "permanently and the socket can never be reused."
	)
	mod_confirm_dialog.popup_centered()


func _on_mod_install_confirmed() -> void:
	var item_key = inventory_book_selected_key
	var keys = pending_mod_installs.keys()
	keys.sort()
	for idx in keys:
		_install_mod(item_key, String(pending_mod_installs[idx]))
	pending_mod_installs.clear()
	_refresh_inventory_book()
	_select_inventory_book_item(item_key)


func _get_enemy_name(enemy_id: String) -> String:
	if enemies.has(enemy_id):
		return String(enemies[enemy_id].get("name", enemy_id))
	return String(ENEMY_SPAWN_TABLE.get(enemy_id, {}).get("display_name", enemy_id))


# Configures an enemy's TargetIndicator Line2D. Same amber border the old
# _make_target_indicator() built, but applied to the node that now ships
# with Enemy.tscn instead of being created and parented separately.
func _style_target_indicator(line: Line2D) -> void:
	var w = HEALTH_BAR_WIDTH
	var h = (HEALTH_BAR_HEIGHT * 2.0) + ACTION_BAR_GAP
	line.clear_points()
	line.add_point(Vector2(0, 0))
	line.add_point(Vector2(w, 0))
	line.add_point(Vector2(w, h))
	line.add_point(Vector2(0, h))
	line.add_point(Vector2(0, 0))
	line.width = 2.0
	line.default_color = Color(0.95, 0.75, 0.2)
	line.z_index = 1
