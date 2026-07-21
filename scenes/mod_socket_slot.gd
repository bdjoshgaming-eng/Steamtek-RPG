extends Panel

# One mod socket on a crafted weapon, acting as a drop target for mods
# dragged out of the inventory list.
#
# Dropping does NOT install. It stages the mod as PENDING, so the player
# can see the resulting stat change and back out. Installation only
# happens on Apply, behind a confirmation, because mods cannot be removed
# once fitted.

var main
var socket_index: int = -1
# Set false for sockets that already hold a permanently installed mod.
var accepts_drop: bool = true


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not accepts_drop or main == null:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("mod_item_key"):
		return false
	return main.can_stage_mod_in_socket(socket_index, String(data["mod_item_key"]))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if main == null or typeof(data) != TYPE_DICTIONARY:
		return
	if not data.has("mod_item_key"):
		return
	main.stage_mod_in_socket(socket_index, String(data["mod_item_key"]))
