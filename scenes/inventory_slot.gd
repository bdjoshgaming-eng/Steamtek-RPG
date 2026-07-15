extends Button
class_name InventorySlot

# Which actual inventory dictionary key this slot currently holds —
# could be a raw resource instance name, a unique charge-item name
# (like a specific Scrap Bandage), or a simple named item/tool. Empty
# means this slot is currently unused.
var item_key: String = ""
# What to actually show and use as drag data / for the use-action —
# the real display name (e.g. "Scrap Bandage", "Mineral Survey Tool"),
# NOT the raw unique key, since that's often a random generated name.
var display_name: String = ""

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE

# Called automatically by Godot when a drag starts from this slot.
# Uses the SAME data format as ability_drag_source.gd ("ability_name"
# key) specifically so it's compatible with your EXISTING
# action_bar_slot.gd's drop-acceptance check without needing any
# changes there — an inventory item and an ability both just become
# "something with a name that can be dropped onto a slot."
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_key == "":
		return null

	var preview = Label.new()
	preview.text = display_name
	set_drag_preview(preview)

	return {"ability_name": display_name}

# Godot's Button doesn't have a built-in "double-click" signal, so
# this listens for the raw mouse event directly and checks its
# double_click flag.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click:
		if item_key != "":
			var main_node = get_node("/root/Main")
			main_node._use_inventory_item(item_key, display_name)
