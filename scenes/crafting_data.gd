class_name CraftingData
extends RefCounted

# =============================================================
# STEAMTEK CRAFTING -- STATIC DATA (Spec Phase 1: data foundation)
# =============================================================
# Everything here is DEFINITION data: what traits exist, what material
# families exist, what blueprints exist. Nothing in this file changes at
# runtime.
#
# Runtime shapes (material batches, crafted items, the player profile)
# live in crafting_models.gd. Operations live in crafting_service.gd.
#
# WHY DICTIONARIES AND NOT Resource/.tres:
#   - the save file is JSON, and Dictionaries serialize to it natively
#   - no editor assets to manage by hand
#   - no shared-mutable-state footgun with per-item instances
#
# No autoload registration needed -- `class_name` makes this reachable
# as CraftingData.THING from anywhere.
#
# ALL numbers here are PLACEHOLDERS subject to tuning, per spec s24.


# --- Scales ---
# Material Quality is 0-100 (spec s24). NOTE this is a DIFFERENT scale
# from the legacy weapon "Quality" stat (0-1000) still used by equipment
# generated outside this system. Do not mix them.
const QUALITY_MIN: int = 0
const QUALITY_MAX: int = 100

# Blueprint familiarity, also 0-100 (spec s6.3).
const FAMILIARITY_MIN: int = 0
const FAMILIARITY_MAX: int = 100


# --- Quality tiers ---
# Player-facing banding for a finished craft. Entries are
# [minimum_score, tier_id, display_name], highest first.
const QUALITY_TIERS: Array = [
	[90, "exceptional", "Exceptional"],
	[75, "great", "Great"],
	[55, "good", "Good"],
	[35, "standard", "Standard"],
	[15, "poor", "Poor"],
	[0, "crude", "Crude"],
]


# --- Traits ---
# A material's PRIMARY TRAIT is the thing it is good at. Traits map to
# the stats a blueprint can push during experimentation later; for now
# they carry an id, a display name, and the stat they influence.
const TRAITS: Dictionary = {
	"conductive": {
		"display_name": "Conductive",
		"influences": "Arc Damage",
		"description": "Carries current well. Favoured in arc and powered work.",
	},
	"tough": {
		"display_name": "Tough",
		"influences": "Durability",
		"description": "Resists deformation and wear.",
	},
	"pliable": {
		"display_name": "Pliable",
		"influences": "Speed",
		"description": "Works easily. Lighter, faster results.",
	},
	"dense": {
		"display_name": "Dense",
		"influences": "Damage Rating",
		"description": "Heavy and solid. Hits harder, moves slower.",
	},
	"heat_stable": {
		"display_name": "Heat Stable",
		"influences": "Thermal Resistance",
		"description": "Holds shape under sustained heat.",
	},
	"pressure_rated": {
		"display_name": "Pressure Rated",
		"influences": "Pressure Capacity",
		"description": "Rated for high internal pressure without failure.",
	},
}


# --- Instabilities ---
# The drawback side of a material (spec s5.3). A batch may carry one.
# These are deliberately player-readable rather than a stat spreadsheet.
const INSTABILITIES: Dictionary = {
	"brittle": {
		"display_name": "Brittle",
		"description": "Fractures under shock. Lowers durability.",
	},
	"corroded": {
		"display_name": "Corroded",
		"description": "Surface decay. Degrades faster in use.",
	},
	"unstable_current": {
		"display_name": "Unstable Current",
		"description": "Arcs unpredictably. Occasional output spikes.",
	},
	"porous": {
		"display_name": "Porous",
		"description": "Absorbs contaminants. Weakens under pressure.",
	},
	"work_hardened": {
		"display_name": "Work Hardened",
		"description": "Already stressed. Resists further shaping.",
	},
}


# --- Resource families ---
# A FAMILY is the kind of material ("Copper"). A BATCH is a specific
# recovered lot of it with its own quality and provenance -- see
# crafting_models.new_material_batch().
#
# "eligible_traits" are the primary traits a batch of this family can
# roll. "eligible_instabilities" likewise. "name_prefixes" feed the
# generated batch name (spec s5.4: "Aurelian Conductive Copper").
const RESOURCE_FAMILIES: Dictionary = {
	"copper": {
		"display_name": "Copper",
		"category": "Metal",
		"eligible_traits": ["conductive", "pliable"],
		"eligible_instabilities": ["corroded", "unstable_current"],
		"name_prefixes": ["Aurelian", "Redseam", "Deepvein", "Bright"],
		"best_use_tags": ["wiring", "arc_components", "contacts"],
	},
	"black_iron": {
		"display_name": "Black Iron",
		"category": "Metal",
		"eligible_traits": ["tough", "dense"],
		"eligible_instabilities": ["brittle", "work_hardened"],
		"name_prefixes": ["Slagfall", "Coldforge", "Underquarry", "Dull"],
		"best_use_tags": ["frames", "hafts", "structural"],
	},
	"gunmetal_steel": {
		"display_name": "Gunmetal Steel",
		"category": "Metal",
		"eligible_traits": ["tough", "dense", "heat_stable"],
		"eligible_instabilities": ["brittle", "work_hardened"],
		"name_prefixes": ["Foundry", "Blacklot", "Reclaimed", "Tempered"],
		"best_use_tags": ["blades", "barrels", "pressure_housings"],
	},
	"aluminum": {
		"display_name": "Aluminum",
		"category": "Metal",
		"eligible_traits": ["pliable", "conductive"],
		"eligible_instabilities": ["porous", "brittle"],
		"name_prefixes": ["Palefoil", "Skimmed", "Lightcast", "Thin"],
		"best_use_tags": ["housings", "light_frames"],
	},
	"quartz": {
		"display_name": "Quartz",
		"category": "Mineral",
		"eligible_traits": ["heat_stable", "conductive"],
		"eligible_instabilities": ["brittle", "porous"],
		"name_prefixes": ["Clearcut", "Smoked", "Fracture", "Glass"],
		"best_use_tags": ["regulators", "optics", "arc_focus"],
	},
}


# --- Blueprints ---
# A blueprint defines WHAT is made and WHICH material slots feed it.
# It references an existing item by "output_item_id" so the crafting
# system produces things the rest of the game already understands.
#
# material_slots entries:
#   slot_id     stable id, used as the key when selecting materials
#   slot_name   player-facing ("Blade", "Hilt")
#   accepts     array of family ids that may fill this slot
#   amount      units required
#   weight      how strongly this slot influences final quality (0-1);
#               weights across a blueprint should total 1.0
#
# "difficulty" (0-100) feeds experimentation point generation and the
# difficulty penalty later (spec s17). Unused in Phase 1.
const BLUEPRINTS: Dictionary = {
	"bp_piston_blade": {
		"display_name": "Piston Blade",
		"output_item_id": "Piston Blade",
		"difficulty": 20,
		"material_slots": [
			{"slot_id": "blade", "slot_name": "Blade", "accepts": ["gunmetal_steel", "black_iron"], "amount": 4, "weight": 0.6},
			{"slot_id": "hilt", "slot_name": "Hilt", "accepts": ["black_iron", "aluminum"], "amount": 2, "weight": 0.25},
			{"slot_id": "binding", "slot_name": "Binding", "accepts": ["copper", "aluminum"], "amount": 1, "weight": 0.15},
		],
		"guaranteed_sockets": 0,
		"max_sockets": 3,
	},
	"bp_arc_rod": {
		"display_name": "Arc Rod",
		"output_item_id": "Arc Rod",
		"difficulty": 30,
		"material_slots": [
			{"slot_id": "core", "slot_name": "Conductive Core", "accepts": ["copper"], "amount": 3, "weight": 0.5},
			{"slot_id": "shaft", "slot_name": "Shaft", "accepts": ["black_iron", "aluminum"], "amount": 2, "weight": 0.3},
			{"slot_id": "regulator", "slot_name": "Regulator", "accepts": ["quartz"], "amount": 1, "weight": 0.2},
		],
		"guaranteed_sockets": 0,
		"max_sockets": 3,
	},
}


# --- Lookup helpers ---

static func get_family(family_id: String) -> Dictionary:
	return RESOURCE_FAMILIES.get(family_id, {})


static func get_trait(trait_id: String) -> Dictionary:
	return TRAITS.get(trait_id, {})


static func get_instability(instability_id: String) -> Dictionary:
	return INSTABILITIES.get(instability_id, {})


static func get_blueprint(blueprint_id: String) -> Dictionary:
	return BLUEPRINTS.get(blueprint_id, {})


# Returns the tier id for a 0-100 score, e.g. 82 -> "great".
static func quality_tier_for(score: float) -> String:
	for entry in QUALITY_TIERS:
		if score >= float(entry[0]):
			return String(entry[1])
	return String(QUALITY_TIERS[QUALITY_TIERS.size() - 1][1])


# Player-facing name for a tier id.
static func quality_tier_name(tier_id: String) -> String:
	for entry in QUALITY_TIERS:
		if String(entry[1]) == tier_id:
			return String(entry[2])
	return tier_id


# --- Expanded resource families (Phase 2) ---
# Enough breadth that thematic floor pools actually differ from each
# other. Families are grouped loosely by category; "tier" indicates how
# deep in the Silo a family generally becomes available:
#   0 = surface/shallow, 1 = mid, 2 = deep (Builders-era technology)
const RESOURCE_FAMILIES_EXTRA: Dictionary = {
	"titanium": {
		"display_name": "Titanium",
		"category": "Metal", "tier": 2,
		"eligible_traits": ["tough", "heat_stable", "pressure_rated"],
		"eligible_instabilities": ["work_hardened"],
		"name_prefixes": ["Deepcore", "Whitegrain", "Builder", "Sealed"],
		"best_use_tags": ["advanced_frames", "pressure_housings"],
	},
	"silver_alloy": {
		"display_name": "Silver Alloy",
		"category": "Metal", "tier": 2,
		"eligible_traits": ["conductive", "pliable"],
		"eligible_instabilities": ["corroded"],
		"name_prefixes": ["Mirrorseam", "Palecast", "Fine", "Vault"],
		"best_use_tags": ["contacts", "arc_focus", "precision_wiring"],
	},
	"pressure_alloy": {
		"display_name": "Pressure Alloy",
		"category": "Metal", "tier": 1,
		"eligible_traits": ["pressure_rated", "tough"],
		"eligible_instabilities": ["brittle", "work_hardened"],
		"name_prefixes": ["Boilerplate", "Ridgeline", "Stamped", "Riveted"],
		"best_use_tags": ["boilers", "pressure_housings", "valves"],
	},
	"scrap_plating": {
		"display_name": "Scrap Plating",
		"category": "Salvage", "tier": 0,
		"eligible_traits": ["tough", "dense"],
		"eligible_instabilities": ["corroded", "brittle", "porous"],
		"name_prefixes": ["Stripped", "Patchwork", "Torn", "Salvaged"],
		"best_use_tags": ["armor_plate", "makeshift_frames"],
	},
	"electronic_salvage": {
		"display_name": "Electronic Salvage",
		"category": "Salvage", "tier": 0,
		"eligible_traits": ["conductive"],
		"eligible_instabilities": ["unstable_current", "corroded"],
		"name_prefixes": ["Gutted", "Pulled", "Dead-Rack", "Scav"],
		"best_use_tags": ["circuits", "triggers", "regulators"],
	},
	"conductive_ceramic": {
		"display_name": "Conductive Ceramic",
		"category": "Mineral", "tier": 1,
		"eligible_traits": ["conductive", "heat_stable"],
		"eligible_instabilities": ["brittle", "porous"],
		"name_prefixes": ["Kilnfired", "Greyglaze", "Sintered", "Hard"],
		"best_use_tags": ["insulators", "arc_components"],
	},
	"graphite": {
		"display_name": "Graphite",
		"category": "Mineral", "tier": 1,
		"eligible_traits": ["conductive", "heat_stable"],
		"eligible_instabilities": ["porous", "brittle"],
		"name_prefixes": ["Blackflake", "Seam", "Pressed", "Soft"],
		"best_use_tags": ["brushes", "heat_shielding", "lubricant"],
	},
	"insulating_polymer": {
		"display_name": "Insulating Polymer",
		"category": "Polymer", "tier": 0,
		"eligible_traits": ["pliable", "heat_stable"],
		"eligible_instabilities": ["porous", "brittle"],
		"name_prefixes": ["Milkweave", "Extruded", "Cured", "Cheap"],
		"best_use_tags": ["insulation", "grips", "seals"],
	},
	"sealant_compound": {
		"display_name": "Sealant Compound",
		"category": "Polymer", "tier": 1,
		"eligible_traits": ["pressure_rated", "pliable"],
		"eligible_instabilities": ["porous"],
		"name_prefixes": ["Gasketgrade", "Tarline", "Thick", "Refinery"],
		"best_use_tags": ["seals", "pressure_housings"],
	},
	"industrial_solvent": {
		"display_name": "Industrial Solvent",
		"category": "Chemical", "tier": 1,
		"eligible_traits": ["pliable"],
		"eligible_instabilities": ["corroded", "unstable_current"],
		"name_prefixes": ["Stillhead", "Cutgrade", "Raw", "Decanted"],
		"best_use_tags": ["cleaning", "chemical_reagents"],
	},
	"battery_chemicals": {
		"display_name": "Battery Chemicals",
		"category": "Chemical", "tier": 1,
		"eligible_traits": ["conductive"],
		"eligible_instabilities": ["unstable_current", "corroded"],
		"name_prefixes": ["Cellgrade", "Wet", "Packed", "Leaching"],
		"best_use_tags": ["power_cells", "arc_components"],
	},
	"hydraulic_fluid": {
		"display_name": "Hydraulic Fluid",
		"category": "Chemical", "tier": 0,
		"eligible_traits": ["pressure_rated", "pliable"],
		"eligible_instabilities": ["corroded", "porous"],
		"name_prefixes": ["Drained", "Bled", "Amber", "Reclaimed"],
		"best_use_tags": ["pistons", "actuators"],
	},
	"cultivated_fiber": {
		"display_name": "Cultivated Fiber",
		"category": "Organic", "tier": 0,
		"eligible_traits": ["pliable", "tough"],
		"eligible_instabilities": ["porous"],
		"name_prefixes": ["Vat-Grown", "Trellis", "Longstrand", "Pale"],
		"best_use_tags": ["bindings", "padding", "wrappings"],
	},
	"fungal_culture": {
		"display_name": "Fungal Culture",
		"category": "Organic", "tier": 0,
		"eligible_traits": ["pliable"],
		"eligible_instabilities": ["porous", "corroded"],
		"name_prefixes": ["Blackbloom", "Ductgrown", "Damp", "Spore"],
		"best_use_tags": ["reagents", "antiseptics"],
	},
	"medical_reagent": {
		"display_name": "Medical Reagent",
		"category": "Organic", "tier": 1,
		"eligible_traits": ["pliable", "heat_stable"],
		"eligible_instabilities": ["corroded"],
		"name_prefixes": ["Sterile", "Ward", "Sealed", "Clinical"],
		"best_use_tags": ["medicine", "stimulants"],
	},
	"superconductive_filament": {
		"display_name": "Superconductive Filament",
		"category": "Steamtek", "tier": 2,
		"eligible_traits": ["conductive"],
		"eligible_instabilities": ["unstable_current"],
		"name_prefixes": ["Hairline", "Builder-Spun", "Coldrun", "Intact"],
		"best_use_tags": ["arc_focus", "advanced_circuits"],
	},
	"steamtek_power_core": {
		"display_name": "Steamtek Power Core",
		"category": "Steamtek", "tier": 2,
		"eligible_traits": ["pressure_rated", "conductive"],
		"eligible_instabilities": ["unstable_current"],
		"name_prefixes": ["Humming", "Dormant", "Sealed", "Ancient"],
		"best_use_tags": ["power_cells", "experimental"],
	},
}


# --- Silo structure ---
# 60 floors across three eras. Deeper is OLDER but cleaner and more
# advanced -- the Builders' original works sit beneath everything the
# later occupants bolted on top.
const SILO_FLOOR_COUNT: int = 60

const ERAS: Dictionary = {
	"survivors": {
		"display_name": "Survivors",
		"floor_min": 1, "floor_max": 20,
		"description": "Recent, makeshift, heavily scavenged.",
		"quality_bias": -8,
	},
	"expansion": {
		"display_name": "Expansion",
		"floor_min": 21, "floor_max": 40,
		"description": "The industrial build-out. Heavy plant and utilities.",
		"quality_bias": 0,
	},
	"builders": {
		"display_name": "Builders",
		"floor_min": 41, "floor_max": 60,
		"description": "Original construction. Older, cleaner, better made.",
		"quality_bias": 12,
	},
}


# --- Floor identities ---
# Each identity belongs to one or more eras and has an eligible resource
# pool. "excluded" is informational -- anything not in common/rare is
# already unavailable -- but it documents intent.
const FLOOR_IDENTITIES: Dictionary = {
	"residential_warren": {
		"display_name": "Residential Warren", "eras": ["survivors"],
		"common": ["scrap_plating", "insulating_polymer", "cultivated_fiber", "electronic_salvage"],
		"rare": ["copper"],
	},
	"waste_reclamation": {
		"display_name": "Waste Reclamation", "eras": ["survivors"],
		"common": ["scrap_plating", "industrial_solvent", "fungal_culture", "hydraulic_fluid"],
		"rare": ["battery_chemicals"],
	},
	"transit_spine": {
		"display_name": "Transit Spine", "eras": ["survivors", "expansion"],
		"common": ["black_iron", "scrap_plating", "hydraulic_fluid", "gunmetal_steel"],
		"rare": ["pressure_alloy"],
	},
	"abandoned_mixed_use": {
		"display_name": "Abandoned Mixed-Use", "eras": ["survivors", "expansion"],
		"common": ["scrap_plating", "electronic_salvage", "insulating_polymer", "copper"],
		"rare": ["quartz"],
	},
	"hydroponics": {
		"display_name": "Hydroponics", "eras": ["survivors", "expansion"],
		"common": ["cultivated_fiber", "fungal_culture", "industrial_solvent"],
		"rare": ["medical_reagent"],
	},
	"electrical_works": {
		"display_name": "Electrical Works", "eras": ["expansion"],
		"common": ["copper", "insulating_polymer", "conductive_ceramic", "battery_chemicals", "electronic_salvage"],
		"rare": ["silver_alloy", "superconductive_filament"],
	},
	"refinery": {
		"display_name": "Refinery", "eras": ["expansion"],
		"common": ["industrial_solvent", "sealant_compound", "hydraulic_fluid", "graphite"],
		"rare": ["pressure_alloy"],
	},
	"heavy_manufacturing": {
		"display_name": "Heavy Manufacturing", "eras": ["expansion"],
		"common": ["black_iron", "gunmetal_steel", "pressure_alloy", "graphite"],
		"rare": ["titanium"],
	},
	"utility_and_power": {
		"display_name": "Utility and Power", "eras": ["expansion", "builders"],
		"common": ["copper", "battery_chemicals", "conductive_ceramic", "pressure_alloy"],
		"rare": ["superconductive_filament", "steamtek_power_core"],
	},
	"medical_ward": {
		"display_name": "Medical Ward", "eras": ["expansion"],
		"common": ["medical_reagent", "fungal_culture", "aluminum", "insulating_polymer"],
		"rare": ["silver_alloy"],
	},
	"deep_extraction": {
		"display_name": "Deep Extraction", "eras": ["builders"],
		"common": ["black_iron", "quartz", "graphite", "titanium", "gunmetal_steel"],
		"rare": ["silver_alloy"],
	},
	"research_vault": {
		"display_name": "Research Vault", "eras": ["builders"],
		"common": ["quartz", "conductive_ceramic", "silver_alloy", "aluminum"],
		"rare": ["superconductive_filament", "steamtek_power_core"],
	},
	"data_infrastructure": {
		"display_name": "Data Infrastructure", "eras": ["builders"],
		"common": ["copper", "silver_alloy", "conductive_ceramic", "electronic_salvage"],
		"rare": ["superconductive_filament"],
	},
	"arc_works": {
		"display_name": "Arc Works", "eras": ["builders"],
		"common": ["copper", "conductive_ceramic", "graphite", "battery_chemicals"],
		"rare": ["superconductive_filament", "steamtek_power_core"],
	},
	"builders_foundry": {
		"display_name": "Builders' Foundry", "eras": ["builders"],
		"common": ["titanium", "gunmetal_steel", "pressure_alloy", "graphite"],
		"rare": ["steamtek_power_core"],
	},
}


# --- Progression guarantees (spec s4.3) ---
# Families the campaign MUST make reachable, and how many sources are
# required. "by_floor" is the deepest floor by which the guarantee must
# already be satisfiable.
# THRESHOLDS ARE TUNED TO THE QUALITY CURVE, deliberately. A common
# Survivors-era source tops out around 72 (base 35-80 minus the era's
# -8 bias), so demanding 80+ that early would make the repair step fire
# on nearly every seed -- at which point the "safeguard" is really the
# generator. These sit just inside what each era can produce naturally,
# so repairs stay the rare exception they are meant to be.
const RESOURCE_GUARANTEES: Array = [
	{"family_id": "copper", "min_quality": 65, "min_sources": 1, "by_floor": 15},
	{"family_id": "black_iron", "min_quality": 65, "min_sources": 1, "by_floor": 30},
	{"family_id": "gunmetal_steel", "min_quality": 0, "min_sources": 2, "by_floor": 40},
	{"family_id": "scrap_plating", "min_quality": 0, "min_sources": 2, "by_floor": 20},
	{"family_id": "insulating_polymer", "min_quality": 0, "min_sources": 1, "by_floor": 20},
	{"family_id": "quartz", "min_quality": 0, "min_sources": 2, "by_floor": 50},
	# High-quality material is a reward for depth, not an early promise.
	{"family_id": "gunmetal_steel", "min_quality": 80, "min_sources": 1, "by_floor": 60},
]


# Returns the merged family table (Phase 1 base + Phase 2 additions).
static func all_families() -> Dictionary:
	var merged = RESOURCE_FAMILIES.duplicate(true)
	for k in RESOURCE_FAMILIES_EXTRA.keys():
		merged[k] = RESOURCE_FAMILIES_EXTRA[k]
	return merged


# Era id that owns a floor number, or "" if out of range.
static func era_for_floor(floor_number: int) -> String:
	for era_id in ERAS.keys():
		var e = ERAS[era_id]
		if floor_number >= int(e["floor_min"]) and floor_number <= int(e["floor_max"]):
			return era_id
	return ""


# Floor identities valid for an era.
static func identities_for_era(era_id: String) -> Array:
	var out: Array = []
	for ident_id in FLOOR_IDENTITIES.keys():
		if FLOOR_IDENTITIES[ident_id].get("eras", []).has(era_id):
			out.append(ident_id)
	out.sort()
	return out
