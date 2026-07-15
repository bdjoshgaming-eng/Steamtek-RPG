extends Control

# ============================================================
# CraftingBook.gd
# ============================================================
# The Crafting Book panel (recipe list + Assembly screen), pulled out
# of main.gd (part of the ongoing split — see GameData.gd and
# TalentViewer.gd for earlier passes). Attached to the CraftingBookUI
# Control node, instantiated by main.gd's _build_crafting_book_ui(),
# which sets `main` below before calling build().
#
# _make_crafting_book_header(), _make_plain_header(), and
# book_category_collapsed stayed in main.gd instead of moving here,
# since the Survey Book uses the same collapsible-category header
# system and shares that state. professions_unlocked, selected_recipe_index
# (also used by an older auto-pick crafting path), inventory,
# TALENT_OWNED_COLOR/TALENT_UNLEARNED_COLOR, crafting_result_ui, and
# several core crafting-math helpers (_matches_requirement,
# _get_weighted_stack_score, _finalize_crafted_item, etc.) also stayed
# in main.gd since other systems use them too. Every reference to
# those below is prefixed with "main." accordingly.
# ============================================================

var main

var crafting_book_list_container: VBoxContainer
var crafting_book_details_label: Label
var crafting_book_craft_button: Button
var crafting_book_result_label: Label
var crafting_book_back_button: Button
var crafting_assembly_recipe_index: int = -1
var crafting_assembly_selections: Dictionary = {}

const MELEE_WEAPON_CLASSES = ["Sword", "Axe", "Hammer", "Brass Knuckles", "Stun Stick"]
const RANGED_WEAPON_CLASSES = ["Pistol", "Assault Rifle", "Sniper Rifle", "Shotgun", "Grenade Launcher", "Flame Thrower"]

# Returns {"class": ..., "type": ..., "subclass": ...}. "type" and
# "subclass" come back as "" when they wouldn't add a meaningful
# extra level (e.g. Tools have no sub-type, and most ranged weapons'
# item_subclass just repeats item_class).
func _categorize_recipe_for_book(recipe: Dictionary) -> Dictionary:
	var item_class = recipe.get("item_class", "")
	var item_subclass = recipe.get("item_subclass", "")

	if MELEE_WEAPON_CLASSES.has(item_class):
		return {"class": "Melee Weapon", "type": item_class, "subclass": item_subclass}
	elif RANGED_WEAPON_CLASSES.has(item_class):
		var subclass_value = "" if item_subclass == item_class else item_subclass
		return {"class": "Ranged Weapon", "type": item_class, "subclass": subclass_value}
	elif item_class == "Tool":
		return {"class": "Tool", "type": "", "subclass": ""}
	elif item_class == "Medicine":
		return {"class": "Medicine", "type": "", "subclass": ""}
	elif item_class == "Component":
		return {"class": "Component", "type": "", "subclass": ""}
	else:
		return {"class": "Material", "type": "", "subclass": ""}

func _build_crafting_book_ui() -> void:
	name = "CraftingBookUI"
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
	main_panel.position = Vector2(460, 165)
	main_panel.size = Vector2(1000, 750)
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	main_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	add_child(main_panel)

	var title_label = Label.new()
	title_label.text = "Crafting"
	title_label.position = Vector2(20, 8)
	title_label.modulate = Color(0.6, 0.9, 0.9)
	main_panel.add_child(title_label)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(960, 6)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): visible = false)
	main_panel.add_child(close_button)

	# Left panel — ingredient breakdown for the selected recipe, plus
	# the actual Craft button and result message.
	var details_panel = Panel.new()
	details_panel.position = Vector2(20, 50)
	details_panel.size = Vector2(380, 660)
	details_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(details_panel)

	var details_header = Label.new()
	details_header.text = "Ingredients"
	details_header.position = Vector2(10, 4)
	details_header.modulate = Color(0.6, 0.9, 0.9)
	details_panel.add_child(details_header)

	var details_scroll = ScrollContainer.new()
	details_scroll.position = Vector2(10, 28)
	details_scroll.size = Vector2(360, 520)
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_panel.add_child(details_scroll)

	crafting_book_details_label = Label.new()
	crafting_book_details_label.custom_minimum_size = Vector2(345, 0)
	crafting_book_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	crafting_book_details_label.text = "Select a recipe to view what it takes to craft."
	crafting_book_details_label.modulate = Color(0.85, 0.95, 0.95)
	details_scroll.add_child(crafting_book_details_label)

	crafting_book_craft_button = Button.new()
	crafting_book_craft_button.text = "Choose Resources"
	crafting_book_craft_button.position = Vector2(10, 558)
	crafting_book_craft_button.custom_minimum_size = Vector2(360, 36)
	crafting_book_craft_button.focus_mode = Control.FOCUS_NONE
	crafting_book_craft_button.pressed.connect(_enter_crafting_assembly)
	details_panel.add_child(crafting_book_craft_button)

	crafting_book_result_label = Label.new()
	crafting_book_result_label.position = Vector2(10, 600)
	crafting_book_result_label.size = Vector2(360, 56)
	crafting_book_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	crafting_book_result_label.text = ""
	crafting_book_result_label.modulate = Color(0.9, 0.85, 0.6)
	details_panel.add_child(crafting_book_result_label)

	# Right panel — scrollable Class > Type > Subclass > Recipe list.
	var list_panel = Panel.new()
	list_panel.position = Vector2(420, 50)
	list_panel.size = Vector2(560, 660)
	list_panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.03, 0.06, 0.06)))
	main_panel.add_child(list_panel)

	crafting_book_back_button = Button.new()
	crafting_book_back_button.text = "< Back to Schematics"
	crafting_book_back_button.position = Vector2(10, 4)
	crafting_book_back_button.custom_minimum_size = Vector2(150, 24)
	crafting_book_back_button.focus_mode = Control.FOCUS_NONE
	crafting_book_back_button.visible = false
	crafting_book_back_button.pressed.connect(_exit_crafting_assembly)
	list_panel.add_child(crafting_book_back_button)

	var list_header = Label.new()
	list_header.text = "Schematics"
	list_header.position = Vector2(10, 4)
	list_header.modulate = Color(0.6, 0.9, 0.9)
	list_panel.add_child(list_header)

	var list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(10, 28)
	list_scroll.size = Vector2(540, 622)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)

	crafting_book_list_container = VBoxContainer.new()
	crafting_book_list_container.custom_minimum_size = Vector2(525, 0)
	crafting_book_list_container.add_theme_constant_override("separation", 2)
	list_scroll.add_child(crafting_book_list_container)

func _refresh_crafting_book() -> void:
	for child in crafting_book_list_container.get_children():
		child.queue_free()

	crafting_book_details_label.text = "Select a recipe to view what it takes to craft."
	crafting_book_result_label.text = ""
	main.selected_recipe_index = -1
	crafting_assembly_recipe_index = -1
	crafting_assembly_selections.clear()
	crafting_book_back_button.visible = false
	crafting_book_craft_button.text = "Choose Resources"
	if crafting_book_craft_button.pressed.is_connected(_execute_assembly_craft):
		crafting_book_craft_button.pressed.disconnect(_execute_assembly_craft)
	if not crafting_book_craft_button.pressed.is_connected(_enter_crafting_assembly):
		crafting_book_craft_button.pressed.connect(_enter_crafting_assembly)

	# Build nested Class -> Type -> Subclass -> [recipe_index] groups.
	var grouped: Dictionary = {}
	for i in range(GameData.recipes.size()):
		var recipe = GameData.recipes[i]
		if recipe.has("requires_profession") and not main.professions_unlocked.get(recipe["requires_profession"], false):
			continue

		var cat = _categorize_recipe_for_book(recipe)
		if not grouped.has(cat["class"]):
			grouped[cat["class"]] = {}
		var type_key = cat["type"] if cat["type"] != "" else "_flat_"
		if not grouped[cat["class"]].has(type_key):
			grouped[cat["class"]][type_key] = {}
		var subclass_key = cat["subclass"] if cat["subclass"] != "" else "_flat_"
		if not grouped[cat["class"]][type_key].has(subclass_key):
			grouped[cat["class"]][type_key][subclass_key] = []
		grouped[cat["class"]][type_key][subclass_key].append(i)

	var class_order = ["Melee Weapon", "Ranged Weapon", "Tool", "Component", "Medicine", "Material"]
	for class_name_key in class_order:
		if not grouped.has(class_name_key):
			continue

		var class_category_key = "craft:" + class_name_key
		crafting_book_list_container.add_child(main._make_crafting_book_header(class_name_key, 0, Color(0.85, 0.7, 0.3), class_category_key, _refresh_crafting_book))

		if main.book_category_collapsed.get(class_category_key, false):
			continue

		var type_keys = grouped[class_name_key].keys()
		type_keys.sort()
		for type_key in type_keys:
			var type_category_key = class_category_key + "/" + type_key
			if type_key != "_flat_":
				crafting_book_list_container.add_child(main._make_crafting_book_header(type_key, 1, Color(0.7, 0.85, 0.85), type_category_key, _refresh_crafting_book))
				if main.book_category_collapsed.get(type_category_key, false):
					continue

			var subclass_keys = grouped[class_name_key][type_key].keys()
			subclass_keys.sort()
			for subclass_key in subclass_keys:
				var indent = 1 if type_key == "_flat_" else 2
				var subclass_category_key = type_category_key + "/" + subclass_key
				if subclass_key != "_flat_":
					crafting_book_list_container.add_child(main._make_crafting_book_header(subclass_key, indent, Color(0.6, 0.75, 0.75), subclass_category_key, _refresh_crafting_book))
					if main.book_category_collapsed.get(subclass_category_key, false):
						continue

				var recipe_indices = grouped[class_name_key][type_key][subclass_key]
				var button_indent = indent if subclass_key == "_flat_" else indent + 1
				for recipe_index in recipe_indices:
					var btn = Button.new()
					btn.text = "  ".repeat(button_indent) + GameData.recipes[recipe_index]["name"]
					btn.custom_minimum_size = Vector2(510, 30)
					btn.focus_mode = Control.FOCUS_NONE
					btn.pressed.connect(_select_crafting_book_recipe.bind(recipe_index))
					crafting_book_list_container.add_child(btn)

# Builds the "Hilt: 2 Metal, 1 Torn Cloth" style breakdown, grouped by
# slot_names when a recipe has them (weapons), or a flat list when it
# doesn't (tools, medicine, simple materials).
func _get_ingredient_breakdown_text(recipe: Dictionary) -> String:
	var lines: Array = []

	if recipe.has("item_class") and recipe.has("item_subclass"):
		lines.append(recipe["item_class"] + " (" + recipe["item_subclass"] + ")")
		lines.append("")

	if recipe.has("slot_names"):
		for requirement_key in recipe["requires"].keys():
			var needed = recipe["requires"][requirement_key]
			var slot_label = recipe["slot_names"].get(requirement_key, requirement_key)
			lines.append(slot_label)
			lines.append("  " + str(needed) + " " + requirement_key)
			lines.append("")
	else:
		lines.append("Requires:")
		for requirement_key in recipe["requires"].keys():
			var needed = recipe["requires"][requirement_key]
			lines.append("  " + str(needed) + " " + requirement_key)

	return "\n".join(lines)

func _select_crafting_book_recipe(recipe_index: int) -> void:
	main.selected_recipe_index = recipe_index
	crafting_book_result_label.text = ""
	crafting_book_details_label.text = _get_ingredient_breakdown_text(GameData.recipes[recipe_index])

# Finds the first main.inventory stack matching a requirement, used to
# pre-select a sensible default when entering Assembly for a slot.
func _find_first_matching_instance(requirement_key: String) -> String:
	for instance_name in main.inventory.keys():
		if main.inventory[instance_name] > 0 and main._matches_requirement(instance_name, requirement_key):
			return instance_name
	return ""

# Switches the right panel from the schematic browser into the
# Assembly step for the currently selected recipe — this is where the
# player picks exactly which resource stack fills each slot and sees
# a live projected-quality preview before committing, similar in
# spirit to SWG's assembly screen (not its exact formulas or look).
func _enter_crafting_assembly() -> void:
	if main.selected_recipe_index == -1:
		crafting_book_result_label.text = "Select a recipe first!"
		return

	crafting_assembly_recipe_index = main.selected_recipe_index
	crafting_assembly_selections.clear()

	var recipe = GameData.recipes[crafting_assembly_recipe_index]
	for requirement_key in recipe["requires"].keys():
		var default_instance = _find_first_matching_instance(requirement_key)
		if default_instance != "":
			crafting_assembly_selections[requirement_key] = default_instance

	crafting_book_back_button.visible = true
	_refresh_crafting_assembly_view()

func _exit_crafting_assembly() -> void:
	_refresh_crafting_book()

func _select_assembly_instance(requirement_key: String, instance_name: String) -> void:
	crafting_assembly_selections[requirement_key] = instance_name
	_refresh_crafting_assembly_view()

# Rebuilds the right panel's contents as the per-slot resource picker,
# and the left panel's contents as the live projected-quality preview.
func _refresh_crafting_assembly_view() -> void:
	for child in crafting_book_list_container.get_children():
		child.queue_free()

	var recipe = GameData.recipes[crafting_assembly_recipe_index]

	var recipe_title = main._make_plain_header(recipe["name"], 0, Color(0.85, 0.7, 0.3))
	crafting_book_list_container.add_child(recipe_title)

	for requirement_key in recipe["requires"].keys():
		var needed = recipe["requires"][requirement_key]
		var slot_label = recipe.get("slot_names", {}).get(requirement_key, requirement_key)

		crafting_book_list_container.add_child(main._make_plain_header(slot_label + " (needs " + str(needed) + " " + requirement_key + ")", 1, Color(0.7, 0.85, 0.85)))

		var found_any = false
		for instance_name in main.inventory.keys():
			if main.inventory[instance_name] <= 0:
				continue
			if not main._matches_requirement(instance_name, requirement_key):
				continue

			found_any = true
			var is_selected = crafting_assembly_selections.get(requirement_key, "") == instance_name

			var btn = Button.new()
			btn.text = "  " + main._get_leaf_label(instance_name) + " (" + str(main.inventory[instance_name]) + " available)" + (" [SELECTED]" if is_selected else "")
			btn.custom_minimum_size = Vector2(510, 28)
			btn.focus_mode = Control.FOCUS_NONE
			var btn_color = main.TALENT_OWNED_COLOR if is_selected else main.TALENT_UNLEARNED_COLOR
			var btn_style = main._make_flat_style(btn_color)
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			btn.add_theme_stylebox_override("pressed", btn_style)
			btn.add_theme_stylebox_override("focus", btn_style)
			btn.pressed.connect(_select_assembly_instance.bind(requirement_key, instance_name))
			crafting_book_list_container.add_child(btn)

		if not found_any:
			var none_label = Label.new()
			none_label.text = "  (none available)"
			none_label.modulate = Color(0.7, 0.3, 0.3)
			crafting_book_list_container.add_child(none_label)

	crafting_book_craft_button.text = "Assemble"
	if crafting_book_craft_button.pressed.is_connected(_enter_crafting_assembly):
		crafting_book_craft_button.pressed.disconnect(_enter_crafting_assembly)
	if not crafting_book_craft_button.pressed.is_connected(_execute_assembly_craft):
		crafting_book_craft_button.pressed.connect(_execute_assembly_craft)

	_update_assembly_preview()

# Live preview of what the current resource selections would produce
# — our own version of "see how resources affect the build" before
# committing, not a copy of any specific game's exact formula/look.
func _update_assembly_preview() -> void:
	var recipe = GameData.recipes[crafting_assembly_recipe_index]

	var lines: Array = []
	lines.append(recipe["name"])
	lines.append("")

	var all_slots_filled = true

	for requirement_key in recipe["requires"].keys():
		var needed = recipe["requires"][requirement_key]
		var slot_label = recipe.get("slot_names", {}).get(requirement_key, requirement_key)
		var instance_name = crafting_assembly_selections.get(requirement_key, "")

		if instance_name == "":
			lines.append(slot_label + ": (none selected)")
			all_slots_filled = false
			continue

		var available = main.inventory.get(instance_name, 0)

		lines.append(slot_label + " <- " + main._get_leaf_label(instance_name))
		if available < needed:
			lines.append("  NOT ENOUGH (" + str(available) + " / " + str(needed) + ")")
			all_slots_filled = false

	lines.append("")

	if not all_slots_filled:
		lines.append("Fill every slot with enough of the right resource before assembling.")

	crafting_book_details_label.text = "\n".join(lines)

# Commits the craft using the SPECIFIC resource stacks chosen in
# Assembly, rather than auto-picking from main.inventory like the old
# flow — this is the actual "Assemble" action.
func _execute_assembly_craft() -> void:
	var recipe = GameData.recipes[crafting_assembly_recipe_index]

	if recipe.has("requires_profession") and not main.professions_unlocked.get(recipe["requires_profession"], false):
		crafting_book_result_label.text = "You haven't learned this pattern!"
		return

	var total_weighted = 0.0
	var total_weight = 0

	for requirement_key in recipe["requires"].keys():
		var needed = recipe["requires"][requirement_key]
		var instance_name = crafting_assembly_selections.get(requirement_key, "")

		if instance_name == "":
			crafting_book_result_label.text = "Every slot needs a resource selected first!"
			return

		var available = main.inventory.get(instance_name, 0)
		if available < needed:
			crafting_book_result_label.text = "Not enough " + main._get_leaf_label(instance_name) + " for that slot!"
			return

	for requirement_key in recipe["requires"].keys():
		var needed = recipe["requires"][requirement_key]
		var instance_name = crafting_assembly_selections[requirement_key]

		var counts_toward_quality = not recipe.has("quality_ingredients") or recipe["quality_ingredients"].has(requirement_key)
		if counts_toward_quality:
			var stack_score = main._get_weighted_stack_score(instance_name, requirement_key, recipe)
			total_weighted += stack_score * needed
			total_weight += needed

		main.inventory[instance_name] -= needed

	var base_quality = 50
	if total_weight > 0:
		base_quality = round(total_weighted / total_weight)

	var finalize_result = main._finalize_crafted_item(recipe, base_quality)
	var result_text = finalize_result["text"]
	var crafted_item_key = finalize_result["item_key"]
	crafting_book_result_label.text = result_text

	var article = main._get_article(recipe["output"])
	main._show_combat_message("You have successfully crafted " + article + " " + recipe["output"] + "!")

	_exit_crafting_assembly()
	main.crafting_result_ui._show_crafting_result_popup(crafted_item_key)
