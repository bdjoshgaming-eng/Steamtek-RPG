extends Control
class_name SteamtekInventoryWindow

## Full inventory window: fixed slot count (so the grid always reads as
## a real inventory instead of resizing per item), a capacity readout,
## Inventory/Mission Items/Currency tabs, and a Details side panel that
## shows an item's real stats when clicked — mirrors main.tscn's
## inventory book layout (Details | Items), styled with Steamtek's own
## dark/amber palette instead of borrowing anyone else's color scheme.

const ITEM_SLOT_SCENE := preload("res://scenes/gameplay/live3d/SteamtekItemSlot.tscn")

signal close_requested
signal slot_double_clicked(item_key: String)

@export var slot_count := 48

@onready var capacity_label: Label = $Header/CapacityLabel
@onready var grid: GridContainer = $Grid
@onready var currency_label: Label = $Footer/CurrencyLabel
@onready var status_label: Label = $Footer/StatusLabel
@onready var close_button: Button = $Close
@onready var tab_inventory: Button = $Tabs/Inventory
@onready var tab_mission: Button = $Tabs/MissionItems
@onready var tab_currency: Button = $Tabs/Currency
@onready var details_item_name: Label = $Details/ItemName
@onready var details_stats: Label = $Details/Stats

var _slots: Array = []
var _current_tab := "inventory"
var _inventory_entries: Array = []
var _mission_entries: Array = []
var _cogs := 0
var _entries_by_key: Dictionary = {}


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
	_show_tab("inventory")


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
		return

	var base_stats: Dictionary = {}
	for stat_name in stat_ranges.keys():
		var range_values: Array = stat_ranges[stat_name]
		base_stats[stat_name] = range_values[0]
		lines.append("%s: %s" % [stat_name, str(range_values[0])])

	if base_stats.has("Speed") and base_stats.has("Damage Rating"):
		var speed: float = float(base_stats["Speed"])
		if speed > 0.0:
			var dps := roundf((float(base_stats["Damage Rating"]) / speed) * 10.0) / 10.0
			lines.append("Damage Per Second: %s" % str(dps))

	details_stats.text = "\n".join(lines)


func set_status_text(text: String) -> void:
	status_label.text = text


func _derive_icon_name(label: String) -> String:
	var paren_index := label.find(" (")
	if paren_index != -1:
		return label.substr(0, paren_index)
	return label
