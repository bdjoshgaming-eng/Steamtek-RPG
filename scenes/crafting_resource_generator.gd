class_name CraftingResourceGenerator
extends RefCounted

# =============================================================
# CAMPAIGN RESOURCE GENERATOR (Spec Phase 2)
# =============================================================
# Generates the resource map ONCE at new-game from a saved campaign
# seed, then never again. This replaces the old sampling/surveying
# system, which spawned hotspots around the player's live position and
# was therefore structurally incompatible with spec s2.4.
#
# ACCEPTANCE CRITERIA this file satisfies:
#   - the same seed always produces the same distribution
#   - different seeds produce different but valid distributions
#   - reloading never rerolls (generation is not called on load)
#   - progression-critical materials are always obtainable
#
# DETERMINISM RULE: every random draw is made from an RNG seeded by a
# value derived from campaign_seed plus a stable key (floor number,
# slot index). Nothing here may call randi()/randf() directly or use an
# unseeded RNG, or the map stops being reproducible.


# How many material sources each floor carries.
const SOURCES_PER_FLOOR_MIN: int = 2
const SOURCES_PER_FLOOR_MAX: int = 4

# Chance a given source slot draws from the floor's RARE pool instead of
# its common pool. Deliberately low -- rare should feel like a find.
const RARE_SOURCE_CHANCE: float = 0.18

# Source behaviour types (spec s4.4).
const SOURCE_TYPES: Array = ["repeatable_salvage", "finite_deposit", "sealed_stockpile"]


# --- Deterministic RNG helpers -------------------------------------
# Derives a stable sub-seed so each floor generates independently of the
# order floors are processed in. Changing this hash changes every map,
# so treat it as frozen once a campaign exists.
static func _sub_seed(campaign_seed: int, key: String) -> int:
	var h: int = campaign_seed
	for i in range(key.length()):
		h = (h * 31 + key.unicode_at(i)) & 0x7FFFFFFF
	return h

static func _rng_for(campaign_seed: int, key: String) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = _sub_seed(campaign_seed, key)
	return rng


# --- Generation -----------------------------------------------------
# Produces the whole campaign resource map. Call ONCE at new game.
#
# Returns:
#   {
#     "campaign_seed": int,
#     "floors": { "floor_3": {identity, era, display_name, sources:[...]}, ... }
#   }
static func generate_campaign(campaign_seed: int) -> Dictionary:
	var floors: Dictionary = {}

	for floor_number in range(1, CraftingData.SILO_FLOOR_COUNT + 1):
		var era_id = CraftingData.era_for_floor(floor_number)
		if era_id == "":
			continue

		var floor_id = "floor_" + str(floor_number)
		var rng = _rng_for(campaign_seed, floor_id)

		# Identity is drawn from those valid for this era.
		var candidates = CraftingData.identities_for_era(era_id)
		if candidates.is_empty():
			continue
		var identity_id = String(candidates[rng.randi() % candidates.size()])
		var identity = CraftingData.FLOOR_IDENTITIES[identity_id]

		var source_count = SOURCES_PER_FLOOR_MIN + (rng.randi() % (SOURCES_PER_FLOOR_MAX - SOURCES_PER_FLOOR_MIN + 1))
		var sources: Array = []
		for slot in range(source_count):
			var src = _generate_source(campaign_seed, floor_number, floor_id, era_id, identity_id, identity, slot)
			if not src.is_empty():
				sources.append(src)

		floors[floor_id] = {
			"floor_number": floor_number,
			"identity_id": identity_id,
			"display_name": String(identity.get("display_name", identity_id)),
			"era_id": era_id,
			"sources": sources,
		}

	var campaign = {"campaign_seed": campaign_seed, "floors": floors}
	_enforce_guarantees(campaign)
	return campaign


static func _generate_source(campaign_seed: int, floor_number: int, floor_id: String,
		era_id: String, identity_id: String, identity: Dictionary, slot: int) -> Dictionary:
	var rng = _rng_for(campaign_seed, floor_id + "_src" + str(slot))

	var common: Array = identity.get("common", [])
	var rare: Array = identity.get("rare", [])
	var use_rare = rare.size() > 0 and rng.randf() < RARE_SOURCE_CHANCE
	var pool: Array = rare if use_rare else common
	if pool.is_empty():
		pool = common
	if pool.is_empty():
		return {}

	var family_id = String(pool[rng.randi() % pool.size()])
	var families = CraftingData.all_families()
	var family: Dictionary = families.get(family_id, {})
	if family.is_empty():
		return {}

	# Quality: base spread, shifted by era (deeper is better made) and
	# lifted slightly for rare finds.
	var era_bias = int(CraftingData.ERAS.get(era_id, {}).get("quality_bias", 0))
	var quality = 35 + rng.randi() % 46          # 35-80 base
	quality += era_bias
	if use_rare:
		quality += 10
	quality = clampi(quality, CraftingData.QUALITY_MIN, CraftingData.QUALITY_MAX)

	var traits: Array = family.get("eligible_traits", [])
	var primary_trait_id = "" if traits.is_empty() else String(traits[rng.randi() % traits.size()])

	var instability_id := ""
	var insts: Array = family.get("eligible_instabilities", [])
	if insts.size() > 0:
		var clean_chance = float(quality) / 130.0
		if rng.randf() > clean_chance:
			instability_id = String(insts[rng.randi() % insts.size()])

	var extraction_purity = 60 + rng.randi() % 41  # 60-100
	var source_type = String(SOURCE_TYPES[rng.randi() % SOURCE_TYPES.size()])
	var capacity = 80 + rng.randi() % 221          # 80-300 units

	var location_id = identity_id + "_" + str(slot + 1)

	return {
		"source_id": "src_" + floor_id + "_" + family_id + "_" + str(slot),
		"family_id": family_id,
		"floor_id": floor_id,
		"floor_number": floor_number,
		"location_id": location_id,
		"location_name": String(identity.get("display_name", identity_id)) + " " + str(slot + 1),
		"quality": quality,
		"primary_trait_id": primary_trait_id,
		"instability_id": instability_id,
		"extraction_purity": extraction_purity,
		"source_type": source_type,
		"capacity": capacity,
		"remaining": capacity,
		"rarity": "rare" if use_rare else "common",
	}


# --- Guarantees (spec s4.3) ----------------------------------------
# Runs after generation and repairs only what fails, deterministically,
# so a campaign can never be unwinnable. Repairs prefer upgrading an
# existing source over injecting a new one, so the map keeps its shape.
static func _enforce_guarantees(campaign: Dictionary) -> void:
	var seed_val = int(campaign.get("campaign_seed", 0))
	for rule in CraftingData.RESOURCE_GUARANTEES:
		var family_id = String(rule["family_id"])
		var min_quality = int(rule.get("min_quality", 0))
		var min_sources = int(rule.get("min_sources", 1))
		var by_floor = int(rule.get("by_floor", CraftingData.SILO_FLOOR_COUNT))

		var matching = _find_sources(campaign, family_id, by_floor)
		var good = []
		for s in matching:
			if int(s["quality"]) >= min_quality:
				good.append(s)

		if good.size() >= min_sources:
			continue

		var shortfall = min_sources - good.size()

		# Repair 1: raise the quality of the best existing candidates.
		matching.sort_custom(func(a, b): return int(a["quality"]) > int(b["quality"]))
		for s in matching:
			if shortfall <= 0:
				break
			if int(s["quality"]) < min_quality:
				s["quality"] = min_quality
				s["guarantee_adjusted"] = true
				shortfall -= 1

		# Repair 2: inject sources at deterministic floors that can host
		# this family, if upgrading was not enough.
		var attempt = 0
		while shortfall > 0 and attempt < CraftingData.SILO_FLOOR_COUNT:
			var host = _find_host_floor(campaign, family_id, by_floor, seed_val, attempt)
			attempt += 1
			if host == "":
				continue
			var injected = _make_guaranteed_source(campaign, host, family_id, min_quality, seed_val, shortfall)
			if injected.is_empty():
				continue
			campaign["floors"][host]["sources"].append(injected)
			shortfall -= 1

		if shortfall > 0:
			push_warning("[CRAFTING] Guarantee unmet for " + family_id + " (short " + str(shortfall) + ").")


static func _find_sources(campaign: Dictionary, family_id: String, by_floor: int) -> Array:
	var out: Array = []
	for floor_id in campaign.get("floors", {}).keys():
		var f = campaign["floors"][floor_id]
		if int(f.get("floor_number", 9999)) > by_floor:
			continue
		for s in f.get("sources", []):
			if String(s.get("family_id", "")) == family_id:
				out.append(s)
	return out


# Picks a floor at or above by_floor whose identity legitimately hosts
# this family. Deterministic: walks floors in a seed-derived order.
static func _find_host_floor(campaign: Dictionary, family_id: String, by_floor: int, seed_val: int, attempt: int) -> String:
	var eligible: Array = []
	for floor_id in campaign.get("floors", {}).keys():
		var f = campaign["floors"][floor_id]
		if int(f.get("floor_number", 9999)) > by_floor:
			continue
		var ident = CraftingData.FLOOR_IDENTITIES.get(String(f.get("identity_id", "")), {})
		var pool: Array = ident.get("common", []) + ident.get("rare", [])
		if pool.has(family_id):
			eligible.append(floor_id)
	if eligible.is_empty():
		return ""
	eligible.sort()
	var rng = _rng_for(seed_val, "guarantee_" + family_id + "_" + str(attempt))
	return String(eligible[rng.randi() % eligible.size()])


static func _make_guaranteed_source(campaign: Dictionary, floor_id: String, family_id: String,
		min_quality: int, seed_val: int, nonce: int) -> Dictionary:
	var f = campaign["floors"][floor_id]
	var families = CraftingData.all_families()
	var family: Dictionary = families.get(family_id, {})
	if family.is_empty():
		return {}

	var rng = _rng_for(seed_val, "guar_src_" + floor_id + "_" + family_id + "_" + str(nonce))
	var traits: Array = family.get("eligible_traits", [])
	var quality = max(min_quality, 55 + rng.randi() % 26)
	var capacity = 120 + rng.randi() % 121

	return {
		"source_id": "src_" + floor_id + "_" + family_id + "_g" + str(nonce),
		"family_id": family_id,
		"floor_id": floor_id,
		"floor_number": int(f.get("floor_number", 0)),
		"location_id": String(f.get("identity_id", "")) + "_reserve",
		"location_name": String(f.get("display_name", floor_id)) + " Reserve",
		"quality": clampi(quality, CraftingData.QUALITY_MIN, CraftingData.QUALITY_MAX),
		"primary_trait_id": "" if traits.is_empty() else String(traits[rng.randi() % traits.size()]),
		"instability_id": "",
		"extraction_purity": 80 + rng.randi() % 21,
		"source_type": "repeatable_salvage",
		"capacity": capacity,
		"remaining": capacity,
		"rarity": "common",
		"guarantee_injected": true,
	}


# --- Validation report ---------------------------------------------
# Read-only. Returns human-readable problems; empty means the campaign
# satisfies every guarantee. Useful as a startup check and in testing.
static func validate_campaign(campaign: Dictionary) -> Array:
	var problems: Array = []
	for rule in CraftingData.RESOURCE_GUARANTEES:
		var family_id = String(rule["family_id"])
		var min_quality = int(rule.get("min_quality", 0))
		var min_sources = int(rule.get("min_sources", 1))
		var by_floor = int(rule.get("by_floor", CraftingData.SILO_FLOOR_COUNT))
		var good = 0
		for s in _find_sources(campaign, family_id, by_floor):
			if int(s["quality"]) >= min_quality:
				good += 1
		if good < min_sources:
			problems.append("%s: need %d source(s) at quality %d+ by floor %d, found %d"
				% [family_id, min_sources, min_quality, by_floor, good])
	return problems


# --- Extraction -----------------------------------------------------
# Turns a permanent world source into a carryable material batch. This
# is the seam the new scavenging loop plugs into: walk up to a source,
# extract, receive a batch that remembers where it came from.
static func extract_from_source(source: Dictionary, amount: int) -> Dictionary:
	var available = int(source.get("remaining", 0))
	var take = min(amount, available)
	if take <= 0:
		return {}
	source["remaining"] = available - take

	var family_id = String(source.get("family_id", ""))
	var families = CraftingData.all_families()
	var family: Dictionary = families.get(family_id, {})
	var prefixes: Array = family.get("name_prefixes", [])
	var trait_id = String(source.get("primary_trait_id", ""))

	var parts: Array = []
	if prefixes.size() > 0:
		# Stable per source, so the same deposit always yields the same
		# named material rather than a new name every extraction.
		var idx = absi(_sub_seed(0, String(source.get("source_id", "")))) % prefixes.size()
		parts.append(String(prefixes[idx]))
	if trait_id != "":
		parts.append(String(CraftingData.get_trait(trait_id).get("display_name", "")))
	parts.append(String(family.get("display_name", family_id)))

	return CraftingModels.new_material_batch(
		"batch_" + String(source.get("source_id", "")) + "_" + str(available),
		family_id,
		" ".join(parts),
		int(source.get("quality", 0)),
		trait_id,
		String(source.get("instability_id", "")),
		take,
		String(source.get("source_id", "")),
		String(source.get("floor_id", "")),
		String(source.get("location_id", "")),
		int(source.get("extraction_purity", 100))
	)


# --- Save / load ----------------------------------------------------
# The campaign map is saved WHOLE and never regenerated on load. That is
# what makes sources permanent for the campaign (spec s4.4).
static func to_save_dict(campaign: Dictionary) -> Dictionary:
	return campaign.duplicate(true)


static func from_save_dict(d: Dictionary) -> Dictionary:
	if d.is_empty() or not d.has("floors"):
		return {}
	return d.duplicate(true)
