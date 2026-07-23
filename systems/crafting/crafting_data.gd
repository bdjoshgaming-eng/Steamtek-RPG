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
	# --- Medicine. Consumables take NO mod sockets. Bandages are the
	# cheapest recipe in the game deliberately: medicine became
	# unobtainable when the old crafting system was cut, and this is what
	# ends that drought.
	"bp_bandages": {
		"display_name": "Crate of Bandages",
		"output_item_id": "Crate of Bandages",
		"difficulty": 10,
		"material_slots": [
			{"slot_id": "fiber", "slot_name": "Fiber", "accepts": ["cultivated_fiber"], "amount": 3, "weight": 0.7},
			{"slot_id": "binding", "slot_name": "Binding", "accepts": ["cultivated_fiber", "insulating_polymer"], "amount": 1, "weight": 0.3},
		],
		"experimentation_categories": ["efficiency", "status_potency"],
		"guaranteed_sockets": 0,
		"max_sockets": 0,
	},
	"bp_antiseptic_salve": {
		"display_name": "Antiseptic Salve",
		"output_item_id": "Antiseptic Salve",
		"difficulty": 25,
		"material_slots": [
			{"slot_id": "reagent", "slot_name": "Reagent", "accepts": ["medical_reagent"], "amount": 2, "weight": 0.5},
			{"slot_id": "culture", "slot_name": "Culture", "accepts": ["fungal_culture"], "amount": 2, "weight": 0.35},
			{"slot_id": "base", "slot_name": "Base", "accepts": ["industrial_solvent"], "amount": 1, "weight": 0.15},
		],
		"experimentation_categories": ["status_potency", "efficiency", "durability"],
		"guaranteed_sockets": 0,
		"max_sockets": 0,
	},
	# --- Core mods. The reagent slot determines the damage type via
	# FAMILY_DAMAGE_TYPE. The housing provides structural support and
	# influences quality but not the type.
	"bp_core_mod": {
		"display_name": "Weapon Core",
		"output_type": "mod",
		"difficulty": 35,
		"material_slots": [
			{"slot_id": "reagent", "slot_name": "Reagent", "accepts": [
				"copper", "silver_alloy", "electronic_salvage", "conductive_ceramic",
				"superconductive_filament", "battery_chemicals",
				"graphite", "quartz",
				"pressure_alloy", "sealant_compound", "hydraulic_fluid",
				"gunmetal_steel", "titanium",
				"industrial_solvent", "fungal_culture", "medical_reagent",
				"black_iron", "aluminum", "scrap_plating",
			], "amount": 3, "weight": 0.7},
			{"slot_id": "housing", "slot_name": "Housing", "accepts": [
				"black_iron", "aluminum", "copper", "insulating_polymer",
				"scrap_plating", "pressure_alloy",
			], "amount": 2, "weight": 0.3},
		],
		"experimentation_categories": ["efficiency", "durability"],
		"guaranteed_sockets": 0,
		"max_sockets": 0,
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


# --- Surface salvage -------------------------------------------------
# The Surface is not part of the Silo's 60 floors, so it has no generated
# sources. These are a small SYNTHETIC set: picked-over street salvage,
# low quality by design, that lets a player craft before ever descending.
# They never touch the seeded Silo map.
const SURFACE_FLOOR_ID: String = "surface"
const SURFACE_QUALITY_MIN: int = 12
const SURFACE_QUALITY_MAX: int = 34

# family_id -> location flavour for the surface salvage points.
const SURFACE_SOURCES: Array = [
	{"family_id": "scrap_plating", "location_name": "Alley Dumpster", "capacity": 40, "source_type": "repeatable_salvage"},
	{"family_id": "cultivated_fiber", "location_name": "Alley Dumpster", "capacity": 30, "source_type": "repeatable_salvage"},
	{"family_id": "copper", "location_name": "Stripped Wiring", "capacity": 24, "source_type": "repeatable_salvage"},
	{"family_id": "black_iron", "location_name": "Rusted Railing", "capacity": 24, "source_type": "repeatable_salvage"},
	{"family_id": "insulating_polymer", "location_name": "Alley Dumpster", "capacity": 20, "source_type": "repeatable_salvage"},
]


# =============================================================
# EXPERIMENTATION (Spec Phase 4, stages 4-6)
# =============================================================
# Experimentation is what turns crafting from "materials in, fixed
# result out" into a decision. Materials set the CEILING (potential);
# experimentation decides how much of it you actually realise.
#
# ANTI-SAVE-SCUM RULE (spec s2.5 / s10.7): every roll derives from the
# item's stored craft_seed plus the player's recorded choices. Reload
# and allocate identically -> identical result. Allocate DIFFERENTLY ->
# different result, which is correct: that is a real choice, not a
# reroll.


# --- Categories ---
# The eight from the spec. Not every blueprint offers every category --
# each blueprint lists its own in "experimentation_categories".
#
# "affects" names the stat the category pushes. "mod_architecture" is
# special: it feeds socket generation in Phase 5 rather than a stat.
const EXPERIMENTATION_CATEGORIES: Dictionary = {
	"output_damage": {
		"display_name": "Output",
		"affects": "Damage Rating",
		"description": "Raises the damage the finished weapon deals on every hit.",
	},
	"accuracy": {
		"display_name": "Precision",
		"affects": "Accuracy",
		"description": "Raises accuracy, so the weapon misses less often.",
	},
	"efficiency": {
		"display_name": "Efficiency",
		"affects": "Action Cost",
		"description": "Lowers the Action cost of using the item.",
	},
	"thermal_control": {
		"display_name": "Thermal Control",
		"affects": "Thermal Resistance",
		"description": "Improves heat tolerance, resisting Thermal damage and sustained fire.",
	},
	"durability": {
		"display_name": "Durability",
		"affects": "Max Durability",
		"description": "Raises maximum durability, so the item lasts longer before repair.",
	},
	"handling": {
		"display_name": "Handling",
		"affects": "Speed",
		"description": "Improves speed, letting you attack more often.",
	},
	"status_potency": {
		"display_name": "Potency",
		"affects": "Effect Strength",
		"description": "Strengthens the item's effect -- healing restored, wounds inflicted, status applied.",
	},
	"mod_architecture": {
		"display_name": "Mod Architecture",
		"affects": "Socket Chance",
		"description": "Improves the odds of extra mod sockets on the finished item. The single strongest influence on how many you get.",
	},
}


# --- Result tiers ---
# [minimum_score, tier_id, display_name, stat_multiplier], best first.
# The multiplier scales that category's contribution to the final item.
# Great (1.0) is the intended "you did this properly" result; anything
# above it is a genuine bonus, anything below is a shortfall.
const EXPERIMENTATION_TIERS: Array = [
	[95.0, "breakthrough", "Breakthrough", 1.60],
	[82.0, "exceptional", "Exceptional", 1.30],
	[68.0, "great", "Great", 1.00],
	[52.0, "good", "Good", 0.75],
	[35.0, "standard", "Standard", 0.50],
	[18.0, "poor", "Poor", 0.25],
	[-999.0, "failure", "Failure", 0.00],
]


# --- Risk modes (spec s9) ---
# The player's explicit risk stance. Aggressive raises the ceiling AND
# the floor -- it is not simply better.
#
# score_bonus       flat addition to the category score
# spread            +/- range of the controlled random component
# instability_chance odds a FAILED category adds a flaw to the item
# socket_penalty    subtracted from socket chance on failure (Phase 5)
const RISK_MODES: Dictionary = {
	"stable": {
		"display_name": "Stable",
		"description": "Lower ceiling, far safer. Best with scarce materials.",
		"score_bonus": 5.0,
		"spread": 8.0,
		"instability_chance": 0.0,
		"socket_penalty": 0.05,
	},
	"standard": {
		"display_name": "Standard",
		"description": "Balanced gain and risk.",
		"score_bonus": 0.0,
		"spread": 15.0,
		"instability_chance": 0.25,
		"socket_penalty": 0.10,
	},
	"aggressive": {
		"display_name": "Aggressive",
		"description": "Highest ceiling. Failures bite, and can flaw the item.",
		"score_bonus": 12.0,
		"spread": 30.0,
		"instability_chance": 0.55,
		"socket_penalty": 0.20,
	},
}
const DEFAULT_RISK_MODE: String = "standard"


# --- Point generation (spec stage 4) ---
# Targets the spec's bands: early 3-5, mid 5-8, late specialist 8-12.
# Workshop, tool and keystone sources are defined now but contribute 0
# until Phases 7 and 8 build them -- so the ceiling rises as those
# systems arrive rather than needing a retune.
const EXP_POINTS_BASE: int = 3
const EXP_POINTS_FAMILIARITY_MAX: int = 3
const EXP_POINTS_WORKSHOP_MAX: int = 2
const EXP_POINTS_TOOL_MAX: int = 2
const EXP_POINTS_COMPATIBILITY_MAX: int = 2
const EXP_POINTS_KEYSTONE_MAX: int = 3

# Score contribution per point allocated to a category. Tuned so that
# spending a sensible share of a normal budget lands around Good/Great.
const EXP_SCORE_PER_POINT: float = 17.0

# Blueprint difficulty subtracts from every category score, scaled so a
# difficulty-100 blueprint is a genuine obstacle without being hopeless.
const EXP_DIFFICULTY_WEIGHT: float = 0.25

# Material potential also lifts the score a little -- better materials
# make experimentation easier, not just higher-ceilinged.
const EXP_POTENTIAL_WEIGHT: float = 0.15


# --- Experimentation lookups ---

static func get_category(category_id: String) -> Dictionary:
	return EXPERIMENTATION_CATEGORIES.get(category_id, {})


static func get_risk_mode(risk_mode_id: String) -> Dictionary:
	return RISK_MODES.get(risk_mode_id, RISK_MODES[DEFAULT_RISK_MODE])


# Returns {tier_id, display_name, multiplier} for a score.
static func experimentation_tier_for(score: float) -> Dictionary:
	for entry in EXPERIMENTATION_TIERS:
		if score >= float(entry[0]):
			return {
				"tier_id": String(entry[1]),
				"display_name": String(entry[2]),
				"multiplier": float(entry[3]),
			}
	var last = EXPERIMENTATION_TIERS[EXPERIMENTATION_TIERS.size() - 1]
	return {"tier_id": String(last[1]), "display_name": String(last[2]), "multiplier": float(last[3])}


# Categories a blueprint actually offers, filtered to ones that exist.
static func categories_for_blueprint(blueprint_id: String) -> Array:
	var bp = get_blueprint(blueprint_id)
	var out: Array = []
	for cid in bp.get("experimentation_categories", []):
		if EXPERIMENTATION_CATEGORIES.has(cid):
			out.append(String(cid))
	return out


# --- Trait / category affinity ---
# Which material traits genuinely help which experimentation category.
# This is what makes the SAME material matter differently depending on
# what you are making (spec s18): dense metal helps Output, pliable
# metal helps Handling, and neither helps Potency.
#
# Used for the material-compatibility bonus. A material whose trait has
# no affinity for a category simply contributes nothing there -- it is
# never a penalty.
const TRAIT_CATEGORY_AFFINITY: Dictionary = {
	"output_damage": ["dense", "conductive"],
	"accuracy": ["pliable", "tough"],
	"efficiency": ["pliable", "conductive"],
	"thermal_control": ["heat_stable"],
	"durability": ["tough", "dense"],
	"handling": ["pliable"],
	"status_potency": ["conductive", "heat_stable"],
	"mod_architecture": ["pliable", "conductive"],
}


# =============================================================
# MOD SOCKETS (Spec Phase 5, section 10)
# =============================================================
# Sockets are the reward for investing in Mod Architecture. Per spec
# s10.1: they are valuable, NOT purely random, Mod Architecture is the
# strongest single influence, and maximum-socket items stay rare.
#
# Rolls derive from the item's stored craft_seed, so reopening the UI or
# reloading cannot reroll a socket count that has already been decided
# (spec s10.6 / s10.7).


const MOD_TYPES: Dictionary = {
	"damage": {
		"melee_name": "Edge",
		"ranged_name": "Barrel",
		"stat": "Damage Rating",
		"eligible_range": ["melee", "ranged"],
	},
	"accuracy": {
		"melee_name": "Counterweight",
		"ranged_name": "Gyro",
		"stat": "Accuracy",
		"eligible_range": ["melee", "ranged"],
	},
	"speed": {
		"melee_name": "Spring Mechanism",
		"ranged_name": "Valve Assembly",
		"stat": "Speed",
		"eligible_range": ["melee", "ranged"],
	},
	"ammo": {
		"melee_name": "",
		"ranged_name": "Magazine",
		"stat": "Ammo Capacity",
		"eligible_range": ["ranged"],
	},
	"range": {
		"melee_name": "",
		"ranged_name": "Scope",
		"stat": "Range",
		"eligible_range": ["ranged"],
	},
	"core": {
		"melee_name": "Core",
		"ranged_name": "Core",
		"stat": "Damage Type",
		"eligible_range": ["melee", "ranged"],
	},
}


static func get_mod_type(mod_type_id: String) -> Dictionary:
	return MOD_TYPES.get(mod_type_id, {})


static func mod_display_name(mod_type_id: String, weapon_range: String) -> String:
	var mt: Dictionary = MOD_TYPES.get(mod_type_id, {})
	if mt.is_empty():
		return mod_type_id
	if weapon_range == "Melee":
		return String(mt.get("melee_name", mod_type_id))
	return String(mt.get("ranged_name", mod_type_id))


# --- Socket probability bands (spec s10.5) ---
# Entries are [minimum_opportunity_score, band_id, weights] where weights
# maps ADDITIONAL socket count -> relative weight. Highest band first.
#
# These are the spec's placeholder distributions. Note the ceiling never
# opens up fully: even Exceptional investment only reaches +3 at 10%, so
# a maximum-socket item stays a genuine event.
const SOCKET_BANDS: Array = [
	[75.0, "exceptional", {0: 5, 1: 45, 2: 40, 3: 10}],
	[50.0, "strong", {0: 20, 1: 60, 2: 18, 3: 2}],
	[25.0, "moderate", {0: 55, 1: 40, 2: 5}],
	[-999.0, "low", {0: 90, 1: 10}],
]


# --- Opportunity score weights (spec s10.4) ---
# Mod Architecture allocation is deliberately the largest term.
const SOCKET_POINTS_WEIGHT: float = 12.0        # per point in mod_architecture
const SOCKET_TIER_WEIGHT: float = 10.0          # x the experimentation tier multiplier
const SOCKET_FAMILIARITY_WEIGHT: float = 0.15
const SOCKET_COMPATIBILITY_WEIGHT: float = 15.0
const SOCKET_WORKSHOP_WEIGHT: float = 5.0       # Phase 8
const SOCKET_DIFFICULTY_WEIGHT: float = 0.20
const SOCKET_INSTABILITY_PENALTY: float = 5.0   # per instability on the item


# Maps material families to the damage type they produce when used as
# the primary reagent in a Core mod craft. Families not listed here
# cannot be used as a Core reagent.
const FAMILY_DAMAGE_TYPE: Dictionary = {
	"copper": "Arc",
	"silver_alloy": "Arc",
	"electronic_salvage": "Arc",
	"conductive_ceramic": "Arc",
	"superconductive_filament": "Arc",
	"battery_chemicals": "Arc",
	"graphite": "Thermal",
	"quartz": "Thermal",
	"pressure_alloy": "Pressure",
	"sealant_compound": "Pressure",
	"hydraulic_fluid": "Pressure",
	"gunmetal_steel": "Ballistic",
	"titanium": "Ballistic",
	"industrial_solvent": "Chemical",
	"fungal_culture": "Chemical",
	"medical_reagent": "Chemical",
	"black_iron": "Kinetic",
	"aluminum": "Kinetic",
	"scrap_plating": "Kinetic",
}


static func damage_type_for_family(family_id: String) -> String:
	return FAMILY_DAMAGE_TYPE.get(family_id, "")


static func is_mod_type_eligible(mod_type_id: String, weapon_range: String) -> bool:
	var mt: Dictionary = MOD_TYPES.get(mod_type_id, {})
	if mt.is_empty():
		return false
	return mt.get("eligible_range", []).has(weapon_range.to_lower())


# Returns {band_id, weights} for an opportunity score.
static func socket_band_for(score: float) -> Dictionary:
	for entry in SOCKET_BANDS:
		if score >= float(entry[0]):
			return {"band_id": String(entry[1]), "weights": entry[2]}
	var last = SOCKET_BANDS[SOCKET_BANDS.size() - 1]
	return {"band_id": String(last[1]), "weights": last[2]}


# Builds the full hover text for an experimentation category: what it
# does, which stat it moves, and which material traits actually help it.
# The trait list is the useful part -- it tells the player what to go
# looking for before they commit points.
static func category_tooltip(category_id: String) -> String:
	var cat = get_category(category_id)
	if cat.is_empty():
		return ""
	var lines: Array = []
	lines.append(String(cat.get("display_name", category_id)))
	lines.append("")
	lines.append(String(cat.get("description", "")))
	lines.append("")
	lines.append("Affects: " + String(cat.get("affects", "")))

	var helpful: Array = TRAIT_CATEGORY_AFFINITY.get(category_id, [])
	if helpful.is_empty():
		lines.append("Helped by: no particular material trait")
	else:
		var names: Array = []
		for t in helpful:
			names.append(String(get_trait(String(t)).get("display_name", t)))
		lines.append("Helped by: " + ", ".join(names))
	return "\n".join(lines)


# =============================================================
# MODS (Spec Phase 6, section 11)
# =============================================================
# Mods slot into the sockets Phase 5 produces. Scope for now is WEAPON
# mods only -- the spec also lists Armor and Cybernetics categories, but
# Steamtek has no armor or cybernetic item types yet, so those are
# deliberately left undefined rather than stubbed.


# --- Quality grades (spec s11.3) ---
# [grade_id, display_name, effect_multiplier, drawback_multiplier]
# Prototype is the spec's example of a high-power grade that carries a
# penalty; Masterwork trades a little raw power to remove it entirely.
# That keeps the top grade a genuine choice rather than a strict upgrade.
const MOD_GRADES: Array = [
	["standard", "Standard", 1.00, 1.00],
	["refined", "Refined", 1.40, 1.00],
	["advanced", "Advanced", 1.80, 1.00],
	["prototype", "Prototype", 2.30, 1.60],
	["masterwork", "Masterwork", 2.10, 0.00],
]


# --- Mod definitions (reworked for type-based system) ---
# mod_type       one of the keys in MOD_TYPES (damage/accuracy/speed/ammo/range/core)
# stat_modifiers stat -> amount at Standard grade; scaled by grade multiplier
# drawback       stat -> penalty amount, scaled by grade drawback multiplier
# instability_cost  added strain; feeds durability loss
# damage_type    (core mods only) which damage type this Core sets
const MOD_DEFINITIONS: Dictionary = {
	"edge_standard": {
		"display_name": "Sharpened Edge",
		"mod_type": "damage",
		"stat_modifiers": {"Damage Rating": 2.0},
		"drawback": {"Speed": 0.1},
		"instability_cost": 0.05,
		"description": "A honed striking surface. More force behind each swing.",
	},
	"barrel_standard": {
		"display_name": "Rifled Barrel",
		"mod_type": "damage",
		"stat_modifiers": {"Damage Rating": 2.0},
		"drawback": {"Accuracy": 2.0},
		"instability_cost": 0.05,
		"description": "Tighter bore, heavier impact. Slight aim drift from the recoil.",
	},
	"counterweight_standard": {
		"display_name": "Balanced Counterweight",
		"mod_type": "accuracy",
		"stat_modifiers": {"Accuracy": 5.0},
		"drawback": {"Speed": 0.1},
		"instability_cost": 0.05,
		"description": "Shifts the balance point for steadier swings.",
	},
	"gyro_standard": {
		"display_name": "Stabilising Gyro",
		"mod_type": "accuracy",
		"stat_modifiers": {"Accuracy": 5.0},
		"drawback": {"Speed": 0.1},
		"instability_cost": 0.05,
		"description": "Spin-stabilised aim. Slightly heavier to bring on target.",
	},
	"spring_mechanism_standard": {
		"display_name": "Coiled Spring Mechanism",
		"mod_type": "speed",
		"stat_modifiers": {"Speed": -0.2},
		"drawback": {"Damage Rating": 1.0},
		"instability_cost": 0.05,
		"description": "Faster recovery between strikes. Less weight behind each one.",
	},
	"valve_assembly_standard": {
		"display_name": "Tuned Valve Assembly",
		"mod_type": "speed",
		"stat_modifiers": {"Speed": -0.15},
		"drawback": {"Damage Rating": 1.0},
		"instability_cost": 0.05,
		"description": "Smoother cycling. Fires faster, hits a little lighter.",
	},
	"magazine_standard": {
		"display_name": "Extended Magazine",
		"mod_type": "ammo",
		"stat_modifiers": {"Ammo Capacity": 5.0},
		"drawback": {"Reload Speed": 0.5},
		"instability_cost": 0.0,
		"description": "Holds more rounds. Takes longer to swap out.",
	},
	"scope_standard": {
		"display_name": "Iron Scope",
		"mod_type": "range",
		"stat_modifiers": {"Range": 10.0},
		"drawback": {"Speed": 0.2},
		"instability_cost": 0.0,
		"description": "Extended sighting range. Slower to acquire targets up close.",
	},
	"core_thermal": {
		"display_name": "Thermal Core",
		"mod_type": "core",
		"damage_type": "Thermal",
		"stat_modifiers": {},
		"drawback": {},
		"instability_cost": 0.10,
		"description": "Converts striking energy to heat. Burns on contact.",
	},
	"core_pressure": {
		"display_name": "Pressure Core",
		"mod_type": "core",
		"damage_type": "Pressure",
		"stat_modifiers": {},
		"drawback": {},
		"instability_cost": 0.10,
		"description": "Channels concussive force. Blast damage on impact.",
	},
	"core_arc": {
		"display_name": "Arc Core",
		"mod_type": "core",
		"damage_type": "Arc",
		"stat_modifiers": {},
		"drawback": {},
		"instability_cost": 0.10,
		"description": "Discharges stored current on contact. Electrical damage.",
	},
	"core_chemical": {
		"display_name": "Chemical Core",
		"mod_type": "core",
		"damage_type": "Chemical",
		"stat_modifiers": {},
		"drawback": {},
		"instability_cost": 0.10,
		"description": "Delivers a toxic payload. Poison damage over time.",
	},
	"core_ballistic": {
		"display_name": "Ballistic Core",
		"mod_type": "core",
		"damage_type": "Ballistic",
		"stat_modifiers": {},
		"drawback": {},
		"instability_cost": 0.10,
		"description": "Focuses penetrating force. Pierces through armor.",
	},
	"core_kinetic": {
		"display_name": "Kinetic Core",
		"mod_type": "core",
		"damage_type": "Kinetic",
		"stat_modifiers": {},
		"drawback": {},
		"instability_cost": 0.05,
		"description": "Amplifies bruising impact. Stronger secondary effect.",
	},
}


static func get_mod(mod_id: String) -> Dictionary:
	return MOD_DEFINITIONS.get(mod_id, {})


# Returns {grade_id, display_name, multiplier, drawback_multiplier}.
static func get_mod_grade(grade_id: String) -> Dictionary:
	for g in MOD_GRADES:
		if String(g[0]) == grade_id:
			return {"grade_id": String(g[0]), "display_name": String(g[1]),
				"multiplier": float(g[2]), "drawback_multiplier": float(g[3])}
	var d = MOD_GRADES[0]
	return {"grade_id": String(d[0]), "display_name": String(d[1]),
		"multiplier": float(d[2]), "drawback_multiplier": float(d[3])}


static func mods_for_weapon_range(weapon_range: String) -> Array:
	var out: Array = []
	for mod_id in MOD_DEFINITIONS.keys():
		var mod_type_id = String(MOD_DEFINITIONS[mod_id].get("mod_type", ""))
		if is_mod_type_eligible(mod_type_id, weapon_range):
			out.append(String(mod_id))
	out.sort()
	return out
