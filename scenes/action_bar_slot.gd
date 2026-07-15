extends Button
class_name ActionBarSlot

# Which ability (if any) is currently assigned to this slot. Empty
# string means the slot is blank.
var assigned_ability: String = ""

func _ready() -> void:
	if text == "":
		text = "(empty)"
	# Without this, a slot holding keyboard focus can silently
	# intercept key presses (like M for the Ability Menu) before they
	# ever reach _unhandled_input — same class of issue Trees/
	# ItemLists caused earlier in this project.
	focus_mode = Control.FOCUS_NONE

# Called automatically by Godot while something is being dragged over
# this button, to ask "would you accept a drop here?" Only accepts
# drags that came from an ability_drag_source.gd button (identified
# by having an "ability_name" key in the dragged data).
func _can_drop_data(_at_position: Vector2, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("ability_name")

# Called automatically when a valid drag is actually released over
# this button — this is where the ability gets assigned to the slot.
func _drop_data(_at_position: Vector2, data) -> void:
	assigned_ability = data["ability_name"]
	text = assigned_ability

# Button's built-in virtual method, called whenever this button is
# clicked — using this instead of connecting the "pressed" signal
# since these 8 slots are created identically and don't need any
# per-slot wiring beyond this script.
func _pressed() -> void:
	if assigned_ability == "":
		return

	# The running scene's root is literally named "Main" (matches
	# Main.tscn), so this reaches back into your main script from
	# deep inside the UI tree without needing a manually wired signal.
	var main_node = get_node("/root/Main")
	main_node._use_ability_by_name(assigned_ability)
