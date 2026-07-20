class_name CraftingModels
extends RefCounted

# =============================================================
# STEAMTEK CRAFTING -- RUNTIME SHAPES (Spec Phase 1)
# =============================================================
# Defines the three things that EXIST at runtime and get saved:
#
#   MaterialBatch      a specific recovered lot of a material family,
#                      with its own quality and provenance
#   CraftedItemInstance a unique item produced by a craft
#   PlayerCraftingProfile  what the player knows and has chosen
#
# Each has a factory (new_*) and a serialize pair (*_to_dict /
# *_from_dict). The factories are the ONE authoritative definition of
# each shape -- never build these dictionaries by hand elsewhere, or the
# save format drifts.
#
# Everything is a plain Dictionary so it round-trips through the JSON
# save file with no conversion layer.


# =============================================================
# MATERIAL BATCH
# =============================================================
# Spec s5.2/s5.3. Player-facing stats stay deliberately simple: Quality,
# a Primary Trait, an optional Instability, Amount, Source, best-use
# tags, and extraction purity. No stat spreadsheet.
#
# PROVENANCE (source_id / floor_id / location_id) is required by spec
# s2.4: resources come from permanent campaign-seeded locations, so a
# batch always remembers where it came from ("Floor 12 Substation").
static func new_material_batch(
		batch_id: String,
		family_id: String,
		display_name: String,
		quality: int,
		primary_trait_id: String,
		instability_id: String,
		amount: int,
		source_id: String,
		floor_id: String,
		location_id: String,
		extraction_purity: int
	) -> Dictionary:
	return {
		"batch_id": batch_id,
		"family_id": family_id,
		"display_name": display_name,
		"quality": clampi(quality, CraftingData.QUALITY_MIN, CraftingData.QUALITY_MAX),
		"primary_trait_id": primary_trait_id,
		"instability_id": instability_id,
		"amount": max(0, amount),
		"source_id": source_id,
		"floor_id": floor_id,
		"location_id": location_id,
		"extraction_purity": clampi(extraction_purity, 0, 100),
	}


static func material_batch_to_dict(batch: Dictionary) -> Dictionary:
	return batch.duplicate(true)


static func material_batch_from_dict(d: Dictionary) -> Dictionary:
	return new_material_batch(
		String(d.get("batch_id", "")),
		String(d.get("family_id", "")),
		String(d.get("display_name", "")),
		int(d.get("quality", 0)),
		String(d.get("primary_trait_id", "")),
		String(d.get("instability_id", "")),
		int(d.get("amount", 0)),
		String(d.get("source_id", "")),
		String(d.get("floor_id", "")),
		String(d.get("location_id", "")),
		int(d.get("extraction_purity", 0))
	)


# =============================================================
# CRAFTED ITEM INSTANCE
# =============================================================
# Spec s16.1. A UNIQUE item -- two crafts of the same blueprint are two
# different instances with different stats and history.
#
# craft_seed is the anti-save-scum mechanism (spec s10.7): the seed is
# stored WITH the item, so reloading and re-finalising cannot reroll a
# result that has already been decided.
#
# Phase 1 fills the identity, material, stat and durability fields.
# experimentation_results, socket_count and installed mods are created
# empty here and populated by later phases (4, 5, 6).
static func new_crafted_item(
		instance_id: String,
		blueprint_id: String,
		display_name: String,
		material_batch_ids: Array,
		final_stats: Dictionary,
		inherited_trait_ids: Array,
		inherited_instability_ids: Array,
		craft_quality_tier: String,
		craft_quality_score: float,
		maximum_durability: float,
		craft_seed: int,
		created_at_campaign_time: float
	) -> Dictionary:
	return {
		"instance_id": instance_id,
		"blueprint_id": blueprint_id,
		"display_name": display_name,
		"material_batch_ids": material_batch_ids.duplicate(),
		"final_stats": final_stats.duplicate(true),
		"inherited_trait_ids": inherited_trait_ids.duplicate(),
		"inherited_instability_ids": inherited_instability_ids.duplicate(),
		"craft_quality_tier": craft_quality_tier,
		"craft_quality_score": craft_quality_score,
		"experimentation_results": {},
		# Phase 4: which risk stance was taken, plus the socket-odds
		# penalty accumulated from failed categories. Phase 5 reads the
		# modifier when generating sockets.
		"risk_mode_id": CraftingData.DEFAULT_RISK_MODE,
		"socket_chance_modifier": 0.0,
		"socket_count": 0,
		# Phase 5: which mod types this item's sockets accept, plus the
		# band and score the roll came from (kept for display/debugging).
		"socket_tags": [],
		"socket_band_id": "none",
		"socket_opportunity": 0.0,
		"installed_mod_instance_ids": [],
		"current_durability": maximum_durability,
		"maximum_durability": maximum_durability,
		"craft_seed": craft_seed,
		"created_at_campaign_time": created_at_campaign_time,
	}


static func crafted_item_to_dict(item: Dictionary) -> Dictionary:
	return item.duplicate(true)


# Rebuilds an instance from saved data. Reads every field explicitly
# with a default so an older save missing a field loads rather than
# crashing -- and so a field added in a later phase does not break
# saves written before it existed.
static func crafted_item_from_dict(d: Dictionary) -> Dictionary:
	var item = new_crafted_item(
		String(d.get("instance_id", "")),
		String(d.get("blueprint_id", "")),
		String(d.get("display_name", "")),
		d.get("material_batch_ids", []),
		d.get("final_stats", {}),
		d.get("inherited_trait_ids", []),
		d.get("inherited_instability_ids", []),
		String(d.get("craft_quality_tier", "crude")),
		float(d.get("craft_quality_score", 0.0)),
		float(d.get("maximum_durability", 100.0)),
		int(d.get("craft_seed", 0)),
		float(d.get("created_at_campaign_time", 0.0))
	)
	# Fields owned by later phases: restore if present.
	item["experimentation_results"] = d.get("experimentation_results", {})
	item["risk_mode_id"] = String(d.get("risk_mode_id", CraftingData.DEFAULT_RISK_MODE))
	item["socket_chance_modifier"] = float(d.get("socket_chance_modifier", 0.0))
	item["socket_count"] = int(d.get("socket_count", 0))
	item["socket_tags"] = d.get("socket_tags", [])
	item["socket_band_id"] = String(d.get("socket_band_id", "none"))
	item["socket_opportunity"] = float(d.get("socket_opportunity", 0.0))
	item["installed_mod_instance_ids"] = d.get("installed_mod_instance_ids", [])
	item["current_durability"] = float(d.get("current_durability", item["maximum_durability"]))
	return item


# =============================================================
# PLAYER CRAFTING PROFILE
# =============================================================
# Spec s16.2. What the player knows, has selected, and has discovered.
#
# selected_keystone_node_ids is capped at MAX_KEYSTONE_NODES by
# CraftingService, not here and not in UI -- spec s16.2 requires the cap
# enforced in one authoritative place.
const MAX_KEYSTONE_NODES: int = 4

static func new_player_profile() -> Dictionary:
	return {
		"known_blueprints": {},
		"blueprint_familiarity": {},
		"selected_keystone_node_ids": [],
		"unlocked_workshop_tier": 0,
		"crafting_progression": {},
		"discovered_resource_sources": {},
	}


static func player_profile_to_dict(profile: Dictionary) -> Dictionary:
	return profile.duplicate(true)


static func player_profile_from_dict(d: Dictionary) -> Dictionary:
	var p = new_player_profile()
	p["known_blueprints"] = d.get("known_blueprints", {})
	p["blueprint_familiarity"] = d.get("blueprint_familiarity", {})
	p["selected_keystone_node_ids"] = d.get("selected_keystone_node_ids", [])
	p["unlocked_workshop_tier"] = int(d.get("unlocked_workshop_tier", 0))
	p["crafting_progression"] = d.get("crafting_progression", {})
	p["discovered_resource_sources"] = d.get("discovered_resource_sources", {})
	return p


# =============================================================
# MOD INSTANCE (Spec Phase 6)
# =============================================================
# A specific copy of a mod at a specific grade. Mods are instanced
# rather than stacked because grade matters and because an installed mod
# is bound to one item.
static func new_mod_instance(instance_id: String, mod_id: String, grade_id: String) -> Dictionary:
	return {
		"mod_instance_id": instance_id,
		"mod_id": mod_id,
		"grade_id": grade_id,
		# "" while loose in the player's store; set to the item's
		# instance_id once installed.
		"installed_in": "",
	}


static func mod_instance_to_dict(mod: Dictionary) -> Dictionary:
	return mod.duplicate(true)


static func mod_instance_from_dict(d: Dictionary) -> Dictionary:
	var m = new_mod_instance(
		String(d.get("mod_instance_id", "")),
		String(d.get("mod_id", "")),
		String(d.get("grade_id", "standard"))
	)
	m["installed_in"] = String(d.get("installed_in", ""))
	return m
