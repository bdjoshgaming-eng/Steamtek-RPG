extends Button
class_name SteamtekItemSlot

## Reusable inventory/crafting slot: icon + count badge + native tooltip +
## double-click signal. Self-contained (no Main-autoload dependency) so it
## works in any Live3D scene that tracks its own local item state.
##
## Named icon_display (not "icon") because Button already has a native
## "icon" export property — reusing that name silently breaks the whole
## script (GDScript refuses to redefine a native member and every scene
## instancing this fails to attach the script).

signal double_clicked(item_key: String)

@onready var icon_display: SteamtekItemIcon = $Icon
@onready var count_label: Label = $CountBadge

var item_key: String = ""


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	text = ""


func set_slot(item_name: String, count: int, key: String) -> void:
	item_key = key
	icon_display.visible = true
	icon_display.set_item(item_name)
	tooltip_text = item_name
	if count > 1:
		count_label.text = "x%d" % count
		count_label.visible = true
	else:
		count_label.visible = false


func set_empty() -> void:
	item_key = ""
	icon_display.visible = false
	tooltip_text = ""
	count_label.visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click and item_key != "":
		double_clicked.emit(item_key)
