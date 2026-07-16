extends Control

# ============================================================
# InventoryBook.gd
# ============================================================
# The Inventory Book panel, pulled out of main.gd (part of the ongoing
# split -- see GameData.gd and TalentViewer.gd for earlier passes).
# Attached to the InventoryBookUI Control node, instantiated by
# main.gd's _build_inventory_book_ui(), which sets `main` below before
# calling build().
#
# Note: equipped_weapon_name is core combat state read by the whole
# combat system, not exclusive to this panel -- this script both reads
# AND writes it (double-clicking an item equips/unequips it) via the
# main. prefix, exactly as main.gd itself would.
# ============================================================

var main

var inventory_book_list_container: VBoxContainer
var inventory_book_stats_label: Label

func _build_inventory_book_ui() -> void:
	name = "InventoryBookUI"
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
	main_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Inventory"
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

	# Left panel -- details for whichever item was last clicked.
	var details_panel = Panel.new()
	details_panel.position = Vector2(20, 50)
	details_panel.size = Vector2(320, 560)
	details_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(details_panel)

	var details_header = Label.new()
	details_header.text = "Details"
	details_header.position = Vector2(10, 4)
	details_header.modulate = Color(0.6, 0.9, 0.9)
	details_panel.add_child(details_header)

	var details_scroll = ScrollContainer.new()
	details_scroll.position = Vector2(10, 28)
	details_scroll.size = Vector2(300, 522)
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_panel.add_child(details_scroll)

	inventory_book_stats_label = Label.new()
	inventory_book_stats_label.custom_minimum_size = Vector2(285, 0)
	inventory_book_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	inventory_book_stats_label.text = "Select an item to view its details."
	inventory_book_stats_label.modulate = Color(0.85, 0.95, 0.95)
	details_scroll.add_child(inventory_book_stats_label)

	# Right panel -- scrollable list of every item currently held.
	var list_panel = Panel.new()
	list_panel.position = Vector2(360, 50)
	list_panel.size = Vector2(520, 560)
	list_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(list_panel)

	var list_header = Label.new()
	list_header.text = "Items"
	list_header.position = Vector2(10, 4)
	list_header.modulate = Color(0.6, 0.9, 0.9)
	list_panel.add_child(list_header)

	var list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(10, 28)
	list_scroll.size = Vector2(500, 522)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)

	inventory_book_list_container = VBoxContainer.new()
	inventory_book_list_container.custom_minimum_size = Vector2(485, 0)
	inventory_book_list_container.add_theme_constant_override("separation", 4)
	list_scroll.add_child(inventory_book_list_container)

func _format_quantity_tiered(qty: int) -> String:
	if qty < 1000:
		return str(qty)
	return str(int(qty / 1000)) + "k"

# Builds the label text for one main.inventory slot. Resources show a
# tiered quantity (1-999 plain, 1000+ as "10k"/"23k"/etc). Items with
# a Charges stat show that instead. Everything else (unique crafted
# equipment) shows just its name -- no "(1)" clutter, since each craft
# is its own slot now. Genuinely stacked non-resource items (like loot
# that dropped together and shares an ID) still show a plain count.
func _get_inventory_slot_label(item_key: String) -> String:
	var display_name = main._get_inventory_display_name(item_key)
	var qty = main.inventory.get(item_key, 0)
	var stats = main.inventory_stats.get(item_key, {})

	if main.resource_subclass_of.has(item_key):
		return display_name + " (" + _format_quantity_tiered(qty) + ")"
	elif stats.has("Charges"):
		return display_name + " (" + str(stats["Charges"]) + " charges)"
	elif qty > 1:
		return display_name + " (" + str(qty) + ")"
	else:
		return display_name

func _is_equippable_item(item_key: String) -> bool:
	var item_class = main.crafted_item_class.get(item_key, "")
	return item_class != "" and item_class != "Component" and item_class != "Medicine" and item_class != "Tool"

func _on_inventory_book_item_double_clicked(item_key: String) -> void:
	if not _is_equippable_item(item_key):
		return

	if main.equipped_weapon_name == item_key:
		main.equipped_weapon_name = ""
	else:
		main.equipped_weapon_name = item_key

	_refresh_inventory_book()

func _refresh_inventory_book() -> void:
	for child in inventory_book_list_container.get_children():
		child.queue_free()

	inventory_book_stats_label.text = "Select an item to view its details."

	for item_key in main.inventory.keys():
		if main.inventory[item_key] <= 0:
			continue

		var display_name = main._get_inventory_display_name(item_key)

		var btn = Button.new()
		btn.text = _get_inventory_slot_label(item_key)
		btn.custom_minimum_size = Vector2(480, 32)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_select_inventory_book_item.bind(item_key))
		btn.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.double_click:
				_on_inventory_book_item_double_clicked(item_key)
		)

		# Equipped item gets a visible border so it's obvious which
		# weapon is currently active, without needing a separate
		# Equip window at all -- double-click toggles it on/off.
		if item_key == main.equipped_weapon_name:
			var equipped_style = main._make_flat_style(Color(0.15, 0.15, 0.15))
			equipped_style.border_width_left = 3
			equipped_style.border_width_top = 3
			equipped_style.border_width_right = 3
			equipped_style.border_width_bottom = 3
			equipped_style.border_color = Color(0.95, 0.75, 0.2)
			btn.add_theme_stylebox_override("normal", equipped_style)
			btn.add_theme_stylebox_override("hover", equipped_style)
			btn.add_theme_stylebox_override("pressed", equipped_style)
			btn.add_theme_stylebox_override("focus", equipped_style)

		# Drag-and-drop uses the item's display name (e.g. "Mineral
		# Survey Tool"), not its internal instance key -- raw resources
		# have randomly-generated instance keys, but _use_ability_by_name
		# (called on drop) dispatches based on the recognizable display
		# name instead.
		var drag_script = load(main.ABILITY_DRAG_SOURCE_SCRIPT_PATH)
		if drag_script != null:
			btn.set_script(drag_script)
			btn.set("ability_name", display_name)

		inventory_book_list_container.add_child(btn)

# Real functional effect text for consumables whose Quality actually
# drives something (Adrenaline Shot, Empty IV Bag) -- shown in the
# Inventory Book instead of just hiding Quality with nothing to
# replace it. Returns [] for anything not specifically handled here.
func _get_consumable_effect_lines(base_name: String, quality: int) -> Array:
	match base_name:
		"Adrenaline Shot":
			var action_amount = main._scale_by_quality(quality, main.ADRENALINE_BOOST_MIN_ACTION, main.ADRENALINE_BOOST_MAX_ACTION)
			return ["Max Action +" + str(action_amount), "10 min duration"]
		"Empty IV Bag":
			var heal_amount = main._scale_by_quality(quality, main.BLOOD_BAG_MIN_HEAL, main.BLOOD_BAG_MAX_HEAL)
			return ["Max Health +" + str(heal_amount), "10 min duration"]
		"Crate of Bandages":
			return ["Heal +" + str(main.BANDAGE_HEAL_AMOUNT)]
		_:
			return []

func _select_inventory_book_item(item_key: String) -> void:
	var display_name = main._get_inventory_display_name(item_key)
	var qty = main.inventory.get(item_key, 0)
	var stats = main.inventory_stats.get(item_key, {})

	var lines: Array = []
	lines.append(display_name)

	# For raw resources, the main.inventory key IS the resource's unique
	# generated name (e.g. "Thaliryxqven") -- show it as its own line,
	# since it's meaningful identity info, not just internal plumbing.
	if main.resource_subclass_of.has(item_key):
		lines.append(item_key)

	lines.append("Quantity: " + str(qty))
	lines.append("")

	if stats.size() == 0:
		lines.append("No additional stats.")
	else:
		var is_resource = main.resource_subclass_of.has(item_key)
		var stat_lines: Array = []

		var base_name = main.consumable_base_name.get(item_key, "")
		stat_lines.append_array(_get_consumable_effect_lines(base_name, stats.get("Quality", 500)))

		for stat_name in stats.keys():
			if stat_name == "Quality" and not is_resource:
				continue
			stat_lines.append(stat_name + ": " + main._format_number(stats[stat_name]))

		if stat_lines.size() == 0:
			lines.append("No additional stats.")
		else:
			lines.append_array(stat_lines)

	inventory_book_stats_label.text = "\n".join(lines)
