extends Control

# ============================================================
# SurveyBook.gd
# ============================================================
# The Survey Book panel, pulled out of main.gd (part of the ongoing
# split — see GameData.gd and TalentViewer.gd for earlier passes).
# Attached to the SurveyBookUI Control node, instantiated by main.gd's
# _build_survey_book_ui(), which sets `main` below before calling
# build().
#
# This one leans on a LOT of core game state (resource tracking,
# hotspots, scanning XP, etc.) since scanning/sampling is a core
# mechanic, not just UI — everything not exclusive to this panel is
# prefixed with "main." accordingly. _make_crafting_book_header() and
# book_category_collapsed are also shared with the Crafting Book (both
# use the same collapsible-category header system).
# ============================================================

var main

var survey_book_list_container: VBoxContainer
var survey_book_scan_label: Label
var survey_book_sample_button: Button
var survey_book_message_label: Label

func _build_survey_book_ui() -> void:
	name = "SurveyBookUI"
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
	main_panel.position = Vector2(510, 215)
	main_panel.size = Vector2(900, 650)
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	main_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Survey"
	title_label.position = Vector2(20, 8)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(860, 6)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): visible = false)
	main_panel.add_child(close_button)

	# Left panel — concentration reading and Sample button. No stats.
	var details_panel = Panel.new()
	details_panel.position = Vector2(20, 50)
	details_panel.size = Vector2(320, 560)
	details_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(details_panel)

	var details_header = Label.new()
	details_header.text = "Scan Result"
	details_header.position = Vector2(10, 4)
	details_header.modulate = Color(0.6, 0.9, 0.9)
	details_panel.add_child(details_header)

	survey_book_scan_label = Label.new()
	survey_book_scan_label.position = Vector2(10, 30)
	survey_book_scan_label.size = Vector2(300, 100)
	survey_book_scan_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	survey_book_scan_label.text = "Select a resource to scan it."
	survey_book_scan_label.modulate = Color(0.85, 0.95, 0.95)
	details_panel.add_child(survey_book_scan_label)

	survey_book_sample_button = Button.new()
	survey_book_sample_button.text = "Sample"
	survey_book_sample_button.position = Vector2(10, 140)
	survey_book_sample_button.custom_minimum_size = Vector2(300, 36)
	survey_book_sample_button.focus_mode = Control.FOCUS_NONE
	survey_book_sample_button.pressed.connect(main._on_sample_pressed)
	details_panel.add_child(survey_book_sample_button)

	survey_book_message_label = Label.new()
	survey_book_message_label.position = Vector2(10, 184)
	survey_book_message_label.size = Vector2(300, 80)
	survey_book_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	survey_book_message_label.text = ""
	survey_book_message_label.modulate = Color(0.9, 0.85, 0.6)
	details_panel.add_child(survey_book_message_label)

	# Right panel — scrollable Class > Subclass > active resource list.
	var list_panel = Panel.new()
	list_panel.position = Vector2(360, 50)
	list_panel.size = Vector2(520, 560)
	list_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(list_panel)

	var list_header = Label.new()
	list_header.text = "Active Resources"
	list_header.position = Vector2(10, 4)
	list_header.modulate = Color(0.6, 0.9, 0.9)
	list_panel.add_child(list_header)

	var list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(10, 28)
	list_scroll.size = Vector2(500, 522)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)

	survey_book_list_container = VBoxContainer.new()
	survey_book_list_container.custom_minimum_size = Vector2(485, 0)
	survey_book_list_container.add_theme_constant_override("separation", 2)
	list_scroll.add_child(survey_book_list_container)

func _refresh_survey_book() -> void:
	for child in survey_book_list_container.get_children():
		child.queue_free()

	survey_book_scan_label.text = "Select a resource to scan it."
	survey_book_message_label.text = ""

	var tree_data: Dictionary = {}
	for instance_name in main.active_resources:
		var subclass_name = main.resource_subclass_of[instance_name]
		var class_name_for_resource = main.resource_class_lookup[subclass_name]
		if not tree_data.has(class_name_for_resource):
			tree_data[class_name_for_resource] = {}
		if not tree_data[class_name_for_resource].has(subclass_name):
			tree_data[class_name_for_resource][subclass_name] = []
		tree_data[class_name_for_resource][subclass_name].append(instance_name)

	var unlocked_classes = []
	if main.active_survey_tool != "" and main.tool_class_access.has(main.active_survey_tool):
		unlocked_classes = main.tool_class_access[main.active_survey_tool]
	else:
		unlocked_classes = main._get_unlocked_classes()

	var class_names_sorted = []
	for class_name_key in tree_data.keys():
		if unlocked_classes.has(class_name_key):
			class_names_sorted.append(class_name_key)
	class_names_sorted.sort()

	for class_name_key in class_names_sorted:
		var class_category_key = "survey:" + class_name_key
		survey_book_list_container.add_child(main._make_crafting_book_header(class_name_key, 0, Color(0.85, 0.7, 0.3), class_category_key, _refresh_survey_book))

		if main.book_category_collapsed.get(class_category_key, false):
			continue

		var subclass_names_sorted = tree_data[class_name_key].keys()
		subclass_names_sorted.sort()

		for subclass_name in subclass_names_sorted:
			if main.gem_gated_subclasses.has(subclass_name) and not main._is_gem_scanning_unlocked():
				continue

			var subclass_category_key = class_category_key + "/" + subclass_name
			survey_book_list_container.add_child(main._make_crafting_book_header(subclass_name, 1, Color(0.7, 0.85, 0.85), subclass_category_key, _refresh_survey_book))

			if main.book_category_collapsed.get(subclass_category_key, false):
				continue

			var instances = tree_data[class_name_key][subclass_name]
			instances.sort_custom(func(a, b): return main.resource_type_of[a] < main.resource_type_of[b])

			for instance_name in instances:
				var btn = Button.new()
				btn.text = "    " + main._get_leaf_label(instance_name)
				btn.custom_minimum_size = Vector2(470, 28)
				btn.focus_mode = Control.FOCUS_NONE
				btn.pressed.connect(_select_survey_book_resource.bind(instance_name))
				survey_book_list_container.add_child(btn)

# Scans a resource — same math as the old resource_tree selection
# (nearest-hotspot concentration, Scanning XP, skill bonuses), just
# without ever displaying main.resource_stats anywhere on this screen.
func _select_survey_book_resource(instance_name: String) -> void:
	if not main.resource_hotspots.has(instance_name):
		main.resource_hotspot_centers[instance_name] = main.player.global_position
		main.resource_hotspots[instance_name] = main._generate_hotspot_set(main.resource_hotspot_centers[instance_name])

	var distance = main._get_nearest_hotspot_distance(instance_name)
	var proximity = 1.0 - clamp(distance / main.MAX_CONCENTRATION_RANGE, 0.0, 1.0)
	var concentration = int(round(100 * proximity))
	concentration = max(concentration, 1)

	var scanning_nodes = main._get_scrap_tinkerer_rank_count("Scanning")
	var mastery_nodes = main._get_scrap_tinkerer_rank_count("Fabrication Mastery")
	concentration += (scanning_nodes * 5) + (mastery_nodes * 2)
	concentration = min(concentration, 100)

	main.current_scan_resource = instance_name
	main.current_scan_concentration = concentration

	main._add_skill_xp("Scanning", 5)

	survey_book_scan_label.text = main._get_resource_display_label(instance_name) + ": " + str(concentration) + "% concentration"
	survey_book_message_label.text = ""

	# Keep the old survey_ui's labels in sync too, since they share
	# the same main.current_scan_resource/main.current_scan_concentration state.
	main.scan_result_label.text = survey_book_scan_label.text
	var stats_text = ""
	var stats = main.resource_stats[instance_name]
	for stat_name in stats.keys():
		stats_text += stat_name + ": " + main._format_number(stats[stat_name]) + "   "
	main.resource_stats_label.text = stats_text