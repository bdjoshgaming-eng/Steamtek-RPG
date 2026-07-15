extends Node

# ============================================================
# Combat.gd
# ============================================================
# Attack resolution, ability validation, hit chance, damage, kill/XP
# crediting, and the training Dummy / Rust Marauder defeat+respawn
# logic — pulled out of main.gd (part of the ongoing split; see
# GameData.gd and TalentViewer.gd for earlier passes).
#
# UNLIKE the UI panels split out earlier, this one is NOT a Control —
# it's a plain Node, instantiated by main.gd and added as a child (no
# visual UI of its own). main.gd sets `main = self` on it right after
# creating it, same back-reference pattern as the panels.
#
# Deliberately scoped narrower than "all of combat": enemy-attacks-
# player logic (_check_dummy_attack, _check_enemy2_attack), the health/
# action regen ticks, and _roll_loot all stayed in main.gd, because
# they're tangled with systems well outside combat proper — Apothecary
# buff expiration (IV Drip/Healing Vapor/Adrenaline Boost/Blood Bag)
# piggybacks on the same regen ticks, and _roll_loot is shared with the
# Dumpster scavenging system. Pulling those out too would require a
# much bigger, riskier restructure for comparatively little benefit —
# see the handoff doc's "Combat system" section for the full reasoning.
#
# Every reference to main.gd's own state/helpers below is prefixed with
# "main." accordingly. GameData.* references are untouched since that's
# a globally-accessible autoload, not something needing a back-reference.
#
# IMPORTANT LESSON from building this file: a blind word-boundary
# find/replace will also "fix" identifier-shaped text sitting inside
# STRING LITERALS, not just real code references — this file has both
# node variables (dummy, enemy2) AND plain string target-ID labels
# ("dummy", "enemy2") used as simple tags in target_id comparisons.
# Only the real code identifiers should ever get the "main." prefix;
# the string literals must stay exactly as-is. Watch for this same
# trap in any future extraction.
# ============================================================

var main

func _attempt_attack() -> void:
	_perform_attack(1.0, main._get_dynamic_attack_action_cost(), "")

func _attempt_ability(ability_name: String) -> void:
	var ability = GameData.ability_definitions[ability_name]
	var weapon_class = main.crafted_item_class.get(main.equipped_weapon_name, "")
	var weapon_subclass = main.crafted_item_subclass.get(main.equipped_weapon_name, "")

	if ability.has("weapon_category"):
		# Pressure Enforcer melee abilities: gated by the equipped
		# weapon's actual One Hand/Two Hand/Unarmed category (subclass-
		# aware), not just its item_class — a "Sword" alone doesn't say
		# whether it's one- or two-handed, so item_class matching isn't
		# enough here. Bare hands resolve to "Unarmed" the same way a
		# real Brass Knuckles weapon does.
		var equipped_category = _get_pressure_weapon_type_label(weapon_class, weapon_subclass)
		if equipped_category != ability["weapon_category"]:
			main._show_combat_message(ability_name + " only works with " + ability["weapon_category"] + " weapons.")
			return
	else:
		# Every other ability (Chrome Gunner's ranged weapons, etc.) —
		# item_class alone is unambiguous here, no subclass needed.
		if not ability["weapons"].has(weapon_class):
			main._show_combat_message(ability_name + " only works with " + ", ".join(ability["weapons"]) + " weapons.")
			return

	var required_box = ability["requires_box"]
	var required_profession = ability["requires_profession"]

	if required_box != "":
		var box_data = GameData.novice_professions[required_profession]["paths"][required_box]
		if box_data["unlocked_nodes"] < 1:
			main._show_combat_message("You haven't learned " + ability_name + " yet! Unlock " + required_box + " first.")
			return
	else:
		if not main.professions_unlocked.get(required_profession, false):
			main._show_combat_message("You need to be a " + required_profession + " to use " + ability_name + "!")
			return

	_perform_attack(ability["damage_multiplier"], ability["action_cost"], ability_name)

# Maps a weapon's item_class + item_subclass to its Pressure Enforcer
# weapon-type label ("One Hand"/"Two Hand"/"Unarmed"), used to look up
# the matching per-type stat (e.g. "One Hand Speed") for whichever
# weapon is currently equipped. Subclass (not just class) matters here
# since some classes span both — a Sword can be "1 Handed" (Piston
# Blade) or "2 Handed" (Piston Greatblade), so item_class alone can't
# tell them apart.
func _get_pressure_weapon_type_label(weapon_class: String, weapon_subclass: String) -> String:
	if weapon_class == "Brass Knuckles" or weapon_class == "":
		return "Unarmed"
	elif GameData.pressure_enforcer_weapons.has(weapon_class):
		return "Two Hand" if weapon_subclass == "2 Handed" else "One Hand"
	return ""

# Sums a named passive stat (e.g. "One Hand Speed") across every owned
# skill box in a profession, reading directly from GameData.TALENT_SKILL_REWARDS —
# the same data that drives the Talent Viewer — so gameplay math and
# what's shown on screen can never drift out of sync.
func _get_total_passive_stat(profession_name: String, stat_name: String) -> float:
	var total = 0.0

	for path_name in GameData.novice_professions[profession_name]["paths"].keys():
		var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
		var owned = path_data["unlocked_nodes"] >= path_data.get("max_nodes", main.NODES_PER_PATH)
		if not owned:
			continue

		var reward = GameData.TALENT_SKILL_REWARDS.get(profession_name, {}).get(path_name, null)
		if reward == null or reward.get("type", "") != "passive":
			continue

		for stat_pair in reward["stats"]:
			if stat_pair[0] == stat_name:
				total += stat_pair[1]

	return total

# Applies a timed debuff to a target. "damage" reduces their outgoing
# damage (fully functional, applied in the enemy attack functions
# below). "accuracy" is tracked but currently has no live effect —
# there's no hit/miss system yet for reduced accuracy to act on.
# "attack_speed" (Bruise) is fully functional — it lengthens this
# target's own attack cooldown while active, applied in the enemy
# attack functions below alongside the damage debuff.
func _apply_debuff(target_id: String, debuff_type: String, amount: float, duration: float) -> void:
	if debuff_type == "damage":
		if target_id == "dummy":
			main.dummy_damage_debuff = amount
		else:
			main.enemy2_damage_debuff = amount
	elif debuff_type == "accuracy":
		if target_id == "dummy":
			main.dummy_accuracy_debuff = amount
		else:
			main.enemy2_accuracy_debuff = amount
	elif debuff_type == "attack_speed":
		if target_id == "dummy":
			main.dummy_attack_speed_debuff = amount
		else:
			main.enemy2_attack_speed_debuff = amount

	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if debuff_type == "damage":
			if target_id == "dummy":
				main.dummy_damage_debuff = 0.0
			else:
				main.enemy2_damage_debuff = 0.0
		elif debuff_type == "accuracy":
			if target_id == "dummy":
				main.dummy_accuracy_debuff = 0.0
			else:
				main.enemy2_accuracy_debuff = 0.0
		elif debuff_type == "attack_speed":
			if target_id == "dummy":
				main.dummy_attack_speed_debuff = 0.0
			else:
				main.enemy2_attack_speed_debuff = 0.0
	)

# Applies Bleed (damage-over-time) to a target. Ticks once per second
# via _on_player_regen_tick, dealing damage_per_tick each tick for
# duration_ticks seconds — same tick cadence as the Apothecary HoTs
# (IV Drip, Blood Bag), just damage instead of healing.
func _apply_dot(target_id: String, damage_per_tick: int, duration_ticks: int) -> void:
	if target_id == "dummy":
		main.dummy_bleed_damage_per_tick = damage_per_tick
		main.dummy_bleed_ticks_remaining = duration_ticks
	else:
		main.enemy2_bleed_damage_per_tick = damage_per_tick
		main.enemy2_bleed_ticks_remaining = duration_ticks

# Applies Anger (taunt) to a target for duration seconds. Currently the
# main.player is the only attackable target either enemy can go after, so
# this has no visible effect yet — it's scaffolding for when co-op
# companions/allies exist and taunt needs to pull enemy attention off
# them and back onto the main.player. Target-selection logic should check
# this timestamp first once that exists.
func _apply_taunt(target_id: String, duration: float) -> void:
	var expires_at_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	if target_id == "dummy":
		main.dummy_taunted_until_msec = expires_at_msec
	else:
		main.enemy2_taunted_until_msec = expires_at_msec

# Resolves a weapon class to its specific weapon-type XP pool. Returns
# "" for a recognized category weapon that doesn't have its own
# specific pool yet (e.g. Pistol, before a Pistols XP pool exists) —
# callers handle that case themselves (general category bonus only,
# no specific-type XP). Also returns "" for anything totally
# unrecognized; callers treat that as the bare-handed/Unarmed default.
func _get_weapon_xp_type(weapon_class: String) -> String:
	if weapon_class == "One Hand":
		return "One Hand XP"
	elif weapon_class == "Two Hand":
		return "Two Hand XP"
	elif weapon_class == "Brass Knuckles":
		return "Unarmed XP"
	elif GameData.rifle_weapons.has(weapon_class):
		return "Rifle XP"
	elif GameData.shotgun_weapons.has(weapon_class):
		return "Shotgun XP"
	elif GameData.heavy_weapon_types.has(weapon_class):
		return "Heavy Weapons XP"
	else:
		return ""

func _perform_attack(damage_multiplier: float, action_cost: int, ability_name: String) -> void:
	if not main.player_alive:
		main._show_combat_message("You are defeated! Waiting to respawn...")
		return

	if ability_name == "":
		# Plain "Attack" is the universal Unarmed action — bare hands or
		# an actual Brass Knuckles weapon only. Every other weapon type
		# has its own dedicated ability instead (Quick Hit, Overhead
		# Swing, the Chrome Gunner equivalents, etc.) — equip one of
		# those and use its named ability rather than generic Attack.
		var attack_weapon_class = main.crafted_item_class.get(main.equipped_weapon_name, "")
		if main.equipped_weapon_name != "" and attack_weapon_class != "Brass Knuckles":
			main._show_combat_message("Attack only works unarmed! Use a weapon-specific ability instead, or unequip your weapon.")
			return
	elif main.equipped_weapon_name == "":
		var allows_bare_handed = GameData.ability_definitions.has(ability_name) and GameData.ability_definitions[ability_name]["weapons"].has("Brass Knuckles")
		if not allows_bare_handed:
			main._show_combat_message("No weapon equipped! Press I to equip one.")
			return

	if not main.attack_ready:
		return

	var target_id = _get_nearest_enemy_in_range()
	if target_id == "":
		main._show_combat_message("No enemy in range! Get closer to attack.")
		return

	if action_cost > 0 and main.player_current_action < action_cost:
		main._show_combat_message("Not enough Action! Need " + str(action_cost) + ", have " + str(main.player_current_action) + ".")
		return

	var weapon_stats = main.inventory_stats.get(main.equipped_weapon_name, {})
	var base_damage = weapon_stats.get("Damage Rating", 5)
	var speed = weapon_stats.get("Speed", 2.0)

	var variance = base_damage * 0.2
	var min_damage = max(1, int(base_damage - variance))
	var max_damage = int(base_damage + variance)
	var damage = randi_range(min_damage, max_damage)

	var weapon_class = main.crafted_item_class.get(main.equipped_weapon_name, "")
	var weapon_subclass = main.crafted_item_subclass.get(main.equipped_weapon_name, "")

	# Melee item_class alone can't tell a one-handed weapon from a
	# two-handed one of the same class (e.g. Piston Blade vs Piston
	# Greatblade are both "Sword") — item_subclass ("1 Handed"/
	# "2 Handed") is what actually distinguishes them, so that's what
	# determines the XP-tracking category for melee weapons. Brass
	# Knuckles stay Unarmed regardless of subclass; ranged weapon
	# classes are unaffected since their subclass always matches their
	# class 1:1 already.
	var xp_class_key = weapon_class
	if weapon_class == "Brass Knuckles" or main.equipped_weapon_name == "":
		xp_class_key = "Brass Knuckles"
	elif GameData.pressure_enforcer_weapons.has(weapon_class):
		xp_class_key = "Two Hand" if weapon_subclass == "2 Handed" else "One Hand"

	var profession_name = ""
	var conditioning_paths = []

	if GameData.pressure_enforcer_weapons.has(weapon_class) or main.equipped_weapon_name == "":
		profession_name = "Pressure Enforcer"
		conditioning_paths = ["Martial Training I", "Martial Training II", "Martial Training III"]
	elif GameData.chrome_gunner_weapons.has(weapon_class):
		profession_name = "Chrome Gunner"
		conditioning_paths = ["Ranged Training I", "Ranged Training II", "Ranged Training III"]

	var crit_hit = false

	if profession_name != "":
		var conditioning_nodes = 0
		var max_conditioning_nodes = 0
		for path_name in conditioning_paths:
			var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
			conditioning_nodes += path_data["unlocked_nodes"]
			max_conditioning_nodes += path_data.get("max_nodes", main.NODES_PER_PATH)

		var speed_bonus = 0.0
		if profession_name == "Pressure Enforcer":
			var weapon_type_label = _get_pressure_weapon_type_label(weapon_class, weapon_subclass)
			if weapon_type_label != "":
				var speed_stat_total = _get_total_passive_stat(profession_name, weapon_type_label + " Speed")
				speed_bonus = speed_stat_total / 100.0
		else:
			speed_bonus = conditioning_nodes * 0.05
		speed = speed * (1.0 - speed_bonus)

		var crit_chance = conditioning_nodes * 0.03
		if randf() < crit_chance:
			var crit_multiplier = 2.0 if conditioning_nodes >= max_conditioning_nodes else 1.5
			damage = round(damage * crit_multiplier)
			crit_hit = true

	var certification_multiplier = 1.0
	if profession_name != "" and main.professions_unlocked.get(profession_name, false):
		certification_multiplier = 1.10

	var weapon_cert_multiplier = 1.0
	var weapon_cert_req = GameData.WEAPON_CERT_REQUIREMENTS.get(main.equipped_weapon_name, null)
	var is_uncertified = false
	if weapon_cert_req != null:
		var cert_path_data = GameData.novice_professions[weapon_cert_req["profession"]]["paths"][weapon_cert_req["box"]]
		var cert_max = cert_path_data.get("max_nodes", main.NODES_PER_PATH)
		if cert_path_data["unlocked_nodes"] < cert_max:
			weapon_cert_multiplier = 0.5
			is_uncertified = true

	damage = round(damage * damage_multiplier * certification_multiplier * weapon_cert_multiplier)

	# Hit-chance roll: our own formula, weapon Accuracy + main.player Accuracy
	# bonus (Pressure Enforcer only, for now) vs a flat per-enemy Defense
	# value. main.BASE_HIT_CHANCE keeps a bare, unskilled attacker landing
	# hits close to half the time; weapon quality and trained Accuracy
	# stats push that up meaningfully from there.
	var weapon_accuracy = weapon_stats.get("Accuracy", 50)
	var player_accuracy_bonus = 0.0
	if profession_name == "Pressure Enforcer":
		var weapon_type_label_for_accuracy = _get_pressure_weapon_type_label(weapon_class, weapon_subclass)
		if weapon_type_label_for_accuracy != "":
			player_accuracy_bonus = _get_total_passive_stat(profession_name, weapon_type_label_for_accuracy + " Accuracy")

	var target_defense = main.DUMMY_DEFENSE if target_id == "dummy" else main.ENEMY2_DEFENSE
	var hit_chance = clamp(main.BASE_HIT_CHANCE + (weapon_accuracy * 0.6) + player_accuracy_bonus - target_defense, main.MIN_HIT_CHANCE, main.MAX_HIT_CHANCE)

	if action_cost > 0:
		main.player_current_action -= action_cost

	if randf() * 100.0 > hit_chance:
		var miss_target_name = main.dummy_name if target_id == "dummy" else main.enemy2_name
		var miss_message = ""
		if ability_name != "":
			miss_message = ability_name + "! "
		miss_message += "You miss " + miss_target_name + "!"
		if action_cost > 0:
			miss_message += " (-" + str(action_cost) + " Action)"
		main._show_combat_message(miss_message)

		main.attack_ready = false
		main.attack_cooldown_timer.wait_time = speed
		main.attack_cooldown_timer.start()
		return

	var target_name = main.dummy_name if target_id == "dummy" else main.enemy2_name

	var is_aoe = false
	if ability_name != "" and GameData.ability_definitions.has(ability_name):
		is_aoe = GameData.ability_definitions[ability_name].get("aoe", false)

	var targets_to_hit: Array = []
	if is_aoe:
		if main.dummy_alive and main.player.global_position.distance_to(main.dummy.global_position) <= main.MELEE_RANGE:
			targets_to_hit.append("dummy")
		if main.enemy2_alive and main.player.global_position.distance_to(main.enemy2.global_position) <= main.MELEE_RANGE:
			targets_to_hit.append("enemy2")
	else:
		targets_to_hit.append(target_id)

	var hit_message = ""
	if ability_name != "":
		hit_message = ability_name + "! "
	if crit_hit:
		hit_message += "CRITICAL HIT! "

	if is_aoe and targets_to_hit.size() > 1:
		hit_message += "You hit all nearby enemies for " + str(int(damage)) + " damage each!"
	else:
		hit_message += "You hit " + target_name + " for " + str(int(damage)) + " damage!"

	if action_cost > 0:
		hit_message += " (-" + str(action_cost) + " Action)"
	if is_uncertified:
		hit_message += " (Uncertified weapon — reduced effectiveness)"

	var action_drain_amount = 0
	var debuff_type = ""
	var debuff_amount = 0.0
	var debuff_duration = 0.0
	var dot_damage_per_tick = 0
	var dot_duration_ticks = 0
	var taunt_duration = 0.0
	if ability_name != "" and GameData.ability_definitions.has(ability_name):
		var ability_data = GameData.ability_definitions[ability_name]
		action_drain_amount = ability_data.get("action_drain", 0)
		debuff_type = ability_data.get("debuff", "")
		debuff_amount = ability_data.get("debuff_amount", 0.0)
		debuff_duration = ability_data.get("debuff_duration", 0.0)
		dot_damage_per_tick = ability_data.get("dot_damage_per_tick", 0)
		dot_duration_ticks = ability_data.get("dot_duration_ticks", 0)
		taunt_duration = ability_data.get("taunt_duration", 0.0)

	var defeat_messages: Array = []

	for hit_target_id in targets_to_hit:
		if hit_target_id == "dummy":
			main.dummy_current_health -= int(damage)
			main.dummy_damage_by_weapon_class[xp_class_key] = main.dummy_damage_by_weapon_class.get(xp_class_key, 0) + int(damage)
			if action_drain_amount > 0:
				main.dummy_current_action = max(0, main.dummy_current_action - action_drain_amount)
			if debuff_type != "":
				_apply_debuff("dummy", debuff_type, debuff_amount, debuff_duration)
			if dot_duration_ticks > 0:
				_apply_dot("dummy", dot_damage_per_tick, dot_duration_ticks)
			if taunt_duration > 0.0:
				_apply_taunt("dummy", taunt_duration)
			if main.dummy_current_health <= 0 or main.dummy_current_action <= 0:
				defeat_messages.append(_defeat_dummy())
		else:
			main.enemy2_current_health -= int(damage)
			main.enemy2_damage_by_weapon_class[xp_class_key] = main.enemy2_damage_by_weapon_class.get(xp_class_key, 0) + int(damage)
			if action_drain_amount > 0:
				main.enemy2_current_action = max(0, main.enemy2_current_action - action_drain_amount)
			if debuff_type != "":
				_apply_debuff("enemy2", debuff_type, debuff_amount, debuff_duration)
			if dot_duration_ticks > 0:
				_apply_dot("enemy2", dot_damage_per_tick, dot_duration_ticks)
			if taunt_duration > 0.0:
				_apply_taunt("enemy2", taunt_duration)
			if main.enemy2_current_health <= 0 or main.enemy2_current_action <= 0:
				defeat_messages.append(_defeat_enemy2())

	if action_drain_amount > 0:
		hit_message += " (-" + str(action_drain_amount) + " Enemy Action)"
	if debuff_type == "damage":
		hit_message += " (" + ability_name + " applied — target deals reduced damage)"
	elif debuff_type == "accuracy":
		hit_message += " (" + ability_name + " applied — target accuracy reduced)"
	elif debuff_type == "attack_speed":
		hit_message += " (" + ability_name + " applied — target attacks slower)"
	if dot_duration_ticks > 0:
		hit_message += " (" + ability_name + " applied — " + str(dot_damage_per_tick) + " damage/sec for " + str(dot_duration_ticks) + " seconds)"
	if taunt_duration > 0.0:
		hit_message += " (" + ability_name + " applied — target is enraged)"

	# Combine damage-dealt text with any defeat/loot messages into ONE
	# message instead of two competing main._show_combat_message() calls —
	# previously the defeat message was shown first, then immediately
	# overwritten by the damage message before it could ever be seen.
	for defeat_message in defeat_messages:
		hit_message += "\n" + defeat_message

	main._show_combat_message(hit_message)

	main.attack_ready = false
	main.attack_cooldown_timer.wait_time = speed
	main.attack_cooldown_timer.start()

func _on_attack_cooldown_finished() -> void:
	main.attack_ready = true

func _get_nearest_enemy_in_range() -> String:
	var candidates = []

	if main.dummy_alive:
		var d = main.player.global_position.distance_to(main.dummy.global_position)
		if d <= main.MELEE_RANGE:
			candidates.append(["dummy", d])

	if main.enemy2_alive:
		var d2 = main.player.global_position.distance_to(main.enemy2.global_position)
		if d2 <= main.MELEE_RANGE:
			candidates.append(["enemy2", d2])

	if candidates.size() == 0:
		return ""

	candidates.sort_custom(func(a, b): return a[1] < b[1])
	return candidates[0][0]

func _defeat_dummy() -> String:
	main.dummy_alive = false
	main.dummy.visible = false
	main.dummy_health_bar_bg.visible = false
	main.dummy_health_bar_fill.visible = false
	main.dummy_action_bar_bg.visible = false
	main.dummy_action_bar_fill.visible = false
	main.dummy_name_label.visible = false

	var total_damage_dealt = 0
	for wc in main.dummy_damage_by_weapon_class.keys():
		total_damage_dealt += main.dummy_damage_by_weapon_class[wc]

	var xp_summary_parts: Array = []

	if total_damage_dealt > 0:
		for wc in main.dummy_damage_by_weapon_class.keys():
			var damage_share = float(main.dummy_damage_by_weapon_class[wc]) / float(total_damage_dealt)
			var share_xp = int(round(main.DUMMY_KILL_XP * damage_share))
			if share_xp <= 0:
				continue

			if wc == "One Hand" or wc == "Two Hand" or wc == "Brass Knuckles":
				var weapon_type_xp_type = _get_weapon_xp_type(wc)
				main._add_skill_xp(weapon_type_xp_type, share_xp)
				main._add_skill_xp("Martial XP", int(round(share_xp * main.MARTIAL_XP_RATE)))
				xp_summary_parts.append(str(share_xp) + " " + weapon_type_xp_type)
			elif GameData.chrome_gunner_weapons.has(wc):
				var ranged_type_xp_type = _get_weapon_xp_type(wc)
				if ranged_type_xp_type != "":
					main._add_skill_xp(ranged_type_xp_type, share_xp)
					xp_summary_parts.append(str(share_xp) + " " + ranged_type_xp_type)
				else:
					xp_summary_parts.append(str(share_xp) + " Ranged Weapon")
				main._add_skill_xp("Ranged Weapon", share_xp)
			else:
				# Bare-handed or an unrecognized weapon class — Unarmed
				# XP is the base/default for the Attack ability.
				main._add_skill_xp("Unarmed XP", share_xp)
				main._add_skill_xp("Martial XP", int(round(share_xp * main.MARTIAL_XP_RATE)))
				xp_summary_parts.append(str(share_xp) + " Unarmed XP")

	if xp_summary_parts.size() > 0:
		main._show_xp_gain_message("You've gained " + ", ".join(xp_summary_parts) + "!")

	main.dummy_damage_by_weapon_class = {}

	var dropped_items = main._roll_loot("Dummy")
	main._update_inventory_display()

	var cogs_dropped = randi_range(main.COGS_MIN_DROP, main.COGS_MAX_DROP)
	main.cogs += cogs_dropped
	main._update_cogs_display()

	var defeat_message = "The main.dummy has been defeated!\n"
	if dropped_items.size() > 0:
		defeat_message += "Loot: "
		for i in range(dropped_items.size()):
			defeat_message += dropped_items[i]
			if i < dropped_items.size() - 1:
				defeat_message += ", "
		defeat_message += ", " + str(cogs_dropped) + " Cogs"
	else:
		defeat_message += "Loot: " + str(cogs_dropped) + " Cogs"

	main.dummy_respawn_timer.start()

	return defeat_message

func _on_dummy_respawn() -> void:
	main.dummy_current_health = main.dummy_max_health
	main.dummy_current_action = main.dummy_max_action
	main.dummy_alive = true
	main.dummy_damage_debuff = 0.0
	main.dummy_accuracy_debuff = 0.0
	main.dummy_attack_speed_debuff = 0.0
	main.dummy_bleed_ticks_remaining = 0
	main.dummy_bleed_damage_per_tick = 0
	main.dummy_taunted_until_msec = 0
	main.dummy_damage_by_weapon_class = {}
	main.dummy.visible = true
	main.dummy_health_bar_bg.visible = true
	main.dummy_health_bar_fill.visible = true
	main.dummy_action_bar_bg.visible = true
	main.dummy_action_bar_fill.visible = true
	main.dummy_name_label.visible = true
	main._show_combat_message("The main.dummy has respawned.")

func _defeat_enemy2() -> String:
	main.enemy2_alive = false
	main.enemy2.visible = false
	main.enemy2_health_bar_bg.visible = false
	main.enemy2_health_bar_fill.visible = false
	main.enemy2_action_bar_bg.visible = false
	main.enemy2_action_bar_fill.visible = false
	main.enemy2_name_label.visible = false

	var total_damage_dealt2 = 0
	for wc in main.enemy2_damage_by_weapon_class.keys():
		total_damage_dealt2 += main.enemy2_damage_by_weapon_class[wc]

	var xp_summary_parts2: Array = []

	if total_damage_dealt2 > 0:
		for wc in main.enemy2_damage_by_weapon_class.keys():
			var damage_share2 = float(main.enemy2_damage_by_weapon_class[wc]) / float(total_damage_dealt2)
			var share_xp2 = int(round(main.ENEMY2_KILL_XP * damage_share2))
			if share_xp2 <= 0:
				continue

			if wc == "One Hand" or wc == "Two Hand" or wc == "Brass Knuckles":
				var weapon_type_xp_type2 = _get_weapon_xp_type(wc)
				main._add_skill_xp(weapon_type_xp_type2, share_xp2)
				main._add_skill_xp("Martial XP", int(round(share_xp2 * main.MARTIAL_XP_RATE)))
				xp_summary_parts2.append(str(share_xp2) + " " + weapon_type_xp_type2)
			elif GameData.chrome_gunner_weapons.has(wc):
				var ranged_type_xp_type2 = _get_weapon_xp_type(wc)
				if ranged_type_xp_type2 != "":
					main._add_skill_xp(ranged_type_xp_type2, share_xp2)
					xp_summary_parts2.append(str(share_xp2) + " " + ranged_type_xp_type2)
				else:
					xp_summary_parts2.append(str(share_xp2) + " Ranged Weapon")
				main._add_skill_xp("Ranged Weapon", share_xp2)
			else:
				main._add_skill_xp("Unarmed XP", share_xp2)
				main._add_skill_xp("Martial XP", int(round(share_xp2 * main.MARTIAL_XP_RATE)))
				xp_summary_parts2.append(str(share_xp2) + " Unarmed XP")

	if xp_summary_parts2.size() > 0:
		main._show_xp_gain_message("You've gained " + ", ".join(xp_summary_parts2) + "!")

	main.enemy2_damage_by_weapon_class = {}

	var dropped_items = main._roll_loot("Enemy2")
	main._update_inventory_display()

	var cogs_dropped = randi_range(main.COGS_MIN_DROP, main.COGS_MAX_DROP)
	main.cogs += cogs_dropped
	main._update_cogs_display()

	var defeat_message = main.enemy2_name + " has been defeated!\n"
	if dropped_items.size() > 0:
		defeat_message += "Loot: "
		for i in range(dropped_items.size()):
			defeat_message += dropped_items[i]
			if i < dropped_items.size() - 1:
				defeat_message += ", "
		defeat_message += ", " + str(cogs_dropped) + " Cogs"
	else:
		defeat_message += "Loot: " + str(cogs_dropped) + " Cogs"

	main.enemy2_respawn_timer.start()

	return defeat_message

func _on_enemy2_respawn() -> void:
	main.enemy2_current_health = main.enemy2_max_health
	main.enemy2_current_action = main.enemy2_max_action
	main.enemy2_alive = true
	main.enemy2_damage_debuff = 0.0
	main.enemy2_accuracy_debuff = 0.0
	main.enemy2_attack_speed_debuff = 0.0
	main.enemy2_bleed_ticks_remaining = 0
	main.enemy2_bleed_damage_per_tick = 0
	main.enemy2_taunted_until_msec = 0
	main.enemy2_damage_by_weapon_class = {}
	main.enemy2.visible = true
	main.enemy2_health_bar_bg.visible = true
	main.enemy2_health_bar_fill.visible = true
	main.enemy2_action_bar_bg.visible = true
	main.enemy2_action_bar_fill.visible = true
	main.enemy2_name_label.visible = true
	main._show_combat_message(main.enemy2_name + " has respawned.")
