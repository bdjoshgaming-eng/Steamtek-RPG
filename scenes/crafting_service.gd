class_name CraftingService
extends RefCounted

# =============================================================
# STEAMTEK CRAFTING -- OPERATIONS (Spec Phase 1)
# =============================================================
# The only place that CHANGES crafting state. Data definitions live in
# crafting_data.gd; runtime shapes live in crafting_models.gd.
#
# Phase 1 scope, per the spec's acceptance criterion:
#   "One blueprint and three material batches can produce a saved
#    crafted item instance. Reloading preserves all values."
#
# So this file does: generate batches, compute material potential,
# validate a material selection, craft, and serialize.
#
# DELIBERATELY NOT HERE YET:
#   experimentation points/allocation   -> Phase 4
#   mod sockets                         -> Phase 5
#   mods                                -> Phase 6
#   crafting keystone effects           -> Phase 7
#   repair / dismantle / rebuild        -> Phase 8
# The hooks those need (craft_seed, socket_count, experimentation_
# results, durability) already exist on the item instance.


# --- ID generation -------------------------------------------------
# Stable, unique, and readable. Save compatibility depends on ids never
# being reused, so these combine a prefix, a timestamp and a counter.
static var _id_counter: int = 0

static func _next_id(prefix: String) -> String:
	_id_counter += 1
	return prefix + "_" + str(Time.get_unix_time_from_system()).replace(".", "") + "_" + str(_id_counter)


# --- Batch generation ----------------------------------------------
# Builds one material batch of a family. Phase 2 (campaign resource
# generator) will call this with seeded values tied to fixed world
# locations; for Phase 1 it takes them directly so the data model can be
# exercised and tested.
#
# The generated display name follows spec s5.4 -- prefix + trait +
# family, e.g. "Aurelian Conductive Copper".
static func generate_batch(
		family_id: String,
		quality: int,
		amount: int,
		source_id: String,
		floor_id: String,
		location_id: String,
		extraction_purity: int = 100,
		rng_seed: int = 0
	) -> Dictionary:
	var family = CraftingData.get_family(family_id)
	if family.is_empty():
		push_error("[CRAFTING] Unknown resource family: " + family_id)
		return {}

	var rng = RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	var eligible_traits: Array = family.get("eligible_traits", [])
	var primary_trait_id: String = ""
	if eligible_traits.size() > 0:
		primary_trait_id = String(eligible_traits[rng.randi() % eligible_traits.size()])

	# Higher quality and purity make an instability less likely. A
	# perfect batch can still be clean; a poor one usually is not.
	var instability_id: String = ""
	var eligible_inst: Array = family.get("eligible_instabilities", [])
	if eligible_inst.size() > 0:
		var clean_chance = (float(quality) / 100.0) * 0.7 + (float(extraction_purity) / 100.0) * 0.3
		if rng.randf() > clean_chance:
			instability_id = String(eligible_inst[rng.randi() % eligible_inst.size()])

	var prefixes: Array = family.get("name_prefixes", [])
	var name_parts: Array = []
	if prefixes.size() > 0:
		name_parts.append(String(prefixes[rng.randi() % prefixes.size()]))
	if primary_trait_id != "":
		name_parts.append(String(CraftingData.get_trait(primary_trait_id).get("display_name", "")))
	name_parts.append(String(family.get("display_name", family_id)))
	var display_name = " ".join(name_parts)

	return CraftingModels.new_material_batch(
		_next_id("batch"), family_id, display_name, quality,
		primary_trait_id, instability_id, amount,
		source_id, floor_id, location_id, extraction_purity
	)


# --- Material potential --------------------------------------------
# Spec s1: "Materials determine the item's potential." This computes
# that potential as a 0-100 score.
#
# Each blueprint slot contributes its material's quality scaled by the
# slot's weight, so the slot that matters most (a blade) dominates the
# slot that matters least (a binding). Extraction purity nudges the
# result, and each instability present applies a small penalty.
#
# EXPERIMENTATION (Phase 4) decides how much of this potential is
# actually realised. Phase 1 realises it directly so the pipeline can be
# tested end to end.
static func compute_material_potential(blueprint_id: String, selection: Dictionary) -> float:
	var bp = CraftingData.get_blueprint(blueprint_id)
	if bp.is_empty():
		return 0.0

	var total_weight := 0.0
	var weighted := 0.0
	var instability_count := 0

	for slot in bp.get("material_slots", []):
		var slot_id = String(slot.get("slot_id", ""))
		var weight = float(slot.get("weight", 0.0))
		total_weight += weight
		var batch = selection.get(slot_id, {})
		if batch.is_empty():
			continue
		var q = float(batch.get("quality", 0))
		var purity = float(batch.get("extraction_purity", 100))
		# Purity moves the effective quality by up to +/-10%.
		var effective = q * (0.9 + (purity / 100.0) * 0.2)
		weighted += effective * weight
		if String(batch.get("instability_id", "")) != "":
			instability_count += 1

	if total_weight <= 0.0:
		return 0.0

	var score = weighted / total_weight
	score -= float(instability_count) * 3.0
	return clampf(score, 0.0, 100.0)


# --- Selection validation ------------------------------------------
# Returns an array of human-readable problems; empty means the
# selection is craftable.
static func validate_selection(blueprint_id: String, selection: Dictionary) -> Array:
	var problems: Array = []
	var bp = CraftingData.get_blueprint(blueprint_id)
	if bp.is_empty():
		problems.append("Unknown blueprint: " + blueprint_id)
		return problems

	for slot in bp.get("material_slots", []):
		var slot_id = String(slot.get("slot_id", ""))
		var slot_name = String(slot.get("slot_name", slot_id))
		var needed = int(slot.get("amount", 0))
		var accepts: Array = slot.get("accepts", [])

		if not selection.has(slot_id) or (selection[slot_id] as Dictionary).is_empty():
			problems.append(slot_name + ": no material selected.")
			continue

		var batch: Dictionary = selection[slot_id]
		var fam = String(batch.get("family_id", ""))
		if accepts.size() > 0 and not accepts.has(fam):
			var fam_name = String(CraftingData.get_family(fam).get("display_name", fam))
			problems.append(slot_name + ": " + fam_name + " is not accepted here.")
		if int(batch.get("amount", 0)) < needed:
			problems.append(slot_name + ": need " + str(needed) + ", have " + str(int(batch.get("amount", 0))) + ".")

	return problems


# --- Crafting -------------------------------------------------------
# Produces a CraftedItemInstance from a blueprint and a slot->batch
# selection. Returns an empty Dictionary if the selection is invalid.
#
# The craft_seed is generated ONCE here and stored on the item. Later
# phases must derive every random outcome for this item from that stored
# seed rather than rolling fresh, so a reload cannot reroll a finalised
# result (spec s2.5 / s10.7).
static func craft(blueprint_id: String, selection: Dictionary, campaign_time: float = 0.0) -> Dictionary:
	var problems = validate_selection(blueprint_id, selection)
	if problems.size() > 0:
		push_error("[CRAFTING] Cannot craft " + blueprint_id + ": " + "; ".join(problems))
		return {}

	var bp = CraftingData.get_blueprint(blueprint_id)
	var potential = compute_material_potential(blueprint_id, selection)
	var tier = CraftingData.quality_tier_for(potential)

	var batch_ids: Array = []
	var traits: Array = []
	var instabilities: Array = []
	for slot in bp.get("material_slots", []):
		var batch = selection.get(String(slot.get("slot_id", "")), {})
		if batch.is_empty():
			continue
		batch_ids.append(String(batch.get("batch_id", "")))
		var t = String(batch.get("primary_trait_id", ""))
		if t != "" and not traits.has(t):
			traits.append(t)
		var inst = String(batch.get("instability_id", ""))
		if inst != "" and not instabilities.has(inst):
			instabilities.append(inst)

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var craft_seed = int(rng.randi())

	# Durability scales with realised quality. Placeholder curve.
	var max_durability = 60.0 + potential * 0.9

	var final_stats = {
		"Material Potential": round(potential),
		"Realised Quality": round(potential),
	}

	return CraftingModels.new_crafted_item(
		_next_id("item"),
		blueprint_id,
		String(bp.get("display_name", blueprint_id)),
		batch_ids,
		final_stats,
		traits,
		instabilities,
		tier,
		potential,
		max_durability,
		craft_seed,
		campaign_time
	)


# --- Keystone selection (authoritative cap) ------------------------
# Spec s16.2 requires the 4-node maximum enforced in ONE service, not
# only in UI. Returns true if the node was selected.
static func select_keystone_node(profile: Dictionary, node_id: String) -> bool:
	var selected: Array = profile.get("selected_keystone_node_ids", [])
	if selected.has(node_id):
		return false
	if selected.size() >= CraftingModels.MAX_KEYSTONE_NODES:
		push_warning("[CRAFTING] Keystone node limit reached (" + str(CraftingModels.MAX_KEYSTONE_NODES) + ").")
		return false
	selected.append(node_id)
	profile["selected_keystone_node_ids"] = selected
	return true


# --- Save / load ----------------------------------------------------
# One dictionary holding everything crafting owns, ready to drop into
# the existing JSON save. main.gd calls these two and nothing else.
static func to_save_dict(batches: Dictionary, items: Dictionary, profile: Dictionary) -> Dictionary:
	var out_batches := {}
	for k in batches.keys():
		out_batches[k] = CraftingModels.material_batch_to_dict(batches[k])
	var out_items := {}
	for k in items.keys():
		out_items[k] = CraftingModels.crafted_item_to_dict(items[k])
	return {
		"version": 1,
		"material_batches": out_batches,
		"crafted_items": out_items,
		"profile": CraftingModels.player_profile_to_dict(profile),
	}


# Returns {"batches": {...}, "items": {...}, "profile": {...}}.
# Safe on a save written before crafting existed -- returns empties.
static func from_save_dict(d: Dictionary) -> Dictionary:
	var batches := {}
	for k in d.get("material_batches", {}).keys():
		batches[k] = CraftingModels.material_batch_from_dict(d["material_batches"][k])
	var items := {}
	for k in d.get("crafted_items", {}).keys():
		items[k] = CraftingModels.crafted_item_from_dict(d["crafted_items"][k])
	var profile = CraftingModels.player_profile_from_dict(d.get("profile", {}))
	return {"batches": batches, "items": items, "profile": profile}
