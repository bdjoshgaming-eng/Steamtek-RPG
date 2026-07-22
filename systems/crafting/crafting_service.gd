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
# Produces a CraftedItemInstance from a blueprint, a slot->batch
# selection, and the player's experimentation choices.
#
# The craft_seed is DERIVED from the blueprint and materials, not
# randomised -- see deterministic_craft_seed(). Reloading and crafting
# the same materials the same way yields the same item.
#
# allocation: {category_id: points}. Pass {} to craft without
# experimenting -- the item is then pure material potential.
static func craft(blueprint_id: String, selection: Dictionary, campaign_time: float = 0.0,
		allocation: Dictionary = {}, risk_mode_id: String = "", profile: Dictionary = {}) -> Dictionary:
	var problems = validate_selection(blueprint_id, selection)
	if problems.size() > 0:
		push_error("[CRAFTING] Cannot craft " + blueprint_id + ": " + "; ".join(problems))
		return {}

	var bp = CraftingData.get_blueprint(blueprint_id)
	var potential = compute_material_potential(blueprint_id, selection)

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

	var craft_seed = deterministic_craft_seed(blueprint_id, batch_ids)
	var risk_id = risk_mode_id if risk_mode_id != "" else CraftingData.DEFAULT_RISK_MODE

	# --- Stage 6: resolve each allocated category ---
	var results: Dictionary = {}
	var socket_modifier := 0.0
	var realised = potential
	for category_id in CraftingData.categories_for_blueprint(blueprint_id):
		var pts = int(allocation.get(category_id, 0))
		if pts <= 0:
			continue
		var res = resolve_category(blueprint_id, selection, category_id, pts,
			risk_id, craft_seed, potential, profile)
		results[category_id] = res
		socket_modifier += float(res["socket_modifier"])
		var flaw = String(res["gained_instability"])
		if flaw != "" and not instabilities.has(flaw):
			instabilities.append(flaw)

	# Experimentation lifts realised quality above raw material
	# potential. Each category contributes a share scaled by its tier,
	# so a Great result is worth four times a Poor one.
	var lift := 0.0
	for cid in results.keys():
		lift += float(results[cid]["multiplier"]) * float(results[cid]["allocated_points"]) * 1.5
	realised = clampf(potential + lift, 0.0, 100.0)

	var tier = CraftingData.quality_tier_for(realised)

	# Failed categories cost durability as well as their points.
	var failure_count := 0
	for cid2 in results.keys():
		if bool(results[cid2]["failed"]):
			failure_count += 1
	var max_durability = 60.0 + realised * 0.9 - float(failure_count) * 8.0
	max_durability = maxf(20.0, max_durability)

	var final_stats = {
		"Material Potential": round(potential),
		"Realised Quality": round(realised),
	}

	var item = CraftingModels.new_crafted_item(
		_next_id("item"),
		blueprint_id,
		String(bp.get("display_name", blueprint_id)),
		batch_ids,
		final_stats,
		traits,
		instabilities,
		tier,
		realised,
		max_durability,
		craft_seed,
		campaign_time
	)
	item["experimentation_results"] = results
	item["risk_mode_id"] = risk_id
	item["socket_chance_modifier"] = socket_modifier

	# --- Phase 5: sockets ---
	# Resolved here, ONCE, and stored on the item. Never recomputed on
	# display, or reopening the inventory would reroll it.
	var sockets = resolve_sockets(blueprint_id, selection, allocation, results,
		instabilities.size(), socket_modifier, craft_seed, profile)
	item["socket_count"] = int(sockets["count"])
	item["socket_band_id"] = String(sockets["band_id"])
	item["socket_opportunity"] = float(sockets["opportunity"])
	return item


static func craft_mod(blueprint_id: String, selection: Dictionary) -> Dictionary:
	var problems = validate_selection(blueprint_id, selection)
	if problems.size() > 0:
		push_error("[CRAFTING] Cannot craft mod " + blueprint_id + ": " + "; ".join(problems))
		return {}

	var reagent_batch = selection.get("reagent", {})
	var family_id = String(reagent_batch.get("family_id", ""))
	var damage_type = CraftingData.damage_type_for_family(family_id)
	if damage_type == "":
		push_error("[CRAFTING] Family '" + family_id + "' has no damage type mapping.")
		return {}

	var mod_id = "core_" + damage_type.to_lower()
	if not CraftingData.MOD_DEFINITIONS.has(mod_id):
		push_error("[CRAFTING] No mod definition for " + mod_id)
		return {}

	var potential = compute_material_potential(blueprint_id, selection)
	var quality = clampf(potential, 0.0, 100.0)
	var grade_id = "standard"
	if quality >= 85.0:
		grade_id = "masterwork"
	elif quality >= 70.0:
		grade_id = "prototype"
	elif quality >= 55.0:
		grade_id = "advanced"
	elif quality >= 35.0:
		grade_id = "refined"

	var effect_strength = clampf(quality / 100.0, 0.05, 1.0)

	var mod = CraftingModels.new_mod_instance(_next_id("mod"), mod_id, grade_id)
	mod["effect_strength"] = effect_strength
	mod["craft_quality"] = quality
	return mod


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


# =============================================================
# EXPERIMENTATION (Spec Phase 4, stages 4-6)
# =============================================================
# Materials set the ceiling; experimentation decides how much of it you
# realise. See CraftingData for the tables this reads.


# --- Deterministic craft seed ---------------------------------------
# THE ANTI-SAVE-SCUM MECHANISM (spec s2.5 / s10.7).
#
# The seed is derived from the blueprint and the exact material batches
# used -- NOT from randomize(). That means:
#   reload + same materials + same allocation + same risk  -> SAME result
#   different allocation or risk                           -> different result
# The first prevents scumming. The second is required: those are real
# choices and must matter.
#
# Batch ids are sorted so slot ordering cannot change the outcome.
static func deterministic_craft_seed(blueprint_id: String, batch_ids: Array) -> int:
	var ids := batch_ids.duplicate()
	ids.sort()
	var key := blueprint_id + "|" + "|".join(ids)
	var h: int = 2166136261
	for i in range(key.length()):
		h = (h ^ key.unicode_at(i)) & 0x7FFFFFFF
		h = (h * 16777619) & 0x7FFFFFFF
	return h


static func _category_rng(craft_seed: int, category_id: String) -> RandomNumberGenerator:
	var h: int = craft_seed
	for i in range(category_id.length()):
		h = (h * 31 + category_id.unicode_at(i)) & 0x7FFFFFFF
	var rng = RandomNumberGenerator.new()
	rng.seed = h
	return rng


# --- Material compatibility -----------------------------------------
# 0.0 - 1.0. How well the chosen materials suit THIS category, based on
# their primary traits. Weighted by slot importance, so the material in
# the slot that matters most dominates.
static func material_compatibility(blueprint_id: String, selection: Dictionary, category_id: String) -> float:
	var bp = CraftingData.get_blueprint(blueprint_id)
	var helpful: Array = CraftingData.TRAIT_CATEGORY_AFFINITY.get(category_id, [])
	if helpful.is_empty():
		return 0.0

	var total_weight := 0.0
	var matched := 0.0
	for slot in bp.get("material_slots", []):
		var w = float(slot.get("weight", 0.0))
		total_weight += w
		var batch = selection.get(String(slot.get("slot_id", "")), {})
		if batch.is_empty():
			continue
		if helpful.has(String(batch.get("primary_trait_id", ""))):
			matched += w
	if total_weight <= 0.0:
		return 0.0
	return clampf(matched / total_weight, 0.0, 1.0)


# --- Stage 4: generate experimentation points ------------------------
# Returns {"total": int, "breakdown": {source: points}} so the UI can
# show the player WHERE their points came from rather than one number.
#
# Workshop, tool and keystone are wired but contribute 0 until Phases 7
# and 8 exist -- the ceiling rises automatically when they land.
static func generate_experimentation_points(blueprint_id: String, selection: Dictionary, profile: Dictionary) -> Dictionary:
	var familiarity = float(profile.get("blueprint_familiarity", {}).get(blueprint_id, 0))
	var familiarity_points = int(round((familiarity / 100.0) * CraftingData.EXP_POINTS_FAMILIARITY_MAX))

	# Average compatibility across the categories this blueprint offers.
	var cats = CraftingData.categories_for_blueprint(blueprint_id)
	var compat_sum := 0.0
	for cid in cats:
		compat_sum += material_compatibility(blueprint_id, selection, cid)
	var compat_avg = 0.0 if cats.is_empty() else compat_sum / float(cats.size())
	var compat_points = int(round(compat_avg * CraftingData.EXP_POINTS_COMPATIBILITY_MAX))

	var workshop_points = int(min(profile.get("unlocked_workshop_tier", 0), CraftingData.EXP_POINTS_WORKSHOP_MAX))
	var tool_points := 0      # Phase 8
	var keystone_points := 0  # Phase 7

	var breakdown = {
		"Base": CraftingData.EXP_POINTS_BASE,
		"Familiarity": familiarity_points,
		"Materials": compat_points,
		"Workshop": workshop_points,
		"Tools": tool_points,
		"Keystone": keystone_points,
	}
	var total := 0
	for k in breakdown.keys():
		total += int(breakdown[k])
	return {"total": total, "breakdown": breakdown}


# --- Stage 6: resolve one category ----------------------------------
# Score assembly mirrors the spec's pseudocode (s17):
#   points + familiarity + compatibility + potential
#   - difficulty penalty + risk bonus + controlled randomness
static func resolve_category(
		blueprint_id: String,
		selection: Dictionary,
		category_id: String,
		allocated_points: int,
		risk_mode_id: String,
		craft_seed: int,
		potential: float,
		profile: Dictionary
	) -> Dictionary:

	var bp = CraftingData.get_blueprint(blueprint_id)
	var risk = CraftingData.get_risk_mode(risk_mode_id)

	var score := 0.0
	score += float(allocated_points) * CraftingData.EXP_SCORE_PER_POINT
	score += float(profile.get("blueprint_familiarity", {}).get(blueprint_id, 0)) * 0.15
	score += material_compatibility(blueprint_id, selection, category_id) * 12.0
	score += potential * CraftingData.EXP_POTENTIAL_WEIGHT
	score -= float(bp.get("difficulty", 0)) * CraftingData.EXP_DIFFICULTY_WEIGHT
	score += float(risk.get("score_bonus", 0.0))

	# Controlled randomness -- derived from the craft seed, never fresh.
	var rng = _category_rng(craft_seed, category_id)
	var spread = float(risk.get("spread", 15.0))
	var roll = rng.randf_range(-spread, spread)
	var final_score = score + roll

	var tier = CraftingData.experimentation_tier_for(final_score)
	var failed = String(tier["tier_id"]) == "failure"

	# Failure consequences (Josh's call): points are wasted, there is a
	# risk-scaled chance of a permanent flaw, and socket odds drop.
	var gained_instability := ""
	var socket_modifier := 0.0
	if failed:
		socket_modifier = -float(risk.get("socket_penalty", 0.0))
		if rng.randf() < float(risk.get("instability_chance", 0.0)):
			var pool: Array = CraftingData.INSTABILITIES.keys()
			if pool.size() > 0:
				gained_instability = String(pool[rng.randi() % pool.size()])

	return {
		"category_id": category_id,
		"allocated_points": allocated_points,
		"tier_id": String(tier["tier_id"]),
		"tier_name": String(tier["display_name"]),
		"multiplier": float(tier["multiplier"]),
		"score": final_score,
		"failed": failed,
		"gained_instability": gained_instability,
		"socket_modifier": socket_modifier,
	}


# --- Allocation validation -------------------------------------------
# Returns problems; empty means the allocation is legal.
static func validate_allocation(blueprint_id: String, allocation: Dictionary, available_points: int) -> Array:
	var problems: Array = []
	var cats = CraftingData.categories_for_blueprint(blueprint_id)
	var spent := 0
	for cid in allocation.keys():
		var pts = int(allocation[cid])
		if pts < 0:
			problems.append("Cannot allocate negative points to " + String(cid) + ".")
		if not cats.has(String(cid)):
			problems.append(String(cid) + " is not a category for this blueprint.")
		spent += pts
	if spent > available_points:
		problems.append("Allocated " + str(spent) + " of " + str(available_points) + " available points.")
	return problems


# =============================================================
# MOD SOCKETS (Spec Phase 5)
# =============================================================


# --- Opportunity score (spec s10.4) ---
# How much the player earned a shot at extra sockets. Mod Architecture
# allocation dominates; materials, familiarity and the experimentation
# result all contribute; difficulty and instability subtract.
#
# socket_chance_modifier carries the penalty Phase 4 recorded when a
# category FAILED -- so a botched experimentation run costs sockets too,
# which is the third failure consequence.
static func compute_socket_opportunity(
		blueprint_id: String,
		selection: Dictionary,
		allocation: Dictionary,
		results: Dictionary,
		instability_count: int,
		socket_chance_modifier: float,
		profile: Dictionary
	) -> float:

	var bp = CraftingData.get_blueprint(blueprint_id)
	var score := 0.0

	# The single strongest influence, per spec s10.1.
	var arch_points = int(allocation.get("mod_architecture", 0))
	score += float(arch_points) * CraftingData.SOCKET_POINTS_WEIGHT

	# How WELL that allocation resolved, not just how much was spent.
	if results.has("mod_architecture"):
		score += float(results["mod_architecture"].get("multiplier", 0.0)) * CraftingData.SOCKET_TIER_WEIGHT

	score += float(profile.get("blueprint_familiarity", {}).get(blueprint_id, 0)) * CraftingData.SOCKET_FAMILIARITY_WEIGHT
	score += material_compatibility(blueprint_id, selection, "mod_architecture") * CraftingData.SOCKET_COMPATIBILITY_WEIGHT
	score += float(profile.get("unlocked_workshop_tier", 0)) * CraftingData.SOCKET_WORKSHOP_WEIGHT
	score -= float(bp.get("difficulty", 0)) * CraftingData.SOCKET_DIFFICULTY_WEIGHT
	score -= float(instability_count) * CraftingData.SOCKET_INSTABILITY_PENALTY

	# Phase 4 failure penalty (a negative fraction), scaled onto this range.
	score += socket_chance_modifier * 100.0

	return maxf(0.0, score)


# --- Weighted roll (spec s10.6) ---
# Deterministic: the RNG is seeded from the item's craft_seed, so the
# same craft always yields the same socket count. Reopening the UI or
# reloading cannot reroll it.
static func roll_additional_sockets(opportunity_score: float, max_additional: int, craft_seed: int) -> int:
	if max_additional <= 0:
		return 0

	var band = CraftingData.socket_band_for(opportunity_score)
	var weights: Dictionary = band["weights"]

	var total := 0
	for k in weights.keys():
		total += int(weights[k])
	if total <= 0:
		return 0

	# Its own seed derivation so socket rolls are independent of the
	# per-category experimentation rolls.
	var rng = _category_rng(craft_seed, "__sockets__")
	var pick = rng.randi() % total

	var running := 0
	var counts: Array = weights.keys()
	counts.sort()
	for c in counts:
		running += int(weights[c])
		if pick < running:
			return clampi(int(c), 0, max_additional)
	return 0


# Full socket resolution for a finished item. Returns
# {count, band_id, opportunity, tags}.
static func resolve_sockets(
		blueprint_id: String,
		selection: Dictionary,
		allocation: Dictionary,
		results: Dictionary,
		instability_count: int,
		socket_chance_modifier: float,
		craft_seed: int,
		profile: Dictionary
	) -> Dictionary:

	var bp = CraftingData.get_blueprint(blueprint_id)
	var guaranteed = int(bp.get("guaranteed_sockets", 0))
	var maximum = int(bp.get("max_sockets", 0))

	# Consumables declare max_sockets 0 and never gain any.
	if maximum <= 0:
		return {"count": 0, "band_id": "none", "opportunity": 0.0, "tags": []}

	var opportunity = compute_socket_opportunity(
		blueprint_id, selection, allocation, results,
		instability_count, socket_chance_modifier, profile)

	var band = CraftingData.socket_band_for(opportunity)
	var headroom = maximum - guaranteed
	var extra = roll_additional_sockets(opportunity, headroom, craft_seed)

	return {
		"count": clampi(guaranteed + extra, 0, maximum),
		"band_id": String(band["band_id"]),
		"opportunity": opportunity,
	}


# =============================================================
# MODS (Spec Phase 6)
# =============================================================


# Creates a loose mod instance the player can carry and later install.
static func create_mod(mod_id: String, grade_id: String = "standard") -> Dictionary:
	if not CraftingData.MOD_DEFINITIONS.has(mod_id):
		push_error("[CRAFTING] Unknown mod: " + mod_id)
		return {}
	return CraftingModels.new_mod_instance(_next_id("mod"), mod_id, grade_id)


# --- Installation rules -------------------------------------------
# Returns an array of reasons the mod CANNOT go in. Empty means it can.
#
# Four checks:
#   1. is there a free socket
#   2. is the mod type eligible for this weapon's range (melee/ranged)
#   3. is there already a mod of this type installed (one per type)
#   4. CL suitability (placeholder -- not enforced yet)
static func mod_install_problems(item: Dictionary, mod: Dictionary, installed_mods: Array, weapon_range: String = "") -> Array:
	var problems: Array = []
	var mod_def = CraftingData.get_mod(String(mod.get("mod_id", "")))
	if mod_def.is_empty():
		problems.append("Unknown mod.")
		return problems

	var sockets = int(item.get("socket_count", 0))
	if sockets <= 0:
		problems.append("This item has no mod sockets.")
		return problems
	if installed_mods.size() >= sockets:
		problems.append("All " + str(sockets) + " sockets are full.")

	var mod_type_id = String(mod_def.get("mod_type", ""))

	if weapon_range != "" and not CraftingData.is_mod_type_eligible(mod_type_id, weapon_range):
		var name = CraftingData.mod_display_name(mod_type_id, weapon_range)
		problems.append(name + " mods cannot be installed in " + weapon_range.to_lower() + " weapons.")

	for other in installed_mods:
		var other_def = CraftingData.get_mod(String(other.get("mod_id", "")))
		if String(other_def.get("mod_type", "")) == mod_type_id:
			var type_name = CraftingData.mod_display_name(mod_type_id, weapon_range)
			problems.append("Already has a " + type_name + " mod installed.")
			break
	return problems


# --- Stat effect ----------------------------------------------------
# Combined stat deltas from a set of installed mods, grade applied.
# Returns {stat_name: delta}. Drawbacks are folded in as negatives so
# callers only ever apply one dictionary.
#
# NOTE on sign: for stats where LOWER is better (Speed is seconds per
# swing), a positive "drawback" value must still make the stat worse, so
# it is ADDED rather than subtracted. Mods that improve Speed declare a
# negative modifier for the same reason.
static func mod_stat_deltas(installed_mods: Array) -> Dictionary:
	var out: Dictionary = {}
	for mod in installed_mods:
		var def = CraftingData.get_mod(String(mod.get("mod_id", "")))
		if def.is_empty():
			continue
		var grade = CraftingData.get_mod_grade(String(mod.get("grade_id", "standard")))
		var mult = float(grade["multiplier"])
		var draw_mult = float(grade["drawback_multiplier"])

		for stat in def.get("stat_modifiers", {}).keys():
			out[stat] = float(out.get(stat, 0.0)) + float(def["stat_modifiers"][stat]) * mult

		for stat2 in def.get("drawback", {}).keys():
			var penalty = float(def["drawback"][stat2]) * draw_mult
			if stat2 == "Speed":
				out[stat2] = float(out.get(stat2, 0.0)) + penalty
			else:
				out[stat2] = float(out.get(stat2, 0.0)) - penalty
	return out


# Total instability strain from installed mods -- feeds durability loss.
static func mod_instability_total(installed_mods: Array) -> float:
	var total := 0.0
	for mod in installed_mods:
		var def = CraftingData.get_mod(String(mod.get("mod_id", "")))
		var grade = CraftingData.get_mod_grade(String(mod.get("grade_id", "standard")))
		total += float(def.get("instability_cost", 0.0)) * float(grade["multiplier"])
	return total


# Human-readable summary of what a mod does at a given grade.
static func mod_effect_summary(mod_id: String, grade_id: String) -> String:
	var def = CraftingData.get_mod(mod_id)
	if def.is_empty():
		return ""
	var grade = CraftingData.get_mod_grade(grade_id)
	var parts: Array = []
	for stat in def.get("stat_modifiers", {}).keys():
		var v = float(def["stat_modifiers"][stat]) * float(grade["multiplier"])
		parts.append(("%+.1f " % v) + stat)
	for stat2 in def.get("drawback", {}).keys():
		var p = float(def["drawback"][stat2]) * float(grade["drawback_multiplier"])
		if p != 0.0:
			parts.append(("%+.1f " % (p if stat2 == "Speed" else -p)) + stat2)
	return ", ".join(parts)
