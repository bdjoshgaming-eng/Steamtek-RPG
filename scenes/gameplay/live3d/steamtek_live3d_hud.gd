extends CanvasLayer
class_name SteamtekLive3DHud

## Reusable HUD for Live3D scenes: a persistent health/action bar + action
## slot strip matching main.tscn's look, plus Talents (real KeystoneViewer,
## backed by the shared GameData.novice_professions autoload) and a
## simplified local Crafting panel (real CraftingData.BLUEPRINTS recipes,
## checked against this scene's own local `progress["items"]`).
##
## Also owns the Inventory window and DialogueBox -- these are game-wide UI
## elements that every Live3D scene needs, instanced here so the base
## transition script provides them automatically.

signal panel_opened
signal panel_closed
signal inventory_slot_double_clicked(item_key: String)

const KEYSTONE_VIEWER_SCRIPT := preload("res://scenes/KeystoneViewer.gd")
const TALENT_BRIDGE_SCRIPT := preload("res://scenes/gameplay/live3d/steamtek_local_talent_bridge.gd")
const ITEM_SLOT_SCENE := preload("res://scenes/gameplay/live3d/SteamtekItemSlot.tscn")
const ITEM_ICON_SCENE := preload("res://scenes/gameplay/live3d/SteamtekItemIcon.tscn")
const INVENTORY_WINDOW_SCENE := preload("res://scenes/gameplay/live3d/SteamtekInventoryWindow.tscn")
const DIALOGUE_BOX_SCENE := preload("res://scenes/gameplay/live3d/SteamtekDialogueBox.tscn")

@onready var health_bar: ProgressBar = $Bars/HealthBar
@onready var action_bar: ProgressBar = $Bars/ActionBar
@onready var heat_bar: ProgressBar = $Bars/HeatBar
@onready var cogs_label: Label = $Bars/CogsLabel
@onready var action_slots: HBoxContainer = $ActionSlots
@onready var talents_panel: Control = $TalentsPanel
@onready var crafting_panel: Control = $CraftingPanel
@onready var blueprint_list: VBoxContainer = $CraftingPanel/Blueprints/List
@onready var materials_grid: GridContainer = $CraftingPanel/Materials/Grid
@onready var carried_label: Label = $CraftingPanel/Carried/Label
@onready var craft_button: Button = $CraftingPanel/CraftButton
@onready var craft_result_label: Label = $CraftingPanel/ResultLabel
@onready var crafting_close: Button = $CraftingPanel/Close
@onready var mods_list: VBoxContainer = $CraftingPanel/Mods/Scroll/List

# Flat Cogs cost to grant a mod. The 8 weapon mods have no blueprint/
# material requirement in the data model (only Core mods do, via
# bp_core_mod + a reagent family) so a flat cost stands in for a real
# recipe -- placeholder tuning value, needs a balance pass.
const MOD_GRANT_COGS_COST := 40

var progress_ref: Dictionary = {}
var save_callback: Callable
var combat_state_ref: Dictionary = {}
var talent_bridge: SteamtekLocalTalentBridge
var keystone_viewer_node: Node
var selected_blueprint_id: String = ""
var inventory_window: SteamtekInventoryWindow
var dialogue_box: SteamtekDialogueBox
var _inventory_enabled := false


func _ready() -> void:
	health_bar.max_value = 500
	health_bar.value = 500
	health_bar.add_theme_stylebox_override("fill", _bar_fill_style(Color(0.55, 0.12, 0.1)))
	health_bar.add_theme_stylebox_override("background", _bar_fill_style(Color(0.08, 0.03, 0.03)))
	action_bar.max_value = 850
	action_bar.value = 850
	action_bar.add_theme_stylebox_override("fill", _bar_fill_style(Color(0.14, 0.42, 0.16)))
	action_bar.add_theme_stylebox_override("background", _bar_fill_style(Color(0.04, 0.08, 0.04)))
	heat_bar.max_value = 100
	heat_bar.value = 0
	heat_bar.add_theme_stylebox_override("fill", _bar_fill_style(Color(0.78, 0.35, 0.08)))
	heat_bar.add_theme_stylebox_override("background", _bar_fill_style(Color(0.1, 0.05, 0.02)))
	for slot_button in action_slots.get_children():
		if slot_button is Button:
			slot_button.text = "(empty)"

	talent_bridge = TALENT_BRIDGE_SCRIPT.new()
	add_child(talent_bridge)
	keystone_viewer_node = KEYSTONE_VIEWER_SCRIPT.new()
	keystone_viewer_node.main = talent_bridge
	add_child(keystone_viewer_node)
	keystone_viewer_node.setup(talents_panel)

	_build_blueprint_buttons()
	_build_mod_buttons()
	craft_button.pressed.connect(_on_craft_pressed)
	crafting_close.pressed.connect(func(): crafting_panel.visible = false)

	talents_panel.visibility_changed.connect(_emit_panel_state)
	crafting_panel.visibility_changed.connect(_emit_panel_state)

	inventory_window = INVENTORY_WINDOW_SCENE.instantiate()
	inventory_window.visible = false
	inventory_window.anchors_preset = Control.PRESET_CENTER
	inventory_window.anchor_left = 0.5
	inventory_window.anchor_top = 0.5
	inventory_window.anchor_right = 0.5
	inventory_window.anchor_bottom = 0.5
	inventory_window.offset_left = -350.0
	inventory_window.offset_top = -323.0
	inventory_window.offset_right = 350.0
	inventory_window.offset_bottom = 323.0
	inventory_window.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_window.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(inventory_window)
	inventory_window.close_requested.connect(func(): set_inventory_open(false))
	inventory_window.slot_double_clicked.connect(func(key: String): inventory_slot_double_clicked.emit(key))
	inventory_window.inventory_changed.connect(_refresh_inventory_display)
	inventory_window.visibility_changed.connect(_emit_panel_state)

	dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)


func _bar_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func bind(progress: Dictionary, save_fn: Callable) -> void:
	progress_ref = progress
	save_callback = save_fn
	inventory_window.bind_inventory_data(progress_ref)
	_refresh_cogs()
	_refresh_inventory_display()


func bind_combat_state(state: Dictionary) -> void:
	combat_state_ref = state
	_refresh_combat_bars()


func _refresh_combat_bars() -> void:
	heat_bar.visible = _is_flame_thrower_equipped()
	if combat_state_ref.is_empty():
		return
	health_bar.max_value = float(combat_state_ref.get("max_health", 500))
	health_bar.value = float(combat_state_ref.get("current_health", 0))
	action_bar.max_value = float(combat_state_ref.get("max_action", 850))
	action_bar.value = float(combat_state_ref.get("current_action", 0))
	heat_bar.max_value = float(combat_state_ref.get("max_heat", 100))
	heat_bar.value = float(combat_state_ref.get("current_heat", 0))


func _is_flame_thrower_equipped() -> bool:
	var weapon_name := String(progress_ref.get("equipped_weapon", ""))
	if weapon_name.is_empty():
		return false
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	return String(weapon_def.get("item_class", "")) == "Flame Thrower"


func _process(_delta: float) -> void:
	_refresh_combat_bars()


func set_inventory_enabled(enabled: bool) -> void:
	_inventory_enabled = enabled


func set_inventory_open(open: bool) -> void:
	if open:
		_refresh_inventory_display()
	inventory_window.visible = open


func is_inventory_open() -> bool:
	return inventory_window.visible


func refresh_inventory(entries: Array, mission_entries: Array, cogs: int, status_text: String) -> void:
	inventory_window.configure(entries, mission_entries, cogs)
	inventory_window.set_status_text(status_text)


# Rebuilds the inventory window straight from progress_ref (the shared
# global inventory dict) so every scene shows current data on open, not
# just whichever scene last happened to push a manual refresh.
func _refresh_inventory_display() -> void:
	var entries: Array = []
	var items: Dictionary = progress_ref.get("items", {})
	for item_name in items.keys():
		entries.append({"key": item_name, "label": item_name, "count": int(items[item_name])})
	var weapons_owned: Dictionary = progress_ref.get("weapons_owned", {})
	var equipped := String(progress_ref.get("equipped_weapon", ""))
	for weapon_name in weapons_owned.keys():
		var label := String(weapon_name)
		if weapon_name == equipped:
			label += " (equipped)"
		entries.append({"key": weapon_name, "label": label, "icon_name": weapon_name, "count": 1})
	var status := "EQUIPPED WEAPON: %s" % (equipped if not equipped.is_empty() else "None")
	refresh_inventory(entries, [], int(progress_ref.get("cogs", 0)), status)
	_refresh_cogs()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("talent_view"):
		talents_panel.visible = not talents_panel.visible
		if talents_panel.visible:
			keystone_viewer_node._rebuild_graph()
			keystone_viewer_node._refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("crafting_menu"):
		crafting_panel.visible = not crafting_panel.visible
		if crafting_panel.visible:
			_refresh_crafting_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("equip_menu") and _inventory_enabled:
		set_inventory_open(not inventory_window.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if talents_panel.visible:
			talents_panel.visible = false
			get_viewport().set_input_as_handled()
		elif crafting_panel.visible:
			crafting_panel.visible = false
			get_viewport().set_input_as_handled()
		elif inventory_window.visible:
			set_inventory_open(false)
			get_viewport().set_input_as_handled()


func _emit_panel_state() -> void:
	if talents_panel.visible or crafting_panel.visible or inventory_window.visible:
		panel_opened.emit()
	else:
		panel_closed.emit()


func _refresh_cogs() -> void:
	cogs_label.text = "Cogs: %d" % int(progress_ref.get("cogs", 0))


func _family_display_name(family_id: String) -> String:
	var entry: Dictionary = CraftingData.RESOURCE_FAMILIES.get(family_id, {})
	if entry.is_empty():
		entry = CraftingData.RESOURCE_FAMILIES_EXTRA.get(family_id, {})
	return String(entry.get("display_name", family_id))


func _build_blueprint_buttons() -> void:
	for blueprint_id in CraftingData.BLUEPRINTS.keys():
		var blueprint: Dictionary = CraftingData.BLUEPRINTS[blueprint_id]
		var display_name := String(blueprint.get("display_name", blueprint_id))

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var icon: SteamtekItemIcon = ITEM_ICON_SCENE.instantiate()
		icon.custom_minimum_size = Vector2(32, 32)
		row.add_child(icon)

		var button := Button.new()
		button.text = display_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_blueprint_selected.bind(blueprint_id))
		row.add_child(button)

		blueprint_list.add_child(row)
		icon.set_item(display_name)


# Phase 6 Batch 2: the 8 weapon mods have no blueprint/material
# requirement in the data model, so granting one is a flat Cogs cost
# rather than a real recipe row -- everything else about mod behavior
# (stat effects, install rules, grades) is the real, spec'd system.
func _build_mod_buttons() -> void:
	for mod_id in CraftingData.MOD_DEFINITIONS.keys():
		var mod_def: Dictionary = CraftingData.MOD_DEFINITIONS[mod_id]
		var display_name := String(mod_def.get("display_name", mod_id))
		var summary := CraftingService.mod_effect_summary(mod_id, "standard")

		var row := VBoxContainer.new()

		var button := Button.new()
		button.text = "%s (%d Cogs)" % [display_name, MOD_GRANT_COGS_COST]
		button.tooltip_text = String(mod_def.get("description", ""))
		button.pressed.connect(_on_mod_grant_pressed.bind(mod_id))
		row.add_child(button)

		if not summary.is_empty():
			var summary_label := Label.new()
			summary_label.text = summary
			summary_label.add_theme_font_size_override("font_size", 12)
			row.add_child(summary_label)

		mods_list.add_child(row)


func _on_mod_grant_pressed(mod_id: String) -> void:
	var cogs := int(progress_ref.get("cogs", 0))
	if cogs < MOD_GRANT_COGS_COST:
		craft_result_label.text = "Not enough Cogs."
		return
	var mod_instance := CraftingService.create_mod(mod_id, "standard")
	if mod_instance.is_empty():
		return
	progress_ref["cogs"] = cogs - MOD_GRANT_COGS_COST
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var mods_owned: Dictionary = progress_ref.get("mods_owned", {})
	var mod_instance_id := String(mod_instance.get("mod_instance_id", ""))
	mod_instances[mod_instance_id] = mod_instance
	mods_owned[mod_instance_id] = true
	progress_ref["mod_instances"] = mod_instances
	progress_ref["mods_owned"] = mods_owned
	if save_callback.is_valid():
		save_callback.call()
	_refresh_cogs()
	var mod_def: Dictionary = CraftingData.get_mod(mod_id)
	craft_result_label.text = "Granted: %s" % String(mod_def.get("display_name", mod_id))


func _refresh_crafting_panel() -> void:
	_refresh_cogs()
	carried_label.text = _carried_materials_summary()
	if selected_blueprint_id == "":
		for child in materials_grid.get_children():
			child.queue_free()
		craft_button.disabled = true
		return
	_refresh_selected_blueprint()


func _on_blueprint_selected(blueprint_id: String) -> void:
	selected_blueprint_id = blueprint_id
	_refresh_selected_blueprint()


func _refresh_selected_blueprint() -> void:
	var blueprint: Dictionary = CraftingData.BLUEPRINTS.get(selected_blueprint_id, {})
	var items: Dictionary = progress_ref.get("items", {})
	for child in materials_grid.get_children():
		child.queue_free()
	var all_satisfied := true
	for slot in blueprint.get("material_slots", []):
		var need: int = int(slot.get("amount", 0))
		var have := 0
		var matched_family := ""
		for family_id in slot.get("accepts", []):
			var display_name := _family_display_name(family_id)
			var count := int(items.get(display_name, 0))
			if count > have:
				have = count
				matched_family = display_name
		if have < need:
			all_satisfied = false
		var icon_source := matched_family if matched_family != "" else _family_display_name(String(slot.get("accepts", [""])[0]))
		var material_slot: SteamtekItemSlot = ITEM_SLOT_SCENE.instantiate()
		materials_grid.add_child(material_slot)
		material_slot.set_slot(icon_source, have, icon_source)
		material_slot.tooltip_text = "%s: %s %d / %d" % [String(slot.get("slot_name", "")), icon_source, have, need]
		material_slot.modulate = Color(1, 1, 1, 1) if have >= need else Color(1, 1, 1, 0.45)
	craft_button.disabled = not all_satisfied
	craft_result_label.text = ""


func _carried_materials_summary() -> String:
	var items: Dictionary = progress_ref.get("items", {})
	if items.is_empty():
		return "Nothing carried."
	var lines: Array = []
	for item_name in items.keys():
		lines.append("%s x%d" % [String(item_name), int(items[item_name])])
	return "\n".join(lines)


func _on_craft_pressed() -> void:
	var blueprint: Dictionary = CraftingData.BLUEPRINTS.get(selected_blueprint_id, {})
	if blueprint.is_empty():
		return
	var items: Dictionary = progress_ref.get("items", {})
	var consumption: Dictionary = {}
	for slot in blueprint.get("material_slots", []):
		var need: int = int(slot.get("amount", 0))
		var have := 0
		var matched_family := ""
		for family_id in slot.get("accepts", []):
			var display_name := _family_display_name(family_id)
			var count := int(items.get(display_name, 0))
			if count > have:
				have = count
				matched_family = display_name
		if have < need or matched_family == "":
			craft_result_label.text = "Missing materials."
			return
		consumption[matched_family] = int(consumption.get(matched_family, 0)) + need
	for display_name in consumption.keys():
		items[display_name] = int(items.get(display_name, 0)) - int(consumption[display_name])
		if items[display_name] <= 0:
			items.erase(display_name)
	progress_ref["items"] = items
	var output_name := String(blueprint.get("display_name", blueprint.get("output_item_id", "Crafted Item")))
	items[output_name] = int(items.get(output_name, 0)) + 1
	if save_callback.is_valid():
		save_callback.call()
	craft_result_label.text = "Crafted: %s" % output_name
	_refresh_selected_blueprint()
