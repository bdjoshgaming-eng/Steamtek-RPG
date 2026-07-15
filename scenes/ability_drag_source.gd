extends Button

# Set this in the Inspector for EACH of the 8 buttons in AbilityMenu,
# to the exact name main.gd expects: "Attack", "Power Strike",
# "Crushing Blow", "Iron Fist", "Quick Slash", "Bludgeon", "Backhand",
# or "Scrap Bandage".
@export var ability_name: String = ""

# Called automatically by Godot when a drag starts from this button.
# Returning null means "this can't be dragged" — only matters if
# ability_name was left blank by mistake.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if ability_name == "":
		return null

	# Small floating label that follows the cursor during the drag,
	# so there's clear visual feedback about what's being dragged.
	var preview = Label.new()
	preview.text = ability_name
	set_drag_preview(preview)

	return {"ability_name": ability_name}
