extends Control

# ============================================================
# TalentViewer.gd
# ============================================================
# The Talent Viewer panel, pulled out of main.gd (Pass 2 of splitting
# the file apart -- see GameData.gd for Pass 1). This script is
# attached to the TalentUI Control node itself, instantiated and added
# to the scene by main.gd's _build_talent_ui(), which also sets `main`
# below before calling build().
#
# A few things deliberately stayed in main.gd instead of moving here,
# because other systems (the trainer dialogue, the Crafting Assembly
# screen) use them too: _get_talent_box_label(), _make_flat_style(),
# _is_prereq_met(), _get_box_cost(), professions_unlocked, xp_pools,
# militant_points_available/engineer_points_available, NODES_PER_PATH,
# and TALENT_OWNED_COLOR/TALENT_UNLEARNED_COLOR. Every reference to
# those below is prefixed with "main." accordingly.
# ============================================================

# Back-reference to the Main script, set once right after this script
# is instantiated (see main.gd's _build_talent_ui()). Needed for
# everything listed above that's shared with other systems.
var main

var talent_grid_container: HBoxContainer
var talent_details_label: Label
var talent_learned_label: Label
var talent_master_container: Panel
var talent_novice_container: Panel
var talent_points_label: Label
var talent_requirements_container: VBoxContainer
var talent_requirements_line: ColorRect
var talent_column_labels_container: HBoxContainer
var talent_prereq_line: ColorRect
var talent_prereq_container: VBoxContainer
var current_talent_profession: String = ""

func _get_elites_requiring(profession_name: String, box_name: String) -> Array:
	var result: Array = []
	for elite_name in GameData.ELITE_PROFESSION_PREREQS.keys():
		for prereq in GameData.ELITE_PROFESSION_PREREQS[elite_name]:
			if prereq["profession"] == profession_name and prereq["box"] == box_name:
				result.append(elite_name)
	return result

# Display text for a single box (left "Unlockable" panel) -- just the
# ability/weapon name, flat stat lines, or a not-yet-designed fallback
# for any profession not built out yet. No tier name, no path name.
func _get_talent_box_display(profession_name: String, path_name: String) -> String:
	var reward = GameData.TALENT_SKILL_REWARDS.get(profession_name, {}).get(path_name, null)
	if reward == null:
		return "Not yet designed"

	match reward.get("type", ""):
		"ability":
			return reward["name"]
		"weapon":
			return "Weapon Cert - " + reward["name"]
		"novice_grants":
			return "\n".join(reward["names"])
		"passive":
			var lines: Array = []
			for stat_pair in reward["stats"]:
				lines.append("+" + str(stat_pair[1]) + " " + stat_pair[0])
			if reward.has("ability"):
				lines.append(reward["ability"])
			if reward.has("abilities"):
				for granted_ability in reward["abilities"]:
					lines.append(granted_ability)
			if reward.has("weapon"):
				lines.append("Weapon Cert - " + reward["weapon"])
			if reward.has("weapons"):
				for granted_weapon in reward["weapons"]:
					lines.append("Weapon Cert - " + granted_weapon)
			if reward.has("recipe_unlocks"):
				for recipe_name in reward["recipe_unlocks"]:
					lines.append("Recipe: " + recipe_name)
			if lines.size() == 0:
				return "Reserved for future stats"
			return "\n".join(lines)
		_:
			return "Not yet designed"

# Whole-profession summary (right "Learned" panel) -- lists every
# learned ability by name, then combined totals for passive stats
# (e.g. two owned Martial Training ranks that both grant One Hand Speed =
# one combined "+4 One Hand Speed" line, not two separate "+2" lines).
# Pending/undesigned boxes are skipped entirely.
func _get_talent_learned_summary(profession_name: String) -> String:
	var ability_lines: Array = []
	var passive_totals: Dictionary = {}

	for path_name in GameData.novice_professions[profession_name]["paths"].keys():
		var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
		var owned = path_data["unlocked_nodes"] >= path_data.get("max_nodes", main.NODES_PER_PATH)
		if not owned:
			continue

		var reward = GameData.TALENT_SKILL_REWARDS.get(profession_name, {}).get(path_name, null)
		if reward == null:
			continue

		match reward.get("type", ""):
			"ability":
				ability_lines.append(reward["name"])
			"weapon":
				ability_lines.append("Weapon Cert - " + reward["name"])
			"novice_grants":
				ability_lines.append_array(reward["names"])
			"passive":
				for stat_pair in reward["stats"]:
					var stat_name = stat_pair[0]
					var amount = stat_pair[1]
					passive_totals[stat_name] = passive_totals.get(stat_name, 0) + amount
				if reward.has("ability"):
					ability_lines.append(reward["ability"])
				if reward.has("abilities"):
					ability_lines.append_array(reward["abilities"])
				if reward.has("weapon"):
					ability_lines.append("Weapon Cert - " + reward["weapon"])
				if reward.has("weapons"):
					for granted_weapon in reward["weapons"]:
						ability_lines.append("Weapon Cert - " + granted_weapon)

	var lines: Array = []
	lines.append_array(ability_lines)
	for stat_name in passive_totals.keys():
		lines.append("+" + str(passive_totals[stat_name]) + " " + stat_name)

	if lines.size() == 0:
		return "Nothing learned yet."

	return "\n".join(lines)

func _build_talent_ui() -> void:
	name = "TalentUI"
	anchor_right = 1
	anchor_bottom = 1
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.anchor_right = 1
	backdrop.anchor_bottom = 1
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var main_panel = Panel.new()
	main_panel.position = Vector2(460, 195)
	main_panel.size = Vector2(1070, 740)
	main_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "SKILLS (testing only)"
	title_label.position = Vector2(20, 8)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(1030, 6)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): visible = false)
	main_panel.add_child(close_button)

	var profession_scroll = ScrollContainer.new()
	profession_scroll.position = Vector2(12, 40)
	profession_scroll.size = Vector2(220, 600)
	main_panel.add_child(profession_scroll)

	var profession_list = VBoxContainer.new()
	profession_list.custom_minimum_size = Vector2(210, 0)
	profession_list.add_theme_constant_override("separation", 4)
	profession_scroll.add_child(profession_list)

	# Basic professions first, then Elite -- Elite membership is
	# determined by GameData.ELITE_PROFESSION_PREREQS, so this list stays in
	# sync automatically if more Elite Professions are added later.
	var basic_header = Label.new()
	basic_header.text = "Basic"
	basic_header.custom_minimum_size = Vector2(210, 0)
	basic_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	basic_header.modulate = Color(0.6, 0.9, 0.9)
	basic_header.add_theme_font_size_override("font_size", 15)
	profession_list.add_child(basic_header)

	for profession_name in GameData.novice_professions.keys():
		if GameData.ELITE_PROFESSION_PREREQS.has(profession_name):
			continue
		var p_button = Button.new()
		p_button.text = profession_name
		p_button.focus_mode = Control.FOCUS_NONE
		p_button.custom_minimum_size = Vector2(210, 30)
		p_button.pressed.connect(_talent_select_profession.bind(profession_name))
		profession_list.add_child(p_button)

	# Spacer between the Basic and Elite groups -- more breathing room
	# than the list's normal 4px separation.
	var group_spacer = Control.new()
	group_spacer.custom_minimum_size = Vector2(210, 20)
	profession_list.add_child(group_spacer)

	var elite_header = Label.new()
	elite_header.text = "Elite"
	elite_header.custom_minimum_size = Vector2(210, 0)
	elite_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_header.modulate = Color(0.6, 0.9, 0.9)
	elite_header.add_theme_font_size_override("font_size", 15)
	profession_list.add_child(elite_header)

	for profession_name in GameData.novice_professions.keys():
		if not GameData.ELITE_PROFESSION_PREREQS.has(profession_name):
			continue
		var p_button = Button.new()
		p_button.text = profession_name
		p_button.focus_mode = Control.FOCUS_NONE
		p_button.custom_minimum_size = Vector2(210, 30)
		p_button.pressed.connect(_talent_select_profession.bind(profession_name))
		profession_list.add_child(p_button)

	# For Elite Professions, shows which base profession(s) must be
	# mastered to enter this one -- same idea as SWG's blue prereq names
	# stacked above the Master box in the elite profession tree view.
	# Shows which Elite Profession(s) require mastering THIS profession
	# (i.e. this box's "Master" rank) -- e.g. selecting Apothecary shows
	# "Leads to: Toxinsmith" here, with a short line connecting down to
	# the Master box below. Empty/hidden for professions nothing
	# requires yet. Populated in _refresh_talent_grid().
	talent_requirements_container = VBoxContainer.new()
	talent_requirements_container.position = Vector2(250, 36)
	talent_requirements_container.size = Vector2(800, 20)
	talent_requirements_container.add_theme_constant_override("separation", 2)
	main_panel.add_child(talent_requirements_container)

	# Short vertical connector from the label above down toward the
	# Master box -- same visual idea as SWG's line from the prereq names
	# down to Master Artisan. Deliberately stops a few px short so it
	# doesn't touch the box. Centered under the label; only shown when
	# the label has text.
	talent_requirements_line = ColorRect.new()
	talent_requirements_line.position = Vector2(649, 56)
	talent_requirements_line.size = Vector2(2, 14)
	talent_requirements_line.color = Color(0.5, 0.75, 1.0)
	main_panel.add_child(talent_requirements_line)

	talent_master_container = Panel.new()
	talent_master_container.position = Vector2(250, 74)
	talent_master_container.size = Vector2(800, 36)
	talent_master_container.add_theme_stylebox_override("panel", main._make_flat_style(Color(0, 0, 0, 0)))
	main_panel.add_child(talent_master_container)

	# Column-header row -- sits directly above the skill grid, one label
	# per column, aligned to that column's width so it lines up exactly
	# with the column beneath it. Shows which Elite Profession(s)
	# require that column's Rank IV -- e.g. "Sniper" appears above the
	# Rifles column, matching SWG's "Chef"/"Tailor"/"Merchant" row
	# above its base-profession columns. Rebuilt per-profession in
	# _refresh_talent_grid(); empty labels take up the same width so
	# columns without a linked Elite Profession just show blank space.
	talent_column_labels_container = HBoxContainer.new()
	talent_column_labels_container.position = Vector2(250, 122)
	talent_column_labels_container.size = Vector2(800, 30)
	talent_column_labels_container.add_theme_constant_override("separation", 14)
	main_panel.add_child(talent_column_labels_container)

	talent_grid_container = HBoxContainer.new()
	talent_grid_container.position = Vector2(250, 164)
	talent_grid_container.size = Vector2(800, 330)
	talent_grid_container.add_theme_constant_override("separation", 14)
	main_panel.add_child(talent_grid_container)

	# Novice bar -- sits directly under the first row of skills, just
	# like Master sits above the last row. Functional and clickable,
	# same pattern as Master: auto-granted on entering the profession.
	# Positioned at grid_top(164) + actual column height(324, now that
	# each column has 4 tiers (4*70 + 4*6 separation gaps, the last gap
	# being before the tree-name label) + the tree-name label itself
	# (~20px)) + 12px gap, matching Master's 12px gap above the grid.
	talent_novice_container = Panel.new()
	talent_novice_container.position = Vector2(250, 500)
	talent_novice_container.size = Vector2(800, 32)
	talent_novice_container.add_theme_stylebox_override("panel", main._make_flat_style(Color(0, 0, 0, 0)))
	main_panel.add_child(talent_novice_container)

	# Below Novice: for Elite Professions only, shows which base
	# profession(s) this one requires, with a short connector line
	# leading down to the text (opposite direction from the "leads to"
	# line above Master) -- e.g. below Sniper's Novice box, a line then
	# "Chrome Gunner". Empty/hidden for the four base professions.
	# Populated in _refresh_talent_grid().
	talent_prereq_line = ColorRect.new()
	talent_prereq_line.position = Vector2(649, 538)
	talent_prereq_line.size = Vector2(2, 10)
	talent_prereq_line.color = Color(0.5, 0.75, 1.0)
	main_panel.add_child(talent_prereq_line)

	talent_prereq_container = VBoxContainer.new()
	talent_prereq_container.position = Vector2(250, 550)
	talent_prereq_container.size = Vector2(800, 30)
	talent_prereq_container.add_theme_constant_override("separation", 2)
	main_panel.add_child(talent_prereq_container)

	# Bottom message frame, split evenly: left shows what the selected
	# box grants, right shows everything already learned in the
	# currently-viewed profession.
	var grants_panel = Panel.new()
	grants_panel.position = Vector2(250, 590)
	grants_panel.size = Vector2(395, 110)
	grants_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(grants_panel)

	var grants_header = Label.new()
	grants_header.text = "Unlockable"
	grants_header.position = Vector2(10, 4)
	grants_header.modulate = Color(0.6, 0.9, 0.9)
	grants_panel.add_child(grants_header)

	var grants_scroll = ScrollContainer.new()
	grants_scroll.position = Vector2(10, 28)
	grants_scroll.size = Vector2(375, 74)
	grants_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grants_panel.add_child(grants_scroll)

	talent_details_label = Label.new()
	talent_details_label.custom_minimum_size = Vector2(355, 0)
	talent_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	talent_details_label.text = "Select a skill box to view details."
	talent_details_label.modulate = Color(0.85, 0.95, 0.95)
	grants_scroll.add_child(talent_details_label)

	var learned_panel = Panel.new()
	learned_panel.position = Vector2(655, 590)
	learned_panel.size = Vector2(395, 110)
	learned_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(learned_panel)

	var learned_header = Label.new()
	learned_header.text = "Learned"
	learned_header.position = Vector2(10, 4)
	learned_header.modulate = Color(0.6, 0.9, 0.9)
	learned_panel.add_child(learned_header)

	var learned_scroll = ScrollContainer.new()
	learned_scroll.position = Vector2(10, 28)
	learned_scroll.size = Vector2(375, 74)
	learned_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	learned_panel.add_child(learned_scroll)

	talent_learned_label = Label.new()
	talent_learned_label.custom_minimum_size = Vector2(355, 0)
	talent_learned_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	talent_learned_label.text = ""
	talent_learned_label.modulate = Color(0.85, 0.95, 0.95)
	learned_scroll.add_child(talent_learned_label)

	talent_points_label = Label.new()
	talent_points_label.position = Vector2(250, 708)
	talent_points_label.size = Vector2(800, 22)
	talent_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talent_points_label.add_theme_font_size_override("font_size", 16)
	talent_points_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	talent_points_label.text = "Militant Points: --   |   Engineer Points: --"
	main_panel.add_child(talent_points_label)


# Groups a profession's raw path names (e.g. "One Hand I", "One Hand II",
# "One Hand III") into ordered columns by their shared base name, so each
# weapon/skill line renders as one vertical column of tiers -- matching
# the grid layout. Paths with no I/II/III suffix (like Scanning)
# become their own single-row column.
func _group_talent_paths(profession_name: String) -> Array:
	var columns: Array = []
	var lookup: Dictionary = {}

	for path_name in GameData.novice_professions[profession_name]["paths"].keys():
		if path_name == "Master" or path_name == "Novice":
			continue

		var base_name = path_name
		var tier = 1

		if path_name.ends_with(" IV"):
			tier = 4
			base_name = path_name.substr(0, path_name.length() - 3)
		elif path_name.ends_with(" III"):
			tier = 3
			base_name = path_name.substr(0, path_name.length() - 4)
		elif path_name.ends_with(" II"):
			tier = 2
			base_name = path_name.substr(0, path_name.length() - 3)
		elif path_name.ends_with(" I"):
			tier = 1
			base_name = path_name.substr(0, path_name.length() - 2)

		if not lookup.has(base_name):
			var entry = {"base": base_name, "tiers": {}}
			columns.append(entry)
			lookup[base_name] = entry

		lookup[base_name]["tiers"][tier] = path_name

	return columns

# A profession name styled and colored like the plain requirement/
# prereq labels, but clickable -- jumps straight to that profession's
# tree. Used everywhere a profession name shows up as a "leads to" or
# "requires" indicator (above Master, above a column, below Novice).
func _make_profession_link_button(profession_name: String) -> Button:
	var btn = Button.new()
	btn.text = profession_name
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 16)
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.75, 0.9, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.75, 0.9, 1.0))
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_talent_select_profession.bind(profession_name))
	return btn

func _talent_select_profession(profession_name: String) -> void:
	_refresh_talent_grid(profession_name)

func _talent_select_node(profession_name: String, path_name: String) -> void:
	talent_details_label.text = _get_talent_box_display(profession_name, path_name)

func _refresh_talent_grid(profession_name: String) -> void:
	current_talent_profession = profession_name

	# "Leads to: X" -- shows which Elite Profession(s) require mastering
	# THIS profession (i.e. its own Master box), with a connector line
	# down to the Master box (not touching it). This is the reverse of
	# a prereq list: a base profession's tree shows what it leads to,
	# not what leads to it (Apothecary's tree shows "Toxinsmith", not
	# the other way around).
	for child in talent_requirements_container.get_children():
		child.queue_free()

	var elites_requiring_master = _get_elites_requiring(profession_name, "Master")
	if elites_requiring_master.size() > 0:
		for elite_name in elites_requiring_master:
			var link_btn = _make_profession_link_button(elite_name)
			link_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			talent_requirements_container.add_child(link_btn)
		talent_requirements_line.visible = true
	else:
		talent_requirements_line.visible = false

	# Below Novice: for Elite Professions, shows which base
	# profession(s) are required to enter this one -- the forward
	# direction of GameData.ELITE_PROFESSION_PREREQS, deduped by profession
	# (Sniper needs two different Chrome Gunner boxes but should only
	# show "Chrome Gunner" once; Toxinsmith needs two different
	# professions, so both show, each on its own line).
	for child in talent_prereq_container.get_children():
		child.queue_free()

	var required_profession_names: Array = []
	for prereq in GameData.ELITE_PROFESSION_PREREQS.get(profession_name, []):
		if not required_profession_names.has(prereq["profession"]):
			required_profession_names.append(prereq["profession"])
	if required_profession_names.size() > 0:
		for required_profession_name in required_profession_names:
			var prereq_link_btn = _make_profession_link_button(required_profession_name)
			prereq_link_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			talent_prereq_container.add_child(prereq_link_btn)
		talent_prereq_line.visible = true
	else:
		talent_prereq_line.visible = false

	for child in talent_grid_container.get_children():
		child.queue_free()

	for child in talent_master_container.get_children():
		child.queue_free()

	var master_path_data = GameData.novice_professions[profession_name]["paths"].get("Master", null)
	if master_path_data != null:
		var master_owned = master_path_data["unlocked_nodes"] >= master_path_data.get("max_nodes", main.NODES_PER_PATH)
		var master_color = Color(0.85, 0.7, 0.2) if master_owned else Color(0.35, 0.28, 0.08)

		var master_btn = Button.new()
		master_btn.text = "Master " + profession_name
		master_btn.anchor_right = 1
		master_btn.anchor_bottom = 1
		master_btn.focus_mode = Control.FOCUS_NONE
		var master_style = main._make_flat_style(master_color)
		master_btn.add_theme_stylebox_override("normal", master_style)
		master_btn.add_theme_stylebox_override("hover", master_style)
		master_btn.add_theme_stylebox_override("pressed", master_style)
		master_btn.add_theme_stylebox_override("focus", master_style)
		master_btn.pressed.connect(_talent_select_node.bind(profession_name, "Master"))
		talent_master_container.add_child(master_btn)

	for child in talent_novice_container.get_children():
		child.queue_free()

	var novice_path_data = GameData.novice_professions[profession_name]["paths"].get("Novice", null)
	if novice_path_data != null:
		var novice_owned = novice_path_data["unlocked_nodes"] >= novice_path_data.get("max_nodes", main.NODES_PER_PATH)
		var novice_color = main.TALENT_OWNED_COLOR if novice_owned else main.TALENT_UNLEARNED_COLOR

		var novice_btn = Button.new()
		novice_btn.text = "Novice " + profession_name
		novice_btn.anchor_right = 1
		novice_btn.anchor_bottom = 1
		novice_btn.focus_mode = Control.FOCUS_NONE
		var novice_style = main._make_flat_style(novice_color)
		novice_btn.add_theme_stylebox_override("normal", novice_style)
		novice_btn.add_theme_stylebox_override("hover", novice_style)
		novice_btn.add_theme_stylebox_override("pressed", novice_style)
		novice_btn.add_theme_stylebox_override("focus", novice_style)
		novice_btn.pressed.connect(_talent_select_node.bind(profession_name, "Novice"))
		talent_novice_container.add_child(novice_btn)

	talent_points_label.text = "Militant Points: " + str(main.militant_points_available) + "   |   Engineer Points: " + str(main.engineer_points_available)
	talent_details_label.text = "Select a skill box to view details."
	talent_learned_label.text = _get_talent_learned_summary(profession_name)

	for child in talent_column_labels_container.get_children():
		child.queue_free()

	var columns = _group_talent_paths(profession_name)

	# Column-header row, built in lockstep with the grid below so each
	# label lines up with its column. Shows "Leads to: X" (or just X,
	# kept short since horizontal space is tight) for any column whose
	# Rank IV is a listed Elite Profession prereq -- e.g. "Sniper" sits
	# above the Rifles column. Blank labels still take up the column's
	# width so unlinked columns just show empty space, keeping every
	# column's Rank IV box aligned regardless of which ones have a label.
	for column in columns:
		var top_tier_keys = column["tiers"].keys()
		top_tier_keys.sort()
		var top_tier_path_name = column["tiers"][top_tier_keys[-1]]
		var elites_requiring_column = _get_elites_requiring(profession_name, top_tier_path_name)

		var col_label_box = VBoxContainer.new()
		col_label_box.custom_minimum_size = Vector2(180, 30)
		col_label_box.add_theme_constant_override("separation", 2)
		talent_column_labels_container.add_child(col_label_box)

		for elite_name in elites_requiring_column:
			var col_link_btn = _make_profession_link_button(elite_name)
			col_link_btn.custom_minimum_size = Vector2(180, 15)
			col_label_box.add_child(col_link_btn)

	for column in columns:
		var col_box = VBoxContainer.new()
		col_box.custom_minimum_size = Vector2(180, 0)
		col_box.add_theme_constant_override("separation", 6)
		talent_grid_container.add_child(col_box)

		var tier_keys = column["tiers"].keys()
		tier_keys.sort()

		# The "next up" box is the lowest-tier one that isn't owned yet
		# and whose prereq is already met -- i.e. the one box in this
		# column you'd actually train next. Only this box gets an XP
		# progress bar, same as SWG only highlighting your next skill.
		var next_path_name = ""
		if main.professions_unlocked.get(profession_name, false):
			for tier in tier_keys:
				var candidate_path_name = column["tiers"][tier]
				var candidate_path_data = GameData.novice_professions[profession_name]["paths"][candidate_path_name]
				var candidate_owned = candidate_path_data["unlocked_nodes"] >= candidate_path_data.get("max_nodes", main.NODES_PER_PATH)
				if not candidate_owned and main._is_prereq_met(profession_name, candidate_path_data):
					next_path_name = candidate_path_name
					break

		tier_keys.reverse()

		for tier in tier_keys:
			var path_name = column["tiers"][tier]
			var path_data = GameData.novice_professions[profession_name]["paths"][path_name]

			var owned = path_data["unlocked_nodes"] >= path_data.get("max_nodes", main.NODES_PER_PATH)

			var box_color: Color
			if owned:
				box_color = main.TALENT_OWNED_COLOR
			else:
				box_color = main.TALENT_UNLEARNED_COLOR

			var style = main._make_flat_style(box_color)

			var btn = Button.new()
			btn.text = main._get_talent_box_label(profession_name, path_name)
			btn.custom_minimum_size = Vector2(170, 70)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_stylebox_override("focus", style)
			btn.pressed.connect(_talent_select_node.bind(profession_name, path_name))
			col_box.add_child(btn)

			if path_name == next_path_name:
				var xp_type = path_data["xp_type"]
				var xp_cost = main._get_box_cost(path_data)["xp_cost"]
				var current_xp = main.xp_pools[xp_type]
				var progress_fraction = clamp(float(current_xp) / float(max(xp_cost, 1)), 0.0, 1.0)

				const PROGRESS_BAR_HEIGHT = 9.0

				var progress_track = ColorRect.new()
				progress_track.color = Color(0, 0, 0, 0.45)
				progress_track.anchor_left = 0.0
				progress_track.anchor_right = 1.0
				progress_track.anchor_top = 1.0
				progress_track.anchor_bottom = 1.0
				progress_track.offset_top = -PROGRESS_BAR_HEIGHT
				progress_track.offset_bottom = 0.0
				progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(progress_track)

				var progress_fill = ColorRect.new()
				progress_fill.color = Color(0.3, 1.0, 0.4) if progress_fraction >= 1.0 else Color(1.0, 0.85, 0.3)
				progress_fill.anchor_left = 0.0
				progress_fill.anchor_right = progress_fraction
				progress_fill.anchor_top = 1.0
				progress_fill.anchor_bottom = 1.0
				progress_fill.offset_top = -PROGRESS_BAR_HEIGHT
				progress_fill.offset_bottom = 0.0
				progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(progress_fill)

		# Tree-name label -- sits below the Rank I box (the last one
		# added above, since tiers render highest-to-lowest top-to-
		# bottom) so it's still obvious which weapon/skill line this
		# column represents now that the boxes themselves have
		# flavorful names instead of "Blade I/II/III/IV".
		var tree_label = Label.new()
		tree_label.text = column["base"]
		tree_label.custom_minimum_size = Vector2(170, 0)
		tree_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tree_label.modulate = Color(0.6, 0.75, 0.75)
		tree_label.add_theme_font_size_override("font_size", 13)
		col_box.add_child(tree_label)
