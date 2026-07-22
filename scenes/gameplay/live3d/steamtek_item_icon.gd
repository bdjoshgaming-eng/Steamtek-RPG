extends Control
class_name SteamtekItemIcon

## Placeholder item icon: a category-colored square with a short
## abbreviation label. No texture/art dependency — swap the Panel's
## style for a TextureRect here later without touching any caller.

@onready var background: Panel = $Background
@onready var label: Label = $Label

var item_name: String = ""


func set_item(new_item_name: String) -> void:
	item_name = new_item_name
	var resolved := SteamtekItemIconRegistry.resolve(new_item_name)
	var style := StyleBoxFlat.new()
	style.bg_color = resolved["color"]
	style.border_color = resolved["color"].lightened(0.35)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	background.add_theme_stylebox_override("panel", style)
	label.text = String(resolved["abbreviation"])
