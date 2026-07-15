extends Node2D

# ============================================================
# Static game data (recipes, professions, abilities, weapon certs,
# elite prereqs, talent display names/rewards) now lives in
# GameData.gd, an autoload singleton (Pass 1 of splitting this file
# apart). Every reference to those tables below is prefixed with
# 'GameData.' — e.g. GameData.novice_professions, GameData.recipes.
# ============================================================

@onready var survey_ui: Control = $UILayer/SurveyUI
@onready var resource_tree: Tree = $UILayer/SurveyUI/ResourceTree
@onready var scan_result_label: Label = $UILayer/SurveyUI/ScanResultLabel
@onready var resource_stats_label: Label = $UILayer/SurveyUI/ResourceStatsLabel
@onready var sample_button: Button = $UILayer/SurveyUI/SampleButton
@onready var sample_message_label: Label = $UILayer/SurveyUI/SampleMessageLabel
@onready var cooldown_timer: Timer = $CooldownTimer
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

@onready var dummy: Node2D = %Dummy
@onready var player_health_bar_bg: Polygon2D = %PlayerHealthBarBg
@onready var player_health_bar_fill: Polygon2D = %PlayerHealthBarFill
@onready var player_action_bar_bg: Polygon2D = %PlayerActionBarBg
@onready var player_action_bar_fill: Polygon2D = %PlayerActionBarFill
@onready var dummy_health_bar_bg: Polygon2D = %DummyHealthBarBg
@onready var dummy_health_bar_fill: Polygon2D = %DummyHealthBarFill
@onready var dummy_action_bar_bg: Polygon2D = %DummyActionBarBg
@onready var dummy_action_bar_fill: Polygon2D = %DummyActionBarFill
@onready var dummy_name_label: Label = %DummyNameLabel

@onready var enemy2: Node2D = %Enemy2
@onready var enemy2_health_bar_bg: Polygon2D = %Enemy2HealthBarBg
@onready var enemy2_health_bar_fill: Polygon2D = %Enemy2HealthBarFill
@onready var enemy2_action_bar_bg: Polygon2D = %Enemy2ActionBarBg
@onready var enemy2_action_bar_fill: Polygon2D = %Enemy2ActionBarFill
@onready var enemy2_name_label: Label = %Enemy2NameLabel
@onready var enemy2_attack_cooldown_timer: Timer = $Enemy2AttackCooldownTimer
@onready var enemy2_respawn_timer: Timer = $Enemy2RespawnTimer

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
@onready var dumpster: Node2D = %Dumpster
@onready var dumpster_visual: Polygon2D = %DumpsterVisual
@onready var dumpster_cooldown_timer: Timer = $DumpsterCooldownTimer
@onready var bandage_cooldown_timer: Timer = $BandageCooldownTimer
@onready var resource_shift_timer: Timer = $ResourceShiftTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var dummy_attack_cooldown_timer: Timer = $DummyAttackCooldownTimer
@onready var player_respawn_timer: Timer = $PlayerRespawnTimer
@onready var player_regen_timer: Timer = $PlayerRegenTimer
@onready var player_action_regen_timer: Timer = $PlayerActionRegenTimer
@onready var dummy_respawn_timer: Timer = $DummyRespawnTimer
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
@onready var recipe_tree: Tree = $UILayer/CraftingUI/RecipeTree
@onready var recipe_info_label: Label = $UILayer/CraftingUI/RecipeInfoLabel
@onready var enhancement_slot_label: Label = $UILayer/CraftingUI/EnhancementSlotLabel
@onready var craft_button: Button = $UILayer/CraftingUI/CraftButton
@onready var craft_result_label: Label = $UILayer/CraftingUI/CraftResultLabel

var resource_classes = {
	"Metal": ["Black Iron", "Copper", "Tin", "Silver", "Gold", "Titanium", "Aluminum", "Gunmetal Steel", "Brass", "Rust"],
	"Mineral": ["Quartz", "Limestone", "Granite", "Diamond", "Obsidian", "Amethyst", "Sapphire", "Ruby", "Emerald", "Concrete", "Pressure Glass"],
	"Flora - Fungal": ["Mushrooms", "Moss", "Lichen", "Bioluminescent Fungus"],
	"Flora - Wood": ["Weathered Wood"],
	"Water": ["Spring Water", "River Water"],
	"Gas": ["Natural Gas", "Methane"],
	"Oil": ["Crude Oil", "Kerosene"]
}

var resource_types = {
	"Copper": ["Cuprite", "Azurite", "Dioptase", "Dornite"]
}

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

var all_possible_resources = []

var gem_gated_subclasses = ["Amethyst", "Diamond", "Sapphire", "Ruby", "Emerald"]

func _get_scrap_tinkerer_rank_count(base_name: String) -> int:
	var total = 0
	for suffix in [" I", " II", " III", " IV"]:
		var path_name = base_name + suffix
		if GameData.novice_professions["Scrap Tinkerer"]["paths"].has(path_name):
			total += GameData.novice_professions["Scrap Tinkerer"]["paths"][path_name]["unlocked_nodes"]
	return total

# --- Apothecary rank/stat helpers ---
# Every bonus here is derived live from unlocked_nodes rather than cached,
# so there's nothing to keep in sync when a node gets trained.
func _get_apothecary_rank_unlocked(path_name: String) -> bool:
	var path_data = GameData.novice_professions["Apothecary"]["paths"].get(path_name, null)
	if path_data == null:
		return false
	return path_data["unlocked_nodes"] >= path_data.get("max_nodes", NODES_PER_PATH)

func _get_healing_speed_bonus() -> int:
	return 2 if _get_apothecary_rank_unlocked("Healing I") else 0

func _get_healing_knowledge_bonus() -> int:
	return 2 if _get_apothecary_rank_unlocked("Healing I") else 0

# Wound Care stacks across ranks II-IV: +4 at II, +4 more at III, +2 more at IV.
func _get_wound_care_bonus() -> int:
	var bonus = 0
	if _get_apothecary_rank_unlocked("Healing II"):
		bonus += 4
	if _get_apothecary_rank_unlocked("Healing III"):
		bonus += 4
	if _get_apothecary_rank_unlocked("Healing IV"):
		bonus += 2
	return bonus

# Medicinal Knowledge stacks across ranks I-III (+4 each); Rank IV
# grants Medicine Potency instead, plus unlocks new recipes later.
func _get_medicinal_knowledge_bonus() -> int:
	var bonus = 0
	if _get_apothecary_rank_unlocked("Medicine Crafting I"):
		bonus += 4
	if _get_apothecary_rank_unlocked("Medicine Crafting II"):
		bonus += 4
	if _get_apothecary_rank_unlocked("Medicine Crafting III"):
		bonus += 4
	return bonus

func _get_medicine_potency_bonus() -> int:
	return 2 if _get_apothecary_rank_unlocked("Medicine Crafting IV") else 0

# Foraging Chance stacks +1 per rank, I through IV (max +4).
func _get_foraging_chance_bonus() -> int:
	var bonus = 0
	for rank_name in ["Medical Foraging I", "Medical Foraging II", "Medical Foraging III", "Medical Foraging IV"]:
		if _get_apothecary_rank_unlocked(rank_name):
			bonus += 1
	return bonus

func _has_bandages_for_salve() -> bool:
	for instance_name in inventory.keys():
		if consumable_base_name.get(instance_name, "") == "Crate of Bandages" and inventory[instance_name] > 0:
			return true
	return false

# Consumes one charge off the first available Crate of Bandages stack —
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

func _is_gem_scanning_unlocked() -> bool:
	return _get_scrap_tinkerer_rank_count("Scanning") >= 3
var resource_class_lookup: Dictionary = {}

var tool_class_access = {
	"Mineral Survey Tool": ["Metal", "Mineral"],
	"Flora Tool": ["Flora - Fungal", "Flora - Wood"],
	"Steam and Oil Sniffer": ["Oil", "Gas", "Water"]
}

var active_survey_tool: String = ""

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

var active_resources = []
var resource_subclass_of: Dictionary = {}
var resource_type_of: Dictionary = {}

var resource_pools: Dictionary = {}
var resource_stats: Dictionary = {}
var resource_hotspots: Dictionary = {}
# Each resource's hotspot cluster is centered on a fixed world position,
# tracked here separately from the player. This is what actually moves
# on a "shift" — NOT the player's current position — so a shift really
# does relocate where the good spots are, rather than just re-rolling
# hotspots around wherever you happen to be standing (which would make
# the shift statistically meaningless, since your scan reading is
# always measured from your own position).
var resource_hotspot_centers: Dictionary = {}
const MAX_CONCENTRATION_RANGE = 2500.0
const HOTSPOT_SPAWN_RADIUS = 2000.0
# Each resource now gets multiple hotspots scattered around, so you're
# not stuck chasing one single point across a large map — whichever
# hotspot is nearest to you determines your scan reading.
const HOTSPOTS_PER_RESOURCE = 4
const RESOURCE_SHIFT_INTERVAL = 600.0
# How far a resource's hotspot cluster can drift from its previous
# center on each shift — deliberately larger than HOTSPOT_SPAWN_RADIUS
# so the whole cluster meaningfully relocates, not just jitters in
# place.
const RESOURCE_SHIFT_DRIFT_RADIUS = 3000.0

var current_scan_resource: String = ""
var current_scan_concentration: int = 0

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

var weapon_stat_names = ["Speed", "Damage Type", "Damage Rating", "Damage Per Second", "Wound Type"]


var enhancement_definitions = {
	"Overcharged Coil": {"Damage Rating Bonus": 8, "Range Bonus": 5}
}

var crafted_item_class: Dictionary = {}
var crafted_item_subclass: Dictionary = {}
var consumable_base_name: Dictionary = {}

# --- Combat ---
var equipped_weapon_name: String = ""
const MELEE_RANGE = 180.0
# Hit-chance formula constants — our own numbers/scale, not copied
# from any external source. See _perform_attack() for the formula.
const BASE_HIT_CHANCE = 50.0
const MIN_HIT_CHANCE = 10.0
const MAX_HIT_CHANCE = 95.0
# Tuned so a brand-new, untrained character (Quality-0 Piston Blade,
# 55 Accuracy, no trained Accuracy bonuses) lands at ~85% hit chance
# against the training Dummy — solidly likely to land a hit, with just
# a small chance to whiff, since it's meant to feel like a low-stakes
# practice target rather than a real fight. Other starting weapons
# (Pressure Scattergun, Pneumatic Rifle) have their own Accuracy
# ranges, so they'll land close to but not necessarily exactly 85% —
# that variance across weapon types is expected, not a bug.
const DUMMY_DEFENSE = -2.0
const ENEMY2_DEFENSE = 16.0
# Light Action cost for the basic Attack — like walking burning a few
# calories, not meant to be draining. Tune this one number to adjust.
const BASIC_ATTACK_ACTION_COST = 20
# Basic Attack's real Action cost now scales with the equipped
# weapon's Speed stat instead of using this flat value — fast/light
# weapons (knuckles, stun sticks) cost less Action per swing, slow/
# heavy weapons (hammers, greatblades) cost more. This constant is
# now only the fallback when no weapon Speed stat is available.
func _get_dynamic_attack_action_cost() -> int:
	var weapon_stats = inventory_stats.get(equipped_weapon_name, {})
	if not weapon_stats.has("Speed"):
		return BASIC_ATTACK_ACTION_COST
	var speed = weapon_stats["Speed"]
	return max(5, int(round(speed * 10.0)))

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
# guessed position — the ActionBar is centered horizontally near the
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

var dummy_attack_ready: bool = true
const DUMMY_ATTACK_MIN_DAMAGE = 15
const DUMMY_ATTACK_MAX_DAMAGE = 40
const DUMMY_ATTACK_COOLDOWN = 2.5
const ENEMY_ATTACK_RANGE = 180.0


var dummy_name: String = "Scrap Thief"
var dummy_difficulty: int = 5
var dummy_max_health: int = 50
var dummy_max_action: int = 50
var dummy_current_action: int = 50
var dummy_current_health: int = 50
var dummy_alive: bool = true
# Subdue (damage debuff) is fully functional — reduces this enemy's
# outgoing damage while active. Disorient (accuracy debuff) is tracked
# here too but has no live effect yet, since there's no hit/miss combat
# system for reduced accuracy to act on.
var dummy_damage_debuff: float = 0.0
var dummy_accuracy_debuff: float = 0.0
# Bruise (attack-speed debuff) — slows this enemy's own attack cadence
# while active. Applied as a multiplier on the enemy's attack cooldown.
var dummy_attack_speed_debuff: float = 0.0
# Bleed (damage-over-time) — ticks once per second alongside player
# regen (see _on_player_regen_tick), dealing dot_damage_per_tick each
# tick for dot_duration_ticks seconds.
var dummy_bleed_ticks_remaining: int = 0
var dummy_bleed_damage_per_tick: int = 0
# Anger (taunt) — tracks that this enemy has been provoked into
# targeting the player. Right now the player is the only possible
# target, so this has no visible effect yet; it's scaffolding for
# when co-op/companion targets exist and taunt needs to redirect
# an enemy away from them and onto the player.
var dummy_taunted_until_msec: int = 0
# Tracks cumulative damage dealt to this enemy broken down by weapon
# class used, across the whole fight — reset on respawn and after
# granting kill XP. Lets kill XP be split proportionally across every
# weapon type actually used, instead of all going to whatever's
# equipped at the moment of the killing blow.
var dummy_damage_by_weapon_class: Dictionary = {}

var enemy2_name: String = "Rust Marauder"
var enemy2_difficulty: int = 8
var enemy2_max_health: int = 80
var enemy2_current_health: int = 80
var enemy2_alive: bool = true
var enemy2_max_action: int = 80
var enemy2_current_action: int = 80
var enemy2_attack_ready: bool = true
var enemy2_damage_debuff: float = 0.0
var enemy2_accuracy_debuff: float = 0.0
var enemy2_attack_speed_debuff: float = 0.0
var enemy2_bleed_ticks_remaining: int = 0
var enemy2_bleed_damage_per_tick: int = 0
var enemy2_taunted_until_msec: int = 0
var enemy2_damage_by_weapon_class: Dictionary = {}
const ENEMY2_ATTACK_MIN_DAMAGE = 24
const ENEMY2_ATTACK_MAX_DAMAGE = 64
const ENEMY2_ATTACK_COOLDOWN = 2.5
const ENEMY2_KILL_XP = 67

const COGS_MIN_DROP = 1
const COGS_MAX_DROP = 5

# --- Trainer ---
const TRAINER_INTERACT_RANGE = 150.0
var trainers: Array = []
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
# Fixed, non-moving scavenge point — the only scavenge point in the
# game right now (the earlier test herb patch has been removed).
var dumpster_available: bool = true
const DUMPSTER_RANGE = 150.0
const DUMPSTER_RESPAWN_TIME = 45.0
const DUMPSTER_COGS_MIN = 2
const DUMPSTER_COGS_MAX = 2

# --- Crate of Bandages / Medicine Usage ---
const BANDAGE_HEAL_AMOUNT = 100
const BANDAGE_HEALING_XP = 15
const BANDAGE_COOLDOWN = 6.0
const BANDAGE_ACTION_COST = 50
var bandage_ready: bool = true
var attack_ready: bool = true
var combat: Node

# --- Healing abilities (IV Drip, Healing Vapor) ---
# Duration assumptions (not specified by design yet — flagged for review):
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

# --- Stims (Adrenaline Boost only — II/III/IV intentionally not built yet) ---
# Temporarily raises max Action (not a heal) — e.g. 850 max + a 50
# bonus = 900 max, with current Action rising by the same amount so
# the new headroom is immediately usable. Bonus scales with the
# consumed Adrenaline Shot's Quality (30 at Quality 0, up to 100 at
# Quality 1000). Lasts 10 minutes, then reverts automatically. Cooldown
# matches the duration, so a new Boost can't be applied — and therefore
# can't stack — until the current one has fully worn off.
const ADRENALINE_BOOST_MIN_ACTION = 30
const ADRENALINE_BOOST_MAX_ACTION = 100
const ADRENALINE_BOOST_DURATION_SEC = 600.0
const ADRENALINE_BOOST_COOLDOWN_SEC = 600.0
var adrenaline_boost_bonus_amount: int = 0
var adrenaline_boost_expires_at_unix: float = 0.0
var adrenaline_boost_ready_at_unix: float = 0.0

# Blood Bag (Stims III) — same structure as Adrenaline Boost, but
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
	"Martial XP": 0,
	"Ranged Weapon": 0,
	"Rifle XP": 0,
	"Shotgun XP": 0,
	"Pistol XP": 0,
	# Heavy Weapons XP no longer maps to a live talent column — Chrome
	# Gunner's old Heavy Weapons tree was renamed to Pistols (which has
	# its own fresh XP type above). Grenade Launcher/Flame Thrower kills
	# still earn this XP (see GameData.heavy_weapon_types below), but it's
	# unspendable until a home for it exists again (Ordinance Specialist
	# is the likely candidate once it's fleshed out).
	"Heavy Weapons XP": 0,
	"Scanning": 0,
	"Sampling": 0,
	"Crafting": 0,
	"Fabrication": 0,
	"One Hand XP": 0,
	"Two Hand XP": 0,
	"Unarmed XP": 0,
	"Healing XP": 0,
	"Medicine Crafting XP": 0,
	"Scavenging XP": 0,
	"Pressure Enforcer Mastery XP": 0,
	"Chrome Gunner Mastery XP": 0,
	"Scrap Tinkerer Mastery XP": 0,
	"Apothecary Mastery XP": 0,
	# --- Elite Professions (placeholder skill trees) ---
	"Optics XP": 0,
	"Concealment XP": 0,
	"Longshot XP": 0,
	"Sniper Training XP": 0,
	"Sniper Mastery XP": 0,
	"Explosives XP": 0,
	"Incendiaries XP": 0,
	"Deployment XP": 0,
	"Ordnance Training XP": 0,
	"Ordnance Specialist Mastery XP": 0,
	"Trigger Discipline XP": 0,
	"Dual Wielding XP": 0,
	"Fast Draw XP": 0,
	"Quickdraw Training XP": 0,
	"Quickdraw Technician Mastery XP": 0,
	"Toxins XP": 0,
	"Compounds XP": 0,
	"Delivery Systems XP": 0,
	"Toxinsmith Training XP": 0,
	"Toxinsmith Mastery XP": 0
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
	"Dumpster": {
		"Common": [{"item": "Torn Cloth", "min_amount": 1, "max_amount": 3}],
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
# "being good at crafting" — crafting is too central to the game to be
# gated behind the same currency as fighting. Toxinsmith is a judgment
# call (it needs both Master Apothecary AND Chrome Gunner Shotguns IV)
# — filed under Engineer since Apothecary is its thematic home; revisit
# if that feels wrong once it's actually designed.
const MILITANT_PROFESSIONS: Array = ["Pressure Enforcer", "Chrome Gunner", "Sniper", "Ordnance Specialist", "Quickdraw Technician"]
const ENGINEER_PROFESSIONS: Array = ["Scrap Tinkerer", "Apothecary", "Toxinsmith"]

var militant_points_available: int = 100
var engineer_points_available: int = 100
var cogs: int = 0

func _is_militant_profession(profession_name: String) -> bool:
	return MILITANT_PROFESSIONS.has(profession_name)

func _points_pool_label(profession_name: String) -> String:
	return "Militant Points" if _is_militant_profession(profession_name) else "Engineer Points"

func _get_points_available(profession_name: String) -> int:
	return militant_points_available if _is_militant_profession(profession_name) else engineer_points_available

func _spend_points(profession_name: String, amount: int) -> void:
	if _is_militant_profession(profession_name):
		militant_points_available -= amount
	else:
		engineer_points_available -= amount

var professions_unlocked: Dictionary = {
	"Pressure Enforcer": false,
	"Chrome Gunner": false,
	"Scrap Tinkerer": false,
	"Apothecary": false
}
var has_chosen_starting_profession: bool = false
const PROFESSION_ENTRY_COST = 5
const ADDITIONAL_PROFESSION_COGS_COST = 1
const NODES_PER_PATH = 4
const MARTIAL_XP_RATE = 0.25
const DUMMY_KILL_XP = 50

var selected_profession: String = ""
var selected_path: String = ""

var selected_recipe_index: int = -1

func _ready() -> void:
	if resource_hotspot_centers == null:
		resource_hotspot_centers = {}

	combat = preload("res://scenes/Combat.gd").new()
	combat.main = self
	add_child(combat)

	# Force the real target resolution at runtime. This is a stopgap —
	# ideally also update Project Settings > Display > Window >
	# Viewport Width/Height to 1920x1080 directly in the editor so the
	# project's own default matches this everywhere, not just here.
	get_window().size = Vector2i(1920, 1080)
	get_window().move_to_center()

	for class_name_key in resource_classes.keys():
		for subclass_name in resource_classes[class_name_key]:
			all_possible_resources.append(subclass_name)
			resource_class_lookup[subclass_name] = class_name_key
			if not resource_types.has(subclass_name):
				resource_types[subclass_name] = [subclass_name]

	for class_name_key in resource_classes.keys():
		for subclass_name in resource_classes[class_name_key]:
			_spawn_resource_instance(subclass_name)

	_refresh_resource_tree()

	resource_tree.item_selected.connect(_on_tree_item_selected)
	resource_tree.focus_mode = Control.FOCUS_NONE
	sample_button.pressed.connect(_on_sample_pressed)
	cooldown_timer.timeout.connect(_on_cooldown_finished)

	_update_inventory_display()
	inventory_label.visible = false
	inventory_ui.visible = false
	_update_cogs_display()

	_grant_starting_bandages()

	_refresh_recipe_tree()

	recipe_tree.item_selected.connect(_on_recipe_tree_item_selected)
	recipe_tree.focus_mode = Control.FOCUS_NONE
	craft_button.pressed.connect(_on_craft_pressed)
	craft_button.focus_mode = Control.FOCUS_NONE

	attack_cooldown_timer.timeout.connect(combat._on_attack_cooldown_finished)
	dummy_attack_cooldown_timer.timeout.connect(_on_dummy_attack_cooldown_finished)
	player_respawn_timer.timeout.connect(_on_player_respawn)
	player_regen_timer.timeout.connect(_on_player_regen_tick)
	player_regen_timer.start()
	player_action_regen_timer.timeout.connect(_on_player_action_regen_tick)
	player_action_regen_timer.start()

	player_spawn_position = player.position
	dummy_respawn_timer.timeout.connect(combat._on_dummy_respawn)
	enemy2_attack_cooldown_timer.timeout.connect(_on_enemy2_attack_cooldown_finished)
	enemy2_respawn_timer.timeout.connect(combat._on_enemy2_respawn)
	dumpster_cooldown_timer.timeout.connect(_on_dumpster_cooldown_finished)
	bandage_cooldown_timer.timeout.connect(_on_bandage_cooldown_finished)
	resource_shift_timer.timeout.connect(_on_resource_shift_timer_timeout)
	resource_shift_timer.wait_time = RESOURCE_SHIFT_INTERVAL
	resource_shift_timer.start()

	# Dumpster placeholder visual — a plain brownish rectangle until real
	# art exists. Deliberately does NOT move on respawn, unlike the herb
	# patch, since this is meant to be a fixed, static scavenge point.
	dumpster_visual.color = Color(0.45, 0.35, 0.25)
	dumpster_visual.polygon = PackedVector2Array([
		Vector2(-25, -20), Vector2(25, -20), Vector2(25, 20), Vector2(-25, 20)
	])

	var trainer_gold = Color(1.0, 0.85, 0.3)

	trainers = [
		{"node": trainer, "sprite": trainer_sprite, "name_label": trainer_name_label, "name": "Foreman Brassguard", "profession": "Pressure Enforcer"},
		{"node": trainer2, "sprite": trainer2_sprite, "name_label": trainer2_name_label, "name": "Sergeant Chromewell", "profession": "Chrome Gunner"},
		{"node": trainer3, "sprite": trainer3_sprite, "name_label": trainer3_name_label, "name": "Tinker Wrenfield", "profession": "Scrap Tinkerer"},
		{"node": trainer4, "sprite": trainer4_sprite, "name_label": trainer4_name_label, "name": "Doctor Vellum", "profession": "Apothecary"}
	]

	for t in trainers:
		t["sprite"].modulate = trainer_gold
		t["name_label"].text = t["name"]
		t["name_label"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t["name_label"].custom_minimum_size = Vector2(NAME_LABEL_WIDTH, 0)
		t["name_label"].modulate = trainer_gold

	message_clear_timer.timeout.connect(_on_message_clear_timer_timeout)
	xp_gain_clear_timer.timeout.connect(_on_xp_gain_clear_timer_timeout)

	skill_tree.item_selected.connect(_on_skill_tree_item_selected)
	skill_tree.focus_mode = Control.FOCUS_NONE
	spend_point_button.pressed.connect(_on_spend_point_pressed)
	spend_point_button.focus_mode = Control.FOCUS_NONE
	spend_point_button.visible = false
	_refresh_skill_tree_ui()

	# Trainer Dialogue now lives in TrainerDialogue.gd, attached directly
	# to the TrainerUI scene node (see that file for details). It
	# configures its own layout/label setup in its own _ready(); this
	# just hands it the main reference it needs for shared state.
	trainer_ui.main = self

	for profession_name in GameData.novice_professions.keys():
		if GameData.ELITE_PROFESSION_PREREQS.has(profession_name):
			continue
		profession_options_list.add_item(profession_name)
	profession_options_list.focus_mode = Control.FOCUS_NONE
	choose_profession_button.pressed.connect(_on_choose_profession_pressed)
	choose_profession_button.focus_mode = Control.FOCUS_NONE

	profession_select_ui.visible = not has_chosen_starting_profession

	survey_ui.visible = false
	crafting_ui.visible = false
	skill_ui.visible = false

	_setup_health_bars()
	call_deferred("_layout_hud")
	var hud_layout_retry_timer = get_tree().create_timer(0.2)
	hud_layout_retry_timer.timeout.connect(_layout_hud)
	call_deferred("_setup_enemy_combat_message_label")
	_build_talent_ui()
	_build_ability_book_ui()
	_build_inventory_book_ui()
	_build_crafting_book_ui()
	_build_crafting_result_ui()
	_build_survey_book_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_viewport().gui_release_focus()

	if event.is_action_pressed("equip_menu"):
		inventory_book_ui.visible = not inventory_book_ui.visible
		if inventory_book_ui.visible:
			_refresh_inventory_book()

	if event.is_action_pressed("inventory_menu"):
		inventory_book_ui.visible = not inventory_book_ui.visible
		if inventory_book_ui.visible:
			_refresh_inventory_book()

	if event.is_action_pressed("forage"):
		_attempt_forage()

	if event.is_action_pressed("interact"):
		_attempt_talk_to_trainer()

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
		if talent_ui.visible:
			var default_profession = talent_ui.current_talent_profession
			if default_profession == "":
				default_profession = GameData.novice_professions.keys()[0]
			talent_ui._refresh_talent_grid(default_profession)

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

func _generate_hotspot_set(base_position: Vector2) -> Array:
	var hotspots: Array = []
	for i in range(HOTSPOTS_PER_RESOURCE):
		hotspots.append(base_position + Vector2(
			randf_range(-HOTSPOT_SPAWN_RADIUS, HOTSPOT_SPAWN_RADIUS),
			randf_range(-HOTSPOT_SPAWN_RADIUS, HOTSPOT_SPAWN_RADIUS)
		))
	return hotspots

func _get_nearest_hotspot_distance(instance_name: String) -> float:
	var nearest_distance = INF
	for hotspot in resource_hotspots[instance_name]:
		var d = player.global_position.distance_to(hotspot)
		if d < nearest_distance:
			nearest_distance = d
	return nearest_distance

func _spawn_resource_instance(subclass_name: String) -> String:
	var instance_name = _generate_unique_resource_name()

	resource_subclass_of[instance_name] = subclass_name

	var types_for_subclass = resource_types[subclass_name]
	var chosen_type = types_for_subclass[randi_range(0, types_for_subclass.size() - 1)]
	resource_type_of[instance_name] = chosen_type

	active_resources.append(instance_name)
	resource_pools[instance_name] = randi_range(50, 150)

	var class_name_for_resource = resource_class_lookup[subclass_name]
	var stat_names = resource_stat_definitions[class_name_for_resource]
	var rolled_stats: Dictionary = {}

	for stat_name in stat_names:
		var min_val = 1
		var max_val = 1000

		if resource_stat_ranges.has(subclass_name) and resource_stat_ranges[subclass_name].has(stat_name):
			var override_range = resource_stat_ranges[subclass_name][stat_name]
			min_val = override_range[0]
			max_val = override_range[1]

		rolled_stats[stat_name] = randi_range(min_val, max_val)

	resource_stats[instance_name] = rolled_stats

	resource_hotspot_centers[instance_name] = player.global_position
	resource_hotspots[instance_name] = _generate_hotspot_set(resource_hotspot_centers[instance_name])

	return instance_name

func _on_resource_shift_timer_timeout() -> void:
	if resource_hotspot_centers == null:
		resource_hotspot_centers = {}
	for instance_name in resource_hotspots.keys():
		var previous_center = resource_hotspot_centers.get(instance_name, player.global_position)
		var new_center = previous_center + Vector2(
			randf_range(-RESOURCE_SHIFT_DRIFT_RADIUS, RESOURCE_SHIFT_DRIFT_RADIUS),
			randf_range(-RESOURCE_SHIFT_DRIFT_RADIUS, RESOURCE_SHIFT_DRIFT_RADIUS)
		)
		resource_hotspot_centers[instance_name] = new_center
		resource_hotspots[instance_name] = _generate_hotspot_set(new_center)
	_show_combat_message("Resource concentrations have shifted.")

func _get_resource_display_label(instance_name: String) -> String:
	var subclass_name = resource_subclass_of[instance_name]
	var type_name = resource_type_of[instance_name]

	if type_name == subclass_name:
		return instance_name + " (" + subclass_name + ")"
	else:
		return instance_name + " (" + type_name + " - " + subclass_name + ")"

func _on_tree_item_selected() -> void:
	var selected = resource_tree.get_selected()
	if selected == null:
		return

	var instance_name = selected.get_metadata(0)
	if instance_name == null:
		return

	if not resource_hotspots.has(instance_name):
		resource_hotspot_centers[instance_name] = player.global_position
		resource_hotspots[instance_name] = _generate_hotspot_set(resource_hotspot_centers[instance_name])

	var distance = _get_nearest_hotspot_distance(instance_name)
	var proximity = 1.0 - clamp(distance / MAX_CONCENTRATION_RANGE, 0.0, 1.0)
	var concentration = int(round(100 * proximity))
	concentration = max(concentration, 1)

	var scanning_nodes = _get_scrap_tinkerer_rank_count("Scanning")
	var mastery_nodes = _get_scrap_tinkerer_rank_count("Fabrication Mastery")
	concentration += (scanning_nodes * 5) + (mastery_nodes * 2)
	concentration = min(concentration, 100)

	current_scan_resource = instance_name
	current_scan_concentration = concentration

	_add_skill_xp("Scanning", 5)

	scan_result_label.text = _get_resource_display_label(instance_name) + ": " + str(concentration) + "% concentration"

	var stats_text = ""
	var stats = resource_stats[instance_name]
	for stat_name in stats.keys():
		stats_text += stat_name + ": " + _format_number(stats[stat_name]) + "   "
	resource_stats_label.text = stats_text

func _on_sample_pressed() -> void:
	if current_scan_resource == "":
		sample_message_label.text = "Scan a resource first!"
		survey_book_ui.survey_book_message_label.text = "Scan a resource first!"
		return

	if not cooldown_timer.is_stopped():
		return

	var desired_amount = _get_yield_for_concentration(current_scan_concentration)
	var remaining = resource_pools[current_scan_resource]
	var actual_amount = min(desired_amount, remaining)

	var type_name = resource_type_of[current_scan_resource]
	var sample_message = "You have sampled " + str(actual_amount) + " " + type_name + "!"
	sample_message_label.text = sample_message
	survey_book_ui.survey_book_message_label.text = sample_message

	_add_to_inventory_with_instance(current_scan_resource, actual_amount)
	_update_inventory_display()

	_add_skill_xp("Sampling", 10)

	resource_pools[current_scan_resource] -= actual_amount

	if resource_pools[current_scan_resource] <= 0:
		_deplete_and_replace(current_scan_resource)

	const SAMPLE_BASE_COOLDOWN = 20.0
	var sampling_nodes = _get_scrap_tinkerer_rank_count("Sampling")
	var mastery_nodes_cd = _get_scrap_tinkerer_rank_count("Fabrication Mastery")
	var cooldown_reduction = (sampling_nodes * 0.10) + (mastery_nodes_cd * 0.05)
	cooldown_reduction = min(cooldown_reduction, 0.9)
	cooldown_timer.wait_time = SAMPLE_BASE_COOLDOWN * (1.0 - cooldown_reduction)

	cooldown_timer.start()
	sample_button.disabled = true
	survey_book_ui.survey_book_sample_button.disabled = true

func _on_cooldown_finished() -> void:
	sample_button.disabled = false
	survey_book_ui.survey_book_sample_button.disabled = false

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

func _get_leaf_label(instance_name: String) -> String:
	if not resource_subclass_of.has(instance_name):
		return instance_name

	var subclass_name = resource_subclass_of[instance_name]
	var type_name = resource_type_of[instance_name]

	if type_name == subclass_name:
		return instance_name
	else:
		return type_name + " - " + instance_name

func _refresh_resource_tree() -> void:
	resource_tree.clear()
	var root = resource_tree.create_item()
	resource_tree.hide_root = true

	var tree_data: Dictionary = {}

	for instance_name in active_resources:
		var subclass_name = resource_subclass_of[instance_name]
		var class_name_for_resource = resource_class_lookup[subclass_name]

		if not tree_data.has(class_name_for_resource):
			tree_data[class_name_for_resource] = {}
		if not tree_data[class_name_for_resource].has(subclass_name):
			tree_data[class_name_for_resource][subclass_name] = []

		tree_data[class_name_for_resource][subclass_name].append(instance_name)

	var unlocked_classes = []
	if active_survey_tool != "" and tool_class_access.has(active_survey_tool):
		unlocked_classes = tool_class_access[active_survey_tool]
	else:
		unlocked_classes = _get_unlocked_classes()
	var class_names_sorted = []
	for class_name_key in tree_data.keys():
		if unlocked_classes.has(class_name_key):
			class_names_sorted.append(class_name_key)
	class_names_sorted.sort()

	for class_name_key in class_names_sorted:
		var category_item = resource_tree.create_item(root)
		category_item.set_text(0, class_name_key)
		category_item.set_selectable(0, false)

		var subclass_names_sorted = tree_data[class_name_key].keys()
		subclass_names_sorted.sort()

		for subclass_name in subclass_names_sorted:
			if gem_gated_subclasses.has(subclass_name) and not _is_gem_scanning_unlocked():
				continue

			var subclass_item = resource_tree.create_item(category_item)
			subclass_item.set_text(0, subclass_name)
			subclass_item.set_selectable(0, false)

			var instances = tree_data[class_name_key][subclass_name]

			instances.sort_custom(func(a, b): return resource_type_of[a] < resource_type_of[b])

			for instance_name in instances:
				var leaf_item = resource_tree.create_item(subclass_item)
				leaf_item.set_text(0, _get_leaf_label(instance_name))
				leaf_item.set_metadata(0, instance_name)

func _deplete_and_replace(depleted_instance_name: String) -> void:
	var depleted_subclass = resource_subclass_of[depleted_instance_name]
	var depleted_label = _get_resource_display_label(depleted_instance_name)

	active_resources.erase(depleted_instance_name)
	resource_pools.erase(depleted_instance_name)
	resource_stats.erase(depleted_instance_name)
	resource_hotspots.erase(depleted_instance_name)

	var new_instance_name = _spawn_resource_instance(depleted_subclass)
	var new_label = _get_resource_display_label(new_instance_name)

	var message = depleted_label + " has been depleted! " + new_label + " has appeared!"

	_refresh_resource_tree()

	current_scan_resource = ""
	current_scan_concentration = 0
	scan_result_label.text = message

func _get_recipe_category(recipe: Dictionary) -> String:
	if recipe.has("item_class"):
		if recipe["item_class"] == "Component":
			return "Components"
		elif recipe["item_class"] == "Medicine":
			return "Medicine"
		elif recipe["item_class"] == "Tool":
			return "Tools"
		else:
			return "Weapons"
	return "General"

func _refresh_recipe_tree() -> void:
	recipe_tree.clear()
	var root = recipe_tree.create_item()
	recipe_tree.hide_root = true

	var categories: Dictionary = {}
	for i in range(GameData.recipes.size()):
		var category = _get_recipe_category(GameData.recipes[i])
		if not categories.has(category):
			categories[category] = []
		categories[category].append(i)

	var category_order = ["Weapons", "Tools", "Components", "Medicine", "General"]

	for category_name in category_order:
		if not categories.has(category_name):
			continue

		var category_item = recipe_tree.create_item(root)
		category_item.set_text(0, category_name)
		category_item.set_selectable(0, false)

		for recipe_index in categories[category_name]:
			var leaf_item = recipe_tree.create_item(category_item)
			leaf_item.set_text(0, GameData.recipes[recipe_index]["name"])
			leaf_item.set_metadata(0, recipe_index)

func _on_recipe_tree_item_selected() -> void:
	var selected = recipe_tree.get_selected()
	if selected == null:
		return

	var recipe_index = selected.get_metadata(0)
	if recipe_index == null:
		return

	selected_recipe_index = recipe_index
	var recipe = GameData.recipes[recipe_index]

	var info_text = ""

	if recipe.has("item_class") and recipe.has("item_subclass"):
		info_text += recipe["item_class"] + " (" + recipe["item_subclass"] + ")\n"

	info_text += "\n"

	if recipe.has("slot_names"):
		info_text += "Ingredients\n"
		for requirement_key in recipe["requires"].keys():
			var needed = recipe["requires"][requirement_key]
			var slot_label = recipe["slot_names"].get(requirement_key, requirement_key)
			info_text += slot_label + "\n"
			info_text += "    Requires " + str(needed) + " " + requirement_key + "\n"
	else:
		var requirements_text = ""
		for requirement_key in recipe["requires"].keys():
			var needed = recipe["requires"][requirement_key]
			requirements_text += requirement_key + ": " + str(needed) + "  "
		info_text += "Requires: " + requirements_text

	recipe_info_label.text = info_text

func _matches_requirement(instance_name: String, requirement_key: String) -> bool:
	if resource_type_of.get(instance_name, "") == requirement_key:
		return true
	if resource_subclass_of.get(instance_name, "") == requirement_key:
		return true
	# Crafted items (Syringe, Adrenaline Shot, Empty IV Bag, weapons, etc.)
	# each get their own randomly-generated instance_name, so a recipe
	# requiring one by its output name has to check consumable_base_name
	# rather than the instance_name itself.
	if consumable_base_name.get(instance_name, "") == requirement_key:
		return true
	if instance_name == requirement_key:
		return true
	# Class-level match: a recipe can require an entire resource class
	# (e.g. "Metal") instead of one specific subclass — satisfied by
	# any resource belonging to that class (Black Iron, Copper, etc.).
	if resource_classes.has(requirement_key):
		var subclass_name = resource_subclass_of.get(instance_name, "")
		if resource_class_lookup.get(subclass_name, "") == requirement_key:
			return true
	return false

func _get_total_amount_for_requirement(requirement_key: String) -> int:
	var total = 0
	for instance_name in inventory.keys():
		if _matches_requirement(instance_name, requirement_key):
			total += inventory[instance_name]
	return total

func _has_enough_resources(requirements: Dictionary) -> bool:
	for requirement_key in requirements.keys():
		var needed = requirements[requirement_key]
		if _get_total_amount_for_requirement(requirement_key) < needed:
			return false
	return true

func _get_weighted_stack_score(instance_name: String, requirement_key: String, recipe: Dictionary) -> float:
	var stats = inventory_stats.get(instance_name, {})
	if stats.size() == 0:
		return 50.0

	var weights = {}
	if recipe.has("stat_weights") and recipe["stat_weights"].has(requirement_key):
		weights = recipe["stat_weights"][requirement_key]

	if weights.size() == 0:
		var sum = 0.0
		for stat_name in stats.keys():
			sum += stats[stat_name]
		return sum / stats.size()

	var weighted_sum = 0.0
	var weight_total = 0.0
	for stat_name in weights.keys():
		if stats.has(stat_name):
			weighted_sum += stats[stat_name] * weights[stat_name]
			weight_total += weights[stat_name]

	if weight_total == 0.0:
		return 50.0

	return weighted_sum / weight_total

func _on_craft_pressed() -> void:
	if selected_recipe_index == -1:
		craft_result_label.text = "Select a recipe first!"
		return

	var recipe = GameData.recipes[selected_recipe_index]

	if not _has_enough_resources(recipe["requires"]):
		craft_result_label.text = "Not enough resources for " + recipe["name"] + "!"
		return

	var total_weighted = 0.0
	var total_weight = 0

	for requirement_key in recipe["requires"].keys():
		var remaining_needed = recipe["requires"][requirement_key]
		var counts_toward_quality = not recipe.has("quality_ingredients") or recipe["quality_ingredients"].has(requirement_key)

		for instance_name in inventory.keys():
			if remaining_needed <= 0:
				break
			if not _matches_requirement(instance_name, requirement_key):
				continue

			var available = inventory[instance_name]
			var take = min(available, remaining_needed)

			if counts_toward_quality:
				var stack_score = _get_weighted_stack_score(instance_name, requirement_key, recipe)
				total_weighted += stack_score * take
				total_weight += take

			inventory[instance_name] -= take
			remaining_needed -= take

	var quality = 50
	if total_weight > 0:
		quality = round(total_weighted / total_weight)

	var finalize_result = _finalize_crafted_item(recipe, quality)
	var result_text = finalize_result["text"]
	craft_result_label.text = result_text

	var article = _get_article(recipe["output"])
	_show_combat_message("You have successfully crafted " + article + " " + recipe["output"] + "!")

# Shared by both the old auto-pick crafting flow (_on_craft_pressed)
# and the new Assembly step (_execute_assembly_craft) — takes an
# already-computed base quality (before the Scrap Tinkerer skill
# multiplier) and a recipe, and handles everything from there:
# quality scaling, item creation, XP, weapon stat generation. Returns
# the result message text; does NOT show it, so callers can display it
# wherever makes sense for their own UI.
func _finalize_crafted_item(recipe: Dictionary, base_quality: int) -> Dictionary:
	var quality = base_quality

	var crafting_nodes = _get_scrap_tinkerer_rank_count("Crafting")
	var mastery_nodes_q = _get_scrap_tinkerer_rank_count("Fabrication Mastery")
	var quality_multiplier = 1.0 + (crafting_nodes * 0.03) + (mastery_nodes_q * 0.01)
	quality = min(1000, round(quality * quality_multiplier))

	# Every crafted item gets its own unique identity, since its exact
	# stats depend on which resources went into it — two Piston Blades
	# made from different Gunmetal Steel batches are genuinely
	# different items, not stacked copies of one. (Loot that drops
	# together from a single kill is a separate system — that one
	# intentionally CAN share an identifier, since it's not crafted.)
	var item_key = _generate_unique_resource_name()
	consumable_base_name[item_key] = recipe["output"]

	var output_quantity = recipe.get("output_quantity", 1)
	_add_to_inventory(item_key, output_quantity)

	if not inventory_stats.has(item_key):
		inventory_stats[item_key] = {}
	inventory_stats[item_key]["Quality"] = quality

	if recipe.has("max_charges"):
		inventory_stats[item_key]["Charges"] = recipe["max_charges"]

	_add_skill_xp("Crafting", 15)
	_add_skill_xp("Fabrication", 5)

	if recipe.has("item_class") and recipe["item_class"] == "Medicine":
		_add_skill_xp("Medicine Crafting XP", 15)

	if recipe.has("item_class"):
		crafted_item_class[item_key] = recipe["item_class"]
	if recipe.has("item_subclass"):
		crafted_item_subclass[item_key] = recipe["item_subclass"]

	var weapon_stats_summary = ""

	if recipe.has("weapon_categorical_stats"):
		for stat_name in recipe["weapon_categorical_stats"].keys():
			var stat_value = recipe["weapon_categorical_stats"][stat_name]
			inventory_stats[item_key][stat_name] = stat_value
			weapon_stats_summary += stat_name + ": " + _format_number(stat_value) + "  "

	if recipe.has("weapon_stat_ranges"):
		for stat_name in recipe["weapon_stat_ranges"].keys():
			var stat_range = recipe["weapon_stat_ranges"][stat_name]
			var min_val = stat_range[0]
			var max_val = stat_range[1]
			var raw_value = min_val + (quality / 1000.0) * (max_val - min_val)

			var scaled_value
			if stat_name == "Speed" or stat_name == "Reload Speed":
				scaled_value = round(raw_value * 10.0) / 10.0
			else:
				scaled_value = round(raw_value)

			inventory_stats[item_key][stat_name] = scaled_value
			weapon_stats_summary += stat_name + ": " + str(scaled_value) + "  "

		var output_stats = inventory_stats[item_key]
		if output_stats.has("Speed") and output_stats.has("Damage Rating"):
			var speed_value = output_stats["Speed"]
			var damage_value = output_stats["Damage Rating"]
			var dps_value = round((damage_value / speed_value) * 10.0) / 10.0
			output_stats["Damage Per Second"] = dps_value
			weapon_stats_summary += "Damage Per Second: " + str(dps_value) + "  "

	_cleanup_empty_inventory_stacks()
	_update_inventory_display()

	var article = _get_article(recipe["output"])
	var result_text = "You have successfully crafted " + article + " " + recipe["output"] + "!"
	if weapon_stats_summary != "":
		result_text += "\n" + weapon_stats_summary.strip_edges()

	return {"text": result_text, "item_key": item_key}

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
	var hotspots_for_save = {}
	for instance_name in resource_hotspots.keys():
		var hotspot_array_for_save = []
		for hotspot in resource_hotspots[instance_name]:
			hotspot_array_for_save.append({"x": hotspot.x, "y": hotspot.y})
		hotspots_for_save[instance_name] = hotspot_array_for_save

	var hotspot_centers_for_save = {}
	for instance_name in resource_hotspot_centers.keys():
		var center = resource_hotspot_centers[instance_name]
		hotspot_centers_for_save[instance_name] = {"x": center.x, "y": center.y}

	var save_data = {
		"inventory": inventory,
		"inventory_stats": inventory_stats,
		"active_resources": active_resources,
		"resource_subclass_of": resource_subclass_of,
		"resource_type_of": resource_type_of,
		"resource_pools": resource_pools,
		"resource_stats": resource_stats,
		"resource_hotspots": hotspots_for_save,
		"resource_hotspot_centers": hotspot_centers_for_save,
		"used_resource_names": used_resource_names,
		"crafted_item_class": crafted_item_class,
		"consumable_base_name": consumable_base_name,
		"equipped_weapon_name": equipped_weapon_name,
		"novice_professions": GameData.novice_professions,
		"xp_pools": xp_pools,
		"militant_points_available": militant_points_available,
		"engineer_points_available": engineer_points_available,
		"professions_unlocked": professions_unlocked,
		"has_chosen_starting_profession": has_chosen_starting_profession,
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

	resource_pools = {}
	for key in save_data["resource_pools"].keys():
		resource_pools[key] = int(save_data["resource_pools"][key])

	inventory_stats = save_data["inventory_stats"]
	active_resources = save_data["active_resources"]
	resource_subclass_of = save_data["resource_subclass_of"]
	resource_type_of = save_data["resource_type_of"]
	resource_stats = save_data["resource_stats"]

	var loaded_hotspots = save_data.get("resource_hotspots", null)
	if loaded_hotspots != null:
		resource_hotspots = {}
		for instance_name in loaded_hotspots.keys():
			var h = loaded_hotspots[instance_name]
			# Old saves stored a single {"x":..,"y":..} point per
			# resource; new saves store an array of them. Handle both
			# so existing save files don't break on load.
			if typeof(h) == TYPE_ARRAY:
				var hotspot_array = []
				for point in h:
					hotspot_array.append(Vector2(point["x"], point["y"]))
				resource_hotspots[instance_name] = hotspot_array
			else:
				resource_hotspots[instance_name] = [Vector2(h["x"], h["y"])]
	used_resource_names = save_data["used_resource_names"]

	var loaded_hotspot_centers = save_data.get("resource_hotspot_centers", null)
	resource_hotspot_centers = {}
	if loaded_hotspot_centers != null:
		for instance_name in loaded_hotspot_centers.keys():
			var c = loaded_hotspot_centers[instance_name]
			resource_hotspot_centers[instance_name] = Vector2(c["x"], c["y"])

	crafted_item_class = save_data.get("crafted_item_class", {})
	consumable_base_name = save_data.get("consumable_base_name", {})
	equipped_weapon_name = save_data.get("equipped_weapon_name", "")

	var loaded_professions = save_data.get("novice_professions", null)
	if loaded_professions != null:
		for profession_name in loaded_professions.keys():
			if not GameData.novice_professions.has(profession_name):
				continue

			var loaded_paths = loaded_professions[profession_name]["paths"]
			for path_name in loaded_paths.keys():
				if GameData.novice_professions[profession_name]["paths"].has(path_name):
					var loaded_nodes = int(loaded_paths[path_name]["unlocked_nodes"])
					GameData.novice_professions[profession_name]["paths"][path_name]["unlocked_nodes"] = loaded_nodes

	var loaded_xp_pools = save_data.get("xp_pools", null)
	if loaded_xp_pools != null:
		for xp_type in loaded_xp_pools.keys():
			if xp_pools.has(xp_type):
				xp_pools[xp_type] = int(loaded_xp_pools[xp_type])

	militant_points_available = int(save_data.get("militant_points_available", militant_points_available))
	engineer_points_available = int(save_data.get("engineer_points_available", engineer_points_available))

	has_chosen_starting_profession = save_data.get("has_chosen_starting_profession", false)
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

	_refresh_resource_tree()
	_update_inventory_display()

	current_scan_resource = ""
	current_scan_concentration = 0
	scan_result_label.text = ""
	resource_stats_label.text = ""

	if inventory.get("Rusty Crafting Kit", 0) <= 0:
		_add_to_inventory("Rusty Crafting Kit", 1)
		_update_inventory_display()

	_show_combat_message("Game loaded!")

# --- Combat ---
# Attack resolution, abilities, hit chance, and kill/XP crediting now
# live in their own script (Combat.gd) — same back-reference pattern
# as the UI panels, just on a plain Node instead of a Control since it
# has no UI of its own.

func _attempt_attack() -> void:
	combat._attempt_attack()

func _attempt_ability(ability_name: String) -> void:
	combat._attempt_ability(ability_name)

func _defeat_dummy() -> String:
	return combat._defeat_dummy()

func _defeat_enemy2() -> String:
	return combat._defeat_enemy2()

func _get_unlocked_classes() -> Array:
	var unlocked = []
	for tool_name in tool_class_access.keys():
		if inventory.get(tool_name, 0) > 0:
			for unlocked_class_name in tool_class_access[tool_name]:
				if not unlocked.has(unlocked_class_name):
					unlocked.append(unlocked_class_name)
	return unlocked

# --- Skills ---

func _add_skill_xp(xp_type: String, amount: int) -> void:
	if not xp_pools.has(xp_type):
		return

	var cap = _get_xp_type_cap(xp_type)
	var current_xp = xp_pools[xp_type]

	xp_pools[xp_type] = min(current_xp + amount, cap)

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
		for other_path_name in GameData.novice_professions[profession_name]["paths"].keys():
			if other_path_name == "Master":
				continue
			var other_path_data = GameData.novice_professions[profession_name]["paths"][other_path_name]
			var other_max = other_path_data.get("max_nodes", NODES_PER_PATH)
			if other_path_data["unlocked_nodes"] < other_max:
				return false
		return true

	var prereq_data = GameData.novice_professions[profession_name]["paths"][prereq_name]
	var prereq_max = prereq_data.get("max_nodes", NODES_PER_PATH)
	return prereq_data["unlocked_nodes"] >= prereq_max

func _get_xp_type_cap(xp_type: String) -> int:
	var lowest_available_cost = -1
	var highest_cost_seen = 0
	var has_new_style = false

	var highest_unlocked_old_style = 0
	var has_old_style = false

	for profession_name in GameData.novice_professions.keys():
		for path_name in GameData.novice_professions[profession_name]["paths"].keys():
			var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
			if path_data["xp_type"] != xp_type:
				continue

			if path_data.has("xp_cost"):
				has_new_style = true
				highest_cost_seen = max(highest_cost_seen, path_data["xp_cost"])

				var max_nodes = path_data.get("max_nodes", 1)
				var already_owned = path_data["unlocked_nodes"] >= max_nodes

				if not already_owned and _is_prereq_met(profession_name, path_data):
					if lowest_available_cost == -1 or path_data["xp_cost"] < lowest_available_cost:
						lowest_available_cost = path_data["xp_cost"]
			else:
				has_old_style = true
				if path_data["unlocked_nodes"] > highest_unlocked_old_style:
					highest_unlocked_old_style = path_data["unlocked_nodes"]

	if has_new_style:
		if lowest_available_cost != -1:
			return int(lowest_available_cost * 1.5)
		return int(highest_cost_seen * 1.5)

	if has_old_style:
		var next_index = min(highest_unlocked_old_style, NODES_PER_PATH - 1)
		return int(skill_xp_thresholds[next_index] * 1.5)

	return int(skill_xp_thresholds[0] * 1.5)

func _refresh_skill_tree_ui() -> void:
	skill_tree.clear()
	var root = skill_tree.create_item()
	skill_tree.hide_root = true

	for profession_name in GameData.novice_professions.keys():
		var profession_item = skill_tree.create_item(root)
		var header_text = profession_name
		if not professions_unlocked.get(profession_name, false):
			header_text += " [LOCKED]"
		profession_item.set_text(0, header_text)
		profession_item.set_selectable(0, false)

		for path_name in GameData.novice_professions[profession_name]["paths"].keys():
			var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
			var unlocked = path_data["unlocked_nodes"]
			var max_nodes = path_data.get("max_nodes", NODES_PER_PATH)

			var display_text = path_name + " (" + str(unlocked) + "/" + str(max_nodes) + ")"

			if unlocked < max_nodes and not _is_prereq_met(profession_name, path_data):
				display_text += " [LOCKED]"

			var leaf = skill_tree.create_item(profession_item)
			leaf.set_text(0, display_text)
			leaf.set_metadata(0, profession_name + "|" + path_name)

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
	var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
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
			info += "\n\nLocked — requires " + path_data["requires"] + " first."
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

	var path_data = GameData.novice_professions[selected_profession]["paths"][selected_path]
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
	_refresh_resource_tree()

func _show_combat_message(text: String) -> void:
	combat_message_label.text = text
	message_clear_timer.start()

func _on_message_clear_timer_timeout() -> void:
	combat_message_label.text = ""

# Separate display slot, positioned directly below the main combat
# message, so "the dummy hits you" text never competes with (and
# silently overwrites) "you hit the dummy" text — they're two
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

# Entry requirements for Elite Professions — each entry must reference

# Returns a list of human-readable "Profession - Box" strings for any
# prereq not yet owned. Empty array means the profession is open to
# select. Professions with no entry in GameData.ELITE_PROFESSION_PREREQS (the
# four base professions) always return empty — no gating on them.
func _get_missing_elite_prereqs(profession_name: String) -> Array:
	var missing: Array = []
	for prereq in GameData.ELITE_PROFESSION_PREREQS.get(profession_name, []):
		var path_data = GameData.novice_professions[prereq["profession"]]["paths"][prereq["box"]]
		var max_nodes = path_data.get("max_nodes", NODES_PER_PATH)
		if path_data["unlocked_nodes"] < max_nodes:
			missing.append(prereq["profession"] + " - " + prereq["box"])
	return missing

# Reverse of the above: given a base profession and one of its boxes
# (e.g. "Chrome Gunner", "Rifles IV"), returns which Elite Profession(s)
# require that specific box — used to show "leads to X" labels on the
# BASE profession's own tree, same idea as SWG showing which advanced
# professions a given box feeds into.

func _on_choose_profession_pressed() -> void:
	var selection = profession_options_list.get_selected_items()
	if selection.size() == 0:
		profession_select_result_label.text = "Select a profession first!"
		return

	var chosen_profession = profession_options_list.get_item_text(selection[0])

	var missing_prereqs = _get_missing_elite_prereqs(chosen_profession)
	if missing_prereqs.size() > 0:
		profession_select_result_label.text = "Requires: " + ", ".join(missing_prereqs)
		return

	if not has_chosen_starting_profession:
		if _get_points_available(chosen_profession) < PROFESSION_ENTRY_COST:
			profession_select_result_label.text = "Not enough " + _points_pool_label(chosen_profession) + "! Need " + str(PROFESSION_ENTRY_COST) + "."
			return

		_spend_points(chosen_profession, PROFESSION_ENTRY_COST)
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
	var bg_color = Color(0.1, 0.1, 0.1)
	var health_color = Color(0.8, 0.1, 0.1)
	var action_color = Color(0.1, 0.8, 0.1)

	for bar in [dummy_health_bar_bg, dummy_action_bar_bg, enemy2_health_bar_bg, enemy2_action_bar_bg]:
		bar.color = bg_color
		bar.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)

	for bar in [player_health_bar_bg, player_action_bar_bg, enemy_hud_health_bar_bg, enemy_hud_action_bar_bg]:
		bar.color = bg_color
		bar.polygon = _make_bar_polygon(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	player_health_bar_fill.color = health_color
	dummy_health_bar_fill.color = health_color
	enemy2_health_bar_fill.color = health_color
	enemy_hud_health_bar_fill.color = health_color
	player_action_bar_fill.color = action_color
	dummy_action_bar_fill.color = action_color
	enemy2_action_bar_fill.color = action_color
	enemy_hud_action_bar_fill.color = action_color

	for fill in [dummy_health_bar_fill, dummy_action_bar_fill, enemy2_health_bar_fill, enemy2_action_bar_fill]:
		fill.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)

	for fill in [player_health_bar_fill, player_action_bar_fill, enemy_hud_health_bar_fill, enemy_hud_action_bar_fill]:
		fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	# Player bars live inside a single PlayerHUD node under UILayer.
	# Its actual screen position is calculated in _layout_hud(), relative
	# to the ActionBar, so the two always stay aligned automatically.
	player_health_bar_bg.position = Vector2.ZERO
	player_health_bar_fill.position = Vector2.ZERO
	player_action_bar_bg.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	player_action_bar_fill.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)

	# EnemyHUD mirrors PlayerHUD's bar layout — no name label, just the
	# health/action bars for whichever enemy is currently tracked.
	enemy_hud_health_bar_bg.position = Vector2.ZERO
	enemy_hud_health_bar_fill.position = Vector2.ZERO
	enemy_hud_action_bar_bg.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	enemy_hud_action_bar_fill.position = Vector2(0, HUD_BAR_HEIGHT + HUD_BAR_GAP)
	enemy_hud.visible = false

	# Numeric "current / max" readouts overlaid on top of the PlayerHUD
	# and EnemyHUD bars only — the floating world-space bars above
	# enemy heads stay plain, unlabeled bars.
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

	dummy_name_label.text = dummy_name
	dummy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dummy_name_label.custom_minimum_size = Vector2(NAME_LABEL_WIDTH, 0)

	enemy2_name_label.text = enemy2_name
	enemy2_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy2_name_label.custom_minimum_size = Vector2(NAME_LABEL_WIDTH, 0)

func _process(_delta: float) -> void:
	_update_health_bars()
	_check_dummy_attack()
	_check_enemy2_attack()

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

	if dummy_alive:
		var dummy_bar_position = dummy.global_position + Vector2(-HEALTH_BAR_WIDTH / 2, -60)
		dummy_health_bar_bg.position = dummy_bar_position
		dummy_health_bar_fill.position = dummy_bar_position

		var bar_center_x = dummy_bar_position.x + (HEALTH_BAR_WIDTH / 2)
		dummy_name_label.position = Vector2(bar_center_x - (NAME_LABEL_WIDTH / 2), dummy_bar_position.y - 24)
		dummy_name_label.modulate = _get_con_color(dummy_difficulty)

		var dummy_action_bar_position = dummy_bar_position + Vector2(0, ACTION_BAR_GAP)
		dummy_action_bar_bg.position = dummy_action_bar_position
		dummy_action_bar_fill.position = dummy_action_bar_position

		var dummy_health_pct = clamp(float(dummy_current_health) / float(dummy_max_health), 0.0, 1.0)
		dummy_health_bar_fill.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH * dummy_health_pct, HEALTH_BAR_HEIGHT)

		var dummy_action_pct = clamp(float(dummy_current_action) / float(dummy_max_action), 0.0, 1.0)
		dummy_action_bar_fill.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH * dummy_action_pct, HEALTH_BAR_HEIGHT)

	if enemy2_alive:
		var enemy2_bar_position = enemy2.global_position + Vector2(-HEALTH_BAR_WIDTH / 2, -60)
		enemy2_health_bar_bg.position = enemy2_bar_position
		enemy2_health_bar_fill.position = enemy2_bar_position

		var enemy2_bar_center_x = enemy2_bar_position.x + (HEALTH_BAR_WIDTH / 2)
		enemy2_name_label.position = Vector2(enemy2_bar_center_x - (NAME_LABEL_WIDTH / 2), enemy2_bar_position.y - 24)
		enemy2_name_label.modulate = _get_con_color(enemy2_difficulty)

		var enemy2_action_bar_position = enemy2_bar_position + Vector2(0, ACTION_BAR_GAP)
		enemy2_action_bar_bg.position = enemy2_action_bar_position
		enemy2_action_bar_fill.position = enemy2_action_bar_position

		var enemy2_health_pct = clamp(float(enemy2_current_health) / float(enemy2_max_health), 0.0, 1.0)
		enemy2_health_bar_fill.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH * enemy2_health_pct, HEALTH_BAR_HEIGHT)

		var enemy2_action_pct = clamp(float(enemy2_current_action) / float(enemy2_max_action), 0.0, 1.0)
		enemy2_action_bar_fill.polygon = _make_bar_polygon(HEALTH_BAR_WIDTH * enemy2_action_pct, HEALTH_BAR_HEIGHT)

	_update_enemy_hud()

# Mirrors the player's fixed HUD bars, but for whichever enemy is
# currently nearest to the player (alive). Hides itself entirely when
# no enemies are alive. This is separate from — and doesn't replace —
# the floating health/action bars each enemy shows above its own head.
func _update_enemy_hud() -> void:
	var tracked_id = _get_tracked_enemy_id()

	if tracked_id == "":
		enemy_hud.visible = false
		return

	enemy_hud.visible = true

	var current_health: int
	var max_health: int
	var current_action: int
	var max_action: int

	if tracked_id == "dummy":
		current_health = dummy_current_health
		max_health = dummy_max_health
		current_action = dummy_current_action
		max_action = dummy_max_action
	else:
		current_health = enemy2_current_health
		max_health = enemy2_max_health
		current_action = enemy2_current_action
		max_action = enemy2_max_action

	var tracked_health_pct = clamp(float(current_health) / float(max_health), 0.0, 1.0)
	enemy_hud_health_bar_fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH * tracked_health_pct, HUD_BAR_HEIGHT)
	enemy_hud_health_label.text = str(current_health) + " / " + str(max_health)
	enemy_hud_health_label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

	var tracked_action_pct = clamp(float(current_action) / float(max_action), 0.0, 1.0)
	enemy_hud_action_bar_fill.polygon = _make_bar_polygon(HUD_BAR_WIDTH * tracked_action_pct, HUD_BAR_HEIGHT)
	enemy_hud_action_label.text = str(current_action) + " / " + str(max_action)
	enemy_hud_action_label.size = Vector2(HUD_BAR_WIDTH, HUD_BAR_HEIGHT)

# Picks whichever alive enemy is nearest to the player AND within
# MELEE_RANGE (the same range that gates actually being able to attack),
# for display in the fixed EnemyHUD panel. Returns "" if no enemy is
# alive and in range — this also doubles as a rough "you're close
# enough to attack" indicator for now.
func _get_tracked_enemy_id() -> String:
	var candidates = []

	if dummy_alive:
		var dummy_distance = player.global_position.distance_to(dummy.global_position)
		if dummy_distance <= MELEE_RANGE:
			candidates.append(["dummy", dummy_distance])

	if enemy2_alive:
		var enemy2_distance = player.global_position.distance_to(enemy2.global_position)
		if enemy2_distance <= MELEE_RANGE:
			candidates.append(["enemy2", enemy2_distance])

	if candidates.size() == 0:
		return ""

	candidates.sort_custom(func(a, b): return a[1] < b[1])
	return candidates[0][0]

# --- Enemy Attacks ---

func _check_dummy_attack() -> void:
	if not dummy_alive or not player_alive or not dummy_attack_ready:
		return

	var distance = dummy.global_position.distance_to(player.global_position)
	if distance > ENEMY_ATTACK_RANGE:
		return

	var damage = randi_range(DUMMY_ATTACK_MIN_DAMAGE, DUMMY_ATTACK_MAX_DAMAGE)
	damage = round(damage * (1.0 - dummy_damage_debuff))
	player_current_health -= damage
	player_current_health = max(player_current_health, 0)

	_show_enemy_combat_message("The dummy hits you for " + str(damage) + " damage!")

	if player_current_health <= 0:
		_defeat_player()

	dummy_attack_ready = false
	dummy_attack_cooldown_timer.wait_time = DUMMY_ATTACK_COOLDOWN * (1.0 + dummy_attack_speed_debuff)
	dummy_attack_cooldown_timer.start()

func _on_dummy_attack_cooldown_finished() -> void:
	dummy_attack_ready = true

func _check_enemy2_attack() -> void:
	if not enemy2_alive or not player_alive or not enemy2_attack_ready:
		return

	var distance = enemy2.global_position.distance_to(player.global_position)
	if distance > ENEMY_ATTACK_RANGE:
		return

	var damage = randi_range(ENEMY2_ATTACK_MIN_DAMAGE, ENEMY2_ATTACK_MAX_DAMAGE)
	damage = round(damage * (1.0 - enemy2_damage_debuff))
	player_current_health -= damage
	player_current_health = max(player_current_health, 0)

	_show_enemy_combat_message(enemy2_name + " hits you for " + str(damage) + " damage!")

	if player_current_health <= 0:
		_defeat_player()

	enemy2_attack_ready = false
	enemy2_attack_cooldown_timer.wait_time = ENEMY2_ATTACK_COOLDOWN * (1.0 + enemy2_attack_speed_debuff)
	enemy2_attack_cooldown_timer.start()

func _on_enemy2_attack_cooldown_finished() -> void:
	enemy2_attack_ready = true

func _defeat_player() -> void:
	player_alive = false
	_show_combat_message("You have been defeated!")
	player_respawn_timer.start()

func _on_player_respawn() -> void:
	player_current_health = player_max_health
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

	# Bleed (Pressure Enforcer Master ability) — same once-per-second
	# tick cadence as the Apothecary HoTs above, just damage instead of
	# healing, and applied to whichever enemy has it active.
	if dummy_alive and dummy_bleed_ticks_remaining > 0:
		dummy_current_health -= dummy_bleed_damage_per_tick
		dummy_bleed_ticks_remaining -= 1
		_show_enemy_combat_message("Bleed deals " + str(dummy_bleed_damage_per_tick) + " damage to " + dummy_name + "!")
		if dummy_current_health <= 0:
			_show_combat_message(_defeat_dummy())

	if enemy2_alive and enemy2_bleed_ticks_remaining > 0:
		enemy2_current_health -= enemy2_bleed_damage_per_tick
		enemy2_bleed_ticks_remaining -= 1
		_show_enemy_combat_message("Bleed deals " + str(enemy2_bleed_damage_per_tick) + " damage to " + enemy2_name + "!")
		if enemy2_current_health <= 0:
			_show_combat_message(_defeat_enemy2())

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

func _roll_loot(enemy_name: String) -> Array:
	var dropped_items = []

	if not loot_tables.has(enemy_name):
		return dropped_items

	var roll = randf()
	var chosen_tier = ""
	var cumulative = 0.0

	for tier_name in ["Common", "Uncommon", "Rare"]:
		cumulative += LOOT_TIER_CHANCES[tier_name]
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
		for path_name in GameData.novice_professions[profession_name]["paths"].keys():
			var unlocked = GameData.novice_professions[profession_name]["paths"][path_name]["unlocked_nodes"]
			for i in range(unlocked):
				total_spent += skill_point_costs[i]

	if has_chosen_starting_profession:
		total_spent += PROFESSION_ENTRY_COST

	return total_spent

func _get_con_color(enemy_difficulty: int) -> Color:
	var player_spent = _get_total_skill_points_spent()
	var effective_spent = max(player_spent, 1)
	var ratio = float(effective_spent) / float(max(enemy_difficulty, 1))

	if ratio >= 2.0:
		return Color(0.5, 0.5, 0.5)
	elif ratio >= 1.25:
		return Color(0.2, 0.9, 0.2)
	elif ratio >= 0.75:
		return Color(1.0, 1.0, 0.2)
	elif ratio >= 0.5:
		return Color(1.0, 0.6, 0.0)
	else:
		return Color(1.0, 0.1, 0.1)

func _grant_starting_weapon(weapon_name: String, quality: int) -> void:
	var recipe = null
	for r in GameData.recipes:
		if r["output"] == weapon_name:
			recipe = r
			break

	if recipe == null:
		return

	# Unique per grant, same rule as crafted items — even a starting
	# weapon has its own generated stats and shouldn't stack/share an
	# identity with another copy of the same weapon name.
	var item_key = _generate_unique_resource_name()
	consumable_base_name[item_key] = weapon_name

	_add_to_inventory(item_key, 1)

	if not inventory_stats.has(item_key):
		inventory_stats[item_key] = {}
	inventory_stats[item_key]["Quality"] = quality

	if recipe.has("item_class"):
		crafted_item_class[item_key] = recipe["item_class"]
	if recipe.has("item_subclass"):
		crafted_item_subclass[item_key] = recipe["item_subclass"]

	if recipe.has("weapon_categorical_stats"):
		for stat_name in recipe["weapon_categorical_stats"].keys():
			inventory_stats[item_key][stat_name] = recipe["weapon_categorical_stats"][stat_name]

	if recipe.has("weapon_stat_ranges"):
		var output_stats = inventory_stats[item_key]
		for stat_name in recipe["weapon_stat_ranges"].keys():
			var stat_range = recipe["weapon_stat_ranges"][stat_name]
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
			var dps_value = round((damage_value / speed_value) * 10.0) / 10.0
			output_stats["Damage Per Second"] = dps_value

# --- Scavenging ---

func _attempt_forage() -> void:
	var dumpster_distance = player.global_position.distance_to(dumpster.global_position)
	if dumpster_distance > DUMPSTER_RANGE:
		_show_combat_message("Too far away! Get closer to scavenge.")
		return

	_scavenge_dumpster()

# Fixed, guaranteed-drop scavenge point (a Dumpster) — unlike the herb
# patch's probability-tiered loot, this always gives the same kind of
# find (Plastic + a flat Cogs amount), matching a simple "always has
# something in it" scavenge spot rather than a rare-resource patch.
func _scavenge_dumpster() -> void:
	if not dumpster_available:
		_show_combat_message("This dumpster has already been picked through. Check back later.")
		return

	var plastic_amount = randi_range(1, 3)

	var foraging_chance_bonus = _get_foraging_chance_bonus()
	if foraging_chance_bonus > 0 and randf() < (foraging_chance_bonus * 0.10):
		plastic_amount += randi_range(1, 3)

	_add_to_inventory("Plastic", plastic_amount)
	cogs += randi_range(DUMPSTER_COGS_MIN, DUMPSTER_COGS_MAX)

	# On top of the guaranteed Plastic + Cogs, every scavenge also rolls
	# the tiered Dumpster loot table for a chance at Torn Cloth/
	# Antiseptic Moss/Healroot/Bloomwort — these used to only come from
	# the (now-removed) herb patch, so this is their only source now.
	var bonus_items = _roll_loot("Dumpster")

	_update_inventory_display()
	_update_cogs_display()

	_add_skill_xp("Scavenging XP", FORAGE_XP)
	_show_xp_gain_message("You've gained " + str(FORAGE_XP) + " Scavenging XP!")

	var result_message = "You scavenge and find: " + str(plastic_amount) + " Plastic, " + str(DUMPSTER_COGS_MIN) + " Cogs"
	for bonus_item in bonus_items:
		result_message += ", " + bonus_item
	_show_combat_message(result_message)

	dumpster_available = false
	dumpster.visible = false
	dumpster_cooldown_timer.wait_time = DUMPSTER_RESPAWN_TIME
	dumpster_cooldown_timer.start()

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

	if not professions_unlocked.get("Apothecary", false):
		_show_combat_message("You need to be an Apothecary to use a Crate of Bandages!")
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

	_add_skill_xp("Healing XP", BANDAGE_HEALING_XP)
	_show_xp_gain_message("You've gained " + str(BANDAGE_HEALING_XP) + " Healing XP!")
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
# from a minimum at Quality 0 up to a maximum at Quality 1000 — e.g.
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
	if not professions_unlocked.get("Apothecary", false):
		_show_combat_message("You need to be an Apothecary to use IV Drip!")
		return
	if not _get_apothecary_rank_unlocked("Healing II"):
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
	_show_combat_message("You apply an IV Drip — healing " + str(IV_DRIP_HEAL_PER_TICK) + " HP/sec for " + str(IV_DRIP_DURATION_TICKS) + " seconds.")

func _attempt_healing_vapor() -> void:
	if not professions_unlocked.get("Apothecary", false):
		_show_combat_message("You need to be an Apothecary to use Healing Vapor!")
		return
	if not _get_apothecary_rank_unlocked("Healing IV"):
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
	# AoE heal — only the player is a valid target right now since
	# there are no other in-scene allies yet. Once co-op players or
	# companions exist, extend this to heal everyone in range.
	var missing_health = player_max_health - player_current_health
	var heal_amount = min(HEALING_VAPOR_HEAL_AMOUNT, missing_health)
	player_current_health += heal_amount
	healing_vapor_ready_at_msec = now_msec + HEALING_VAPOR_COOLDOWN_MSEC
	_show_combat_message("You release a cloud of Healing Vapor, restoring " + str(heal_amount) + " HP!")

func _attempt_adrenaline_boost() -> void:
	if not professions_unlocked.get("Apothecary", false):
		_show_combat_message("You need to be an Apothecary to use Adrenaline Boost!")
		return
	if not _get_apothecary_rank_unlocked("Stims I"):
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
	_show_combat_message("You inject an Adrenaline Shot — +" + str(bonus_amount) + " Max Action for 10 minutes!")

func _attempt_blood_bag() -> void:
	if not professions_unlocked.get("Apothecary", false):
		_show_combat_message("You need to be an Apothecary to use Blood Bag!")
		return
	if not _get_apothecary_rank_unlocked("Stims III"):
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

	# Defensive: same non-stacking safeguard as Adrenaline Boost — revert
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
	_show_combat_message("You use Blood Bag — +" + str(bonus_amount) + " Max Health for 10 minutes!")

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

	# Force Top-Left anchoring explicitly — if ActionBar's anchors were
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
	# is defensive — the real fix is re-running via size_changed below.
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

func _trigger_slot(slot: ActionBarSlot) -> void:
	if slot.assigned_ability != "":
		_use_ability_by_name(slot.assigned_ability)

func _use_ability_by_name(ability_name: String) -> void:
	if ability_name == "Attack":
		_attempt_attack()
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
	elif ability_name == "Mineral Survey Tool" or ability_name == "Flora Tool" or ability_name == "Steam and Oil Sniffer":
		if survey_book_ui.visible and active_survey_tool == ability_name:
			survey_book_ui.visible = false
		else:
			active_survey_tool = ability_name
			survey_book_ui.visible = true
			survey_book_ui._refresh_survey_book()
	elif ability_name == "Rusty Crafting Kit":
		crafting_book_ui.visible = not crafting_book_ui.visible
		if crafting_book_ui.visible:
			crafting_book_ui._refresh_crafting_book()
	elif GameData.ability_definitions.has(ability_name):
		_attempt_ability(ability_name)
	else:
		_show_combat_message("Nothing to do with " + ability_name + ".")

func _use_inventory_item(_item_key: String, display_name: String) -> void:
	_use_ability_by_name(display_name)

# --- Trainer ---

func _attempt_talk_to_trainer() -> void:
	var nearest_index = _get_nearest_trainer_in_range()
	if nearest_index == -1:
		_show_combat_message("No trainer is close enough to talk to.")
		return

	if trainer_ui.visible and active_trainer_index == nearest_index:
		trainer_ui.visible = false
		return

	active_trainer_index = nearest_index
	trainer_ui.visible = true
	trainer_dialogue_state = "GREETING"
	trainer_ui._refresh_trainer_dialogue()

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
# states — GREETING, SKILL_LIST, CONFIRM — clearing and rebuilding the
# option buttons in trainer_options each time the state changes.

# --- Trainer Dialogue ---
# Now lives in TrainerDialogue.gd, attached directly to the TrainerUI
# scene node (see that file for why this one's different from the
# other panels). Cross-calls into it use the trainer_ui reference
# below, same pattern as ability_book_ui/survey_book_ui/etc.

func _learn_trainer_profession() -> void:
	if active_trainer_index == -1:
		return
	var this_trainer_profession = trainers[active_trainer_index]["profession"]

	if professions_unlocked.get(this_trainer_profession, false):
		trainer_ui._show_train_result("You've already learned " + this_trainer_profession + "!")
		return

	if not has_chosen_starting_profession:
		if _get_points_available(this_trainer_profession) < PROFESSION_ENTRY_COST:
			trainer_ui._show_train_result("Not enough " + _points_pool_label(this_trainer_profession) + "! Need " + str(PROFESSION_ENTRY_COST) + ".")
			return

		_spend_points(this_trainer_profession, PROFESSION_ENTRY_COST)
		professions_unlocked[this_trainer_profession] = true
		has_chosen_starting_profession = true
		_grant_novice_unlock(this_trainer_profession)
		_grant_profession_starting_kit(this_trainer_profession)
		trainer_ui._show_train_result("You are now a " + this_trainer_profession + "!")
	else:
		if _get_points_available(this_trainer_profession) < PROFESSION_ENTRY_COST:
			trainer_ui._show_train_result("Not enough " + _points_pool_label(this_trainer_profession) + "! Need " + str(PROFESSION_ENTRY_COST) + ".")
			return

		if cogs < ADDITIONAL_PROFESSION_COGS_COST:
			trainer_ui._show_train_result("Not enough Cogs! Need " + str(ADDITIONAL_PROFESSION_COGS_COST) + ", have " + str(cogs) + ".")
			return

		_spend_points(this_trainer_profession, PROFESSION_ENTRY_COST)
		cogs -= ADDITIONAL_PROFESSION_COGS_COST
		_update_cogs_display()
		professions_unlocked[this_trainer_profession] = true
		_grant_novice_unlock(this_trainer_profession)
		trainer_ui._show_train_result("You have learned " + this_trainer_profession + "!")

	_refresh_skill_tree_ui()

func _grant_novice_unlock(profession_name: String) -> void:
	if GameData.novice_professions[profession_name]["paths"].has("Novice"):
		GameData.novice_professions[profession_name]["paths"]["Novice"]["unlocked_nodes"] = 1

	if profession_name == "Scrap Tinkerer":
		_add_to_inventory("Mineral Survey Tool", 1)
		_add_to_inventory("Flora Tool", 1)
		_add_to_inventory("Steam and Oil Sniffer", 1)
		_add_to_inventory("Rusty Crafting Kit", 1)
		_update_inventory_display()

# Grants the one-time starting weapons + 100 Cogs bonus. Only ever
# called for the very first profession a player picks — subsequent
# additional professions get their Novice abilities (via
# _grant_novice_unlock) but no repeat weapon/cogs kit.
# Every new character starts with 2 Crates of Bandages, independent of
# profession — each is its own generated instance with a full 5
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

func _grant_profession_starting_kit(profession_name: String) -> void:
	match profession_name:
		"Pressure Enforcer":
			_grant_starting_weapon("Piston Blade", 0)
			_add_to_inventory("Mineral Survey Tool", 1)
			_add_to_inventory("Rusty Crafting Kit", 1)
		"Chrome Gunner":
			_grant_starting_weapon("Pressure Scattergun", 0)
			_add_to_inventory("Mineral Survey Tool", 1)
			_add_to_inventory("Rusty Crafting Kit", 1)
		"Apothecary":
			_grant_starting_weapon("Pneumatic Rifle", 0)
			_add_to_inventory("Mineral Survey Tool", 1)
			_add_to_inventory("Rusty Crafting Kit", 1)

	cogs += 100
	_update_cogs_display()
	_update_inventory_display()

# --- Talent Tree Viewer ---
# A testing/reference-only overlay for visualizing the skill trees.
# Fully built here in code (no manual scene
# nodes needed) so it can be dropped in and iterated on freely.
# Toggle with the "talent_view" input action (map a key to it in
# Project Settings > Input Map). This does NOT replace the real
# functional Skill UI (skill_ui/skill_tree) — it's a separate visual
# reference layered on top of the same underlying data.

var talent_ui: Control
var ability_book_ui: Control
var inventory_book_ui: Control
var crafting_book_ui: Control
var crafting_result_ui: Control
var survey_book_ui: Control
# Path to the existing drag-source script, reused so abilities dragged
# from the Ability Book work identically to the old fixed menu — if
# this path is wrong for your project, this is the one line to fix.
const ABILITY_DRAG_SOURCE_SCRIPT_PATH = "res://scenes/ability_drag_source.gd"

# Skill box colors. TALENT_OWNED_COLOR is a softened version of #870146 —
# easier on the eyes for a color you'll be staring at a lot. To use
# the exact original hex instead, swap the line below for:
#   const TALENT_OWNED_COLOR = Color("870146")
const TALENT_OWNED_COLOR = Color("b5336e")
const TALENT_UNLEARNED_COLOR = Color(0.28, 0.28, 0.28)

func _get_talent_box_label(profession_name: String, path_name: String) -> String:
	return GameData.TALENT_BOX_DISPLAY_NAMES.get(profession_name, {}).get(path_name, path_name)




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






# --- Ability Book ---
# A testing/reference-quality replacement for the old fixed 8-button
# AbilityMenu, which could only ever show 6 hardcoded abilities and
# had no way to display anything added later (Cleave, Subdue, all of
# Chrome Gunner's abilities, etc.). This scans GameData.ability_definitions
# directly, so any future ability shows up automatically — nothing
# to remember to wire up by hand. Fully built here in code, same
# approach as the Talent Viewer.

# Talent Viewer now lives in its own script (TalentViewer.gd, Pass 2 of
# splitting main.gd apart) — this just instantiates it, gives it a
# back-reference to main for the handful of things it still shares
# with other systems, adds it to the scene, and tells it to build its
# UI. See TalentViewer.gd for everything else.
func _build_talent_ui() -> void:
	talent_ui = preload("res://scenes/TalentViewer.gd").new()
	talent_ui.main = self
	$UILayer.add_child(talent_ui)
	talent_ui._build_talent_ui()

# Ability Book now lives in its own script (AbilityBook.gd) — same
# pattern as TalentViewer.gd.
func _build_ability_book_ui() -> void:
	ability_book_ui = preload("res://scenes/AbilityBook.gd").new()
	ability_book_ui.main = self
	$UILayer.add_child(ability_book_ui)
	ability_book_ui._build_ability_book_ui()

func _refresh_ability_book() -> void:
	ability_book_ui._refresh_ability_book()

func _make_ability_book_button(ability_name: String) -> Button:
	return ability_book_ui._make_ability_book_button(ability_name)

# --- Inventory Book ---
# A testing/reference UI for inventory, styled the same way as the
# Talent Viewer and Ability Book (fully built in code, scrollable, no
# fixed slot count). Clicking any item shows its actual stats — this
# works generically for resources, crafted weapons, and tools alike,
# since they all already share the same inventory_stats dictionary.

# Inventory Book now lives in its own script (InventoryBook.gd) — same
# pattern as TalentViewer.gd.
func _build_inventory_book_ui() -> void:
	inventory_book_ui = preload("res://scenes/InventoryBook.gd").new()
	inventory_book_ui.main = self
	$UILayer.add_child(inventory_book_ui)
	inventory_book_ui._build_inventory_book_ui()

func _refresh_inventory_book() -> void:
	inventory_book_ui._refresh_inventory_book()

# --- Crafting Book ---
# The recipe list + Assembly screen now live in their own script
# (CraftingBook.gd) — same pattern as TalentViewer.gd. The shared
# collapsible-category header system below (also used by the Survey
# Book) stays here in main.gd.

func _build_crafting_book_ui() -> void:
	crafting_book_ui = preload("res://scenes/CraftingBook.gd").new()
	crafting_book_ui.main = self
	$UILayer.add_child(crafting_book_ui)
	crafting_book_ui._build_crafting_book_ui()

func _refresh_crafting_book() -> void:
	crafting_book_ui._refresh_crafting_book()

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

func _make_crafting_book_header(text: String, indent: int, color: Color, category_key: String, refresh_callback: Callable) -> Button:
	var is_collapsed = book_category_collapsed.get(category_key, false)
	var arrow = "\u25b6 " if is_collapsed else "\u25bc "

	var header = Button.new()
	header.text = "  ".repeat(indent) + arrow + text
	header.modulate = color
	header.add_theme_font_size_override("font_size", 15 - indent)
	header.flat = true
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.focus_mode = Control.FOCUS_NONE
	header.custom_minimum_size = Vector2(510, 0)
	header.pressed.connect(_toggle_book_category.bind(category_key, refresh_callback))
	return header

# --- Completed Item Popup ---
# Shows the finished item right after Assemble, with its full stats —
# separate from the Crafting Book itself so it reads as a clear
# "here's what you made" moment rather than just more list text.
# Includes a placeholder Mod Slots section now specifically so the
# layout already has a home for that feature when it's built later,
# rather than needing this window redesigned at that point.

# Completed Item Popup now lives in its own script
# (CraftingResultPopup.gd) — same pattern as TalentViewer.gd.
func _build_crafting_result_ui() -> void:
	crafting_result_ui = preload("res://scenes/CraftingResultPopup.gd").new()
	crafting_result_ui.main = self
	$UILayer.add_child(crafting_result_ui)
	crafting_result_ui._build_crafting_result_ui()

# --- Survey Book ---
# A testing/reference UI for surveying, styled like the other books.
# Deliberately does NOT show resource stats (Conductivity, Toughness,
# etc.) anywhere on this screen — those stay exclusive to the
# Inventory Book and Crafting Book, per request. This only shows
# concentration %, matching what a real survey tool would tell you.

# Survey Book now lives in its own script (SurveyBook.gd) — same
# pattern as TalentViewer.gd.
func _build_survey_book_ui() -> void:
	survey_book_ui = preload("res://scenes/SurveyBook.gd").new()
	survey_book_ui.main = self
	$UILayer.add_child(survey_book_ui)
	survey_book_ui._build_survey_book_ui()
