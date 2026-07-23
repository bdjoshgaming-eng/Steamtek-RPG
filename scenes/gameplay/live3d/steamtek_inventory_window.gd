extends Control
class_name SteamtekInventoryWindow

## Full inventory window: fixed slot count (so the grid always reads as
## a real inventory instead of resizing per item), a capacity readout,
## Inventory/Mission Items/Currency tabs, and a Details side panel that
## shows an item's real stats when clicked -- mirrors main.tscn's
## inventory book layout (Details | Items), styled with Steamtek's own
## dark/amber palette instead of borrowing anyone else's color scheme.

const ITEM_SLOT_SCENE := preload("res://scenes/gameplay/live3d/SteamtekItemSlot.tscn")

signal close_requested
signal slot_double_clicked(item_key: String)
signal inventory_changed

@export var slot_count := 48

@onready var capacity_label: Label = $Header/CapacityLabel
@onready var grid: GridContainer = $Grid
@onready var currency_label: Label = $Footer/CurrencyLabel
@onready var status_label: Label = $Footer/StatusLabel
@onready var close_button: Button = $Close
@onready var tab_inventory: Button = $Tabs/Inventory
@onready var tab_mission: Button = $Tabs/MissionItems
@onready var tab_currency: Button = $Tabs/Currency
@onready var details_item_name: Label = $Details/Scroll/Content/ItemName
@onready var details_stats: Label = $Details/Scroll/Content/Stats
@onready var mods_panel: VBoxContainer = $Details/Scroll/Content/ModsPanel
@onready var socket_list: VBoxContainer = $Details/Scroll/Content/ModsPanel/SocketList
@onready var owned_mods_list: VBoxContainer = $Details/Scroll/Content/ModsPanel/OwnedModsList
@onready var durability_panel: VBoxContainer = $Details/Scroll/Content/ModsPanel/DurabilityPanel
@onready var durability_label: Label = $Details/Scroll/Content/ModsPanel/DurabilityPanel/DurabilityLabel
@onready var repair_button: Button = $Details/Scroll/Content/ModsPanel/DurabilityPanel/RepairButton
@onready var rebuild_button: Button = $Details/Scroll/Content/ModsPanel/DurabilityPanel/RebuildButton
@onready var dismantle_button: Button = $Details/Scroll/Content/ModsPanel/DurabilityPanel/DismantleButton

# A weapon's mod sockets aren't rolled by an experimentation pass here
# (that machinery is Phase 4/5, gated behind the full crafting-panel
# flow this simplified Live3D window doesn't use) -- every weapon just
# gets a flat, lazily-created CraftedItemInstance wrapper with this many
# sockets the first time a mod is installed on it. Placeholder pending
# the real depth-ceiling socket curve.
const DEFAULT_WEAPON_SOCKET_COUNT := 3

# Phase 8 Cogs costs -- placeholder tuning, needs a balance pass.
const REPAIR_COGS_PER_POINT := 1
const REBUILD_COGS_COST := 60
const DISMANTLE_REFUND_BASE := 50

var _slots: Array = []
var _current_tab := "inventory"
var _inventory_entries: Array = []
var _mission_entries: Array = []
var _cogs := 0
var _entries_by_key: Dictionary = {}
var progress_ref: Dictionary = {}
var _selected_weapon_key := ""


func _ready() -> void:
	for i in slot_count:
		var slot: SteamtekItemSlot = ITEM_SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.set_empty()
		slot.double_clicked.connect(slot_double_clicked.emit)
		slot.pressed.connect(func(): _show_details(slot.item_key))
		_slots.append(slot)
	close_button.pressed.connect(func(): close_requested.emit())
	tab_inventory.pressed.connect(_show_tab.bind("inventory"))
	tab_mission.pressed.connect(_show_tab.bind("mission"))
	tab_currency.pressed.connect(_show_tab.bind("currency"))
	repair_button.pressed.connect(_on_repair_pressed)
	rebuild_button.pressed.connect(_on_rebuild_pressed)
	dismantle_button.pressed.connect(_on_dismantle_pressed)
	_show_tab("inventory")


func bind_inventory_data(progress: Dictionary) -> void:
	progress_ref = progress


func configure(inventory_entries: Array, mission_entries: Array, cogs: int) -> void:
	_inventory_entries = inventory_entries
	_mission_entries = mission_entries
	_cogs = cogs
	currency_label.text = "Cogs carried: %d" % cogs
	_render_current_tab()


func _show_tab(tab_name: String) -> void:
	_current_tab = tab_name
	tab_inventory.button_pressed = tab_name == "inventory"
	tab_mission.button_pressed = tab_name == "mission"
	tab_currency.button_pressed = tab_name == "currency"
	grid.visible = tab_name != "currency"
	_render_current_tab()


func _render_current_tab() -> void:
	if _current_tab == "currency":
		# Cogs carried is already shown by the footer's currency_label
		# (set in configure()) -- the header just labels the tab instead
		# of duplicating that text into the wrong label.
		capacity_label.text = "CURRENCY"
		return
	var entries: Array = _inventory_entries if _current_tab == "inventory" else _mission_entries
	capacity_label.text = "CAPACITY  %d/%d" % [entries.size(), slot_count]
	_entries_by_key.clear()
	for i in _slots.size():
		var slot: SteamtekItemSlot = _slots[i]
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var label: String = String(entry.get("label", entry.get("key", "")))
			var icon_name: String = String(entry.get("icon_name", _derive_icon_name(label)))
			var count: int = int(entry.get("count", 1))
			var key: String = String(entry.get("key", label))
			slot.set_slot(icon_name, count, key)
			slot.tooltip_text = label
			_entries_by_key[key] = {"label": label, "icon_name": icon_name, "count": count}
		else:
			slot.set_empty()


func _show_details(item_key: String) -> void:
	if item_key == "" or not _entries_by_key.has(item_key):
		details_item_name.text = "Select an item to view its details."
		details_stats.text = ""
		mods_panel.visible = false
		_selected_weapon_key = ""
		return
	var entry: Dictionary = _entries_by_key[item_key]
	var icon_name: String = String(entry["icon_name"])
	details_item_name.text = String(entry["label"])

	var lines: Array = []
	lines.append("Quantity: %d" % int(entry["count"]))
	lines.append("")

	var item_def: Dictionary = GameData.ITEM_DEFINITIONS.get(icon_name, {})
	var stat_ranges: Dictionary = item_def.get("weapon_stat_ranges", {})
	if stat_ranges.is_empty():
		details_stats.text = "\n".join(lines)
		mods_panel.visible = false
		_selected_weapon_key = ""
		return

	_selected_weapon_key = icon_name
	var installed_mods := _get_installed_mods_for_weapon(icon_name)
	var effective_stats: Dictionary = CraftingService.compute_final_weapon_stats(stat_ranges, installed_mods)
	for stat_name in stat_ranges.keys():
		lines.append("%s: %s" % [stat_name, str(effective_stats.get(stat_name, 0.0))])
	lines.append("Damage Type: %s" % CraftingService.resolve_damage_type(installed_mods))

	if effective_stats.has("Speed") and effective_stats.has("Damage Rating"):
		var speed: float = float(effective_stats["Speed"])
		if speed > 0.0:
			var dps := roundf((float(effective_stats["Damage Rating"]) / speed) * 10.0) / 10.0
			lines.append("Damage Per Second: %s" % str(dps))

	details_stats.text = "\n".join(lines)
	mods_panel.visible = true
	_refresh_mods_panel(icon_name, installed_mods)


func set_status_text(text: String) -> void:
	status_label.text = text


func _derive_icon_name(label: String) -> String:
	var paren_index := label.find(" (")
	if paren_index != -1:
		return label.substr(0, paren_index)
	return label


# --- Mod install/remove (Phase 6 Batch 2) ------------------------------

func _get_installed_mods_for_weapon(weapon_name: String) -> Array:
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	if weapon_instance_id.is_empty():
		return []
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	var item: Dictionary = crafted_items.get(weapon_instance_id, {})
	if item.is_empty():
		return []
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var installed_mods: Array = []
	for mod_instance_id in item.get("installed_mod_instance_ids", []):
		var mod: Dictionary = mod_instances.get(String(mod_instance_id), {})
		if not mod.is_empty():
			installed_mods.append(mod)
	return installed_mods


# Returns the weapon's crafted instance, creating a bare one (flat
# DEFAULT_WEAPON_SOCKET_COUNT sockets, no experimentation/quality pass)
# the first time a mod is ever installed on it.
func _get_or_create_weapon_instance(weapon_name: String) -> Dictionary:
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	if not instance_id.is_empty() and crafted_items.has(instance_id):
		return crafted_items[instance_id]
	var new_instance_id := "weapon_%d_%d" % [Time.get_ticks_msec(), randi() % 100000]
	var item := CraftingModels.new_crafted_item(
		new_instance_id, "", weapon_name, [], {}, [], [], "standard", 50.0, 100.0, 0, 0.0
	)
	item["socket_count"] = DEFAULT_WEAPON_SOCKET_COUNT
	crafted_items[new_instance_id] = item
	progress_ref["crafted_items"] = crafted_items
	crafted_weapon_instances[weapon_name] = new_instance_id
	progress_ref["crafted_weapon_instances"] = crafted_weapon_instances
	return item


func _refresh_mods_panel(weapon_name: String, installed_mods: Array) -> void:
	for child in socket_list.get_children():
		child.queue_free()
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	var existing_item: Dictionary = crafted_items.get(weapon_instance_id, {})
	var socket_count: int = (
		int(existing_item.get("socket_count", 0)) if not existing_item.is_empty() else DEFAULT_WEAPON_SOCKET_COUNT
	)

	durability_panel.visible = not existing_item.is_empty()
	if not existing_item.is_empty():
		var current := float(existing_item.get("current_durability", 0.0))
		var maximum := float(existing_item.get("maximum_durability", 0.0))
		durability_label.text = "Durability: %d / %d%s" % [
			int(round(current)), int(round(maximum)), " (BROKEN)" if current <= 0.0 else ""
		]
		var missing := maxf(0.0, maximum - current)
		repair_button.text = "Repair (%d Cogs)" % int(ceil(missing * REPAIR_COGS_PER_POINT))
		repair_button.disabled = missing <= 0.0
		rebuild_button.text = "Rebuild (%d Cogs)" % REBUILD_COGS_COST
		var refund := int(round(CraftingService.dismantle_refund_fraction(existing_item) * DISMANTLE_REFUND_BASE))
		dismantle_button.text = "Dismantle (+%d Cogs)" % refund
	for i in socket_count:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i < installed_mods.size():
			var mod: Dictionary = installed_mods[i]
			var mod_def: Dictionary = CraftingData.get_mod(String(mod.get("mod_id", "")))
			label.text = "%s (%s)" % [
				String(mod_def.get("display_name", "?")), String(mod.get("grade_id", "standard"))
			]
			var remove_button := Button.new()
			remove_button.text = "Remove"
			remove_button.pressed.connect(_on_remove_mod_pressed.bind(String(mod.get("mod_instance_id", ""))))
			row.add_child(label)
			row.add_child(remove_button)
		else:
			label.text = "(empty socket)"
			row.add_child(label)
		socket_list.add_child(row)

	for child in owned_mods_list.get_children():
		child.queue_free()
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var mods_owned: Dictionary = progress_ref.get("mods_owned", {})
	for mod_instance_id in mods_owned.keys():
		var mod: Dictionary = mod_instances.get(String(mod_instance_id), {})
		if mod.is_empty():
			continue
		var mod_def: Dictionary = CraftingData.get_mod(String(mod.get("mod_id", "")))
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s (%s)" % [
			String(mod_def.get("display_name", "?")), String(mod.get("grade_id", "standard"))
		]
		var install_button := Button.new()
		install_button.text = "Install"
		install_button.pressed.connect(_on_install_mod_pressed.bind(String(mod_instance_id)))
		row.add_child(label)
		row.add_child(install_button)
		owned_mods_list.add_child(row)


func _on_install_mod_pressed(mod_instance_id: String) -> void:
	if _selected_weapon_key.is_empty():
		return
	var weapon_name := _selected_weapon_key
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var mod: Dictionary = mod_instances.get(mod_instance_id, {})
	if mod.is_empty():
		return
	var weapon_def: Dictionary = GameData.ITEM_DEFINITIONS.get(weapon_name, {})
	var weapon_class := String(weapon_def.get("item_class", ""))
	var weapon_range := String(CombatData.family_for_class(weapon_class).get("range", ""))
	var installed_mods := _get_installed_mods_for_weapon(weapon_name)
	var item := _get_or_create_weapon_instance(weapon_name)
	var problems := CraftingService.mod_install_problems(item, mod, installed_mods, weapon_range)
	if not problems.is_empty():
		set_status_text(String(problems[0]))
		return
	CraftingService.apply_mod_installation(item, mod)
	var mods_owned: Dictionary = progress_ref.get("mods_owned", {})
	mods_owned.erase(mod_instance_id)
	progress_ref["mods_owned"] = mods_owned
	set_status_text("Installed.")
	_show_details(weapon_name)


func _on_remove_mod_pressed(mod_instance_id: String) -> void:
	if _selected_weapon_key.is_empty():
		return
	var weapon_name := _selected_weapon_key
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	if weapon_instance_id.is_empty():
		return
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	var item: Dictionary = crafted_items.get(weapon_instance_id, {})
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var mod: Dictionary = mod_instances.get(mod_instance_id, {})
	if item.is_empty() or mod.is_empty():
		return
	CraftingService.remove_mod_installation(item, mod)
	var mods_owned: Dictionary = progress_ref.get("mods_owned", {})
	mods_owned[mod_instance_id] = true
	progress_ref["mods_owned"] = mods_owned
	set_status_text("Removed.")
	_show_details(weapon_name)


# --- Repair/Rebuild/Dismantle (Phase 8) ---------------------------------

func _on_repair_pressed() -> void:
	if _selected_weapon_key.is_empty():
		return
	var weapon_name := _selected_weapon_key
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	if weapon_instance_id.is_empty():
		return
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	var item: Dictionary = crafted_items.get(weapon_instance_id, {})
	if item.is_empty():
		return
	var missing := maxf(0.0, float(item.get("maximum_durability", 0.0)) - float(item.get("current_durability", 0.0)))
	var cost := int(ceil(missing * REPAIR_COGS_PER_POINT))
	if cost <= 0:
		return
	var cogs := int(progress_ref.get("cogs", 0))
	if cogs < cost:
		set_status_text("Not enough Cogs.")
		return
	progress_ref["cogs"] = cogs - cost
	CraftingService.repair_item(item, missing)
	set_status_text("Repaired.")
	inventory_changed.emit()
	_show_details(weapon_name)


func _on_rebuild_pressed() -> void:
	if _selected_weapon_key.is_empty():
		return
	var weapon_name := _selected_weapon_key
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	if weapon_instance_id.is_empty():
		return
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	var item: Dictionary = crafted_items.get(weapon_instance_id, {})
	if item.is_empty():
		return
	var cogs := int(progress_ref.get("cogs", 0))
	if cogs < REBUILD_COGS_COST:
		set_status_text("Not enough Cogs.")
		return
	progress_ref["cogs"] = cogs - REBUILD_COGS_COST
	var freed_mod_instance_ids := CraftingService.rebuild_item(item)
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var mods_owned: Dictionary = progress_ref.get("mods_owned", {})
	for mod_instance_id in freed_mod_instance_ids:
		var mod: Dictionary = mod_instances.get(String(mod_instance_id), {})
		if not mod.is_empty():
			mod["installed_in"] = ""
		mods_owned[String(mod_instance_id)] = true
	progress_ref["mods_owned"] = mods_owned
	set_status_text("Rebuilt.")
	inventory_changed.emit()
	_show_details(weapon_name)


func _on_dismantle_pressed() -> void:
	if _selected_weapon_key.is_empty():
		return
	var weapon_name := _selected_weapon_key
	var crafted_weapon_instances: Dictionary = progress_ref.get("crafted_weapon_instances", {})
	var weapon_instance_id := String(crafted_weapon_instances.get(weapon_name, ""))
	if weapon_instance_id.is_empty():
		return
	var crafted_items: Dictionary = progress_ref.get("crafted_items", {})
	var item: Dictionary = crafted_items.get(weapon_instance_id, {})
	if item.is_empty():
		return
	var refund := int(round(CraftingService.dismantle_refund_fraction(item) * DISMANTLE_REFUND_BASE))
	var mod_instances: Dictionary = progress_ref.get("mod_instances", {})
	var mods_owned: Dictionary = progress_ref.get("mods_owned", {})
	for mod_instance_id in item.get("installed_mod_instance_ids", []):
		var mod: Dictionary = mod_instances.get(String(mod_instance_id), {})
		if not mod.is_empty():
			mod["installed_in"] = ""
		mods_owned[String(mod_instance_id)] = true
	progress_ref["mods_owned"] = mods_owned
	crafted_items.erase(weapon_instance_id)
	progress_ref["crafted_items"] = crafted_items
	crafted_weapon_instances.erase(weapon_name)
	progress_ref["crafted_weapon_instances"] = crafted_weapon_instances
	var weapons_owned: Dictionary = progress_ref.get("weapons_owned", {})
	weapons_owned.erase(weapon_name)
	progress_ref["weapons_owned"] = weapons_owned
	if String(progress_ref.get("equipped_weapon", "")) == weapon_name:
		progress_ref["equipped_weapon"] = ""
	progress_ref["cogs"] = int(progress_ref.get("cogs", 0)) + refund
	set_status_text("Dismantled: +%d Cogs" % refund)
	inventory_changed.emit()
	_show_details("")
