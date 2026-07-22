extends Control
class_name SteamtekItemGridPanel

## Generic icon-grid panel used for storage crates, player inventory, and
## anywhere else a Live3D scene needs to show a list of items/weapons.
## Callers own the actual item state (a local `progress` dictionary) —
## this panel only renders whatever `configure()` is given and reports
## double-clicks back via a Callable, matching the pattern already used
## by `steamtek_apartment.gd`'s storage/inventory windows.

const ITEM_SLOT_SCENE := preload("res://scenes/gameplay/live3d/SteamtekItemSlot.tscn")

@onready var title_label: Label = $Title
@onready var grid: GridContainer = $Grid


func configure(panel_title: String, entries: Array, on_double_click: Callable) -> void:
	title_label.text = panel_title
	for child in grid.get_children():
		child.queue_free()
	for entry in entries:
		var slot: SteamtekItemSlot = ITEM_SLOT_SCENE.instantiate()
		grid.add_child(slot)
		var label: String = String(entry.get("label", entry.get("key", "")))
		var icon_name: String = String(entry.get("icon_name", _derive_icon_name(label)))
		var count: int = int(entry.get("count", 1))
		slot.set_slot(icon_name, count, String(entry.get("key", label)))
		slot.tooltip_text = label
		slot.double_clicked.connect(on_double_click)


func _derive_icon_name(label: String) -> String:
	var paren_index := label.find(" (")
	if paren_index != -1:
		return label.substr(0, paren_index)
	return label
