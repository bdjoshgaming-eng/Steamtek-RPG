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
#
# Phase 5 adds three DEFENSIVE stats, all percentages and all CL-derived
# only (no archetype shaping -- archetype shapes resistances, CL shapes
# defense): "dodge" is a full-avoid chance rolled AFTER the hit check and
# is deliberately capped low (15%% at CL40) so it never compounds with
# Defense into a frustrating double-whiff; "block" is a partial-mitigation
# chance that halves incoming damage; "crit_resist" subtracts directly
# from the attacker's critical chance.
const CL_ANCHORS: Dictionary = {
	1: {"health": 50, "action": 50, "damage": 27, "defense": -2, "armor": 0, "dodge": 0.0, "block": 0.0, "crit_resist": 0.0},
	5: {"health": 110, "action": 90, "damage": 48, "defense": 16, "armor": 15, "dodge": 2.0, "block": 3.0, "crit_resist": 2.0},
	10: {"health": 250, "action": 190, "damage": 85, "defense": 35, "armor": 30, "dodge": 4.0, "block": 6.0, "crit_resist": 4.0},
	15: {"health": 600, "action": 440, "damage": 146, "defense": 55, "armor": 48, "dodge": 6.0, "block": 8.0, "crit_resist": 6.0},
	20: {"health": 1365, "action": 980, "damage": 238, "defense": 75, "armor": 66, "dodge": 8.0, "block": 11.0, "crit_resist": 8.0},
	25: {"health": 2940, "action": 2100, "damage": 374, "defense": 100, "armor": 93, "dodge": 10.0, "block": 13.0, "crit_resist": 10.0},
	30: {"health": 5800, "action": 4100, "damage": 578, "defense": 130, "armor": 120, "dodge": 12.0, "block": 15.0, "crit_resist": 11.0},
	35: {"health": 10920, "action": 7700, "damage": 867, "defense": 165, "armor": 152, "dodge": 13.0, "block": 18.0, "crit_resist": 13.0},
	40: {"health": 21000, "action": 14700, "damage": 1241, "defense": 200, "armor": 193, "dodge": 15.0, "block": 20.0, "crit_resist": 15.0},
}


# Damage multiplier applied when a defender BLOCKS (Phase 5). A block is
# partial mitigation, not an avoid -- the hit still lands for half.
const BLOCK_DAMAGE_MULTIPLIER: float = 0.5


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


# --- Phase 4c: per-archetype resistance profiles ---
# An enemy's resistance PROFILE (which damage types get through) comes
# from its ARCHETYPE -- something intrinsic to what the enemy is, not
# from worn gear. Enemies have the same Armor Rating regardless of what
# they appear to be wearing; visible equipment is presentation only.
#
# Values are MULTIPLIERS against the enemy's CL-derived Armor Rating, so
# Combat Level sets the MAGNITUDE and archetype sets the SHAPE. 1.0 means
# "full armor rating against this type", 0.0 is a permanent hole at every
# CL, and values above 1.0 are hardened. This keeps the CL anchor table
# meaningful (a CL40 enemy is still far tougher than a CL5 one) while
# making damage type a real tactical choice.
#
# Design intent: every damage type is the right answer against something.
# Brawlers/Heavies/Shield Specialists soak physical but fold to Arc.
# Engineers and Hackers run on electronics, so Arc and EMP are their hard
# counter. Medics work with chemicals so they resist them. Snipers are
# glass. Chemical and EMP have no weapons yet, so those columns are
# inert until those weapon families exist.
const ARCHETYPE_RESISTANCE_PROFILES: Dictionary = {
	"Brawler":           {"Kinetic": 1.3, "Ballistic": 0.7, "Thermal": 0.6, "Pressure": 0.8, "Arc": 0.5, "Chemical": 0.6, "EMP": 1.0},
	"Assault":           {"Kinetic": 1.0, "Ballistic": 1.2, "Thermal": 0.8, "Pressure": 0.8, "Arc": 0.7, "Chemical": 0.7, "EMP": 1.0},
	"Rifleman":          {"Kinetic": 0.8, "Ballistic": 1.0, "Thermal": 0.8, "Pressure": 0.7, "Arc": 0.8, "Chemical": 0.8, "EMP": 1.0},
	"Heavy":             {"Kinetic": 1.5, "Ballistic": 1.4, "Thermal": 1.0, "Pressure": 1.2, "Arc": 0.6, "Chemical": 0.8, "EMP": 0.8},
	"Sniper":            {"Kinetic": 0.6, "Ballistic": 0.8, "Thermal": 0.7, "Pressure": 0.6, "Arc": 0.8, "Chemical": 0.8, "EMP": 1.0},
	"Engineer":          {"Kinetic": 0.8, "Ballistic": 0.8, "Thermal": 1.3, "Pressure": 1.2, "Arc": 0.4, "Chemical": 1.2, "EMP": 0.3},
	"Hacker":            {"Kinetic": 0.6, "Ballistic": 0.6, "Thermal": 0.7, "Pressure": 0.6, "Arc": 0.3, "Chemical": 0.8, "EMP": 0.2},
	"Medic":             {"Kinetic": 0.7, "Ballistic": 0.7, "Thermal": 0.9, "Pressure": 0.8, "Arc": 0.8, "Chemical": 1.4, "EMP": 0.9},
	"Commander":         {"Kinetic": 1.1, "Ballistic": 1.1, "Thermal": 1.0, "Pressure": 1.0, "Arc": 0.9, "Chemical": 0.9, "EMP": 0.8},
	"Shield Specialist": {"Kinetic": 1.4, "Ballistic": 1.3, "Thermal": 1.0, "Pressure": 1.5, "Arc": 0.7, "Chemical": 0.9, "EMP": 0.7},
}


# Fallback profile for an unknown or missing archetype: uniform 1.0, i.e.
# exactly the Phase 4b behavior. Nothing breaks if an enemy is added
# without an archetype -- it simply resists every type at its full armor
# rating until a profile is assigned.
const DEFAULT_RESISTANCE_PROFILE_VALUE: float = 1.0


# Builds a per-type resistance dictionary by scaling the enemy's derived
# Armor Rating through its archetype profile (Phase 4c). Called from
# main._apply_cl_derivation() whenever an enemy's CL stats are applied.
func new_resistances(armor_rating: int, archetype: String = "") -> Dictionary:
	var profile: Dictionary = ARCHETYPE_RESISTANCE_PROFILES.get(archetype, {})
	var r: Dictionary = {}
	for dtype in DAMAGE_TYPES:
		var mult: float = profile.get(dtype, DEFAULT_RESISTANCE_PROFILE_VALUE)
		r[dtype] = int(round(float(armor_rating) * mult))
	return r


# --- Phase 6a: archetype stat modifiers ---
# Multipliers applied to the CL-derived base stats. ARCHETYPE is what an
# enemy fundamentally IS, so it shapes core stats meaningfully: a Sniper
# hits hard and dies fast, a Shield Specialist is the inverse. These
# stack on top of the CL anchor table -- CL sets the tier, archetype sets
# the character within that tier.
const ARCHETYPE_STAT_MODIFIERS: Dictionary = {
	"Brawler":           {"health": 1.15, "damage": 1.00, "defense": 0.90},
	"Assault":           {"health": 1.00, "damage": 1.05, "defense": 1.00},
	"Rifleman":          {"health": 0.90, "damage": 1.10, "defense": 1.00},
	"Heavy":             {"health": 1.40, "damage": 1.15, "defense": 0.85},
	"Sniper":            {"health": 0.70, "damage": 1.35, "defense": 0.90},
	"Engineer":          {"health": 0.95, "damage": 0.85, "defense": 1.05},
	"Hacker":            {"health": 0.75, "damage": 0.80, "defense": 1.10},
	"Medic":             {"health": 0.90, "damage": 0.75, "defense": 1.00},
	"Commander":         {"health": 1.10, "damage": 1.05, "defense": 1.15},
	"Shield Specialist": {"health": 1.25, "damage": 0.85, "defense": 1.25},
}


# --- Phase 6a: faction definitions ---
# Faction is primarily IDENTITY -- who the enemy fights for, what they
# carry, what they drop. Every faction fields the full range from pawns
# to queens; that spread comes from COMBAT LEVEL, not from faction.
#
# The small multipliers below only express gear quality at IDENTICAL CL
# and archetype (Rust Syndicate scavenge, Blackline are equipped
# professionals). Next to the CL curve -- 50 HP at CL1 vs 21000 at CL40 --
# this spread is deliberately minor. If faction should carry NO power
# influence at all, set every value here to 1.0; nothing else needs to
# change.
const FACTION_DEFINITIONS: Dictionary = {
	"Rust Syndicate": {
		"description": "Street gangs and scavengers.",
		"modifiers": {"health": 0.90, "damage": 0.95, "armor": 0.85},
	},
	"Blackline Security": {
		"description": "Corporate military contractors.",
		"modifiers": {"health": 1.05, "damage": 1.10, "armor": 1.15},
	},
	"Reactor Authority": {
		"description": "Industrial government security.",
		"modifiers": {"health": 1.15, "damage": 1.00, "armor": 1.20},
	},
	"Ghost Circuit": {
		"description": "Cybernetically enhanced mercenaries.",
		"modifiers": {"health": 0.95, "damage": 1.15, "armor": 0.90},
	},
}


# Returns the combined stat multiplier for a given archetype + faction.
# Missing or unknown names fall back to 1.0, so an enemy can always be
# generated even with incomplete identity data.
func stat_modifiers_for(archetype: String, faction: String) -> Dictionary:
	var a: Dictionary = ARCHETYPE_STAT_MODIFIERS.get(archetype, {})
	var f: Dictionary = FACTION_DEFINITIONS.get(faction, {}).get("modifiers", {})
	return {
		"health": float(a.get("health", 1.0)) * float(f.get("health", 1.0)),
		"damage": float(a.get("damage", 1.0)) * float(f.get("damage", 1.0)),
		"defense": float(a.get("defense", 1.0)),
		"armor": float(f.get("armor", 1.0)),
	}


# --- Phase 6a: enemy generation ---
# Builds a complete runtime enemy entry from identity alone. This is the
# single constructor for enemies going forward -- derived combat values
# are filled from the Combat Level at startup by
# main._apply_cl_derivation(), so everything here is identity + state.
#
# Phase 6b will genericize main.gd's per-enemy code paths, and 6c adds
# true runtime spawning; until then this feeds default_enemies().
func generate_enemy(display_name: String, cl: int, archetype: String, faction: String) -> Dictionary:
	return {
		"name": display_name,
		"cl": cl,
		"archetype": archetype,
		"faction": faction,
		"max_health": 0,
		"current_health": 0,
		"max_action": 0,
		"current_action": 0,
		"attack_min_damage": 0,
		"attack_max_damage": 0,
		"defense": 0,
		"armor_rating": 0,
		"resistances": {},
		"dodge": 0.0,
		"block": 0.0,
		"crit_resist": 0.0,
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
	}


func default_enemies() -> Dictionary:
	# Both starting enemies now come out of the generator rather than
	# hand-written dictionaries (Phase 6a). Adding an enemy is one line.
	return {
		"dummy": generate_enemy("Scrap Thief", 1, "Brawler", "Rust Syndicate"),
		"enemy2": generate_enemy("Rust Marauder", 5, "Assault", "Rust Syndicate"),
	}


# --- Phase 7: rank marks & threat ---
# The player never sees a Combat Level number. What they see instead is a
# RANK MARK -- a terse symbol that communicates roughly how far up the
# scale an enemy sits without exposing the underlying CL. Inspired by
# Neocron's rank marks; the SYMBOLS are the borrowed idea, but the
# thresholds below are fitted to Steamtek's own CL anchor table so each
# mark lines up with a real tier of the progression curve rather than
# Neocron's spacing.
#
# Entries are [minimum_cl, mark], highest first for a simple scan.
const RANK_MARKS: Array = [
	[95, "***"],
	[85, "**"],
	[71, "*"],
	[56, "<<<<"],
	[41, "<<<"],
	[31, "<<"],
	[21, "<"],
	[16, "////"],
	[11, "///"],
	[6, "//"],
	[1, "/"],
]


# Threat tiers, evaluated as enemy CL / effective player CL. Reuses the
# five-colour language the old CON system already used, so the palette
# stays familiar -- only the input changed (CL instead of a hand-set
# difficulty number). Entries are [max_ratio, label, color].
const THREAT_TIERS: Array = [
	[0.50, "Trivial", Color(0.50, 0.50, 0.50)],
	[0.80, "Easy", Color(0.20, 0.90, 0.20)],
	[1.25, "Even", Color(1.00, 1.00, 0.20)],
	[2.00, "Dangerous", Color(1.00, 0.60, 0.00)],
]
const THREAT_DEADLY: Array = ["Deadly", Color(1.00, 0.10, 0.10)]


# How much effective Combat Level one spent skill point is worth. Street
# Thug offers ~44 points across its four keystones, so a fully-spent
# Street Thug lands near CL 40 -- the top of the current anchor table --
# leaving CL 41-100 for the professions above it. Tunable as later tiers
# are built out.
const PLAYER_CL_PER_SKILL_POINT: float = 0.9
const PLAYER_CL_MAX: int = 100


# ============================================================
# Phase 10: weapon families, proficiency, certification
# ============================================================
# Steamtek-native family list: the 12 weapon classes the game already
# uses ARE the 12 families, rather than the framework's 11-ranged +
# 1-collapsed-melee list, which would have thrown away the six distinct
# melee classes. Each family names the keystone that governs its
# proficiency.
#
# NOTE: Street Thug is a generalist, so its Melee keystone lifts all six
# melee families equally (same for Ranged). Families are still tracked
# INDIVIDUALLY here so that per-family nodes in later specialist
# professions (Sniper, Bombardier, etc.) become a source swap rather
# than a restructure.
const WEAPON_FAMILIES: Dictionary = {
	"Sword": {"keystone": "Melee", "range": "Melee"},
	"Axe": {"keystone": "Melee", "range": "Melee"},
	"Hammer": {"keystone": "Melee", "range": "Melee"},
	"Brass Knuckles": {"keystone": "Melee", "range": "Melee"},
	"Stun Stick": {"keystone": "Melee", "range": "Melee"},
	"Baton": {"keystone": "Melee", "range": "Melee"},
	"Pistol": {"keystone": "Ranged", "range": "Ranged"},
	"Assault Rifle": {"keystone": "Ranged", "range": "Ranged"},
	"Sniper Rifle": {"keystone": "Ranged", "range": "Ranged"},
	"Shotgun": {"keystone": "Ranged", "range": "Ranged"},
	"Grenade Launcher": {"keystone": "Ranged", "range": "Ranged"},
	"Flame Thrower": {"keystone": "Ranged", "range": "Ranged"},
}


# Proficiency tiers, keyed by points spent in the governing keystone.
# "min_points" is inclusive; the highest tier whose min_points is met
# wins. accuracy adds to the hit-chance formula; speed_pct reduces the
# attack cooldown (a better-trained attacker swings the same weapon
# faster, per the SWG proficiency concept).
const PROFICIENCY_TIERS: Array = [
	{"tier": 0, "label": "Untrained", "min_points": 0, "accuracy": 0, "speed_pct": 0.00},
	{"tier": 1, "label": "I", "min_points": 1, "accuracy": 10, "speed_pct": 0.03},
	{"tier": 2, "label": "II", "min_points": 5, "accuracy": 25, "speed_pct": 0.07},
	{"tier": 3, "label": "III", "min_points": 10, "accuracy": 45, "speed_pct": 0.12},
	{"tier": 4, "label": "IV", "min_points": 15, "accuracy": 70, "speed_pct": 0.18},
]


# Graded penalty for wielding a weapon the character is NOT certified
# for, replacing the old blanket half-damage placeholder. The damage hit
# is softer than the old 0.5 because the accuracy, action-cost and
# special-lockout penalties now carry real weight on their own.
const UNCERTIFIED_PENALTY: Dictionary = {
	"accuracy": -35,
	"action_cost_multiplier": 1.5,
	"max_ability_coefficient": 1.0,
	"damage_multiplier": 0.75,
}


# Returns the family record for a weapon class, or an empty dictionary if
# the class is unknown (e.g. unarmed with nothing equipped).
func family_for_class(weapon_class: String) -> Dictionary:
	return WEAPON_FAMILIES.get(weapon_class, {})


# ============================================================
# Phase 9: loot quality scaling by Combat Level
# ============================================================
# Higher-CL enemies roll the better loot TIERS more often. Per the
# framework, CL raises loot QUALITY/grade, not quantity -- drop amounts
# are untouched, and UltraRare keeps its own independent per-entry roll.
#
# Bands are inclusive of max_cl; anything above the last band uses the
# last band. Chances within a band must sum to <= 1.0; whatever is left
# over is a no-drop chance (currently 0.0).
const LOOT_TIER_BANDS: Array = [
	{"max_cl": 5, "Common": 0.85, "Uncommon": 0.13, "Rare": 0.02},
	{"max_cl": 10, "Common": 0.78, "Uncommon": 0.18, "Rare": 0.04},
	{"max_cl": 20, "Common": 0.70, "Uncommon": 0.23, "Rare": 0.07},
	{"max_cl": 30, "Common": 0.60, "Uncommon": 0.28, "Rare": 0.12},
	{"max_cl": 40, "Common": 0.50, "Uncommon": 0.32, "Rare": 0.18},
	{"max_cl": 100, "Common": 0.40, "Uncommon": 0.35, "Rare": 0.25},
]
