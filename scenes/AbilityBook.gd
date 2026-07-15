extends Control

# ============================================================
# AbilityBook.gd
# ============================================================
# The Ability Book panel, pulled out of main.gd (part of the ongoing
# split — see GameData.gd and TalentViewer.gd for the earlier passes).
# Attached directly to the AbilityBookUI Control node, instantiated by
# main.gd's _build_ability_book_ui(), which sets `main` below before
# calling build().
#
# Shared with other systems, so left in main.gd instead of moving here:
# _make_flat_style(), _use_ability_by_name(), _get_apothecary_rank_unlocked(),
# ABILITY_DRAG_SOURCE_SCRIPT_PATH (also used by the Inventory Book), and
# professions_unlocked. Every reference to those below is prefixed
# with "main." accordingly.
# ============================================================

var main

var ability_book_list_container: VBoxContainer

func _is_ability_learned(ability_name: String) -> bool:
	var ability = GameData.ability_definitions[ability_name]
	var required_profession = ability["requires_profession"]

	if not main.professions_unlocked.get(required_profession, false):
		return false

	var required_box = ability["requires_box"]
	if required_box != "":
		var box_data = GameData.novice_professions[required_profession]["paths"][required_box]
		if box_data["unlocked_nodes"] < 1:
			return false

	return true

func _build_ability_book_ui() -> void:
	name = "AbilityBookUI"
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
	main_panel.position = Vector2(660, 230)
	main_panel.size = Vector2(600, 620)
	main_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Ability Book"
	title_label.position = Vector2(20, 8)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(560, 6)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): visible = false)
	main_panel.add_child(close_button)

	var hint_label = Label.new()
	hint_label.text = "Click to use once. Drag onto an action bar slot to assign it."
	hint_label.position = Vector2(20, 36)
	hint_label.modulate = Color(0.7, 0.75, 0.75)
	hint_label.add_theme_font_size_override("font_size", 12)
	main_panel.add_child(hint_label)

	var list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(20, 64)
	list_scroll.size = Vector2(560, 540)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_panel.add_child(list_scroll)

	ability_book_list_container = VBoxContainer.new()
	ability_book_list_container.custom_minimum_size = Vector2(540, 0)
	ability_book_list_container.add_theme_constant_override("separation", 4)
	list_scroll.add_child(ability_book_list_container)

func _make_ability_book_button(ability_name: String) -> Button:
	var btn = Button.new()
	btn.text = ability_name
	btn.custom_minimum_size = Vector2(540, 34)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(main._use_ability_by_name.bind(ability_name))

	var drag_script = load(main.ABILITY_DRAG_SOURCE_SCRIPT_PATH)
	if drag_script == null:
		push_warning("Ability Book: could not load drag script at " + main.ABILITY_DRAG_SOURCE_SCRIPT_PATH + " — dragging will not work until this path is fixed.")
	else:
		btn.set_script(drag_script)
		btn.set("ability_name", ability_name)

	return btn

func _refresh_ability_book() -> void:
	for child in ability_book_list_container.get_children():
		child.queue_free()

	var available_names: Array = ["Attack"]

	if main.professions_unlocked.get("Apothecary", false):
		available_names.append("Apply Bandage")
		if main._get_apothecary_rank_unlocked("Healing II"):
			available_names.append("IV Drip")
		if main._get_apothecary_rank_unlocked("Healing IV"):
			available_names.append("Healing Vapor")
		if main._get_apothecary_rank_unlocked("Stims I"):
			available_names.append("Adrenaline Boost")
		if main._get_apothecary_rank_unlocked("Stims III"):
			available_names.append("Blood Bag")

	for profession_name in GameData.novice_professions.keys():
		if not main.professions_unlocked.get(profession_name, false):
			continue

		for ability_name in GameData.ability_definitions.keys():
			var ability_data = GameData.ability_definitions[ability_name]
			if ability_data.get("requires_profession", "") != profession_name:
				continue
			if _is_ability_learned(ability_name):
				available_names.append(ability_name)

	available_names.sort()

	for ability_name in available_names:
		ability_book_list_container.add_child(_make_ability_book_button(ability_name))
