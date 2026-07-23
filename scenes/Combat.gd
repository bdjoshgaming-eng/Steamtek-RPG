extends Node

# ============================================================
# Combat.gd -- autoload singleton (combat LOGIC layer)
# ============================================================
# Phase 0 of the Combat Overhaul (see
# Steamtek_Combat_Overhaul_Outline.md). This is the single place all
# attack damage is computed, so balance can be tuned in one spot instead
# of inline inside main.gd. Behavior is IDENTICAL to the old inline math;
# this pass only relocates it to a chokepoint that later phases plug
# into (stat blocks, armor mitigation, the full coefficient formula).
#
# This file holds LOGIC only -- no static data tables. Combat DATA (the
# stat-block schema, CL anchor table, armor classes, etc.) will live in a
# separate CombatData.gd autoload starting in Phase 1.
#
# Setup required once in the Godot editor:
#   Project Settings -> Autoload -> add this file, Node Name "Combat"
# ============================================================

# Mirror of main.gd's NODES_PER_PATH so the path-based weapon-cert
# fallback below resolves max_nodes exactly as it did inline. Keep these
# two in sync until the cert model is expanded in a later phase.
const NODES_PER_PATH: int = 4


# Player basic/special attack damage. Rolls weapon variance, applies the
# crit roll, the profession certification bonus (1.10), and the
# uncertified-weapon penalty (0.5), then the ability coefficient
# (damage_multiplier). Returns the final integer damage plus the crit and
# uncertified flags the caller still needs for hit messaging.
#
# Expected keys in p:
#   base_damage          -- weapon Damage Rating (number)
#   damage_multiplier     -- ability coefficient (float, 1.0 = basic)
#   conditioning_nodes    -- summed Combat Training nodes (int)
#   max_conditioning_nodes-- max of the above (int), gates 2.0x vs 1.5x crit
#   profession_certified  -- bool, is the attacker's profession learned
#   equipped_weapon_name  -- String, used for the weapon-cert lookup
#   professions_unlocked  -- Dictionary of profession -> bool
func compute_player_attack_damage(p: Dictionary) -> Dictionary:
	# Master damage formula (framework spec 3.3), written out explicitly:
	#   Damage = WeaponDamage x AbilityCoefficient x ClassModifier
	#            x CertificationModifier x CriticalModifier
	#            x WeakPointModifier x RandomVariance
	# WeaponDamage x RandomVariance is the weapon's rolled base; every other
	# factor is a named multiplier so balance is tuned in one place.
	# ClassModifier and WeakPointModifier are 1.0 placeholders for now:
	# ClassModifier is reserved for per-class damage tuning, and
	# WeakPointModifier is populated by the Phase 5 combat-roll layer.
	var base_damage = p.get("base_damage", 5)
	var ability_coefficient: float = p.get("damage_multiplier", 1.0)
	var conditioning_nodes: int = p.get("conditioning_nodes", 0)
	var max_conditioning_nodes: int = p.get("max_conditioning_nodes", 0)

	# WeaponDamage x RandomVariance -- the weapon's rolled base damage.
	var variance = base_damage * 0.2
	var min_damage = max(1, int(base_damage - variance))
	var max_damage = int(base_damage + variance)
	var weapon_roll = randi_range(min_damage, max_damage)

	# CriticalModifier. Phase 5: the target's Critical Resistance (a
	# percentage from its CL) subtracts directly from the attacker's crit
	# chance, floored at zero so a high-CL enemy suppresses crits without
	# ever making them impossible to roll toward.
	var crit_hit = false
	var critical_modifier = 1.0
	var crit_resistance: float = p.get("target_crit_resistance", 0.0)
	var crit_chance = max(0.0, (conditioning_nodes * 0.03) - (crit_resistance / 100.0))
	if randf() < crit_chance:
		critical_modifier = 2.0 if conditioning_nodes >= max_conditioning_nodes else 1.5
		crit_hit = true

	# CertificationModifier -- profession-certified bonus (1.10) and the
	# Phase 10 graded uncertified damage penalty. The other three
	# uncertified penalties (accuracy, action cost, special lockout) are
	# applied by the caller, which is why this one is softer than the old
	# blanket 0.5.
	var certification_modifier = 1.0
	if p.get("profession_certified", false):
		certification_modifier *= 1.10
	var is_uncertified = is_weapon_uncertified(p.get("equipped_weapon_name", ""), p.get("professions_unlocked", {}))
	if is_uncertified:
		certification_modifier *= float(CombatData.UNCERTIFIED_PENALTY["damage_multiplier"])

	# ClassModifier and WeakPointModifier -- reserved 1.0 slots (Phase 5+).
	var class_modifier = 1.0
	var weak_point_modifier = 1.0

	# Single final multiply (one round; no intermediate rounding).
	var damage = round(float(weapon_roll) * ability_coefficient * class_modifier * certification_modifier * critical_modifier * weak_point_modifier)

	return {"damage": int(damage), "crit": crit_hit, "uncertified": is_uncertified}
func compute_enemy_attack_damage(min_damage: int, max_damage: int, damage_debuff: float) -> int:
	var damage = randi_range(min_damage, max_damage)
	damage = round(damage * (1.0 - damage_debuff))
	return int(damage)


# Resolves whether the equipped weapon is UNCERTIFIED for the attacker.
# Exact port of the inline cert check from main.gd's _perform_attack:
# weapons absent from WEAPON_CERT_REQUIREMENTS are always certified;
# keystone professions certify Novice weapons on unlock and gated weapons
# once enough keystone points are spent; path professions certify once the
# named box is fully filled.
func is_weapon_uncertified(equipped_weapon_name: String, professions_unlocked: Dictionary) -> bool:
	var weapon_cert_req = GameData.WEAPON_CERT_REQUIREMENTS.get(equipped_weapon_name, null)
	if weapon_cert_req == null:
		return false

	var requirement_options = weapon_cert_req if weapon_cert_req is Array else [weapon_cert_req]
	var is_uncertified = true
	for option in requirement_options:
		var cert_prof_data = GameData.novice_professions.get(option["profession"], {})
		# Keystone professions (Street Thug).
		if cert_prof_data.has("keystones"):
			# Not certified at all until the profession is learned.
			if not professions_unlocked.get(option["profession"], false):
				continue
			# Novice-tier weapon: certified as soon as the profession is
			# learned, no points needed.
			if option.get("box", "") == "Novice":
				is_uncertified = false
				break
			# Keystone-gated weapon: certified once enough points have been
			# spent in the matching keystone.
			if option.has("keystone"):
				var ks_name_req = option["keystone"]
				var ks_data_req = cert_prof_data["keystones"].get(ks_name_req, {})
				var points_needed = option.get("points_required", 5)
				if ks_data_req.get("points_spent", 0) >= points_needed:
					is_uncertified = false
					break
			continue
		# Path-based professions: check the specific box.
		var box_name = option.get("box", "")
		if box_name == "" or not cert_prof_data.has("paths") or not cert_prof_data["paths"].has(box_name):
			continue
		var cert_path_data = cert_prof_data["paths"][box_name]
		var cert_max = cert_path_data.get("max_nodes", NODES_PER_PATH)
		if cert_path_data["unlocked_nodes"] >= cert_max:
			is_uncertified = false
			break
	return is_uncertified


# Derives an enemy's core combat values from its hidden Combat Level by
# interpolating the CL anchor table (CombatData.CL_ANCHORS). Returns
# health, action, damage (center of the attack roll), and defense. CLs
# below or above the anchored range clamp to the nearest anchor (CL41-100
# stubbed until the table is expanded).
func derive_stats_from_cl(cl: int, archetype: String = "", faction: String = "") -> Dictionary:
	var anchors = CombatData.CL_ANCHORS
	var levels = anchors.keys()
	levels.sort()
	var lo = levels[0]
	var hi = levels[levels.size() - 1]
	if cl <= lo:
		return _apply_identity_modifiers(_anchor_values(anchors[lo]), archetype, faction)
	if cl >= hi:
		return _apply_identity_modifiers(_anchor_values(anchors[hi]), archetype, faction)
	var a = lo
	var b = hi
	for i in range(levels.size() - 1):
		if cl >= levels[i] and cl <= levels[i + 1]:
			a = levels[i]
			b = levels[i + 1]
			break
	var t = float(cl - a) / float(b - a)
	var da = anchors[a]
	var db = anchors[b]
	return _apply_identity_modifiers({
		"health": int(round(lerp(float(da["health"]), float(db["health"]), t))),
		"action": int(round(lerp(float(da["action"]), float(db["action"]), t))),
		"damage": int(round(lerp(float(da["damage"]), float(db["damage"]), t))),
		"defense": int(round(lerp(float(da["defense"]), float(db["defense"]), t))),
		"armor": int(round(lerp(float(da["armor"]), float(db["armor"]), t))),
		"crit_resist": lerp(float(da.get("crit_resist", 0.0)), float(db.get("crit_resist", 0.0)), t),
	}, archetype, faction)


func _anchor_values(a: Dictionary) -> Dictionary:
	return {
		"health": int(a["health"]),
		"action": int(a["action"]),
		"damage": int(a["damage"]),
		"defense": int(a["defense"]),
		"armor": int(a["armor"]),
		"crit_resist": float(a.get("crit_resist", 0.0)),
	}


# --- Phase 4a: armor mitigation ---
# Armor Rating converts to a Damage Reduction fraction via diminishing
# returns: DR = rating / (rating + ARMOR_DR_CONSTANT). It climbs steeply
# at first, flattens, and asymptotes toward 1.0 without reaching it, so no
# enemy is ever fully immune. Armor Penetration (weapons, Phase 4b)
# subtracts from rating before the curve; 0 for now.
const ARMOR_DR_CONSTANT: float = 140.0


func damage_reduction_from_rating(rating: int) -> float:
	if rating <= 0:
		return 0.0
	return float(rating) / (float(rating) + ARMOR_DR_CONSTANT)


# Reduces an incoming damage number by the target's armor. Returns the
# post-mitigation integer damage actually dealt.
func apply_mitigation(damage, armor_rating: int, armor_penetration: int = 0) -> int:
	var effective_rating = max(0, armor_rating - armor_penetration)
	var dr = damage_reduction_from_rating(effective_rating)
	return int(round(float(damage) * (1.0 - dr)))


# Effective Health: the raw damage total needed to drop this combatant,
# i.e. Base Health seen through its armor. This is the encounter-balancing
# value from Phase 4a on. EHP == base_health when armor is 0.
func effective_health(base_health: int, armor_rating: int) -> int:
	var dr = damage_reduction_from_rating(armor_rating)
	if dr >= 1.0:
		return base_health
	return int(round(float(base_health) / (1.0 - dr)))


# --- Grit: player DoT/CC resistance (ranged-only combat redesign) ---
# The replacement for the doc's "Defense/Toughness" stat: a separate
# mitigation lever from Armor (direct-hit damage, above) and the Dodge
# Roll (avoids damage entirely) that instead softens damage-over-time
# ticks and shortens/weakens crowd-control (stun, knockback, debuffs)
# landed on the PLAYER. Same diminishing-returns shape as armor, just a
# lower constant since Grit's point pool (the Auxiliary keystone's Grit
# nodes) is much smaller than Armor Rating's range.
#
# NOT YET CONSUMED ANYWHERE: no enemy DoT or CC ability exists yet for
# this to resist. Wire these in against the player's Grit total once one
# does -- the same unconsumed-stub state Melee/Ranged Defense are already
# in above in the Auxiliary keystone.
const GRIT_DR_CONSTANT: float = 60.0

func grit_dot_reduction(grit_points: float) -> float:
	if grit_points <= 0.0:
		return 0.0
	return grit_points / (grit_points + GRIT_DR_CONSTANT)

func grit_cc_duration_mult(grit_points: float) -> float:
	return 1.0 - grit_dot_reduction(grit_points)


# --- Phase 4b/4c: typed mitigation ---
# Reduces incoming damage by the target's resistance to THIS damage type.
# resistances maps damage type -> rating; the matched rating (minus armor
# penetration) runs through the same diminishing-returns curve as 4a.
# As of Phase 4c those ratings VARY per damage type: CombatData builds
# them from the enemy's CL-derived Armor Rating shaped by its archetype
# profile, so damage type selection now matters. An enemy with no
# archetype still resists uniformly, matching 4b behavior.
func apply_typed_mitigation(damage, resistances: Dictionary, damage_type: String, armor_penetration: int = 0) -> int:
	var rating = int(resistances.get(damage_type, 0))
	var effective_rating = max(0, rating - armor_penetration)
	var dr = damage_reduction_from_rating(effective_rating)
	return int(round(float(damage) * (1.0 - dr)))



# --- Phase 6a: identity modifiers ---
# Applies the archetype + faction stat multipliers to a CL-derived stat
# set. CL establishes the TIER (a CL40 enemy dwarfs a CL5 one); archetype
# and faction shape the character within that tier. Health, damage,
# defense and armor are scaled; crit_resist is left alone so it stays
# purely CL-driven as designed.
#
# Armor is scaled BEFORE resistances are built from it, so an armor
# modifier flows through into every damage-type resistance automatically.
func _apply_identity_modifiers(d: Dictionary, archetype: String, faction: String) -> Dictionary:
	if archetype == "" and faction == "":
		return d
	var m = CombatData.stat_modifiers_for(archetype, faction)
	d["health"] = int(round(float(d["health"]) * m["health"]))
	d["damage"] = int(round(float(d["damage"]) * m["damage"]))
	d["defense"] = int(round(float(d["defense"]) * m["defense"]))
	d["armor"] = int(round(float(d["armor"]) * m["armor"]))
	return d


# --- Phase 7: rank marks & threat ---
# Converts a hidden Combat Level into the rank mark the player actually
# sees. This is the ONLY thing that should ever surface CL to the UI --
# the raw number stays internal.
func rank_mark_for_cl(cl: int) -> String:
	for entry in CombatData.RANK_MARKS:
		if cl >= int(entry[0]):
			return String(entry[1])
	return String(CombatData.RANK_MARKS[CombatData.RANK_MARKS.size() - 1][1])


# Effective player Combat Level, derived from total skill points spent so
# the player sits on the same 1-100 scale enemies do. Phase 7 uses this
# purely for threat comparison; it is not a player-facing stat.
func effective_player_cl(total_skill_points_spent: int) -> int:
	var cl = 1.0 + float(total_skill_points_spent) * CombatData.PLAYER_CL_PER_SKILL_POINT
	return int(clamp(round(cl), 1, CombatData.PLAYER_CL_MAX))


# Threat of an enemy relative to the player, as {label, color}. Ratio is
# enemy CL over effective player CL, so an enemy at the player's own
# level reads "Even" regardless of where on the curve they both sit.
func threat_for(enemy_cl: int, player_cl: int) -> Dictionary:
	var safe_player_cl = max(player_cl, 1)
	var ratio = float(enemy_cl) / float(safe_player_cl)
	for tier in CombatData.THREAT_TIERS:
		if ratio <= float(tier[0]):
			return {"label": String(tier[1]), "color": tier[2]}
	return {"label": String(CombatData.THREAT_DEADLY[0]), "color": CombatData.THREAT_DEADLY[1]}


# ============================================================
# Phase 10: weapon proficiency + graded certification penalty
# ============================================================


# Points spent in the keystone that governs a weapon family. Returns 0
# for unknown families or professions without keystones.
func keystone_points_for_family(weapon_class: String, professions: Dictionary, profession_name: String = "Street Thug") -> int:
	var fam = CombatData.family_for_class(weapon_class)
	if fam.is_empty():
		return 0
	var prof = professions.get(profession_name, {})
	if not prof.has("keystones"):
		return 0
	var ks = prof["keystones"].get(fam["keystone"], {})
	return int(ks.get("points_spent", 0))


# Resolves a proficiency tier from points spent in the governing
# keystone. Returns tier number, display label, accuracy bonus and speed
# percentage. Unknown families fall back to Untrained.
func proficiency_for_family(weapon_class: String, keystone_points: int) -> Dictionary:
	var fam = CombatData.family_for_class(weapon_class)
	if fam.is_empty():
		return {"tier": 0, "label": "Untrained", "accuracy": 0, "speed_pct": 0.0, "family": weapon_class}
	var chosen = CombatData.PROFICIENCY_TIERS[0]
	for entry in CombatData.PROFICIENCY_TIERS:
		if keystone_points >= int(entry["min_points"]):
			chosen = entry
	return {
		"tier": int(chosen["tier"]),
		"label": String(chosen["label"]),
		"accuracy": int(chosen["accuracy"]),
		"speed_pct": float(chosen["speed_pct"]),
		"family": weapon_class,
	}


# The accuracy penalty applied when wielding an uncertified weapon.
func uncertified_accuracy_penalty(is_uncertified: bool) -> int:
	if not is_uncertified:
		return 0
	return int(CombatData.UNCERTIFIED_PENALTY["accuracy"])


# Action cost after the uncertified surcharge. Certified attackers pay
# the listed cost unchanged.
func adjusted_action_cost(action_cost: int, is_uncertified: bool) -> int:
	if not is_uncertified or action_cost <= 0:
		return action_cost
	return int(round(float(action_cost) * float(CombatData.UNCERTIFIED_PENALTY["action_cost_multiplier"])))


# Ability coefficient after the uncertified lockout. An uncertified
# wielder cannot get special-attack multipliers -- their specials land
# as basic hits -- but utility abilities keep their small coefficient.
func adjusted_ability_coefficient(coefficient: float, is_uncertified: bool) -> float:
	if not is_uncertified:
		return coefficient
	var cap = float(CombatData.UNCERTIFIED_PENALTY["max_ability_coefficient"])
	return min(coefficient, cap)


# Phase 9: returns the loot tier chances for an enemy's Combat Level by
# selecting the first band whose max_cl the CL falls within. CLs above
# the last band clamp to it.
func loot_tier_chances_for_cl(cl: int) -> Dictionary:
	var bands = CombatData.LOOT_TIER_BANDS
	var chosen = bands[bands.size() - 1]
	for band in bands:
		if cl <= int(band["max_cl"]):
			chosen = band
			break
	return {
		"Common": float(chosen["Common"]),
		"Uncommon": float(chosen["Uncommon"]),
		"Rare": float(chosen["Rare"]),
	}


# ============================================================
# STARTUP DATA VALIDATION
# ============================================================
# Cross-checks GameData against CombatData at startup. Reads
# ITEM_DEFINITIONS, not recipes, so it keeps working after the crafting
# system is removed.
#
# WHY THIS EXISTS: every check below guards the same failure shape --
# a dictionary lookup with a default, e.g.
#     resistances.get(damage_type, 0)
# If the key is wrong, the lookup returns a perfectly legal value and
# NOTHING complains. That is exactly how a stale GameData.gd let 12
# weapons carry pre-Phase-4b damage type names, match no resistance
# key, receive rating 0, and bypass enemy armor entirely for several
# sessions without a single error.
#
# These are all read-only checks. They run once, cost nothing, and turn
# silent data drift into a visible failure.
#
# Returns an Array of human-readable issue strings (empty == all good).
func validate_game_data() -> Array:
	var issues: Array = []

	# --- 1. Weapon families (item_class) must exist in WEAPON_FAMILIES ---
	# A mismatch means no proficiency tier and no certification resolve.
	for wname in GameData.ITEM_DEFINITIONS.keys():
		var idef = GameData.ITEM_DEFINITIONS[wname]
		if not idef.has("weapon_stat_ranges"):
			continue
		var fam = idef.get("item_class", "")
		if fam == "":
			issues.append("Weapon '" + wname + "' has no item_class (weapon family).")
		elif not CombatData.WEAPON_FAMILIES.has(fam):
			issues.append("Weapon '" + wname + "' has unknown family '" + str(fam) + "' -- proficiency and certs will not resolve.")

	# --- 3. Weapon family keystones must be real keystones ---
	# C1 retired the Crafting keystone; this catches anything still
	# pointing at a keystone that no longer exists.
	var street = GameData.novice_professions.get("Street Thug", {})
	var keystones = street.get("keystones", {})
	for fam_name in CombatData.WEAPON_FAMILIES.keys():
		var ks_ref = CombatData.WEAPON_FAMILIES[fam_name].get("keystone", "")
		if ks_ref != "" and not keystones.has(ks_ref):
			issues.append("Weapon family '" + fam_name + "' points at keystone '" + ks_ref + "' which does not exist.")

	# --- 4. Weapon cert requirements must point at real keystones ---
	for cert_weapon in GameData.WEAPON_CERT_REQUIREMENTS.keys():
		var req = GameData.WEAPON_CERT_REQUIREMENTS[cert_weapon]
		var cert_ks = req.get("keystone", "")
		if cert_ks != "" and not keystones.has(cert_ks):
			issues.append("Cert for '" + cert_weapon + "' requires keystone '" + cert_ks + "' which does not exist.")

	# --- 5. Ability nodes must have a matching ability definition ---
	# A node naming an ability that was never defined silently grants
	# nothing when purchased.
	for ks_name in keystones.keys():
		var nodes = keystones[ks_name].get("nodes", {})
		for node_name in nodes.keys():
			var nd = nodes[node_name]
			if nd.get("type", "") != "ability":
				continue
			var ability_name = nd.get("ability", node_name)
			if not GameData.ability_definitions.has(ability_name):
				issues.append("Keystone '" + ks_name + "' node '" + node_name + "' grants ability '" + ability_name + "' which has no definition.")

	# --- 6. Enemy archetypes and factions must resolve ---
	# An unknown archetype falls back to uniform 1.0 resistances, which
	# looks exactly like working code.
	var default_enemy_set = CombatData.default_enemies()
	for enemy_id in default_enemy_set.keys():
		var e = default_enemy_set[enemy_id]
		var arch = e.get("archetype", "")
		var fac = e.get("faction", "")
		if arch == "":
			issues.append("Enemy '" + enemy_id + "' has no archetype.")
		else:
			if not CombatData.ARCHETYPE_RESISTANCE_PROFILES.has(arch):
				issues.append("Enemy '" + enemy_id + "' archetype '" + arch + "' has no resistance profile.")
			if not CombatData.ARCHETYPE_STAT_MODIFIERS.has(arch):
				issues.append("Enemy '" + enemy_id + "' archetype '" + arch + "' has no stat modifiers.")
		if fac != "" and not CombatData.FACTION_DEFINITIONS.has(fac):
			issues.append("Enemy '" + enemy_id + "' faction '" + fac + "' is not defined.")

	return issues
