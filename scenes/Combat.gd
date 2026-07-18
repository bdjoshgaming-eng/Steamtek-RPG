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

	# CriticalModifier.
	var crit_hit = false
	var critical_modifier = 1.0
	var crit_chance = conditioning_nodes * 0.03
	if randf() < crit_chance:
		critical_modifier = 2.0 if conditioning_nodes >= max_conditioning_nodes else 1.5
		crit_hit = true

	# CertificationModifier -- profession-certified bonus (1.10) and the
	# uncertified-weapon penalty (0.5, placeholder until the Phase 10 model).
	var certification_modifier = 1.0
	if p.get("profession_certified", false):
		certification_modifier *= 1.10
	var is_uncertified = _resolve_uncertified(p.get("equipped_weapon_name", ""), p.get("professions_unlocked", {}))
	if is_uncertified:
		certification_modifier *= 0.5

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
func _resolve_uncertified(equipped_weapon_name: String, professions_unlocked: Dictionary) -> bool:
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
func derive_stats_from_cl(cl: int) -> Dictionary:
	var anchors = CombatData.CL_ANCHORS
	var levels = anchors.keys()
	levels.sort()
	var lo = levels[0]
	var hi = levels[levels.size() - 1]
	if cl <= lo:
		return _anchor_values(anchors[lo])
	if cl >= hi:
		return _anchor_values(anchors[hi])
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
	return {
		"health": int(round(lerp(float(da["health"]), float(db["health"]), t))),
		"action": int(round(lerp(float(da["action"]), float(db["action"]), t))),
		"damage": int(round(lerp(float(da["damage"]), float(db["damage"]), t))),
		"defense": int(round(lerp(float(da["defense"]), float(db["defense"]), t))),
		"armor": int(round(lerp(float(da["armor"]), float(db["armor"]), t))),
	}


func _anchor_values(a: Dictionary) -> Dictionary:
	return {
		"health": int(a["health"]),
		"action": int(a["action"]),
		"damage": int(a["damage"]),
		"defense": int(a["defense"]),
		"armor": int(a["armor"]),
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


# --- Phase 4b: typed mitigation ---
# Reduces incoming damage by the target's resistance to THIS damage type.
# resistances maps damage type -> rating; the matched rating (minus armor
# penetration) runs through the same diminishing-returns curve as 4a.
# Phase 4b resistances are uniform, so this matches 4a numerically until
# 4c varies them.
func apply_typed_mitigation(damage, resistances: Dictionary, damage_type: String, armor_penetration: int = 0) -> int:
	var rating = int(resistances.get(damage_type, 0))
	var effective_rating = max(0, rating - armor_penetration)
	var dr = damage_reduction_from_rating(effective_rating)
	return int(round(float(damage) * (1.0 - dr)))
