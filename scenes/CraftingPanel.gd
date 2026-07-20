extends Node

# ============================================================
# CraftingPanel.gd -- blueprint crafting UI (Phase 3c)
# ============================================================
# Built entirely in code, mirroring KeystoneViewer's pattern: main.gd
# instantiates this, hands it a parent Control, and it builds itself.
#
# Reads BLUEPRINTS from CraftingData and material batches from main. All
# state changes go through main._perform_craft(), which validates, consumes
# materials and grants the finished item -- this file never mutates state
# directly.
#
# NOTE: this script extends Node, NOT CanvasItem, so CanvasItem-only calls
# such as get_viewport_rect() are unavailable here. Sizes come from the
# parent Control.
# ============================================================

var main

var root: Control
var blueprint_list: VBoxContainer
var slot_container: VBoxContainer
var preview_label: Label
var craft_button: Button
var status_label: Label

var selected_blueprint_id: String = ""
# slot_id -> batch_id
var selections: Dictionary = {}

const PANEL_BG := Color(0.07, 0.08, 0.10, 0.96)
const ACCENT := Color(0.85, 0.62, 0.22)
const TEXT_DIM := Color(0.62, 0.66, 0.72)
const TEXT_OK := Color(0.55, 0.85, 0.55)
const TEXT_BAD := Color(0.90, 0.45, 0.40)


func setup(parent: Control) -> void:
	_build_ui(parent)
	refresh()


func _build_ui(parent: Control) -> void:
	root = parent

	var backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.02, 0.03, 0.85)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	# --- header ---
	var strip = ColorRect.new()
	strip.color = PANEL_BG
	strip.anchor_right = 1.0
	strip.offset_bottom = 54
	root.add_child(strip)

	var title = Label.new()
	title.text = "CRAFTING"
	title.position = Vector2(20, 12)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	status_label = Label.new()
	status_label.anchor_left = 0.0
	status_label.position = Vector2(160, 16)
	status_label.add_theme_color_override("font_color", TEXT_DIM)
	root.add_child(status_label)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -52
	close_btn.offset_top = 6
	close_btn.offset_right = -10
	close_btn.offset_bottom = 48
	close_btn.pressed.connect(_on_close)
	root.add_child(close_btn)

	# --- left: blueprint list ---
	var left_bg = Panel.new()
	left_bg.offset_left = 14
	left_bg.offset_top = 66
	left_bg.offset_right = 334
	left_bg.anchor_bottom = 1.0
	left_bg.offset_bottom = -14
	root.add_child(left_bg)

	var left_title = Label.new()
	left_title.text = "Blueprints"
	left_title.position = Vector2(28, 76)
	left_title.add_theme_color_override("font_color", ACCENT)
	root.add_child(left_title)

	var left_scroll = ScrollContainer.new()
	left_scroll.offset_left = 24
	left_scroll.offset_top = 104
	left_scroll.offset_right = 326
	left_scroll.anchor_bottom = 1.0
	left_scroll.offset_bottom = -24
	root.add_child(left_scroll)

	blueprint_list = VBoxContainer.new()
	blueprint_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(blueprint_list)

	# --- right: slots + preview ---
	var right_bg = Panel.new()
	right_bg.offset_left = 348
	right_bg.offset_top = 66
	right_bg.anchor_right = 1.0
	right_bg.offset_right = -14
	right_bg.anchor_bottom = 1.0
	right_bg.offset_bottom = -14
	root.add_child(right_bg)

	var right_title = Label.new()
	right_title.text = "Materials"
	right_title.position = Vector2(362, 76)
	right_title.add_theme_color_override("font_color", ACCENT)
	root.add_child(right_title)

	var right_scroll = ScrollContainer.new()
	right_scroll.offset_left = 358
	right_scroll.offset_top = 104
	right_scroll.anchor_right = 1.0
	right_scroll.offset_right = -24
	right_scroll.anchor_bottom = 1.0
	right_scroll.offset_bottom = -150
	root.add_child(right_scroll)

	slot_container = VBoxContainer.new()
	slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(slot_container)

	preview_label = Label.new()
	preview_label.offset_left = 358
	preview_label.anchor_top = 1.0
	preview_label.anchor_bottom = 1.0
	preview_label.anchor_right = 1.0
	preview_label.offset_top = -138
	preview_label.offset_right = -24
	preview_label.offset_bottom = -66
	preview_label.add_theme_color_override("font_color", TEXT_DIM)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(preview_label)

	craft_button = Button.new()
	craft_button.text = "Craft"
	craft_button.offset_left = 358
	craft_button.anchor_top = 1.0
	craft_button.anchor_bottom = 1.0
	craft_button.offset_top = -58
	craft_button.offset_bottom = -20
	craft_button.custom_minimum_size = Vector2(180, 38)
	craft_button.pressed.connect(_on_craft_pressed)
	root.add_child(craft_button)


# ------------------------------------------------------------
# Refresh
# ------------------------------------------------------------

func refresh() -> void:
	_refresh_blueprint_list()
	_refresh_slots()
	_refresh_preview()
	_refresh_status()


func _refresh_status() -> void:
	if status_label == null:
		return
	var count = 0
	for bid in main.material_batches.keys():
		count += int(main.material_batches[bid].get("amount", 0))
	status_label.text = "Materials carried: " + str(count) + " units across " + str(main.material_batches.size()) + " batches"


func _refresh_blueprint_list() -> void:
	if blueprint_list == null:
		return
	for child in blueprint_list.get_children():
		child.queue_free()

	var ids = CraftingData.BLUEPRINTS.keys()
	ids.sort()
	for bp_id in ids:
		var bp = CraftingData.BLUEPRINTS[bp_id]
		var btn = Button.new()
		var craftable = _blueprint_is_craftable(String(bp_id))
		btn.text = String(bp.get("display_name", bp_id)) + ("" if craftable else "  (no materials)")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(290, 34)
		if String(bp_id) == selected_blueprint_id:
			btn.add_theme_color_override("font_color", ACCENT)
		elif not craftable:
			btn.add_theme_color_override("font_color", TEXT_DIM)
		btn.pressed.connect(_on_blueprint_selected.bind(String(bp_id)))
		blueprint_list.add_child(btn)


# True when every slot has at least one usable batch in the player's store.
func _blueprint_is_craftable(bp_id: String) -> bool:
	var bp = CraftingData.get_blueprint(bp_id)
	for slot in bp.get("material_slots", []):
		if main._batches_for_slot(slot).is_empty():
			return false
	return true


func _refresh_slots() -> void:
	if slot_container == null:
		return
	for child in slot_container.get_children():
		child.queue_free()

	if selected_blueprint_id == "":
		var hint = Label.new()
		hint.text = "Select a blueprint on the left."
		hint.add_theme_color_override("font_color", TEXT_DIM)
		slot_container.add_child(hint)
		return

	var bp = CraftingData.get_blueprint(selected_blueprint_id)
	for slot in bp.get("material_slots", []):
		var slot_id = String(slot.get("slot_id", ""))
		var row = VBoxContainer.new()

		var head = Label.new()
		head.text = String(slot.get("slot_name", slot_id)) + "  --  needs " + str(int(slot.get("amount", 1))) + " unit(s)"
		head.add_theme_color_override("font_color", ACCENT)
		row.add_child(head)

		var accepts: Array = slot.get("accepts", [])
		var accepts_lbl = Label.new()
		accepts_lbl.text = "   accepts: " + ", ".join(accepts)
		accepts_lbl.add_theme_color_override("font_color", TEXT_DIM)
		row.add_child(accepts_lbl)

		var options = main._batches_for_slot(slot)
		if options.is_empty():
			var none = Label.new()
			none.text = "   nothing suitable carried"
			none.add_theme_color_override("font_color", TEXT_BAD)
			row.add_child(none)
		else:
			var picker = OptionButton.new()
			picker.custom_minimum_size = Vector2(420, 32)
			var chosen_index = 0
			for i in range(options.size()):
				var b = options[i]
				picker.add_item(
					String(b.get("display_name", "material"))
					+ "  (Q" + str(int(b.get("quality", 0)))
					+ ", " + str(int(b.get("amount", 0))) + " held)"
				)
				picker.set_item_metadata(i, String(b.get("batch_id", "")))
				if selections.get(slot_id, "") == String(b.get("batch_id", "")):
					chosen_index = i
			picker.select(chosen_index)
			# Keep the model in step with what is displayed.
			selections[slot_id] = String(picker.get_item_metadata(chosen_index))
			picker.item_selected.connect(_on_slot_choice.bind(slot_id, picker))
			row.add_child(picker)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		row.add_child(spacer)
		slot_container.add_child(row)


func _refresh_preview() -> void:
	if preview_label == null or craft_button == null:
		return

	if selected_blueprint_id == "":
		preview_label.text = ""
		craft_button.disabled = true
		return

	var selection = _build_selection()
	var problems = CraftingService.validate_selection(selected_blueprint_id, selection)
	if not problems.is_empty():
		preview_label.add_theme_color_override("font_color", TEXT_BAD)
		preview_label.text = "Cannot craft yet:\n- " + "\n- ".join(problems)
		craft_button.disabled = true
		return

	var potential = CraftingService.compute_material_potential(selected_blueprint_id, selection)
	var tier_id = CraftingData.quality_tier_for(potential)
	var bp = CraftingData.get_blueprint(selected_blueprint_id)
	preview_label.add_theme_color_override("font_color", TEXT_OK)
	preview_label.text = (
		"Ready to craft: " + String(bp.get("display_name", selected_blueprint_id))
		+ "\nMaterial potential: " + str(int(round(potential))) + " / 100"
		+ "   (" + CraftingData.quality_tier_name(tier_id) + ")"
		+ "\nBetter materials raise this. Experimentation (a later phase) decides how much of it is realised."
	)
	craft_button.disabled = false


# Resolves the stored batch_id choices into the actual batch dictionaries
# CraftingService expects.
func _build_selection() -> Dictionary:
	var out: Dictionary = {}
	if selected_blueprint_id == "":
		return out
	var bp = CraftingData.get_blueprint(selected_blueprint_id)
	for slot in bp.get("material_slots", []):
		var slot_id = String(slot.get("slot_id", ""))
		var batch_id = String(selections.get(slot_id, ""))
		if batch_id != "" and main.material_batches.has(batch_id):
			out[slot_id] = main.material_batches[batch_id]
	return out


# ------------------------------------------------------------
# Signals
# ------------------------------------------------------------

func _on_blueprint_selected(bp_id: String) -> void:
	selected_blueprint_id = bp_id
	selections.clear()
	refresh()


func _on_slot_choice(index: int, slot_id: String, picker: OptionButton) -> void:
	selections[slot_id] = String(picker.get_item_metadata(index))
	_refresh_preview()


func _on_craft_pressed() -> void:
	var selection = _build_selection()
	var crafted = main._perform_craft(selected_blueprint_id, selection)
	if crafted.is_empty():
		refresh()
		return
	# Materials were consumed, so previous choices may no longer be valid.
	selections.clear()
	refresh()


func _on_close() -> void:
	if main != null:
		main.close_crafting_panel()
