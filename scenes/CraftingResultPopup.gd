extends Control

# ============================================================
# CraftingResultPopup.gd
# ============================================================
# The "Item Crafted!" popup, pulled out of main.gd (part of the
# ongoing split — see GameData.gd and TalentViewer.gd for earlier
# passes). Attached to the CraftingResultUI Control node, instantiated
# by main.gd's _build_crafting_result_ui(), which sets `main` below
# before calling build(). The Crafting Book (still in main.gd for now)
# calls this popup's _show_crafting_result_popup() directly through
# main's crafting_result_ui reference once a craft finishes.
#
# Shared with other systems, so left in main.gd instead of moving here:
# _make_flat_style(), _get_inventory_display_name(), _format_number(),
# and inventory_stats. Every reference to those below is prefixed with
# "main." accordingly.
# ============================================================

var main

var crafting_result_label: Label
var crafting_result_mod_slots_label: Label

func _build_crafting_result_ui() -> void:
	name = "CraftingResultUI"
	anchor_right = 1
	anchor_bottom = 1
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.anchor_right = 1
	backdrop.anchor_bottom = 1
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var main_panel = Panel.new()
	main_panel.position = Vector2(760, 290)
	main_panel.size = Vector2(400, 500)
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	main_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Item Crafted!"
	title_label.position = Vector2(20, 10)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	title_label.add_theme_font_size_override("font_size", 18)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(360, 8)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): visible = false)
	main_panel.add_child(close_button)

	var stats_scroll = ScrollContainer.new()
	stats_scroll.position = Vector2(15, 46)
	stats_scroll.size = Vector2(370, 300)
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_panel.add_child(stats_scroll)

	crafting_result_label = Label.new()
	crafting_result_label.custom_minimum_size = Vector2(355, 0)
	crafting_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	crafting_result_label.text = ""
	crafting_result_label.modulate = Color(0.85, 0.95, 0.95)
	stats_scroll.add_child(crafting_result_label)

	var mod_slots_header = Label.new()
	mod_slots_header.text = "Mod Slots"
	mod_slots_header.position = Vector2(15, 356)
	mod_slots_header.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(mod_slots_header)

	var mod_slots_panel = Panel.new()
	mod_slots_panel.position = Vector2(15, 380)
	mod_slots_panel.size = Vector2(370, 90)
	mod_slots_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(mod_slots_panel)

	crafting_result_mod_slots_label = Label.new()
	crafting_result_mod_slots_label.position = Vector2(10, 8)
	crafting_result_mod_slots_label.size = Vector2(350, 74)
	crafting_result_mod_slots_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	crafting_result_mod_slots_label.text = "No mod slots installed yet. Adding item mods is a planned feature."
	crafting_result_mod_slots_label.modulate = Color(0.6, 0.6, 0.6)
	mod_slots_panel.add_child(crafting_result_mod_slots_label)

	var continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.position = Vector2(15, 460)
	continue_button.custom_minimum_size = Vector2(370, 30)
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(func(): visible = false)
	main_panel.add_child(continue_button)

func _show_crafting_result_popup(item_key: String) -> void:
	var display_name = main._get_inventory_display_name(item_key)
	var stats = main.inventory_stats.get(item_key, {})

	var lines: Array = []
	lines.append(display_name)
	lines.append("")

	var stat_lines: Array = []
	for stat_name in stats.keys():
		if stat_name == "Quality":
			continue
		stat_lines.append(stat_name + ": " + main._format_number(stats[stat_name]))

	if stat_lines.size() == 0:
		lines.append("No additional stats.")
	else:
		lines.append_array(stat_lines)

	crafting_result_label.text = "\n".join(lines)
	visible = true
