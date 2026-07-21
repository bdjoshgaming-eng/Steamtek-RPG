extends Button

# Makes an inventory entry that is a MOD draggable onto a weapon's socket
# slot. Deliberately a separate payload shape from ability_drag_source.gd:
# that one returns {"ability_name": ...} for the action bar, this returns
# {"mod_item_key": ...}. Because the keys differ, action-bar slots reject
# mods and socket slots reject abilities, with no extra checks anywhere.

var mod_item_key: String = ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if mod_item_key == "":
		return null

	var preview = Label.new()
	preview.text = text
	set_drag_preview(preview)

	return {"mod_item_key": mod_item_key}
