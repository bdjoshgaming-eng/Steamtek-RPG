@tool
extends EditorPlugin

const COUCH_PROFILE_ID := "STK_PROP_Couch_A_Upholstery_v1"
const COUCH_BASE_SCENE_PATH := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_A.tscn"
const COUCH_TEMPLATE_MATERIAL_PATH := "res://assets/environment/live3d/materials/apartment_interior_variants/STK_MAT_Couch_A_DeepTeal.tres"
const BED_PROFILE_ID := "steamtek_bed_v1"
const BED_BASE_SCENE_PATH := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bed_A.tscn"
const BED_TEMPLATE_MATERIAL_PATH := "res://assets/environment/live3d/materials/apartment_interior_variants/bed/STK_MAT_Bed_A_SourceMatte.tres"
const BED_REGIONS := ["Bedding_Main", "Bedding_Secondary", "Frame_PaintedMetal", "Accent_Powered"]
const BOOKSHELF_PROFILE_ID := "steamtek_bookshelf_v1"
const BOOKSHELF_BASE_SCENE_PATH := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn"
const BOOKSHELF_TEMPLATE_MATERIAL_PATH := "res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_SourceMatte.tres"
const BOOKSHELF_REGIONS := ["Frame_PaintedMetal", "Shelf_PaintedMetal", "Accent_Powered"]
const SECTIONAL_PROFILE_ID := "steamtek_sectional_couch_v1"
const SECTIONAL_BASE_SCENE_PATH := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Left.tscn"
const SECTIONAL_TEMPLATE_MATERIAL_PATH := "res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_left/STK_MAT_Couch_L4_Left_SourceMatte.tres"
const SECTIONAL_RIGHT_BASE_SCENE_PATH := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Right.tscn"
const SECTIONAL_RIGHT_TEMPLATE_MATERIAL_PATH := "res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_right/STK_MAT_Couch_L4_Right_SourceMatte.tres"
const SECTIONAL_REGIONS := ["Cushion_Leather", "Frame_PaintedMetal", "Accent_Metal"]
const DINING_TABLE_PROFILE_ID := "steamtek_dining_table_rect_v1"
const DINING_TABLE_BASE_SCENE_PATH := "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Table_Dining_Rect_01.tscn"
const DINING_TABLE_TEMPLATE_MATERIAL_PATH := "res://assets/environment/live3d/materials/apartment_interior_variants/table_dining_rect_01/STK_MAT_Table_Dining_Rect_01_SourceMatte.tres"
const DINING_TABLE_REGIONS := ["Tabletop_DarkSurface", "Frame_PaintedMetal", "Accent_Metal", "Accent_Powered_Cyan", "Accent_Powered_Magenta"]
const VARIANT_SCRIPT_PATH := "res://scenes/environment/live3d/props/static_prop_material_variant.gd"
const BOOKSHELF_VARIANT_SCRIPT_PATH := VARIANT_SCRIPT_PATH
const GENERATED_MATERIAL_DIR := "res://assets/environment/live3d/materials/apartment_interior_variants/generated"
const GENERATED_SCENE_DIR := "res://scenes/environment/live3d/props/apartment_interior/generated_variants"
const SCENE_OVERRIDE_META := "material_variant_scene_override"
const SCENE_OVERRIDE_BASE_PATH_META := "material_variant_scene_override_base_material_path"

const STEAMTEK_PALETTE := [
	{"name": "Oxblood", "color": Color(0.28, 0.055, 0.065)},
	{"name": "Deep Teal", "color": Color(0.055, 0.285, 0.305)},
	{"name": "Electric Plum", "color": Color(0.405, 0.085, 0.31)},
	{"name": "Burnished Ochre", "color": Color(0.49, 0.285, 0.065)},
	{"name": "Gunmetal Blue", "color": Color(0.10, 0.17, 0.24)},
	{"name": "Charcoal", "color": Color(0.105, 0.11, 0.125)},
	{"name": "Verdigris", "color": Color(0.12, 0.36, 0.31)},
	{"name": "Magenta Signal", "color": Color(0.72, 0.07, 0.43)},
	{"name": "Cyan Signal", "color": Color(0.02, 0.57, 0.68)},
	{"name": "Bright Green Signal", "color": Color(0.25, 0.78, 0.20)},
]

var dock: ScrollContainer
var dock_content: VBoxContainer
var asset_status: Label
var region_picker: OptionButton
var palette_picker: OptionButton
var color_picker: ColorPickerButton
var tint_strength: SpinBox
var brightness: SpinBox
var roughness_offset: SpinBox
var metallic_offset: SpinBox
var emission_strength: SpinBox
var emission_enabled: CheckBox
var variant_name: LineEdit
var status_label: Label

var preview_target: Node3D
var preview_material: ShaderMaterial
var preview_original_materials: Dictionary = {}
var palette_change_in_progress := false
var region_ui_change_in_progress := false
var active_region := ""
var selected_module_instance_id := 0
var bed_region_state: Dictionary = {}


func _enter_tree() -> void:
	_create_dock()
	var selection := get_editor_interface().get_selection()
	selection.selection_changed.connect(_on_selection_changed)
	_update_selected_asset()


func _exit_tree() -> void:
	_revert_preview(false)
	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.queue_free()
	_write_preferred_dock_layout()


func _create_dock() -> void:
	dock = ScrollContainer.new()
	dock.name = "STK Variants"
	dock.custom_minimum_size = Vector2(280.0, 0.0)
	dock.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dock_content = VBoxContainer.new()
	dock_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock.add_child(dock_content)

	var title := Label.new()
	title.text = "Steamtek Material Variant Editor"
	title.tooltip_text = "Create safe, reusable color variants without graphics software."
	dock_content.add_child(title)

	var intro := Label.new()
	intro.text = "Select a supported asset. Only approved material regions can change. Geometry, collision, pivots, and sockets stay locked."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock_content.add_child(intro)

	dock_content.add_child(HSeparator.new())

	asset_status = Label.new()
	asset_status.text = "Selected asset: none"
	asset_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock_content.add_child(asset_status)

	var region_label := Label.new()
	region_label.text = "Recolorable region"
	dock_content.add_child(region_label)

	region_picker = OptionButton.new()
	region_picker.add_item("Upholstery")
	region_picker.disabled = true
	region_picker.tooltip_text = "The couch intake profile exposes only its upholstery region."
	region_picker.item_selected.connect(_on_region_selected)
	dock_content.add_child(region_picker)

	var palette_label := Label.new()
	palette_label.text = "Steamtek palette"
	dock_content.add_child(palette_label)

	palette_picker = OptionButton.new()
	palette_picker.add_item("Custom color")
	for entry in STEAMTEK_PALETTE:
		var item_index := palette_picker.item_count
		palette_picker.add_item(str(entry.get("name", "Preset")))
		palette_picker.set_item_metadata(item_index, entry.get("color", Color.WHITE))
	palette_picker.selected = 2
	palette_picker.item_selected.connect(_on_palette_selected)
	dock_content.add_child(palette_picker)

	color_picker = ColorPickerButton.new()
	color_picker.color = STEAMTEK_PALETTE[1]["color"]
	color_picker.edit_alpha = false
	color_picker.tooltip_text = "Choose any custom color. Steamtek presets help maintain visual consistency."
	color_picker.color_changed.connect(_on_custom_color_changed)
	dock_content.add_child(color_picker)

	tint_strength = _add_number_control("Color strength", 0.0, 1.0, 0.01, 0.94, "How strongly the selected region takes the new color.")
	brightness = _add_number_control("Brightness", 0.5, 1.5, 0.01, 1.0, "Preserves painted detail while shifting the recolored region brighter or darker.")
	roughness_offset = _add_number_control("Roughness adjustment", -0.5, 0.5, 0.01, 0.0, "Negative is glossier; positive is rougher. Use small changes.")
	metallic_offset = _add_number_control("Metallic adjustment", -0.15, 0.15, 0.01, 0.0, "Safe fine adjustment for painted metal only.")
	metallic_offset.editable = false
	emission_strength = _add_number_control("Emission strength", 0.0, 4.0, 0.05, 1.0, "Locked: upholstery is not a powered region.")
	emission_strength.editable = false
	emission_enabled = CheckBox.new()
	emission_enabled.text = "Powered accent enabled"
	emission_enabled.button_pressed = true
	emission_enabled.disabled = true
	emission_enabled.tooltip_text = "Available only for an approved powered accent region."
	emission_enabled.toggled.connect(_on_emission_toggled)
	dock_content.add_child(emission_enabled)

	var preview_row := HBoxContainer.new()
	preview_row.add_child(_make_button("Preview on Selected Asset", _preview_selected))
	preview_row.add_child(_make_button("Revert Preview", _revert_preview))
	dock_content.add_child(preview_row)

	var apply_scene_button := _make_button("Apply to This Scene", _apply_to_scene)
	apply_scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_scene_button.tooltip_text = "Embed the current material settings on this prop instance. Save the open scene with Ctrl+S."
	dock_content.add_child(apply_scene_button)
	var remove_scene_button := _make_button("Remove Scene Override", _remove_scene_override)
	remove_scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_scene_button.tooltip_text = "Restore this prop instance to the material inherited from its reusable base scene."
	dock_content.add_child(remove_scene_button)

	dock_content.add_child(HSeparator.new())

	var name_label := Label.new()
	name_label.text = "New variant name"
	dock_content.add_child(name_label)

	variant_name = LineEdit.new()
	variant_name.placeholder_text = "Example: Midnight Teal"
	variant_name.tooltip_text = "A safe file suffix and Builder label are created automatically."
	dock_content.add_child(variant_name)

	dock_content.add_child(_make_button("Save as Variant", _save_variant))

	status_label = Label.new()
	status_label.text = "Ready. Select a supported couch, bed, bookshelf, sectional, or dining table."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock_content.add_child(status_label)

	# Share the lower-right area with the Builder as a separate named tab. The
	# unique dock name prevents restored layouts from crossing tab identity and
	# content when the two editor plugins reload in a different order.
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	call_deferred("_enforce_live3d_builder_tab_order")


func _enforce_live3d_builder_tab_order() -> void:
	# Godot restores dock layout asynchronously after plugins enter the tree.
	# Recheck for several frames from the later-loading Variants plugin so the
	# Builder remains the first tab even when an older layout is restored.
	for _frame in range(600):
		await get_tree().process_frame
		if not is_instance_valid(dock):
			return
		var variant_editor_dock := dock.get_parent()
		var tab_container := variant_editor_dock.get_parent() if variant_editor_dock != null else null
		if tab_container == null:
			continue
		for editor_dock in tab_container.get_children():
			for content in editor_dock.get_children():
				if content.name != "Steamtek Live3D Builder":
					continue
				if editor_dock.get_index() != 0:
					(tab_container as TabContainer).get_tab_bar().move_tab(editor_dock.get_index(), 0)
					tab_container.emit_signal("active_tab_rearranged", 0)
					if tab_container is TabContainer:
						(tab_container as TabContainer).current_tab = 0
				break
	_write_preferred_dock_layout()


func _write_preferred_dock_layout() -> void:
	var layout_path := ProjectSettings.globalize_path("res://.godot/editor/editor_layout.cfg")
	var layout := ConfigFile.new()
	if layout.load(layout_path) != OK:
		return
	layout.set_value("docks", "dock_6", "Steamtek Live3D Builder,STK Variants")
	layout.set_value("docks", "dock_6_selected_tab_idx", 0)
	layout.save(layout_path)


func _add_number_control(label_text: String, minimum: float, maximum: float, step: float, value: float, tooltip: String) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	dock_content.add_child(label)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = value
	control.tooltip_text = tooltip
	control.value_changed.connect(_on_control_changed)
	dock_content.add_child(control)
	return control


func _make_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.pressed.connect(callback)
	return button


func _on_selection_changed() -> void:
	if preview_target != _selected_supported_module():
		_revert_preview(false)
	_update_selected_asset()


func _update_selected_asset() -> void:
	var module := _selected_supported_module()
	if module == null:
		asset_status.text = "Selected asset: unsupported or none"
		selected_module_instance_id = 0
		bed_region_state.clear()
		active_region = ""
		_set_regions([])
		return
	var module_instance_id := module.get_instance_id()
	var module_changed := selected_module_instance_id != module_instance_id
	if module_changed:
		selected_module_instance_id = module_instance_id
		bed_region_state.clear()
		active_region = ""
	var profile := _module_profile(module)
	if profile == BED_PROFILE_ID:
		asset_status.text = "Selected asset: %s\nProfile: Bed material regions" % module.name
		if module_changed:
			_load_bed_state_from_scene_override(module)
		_set_regions(BED_REGIONS)
	elif profile == BOOKSHELF_PROFILE_ID:
		asset_status.text = "Selected asset: %s\nProfile: Bookshelf material regions" % module.name
		if module_changed:
			_load_bookshelf_state_from_scene_override(module)
		_set_regions(BOOKSHELF_REGIONS)
	elif profile == SECTIONAL_PROFILE_ID:
		asset_status.text = "Selected asset: %s\nProfile: Sectional couch material regions" % module.name
		if module_changed:
			_load_sectional_state_from_scene_override(module)
		_set_regions(SECTIONAL_REGIONS)
	elif profile == DINING_TABLE_PROFILE_ID:
		asset_status.text = "Selected asset: %s\nProfile: Dining table material regions" % module.name
		if module_changed:
			_load_dining_table_state_from_scene_override(module)
		_set_regions(DINING_TABLE_REGIONS)
	else:
		asset_status.text = "Selected asset: %s\nProfile: Couch upholstery" % module.name
		_set_regions(["Upholstery"])
		if module_changed:
			_load_couch_controls_from_scene_override(module)
	_update_region_controls()


func _selected_supported_module() -> Node3D:
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	if selected.is_empty():
		return null
	var current := selected[0] as Node
	while current != null:
		if current is Node3D:
			var profile := str(current.get_meta("material_variant_profile", ""))
			if profile == COUCH_PROFILE_ID or profile == BED_PROFILE_ID or profile == BOOKSHELF_PROFILE_ID or profile == SECTIONAL_PROFILE_ID or profile == DINING_TABLE_PROFILE_ID:
				return current as Node3D
		current = current.get_parent()
	return null


func _module_profile(module: Node3D) -> String:
	if module == null:
		return ""
	return str(module.get_meta("material_variant_profile", ""))


func _set_regions(regions: Array) -> void:
	if not is_instance_valid(region_picker):
		return
	var previous := active_region
	region_picker.clear()
	for region in regions:
		region_picker.add_item(str(region))
	region_picker.disabled = regions.size() <= 1
	var chosen_index := 0
	if not previous.is_empty():
		for index in region_picker.item_count:
			if region_picker.get_item_text(index) == previous:
				chosen_index = index
				break
	if region_picker.item_count > 0:
		region_picker.select(chosen_index)
		active_region = region_picker.get_item_text(chosen_index)
	else:
		active_region = ""
	_load_active_region_controls()


func _selected_region() -> String:
	if region_picker.item_count == 0 or region_picker.selected < 0:
		return ""
	return region_picker.get_item_text(region_picker.selected)


func _on_region_selected(_index: int) -> void:
	if region_ui_change_in_progress:
		return
	_capture_active_region_state()
	active_region = _selected_region()
	_load_active_region_controls()
	_update_region_controls()


func _update_region_controls() -> void:
	var region := _selected_region()
	var powered := region.begins_with("Accent_Powered")
	var painted_metal := region == "Frame_PaintedMetal" or region == "Accent_Metal" or region == "Tabletop_DarkSurface"
	if is_instance_valid(tint_strength):
		tint_strength.editable = not powered
	if is_instance_valid(brightness):
		brightness.editable = not powered
	if is_instance_valid(roughness_offset):
		roughness_offset.editable = not powered
	if is_instance_valid(metallic_offset):
		metallic_offset.editable = painted_metal
	if is_instance_valid(emission_strength):
		emission_strength.editable = powered
	if is_instance_valid(emission_enabled):
		emission_enabled.disabled = not powered
	if region == "Upholstery":
		region_picker.tooltip_text = "The couch intake profile exposes only its upholstery region."
	elif not region.is_empty():
		region_picker.tooltip_text = "Only the selected approved material region will change."
	else:
		region_picker.tooltip_text = "Select a supported asset first."


func _default_bed_region_state(region: String) -> Dictionary:
	var default_color := Color(0.28, 0.055, 0.065)
	match region:
		"Bedding_Secondary":
			default_color = Color(0.38, 0.35, 0.34)
		"Frame_PaintedMetal":
			default_color = Color(0.075, 0.135, 0.17)
		"Accent_Powered":
			default_color = Color(0.02, 0.57, 0.68)
	return {
		"color": default_color,
		"tint_strength": 0.94,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": 1.25,
		"emission_enabled": true,
	}


func _default_bookshelf_region_state(region: String) -> Dictionary:
	var default_color := Color(0.055, 0.10, 0.13)
	match region:
		"Shelf_PaintedMetal":
			default_color = Color(0.035, 0.055, 0.065)
		"Accent_Powered":
			default_color = Color(0.02, 0.57, 0.68)
	return {
		"color": default_color,
		"tint_strength": 0.82,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": 1.10,
		"emission_enabled": true,
	}


func _default_sectional_region_state(region: String) -> Dictionary:
	var default_color := Color(0.28, 0.055, 0.065)
	match region:
		"Frame_PaintedMetal":
			default_color = Color(0.055, 0.10, 0.13)
		"Accent_Metal":
			default_color = Color(0.45, 0.22, 0.09)
	return {
		"color": default_color,
		"tint_strength": 0.86,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": 0.0,
		"emission_enabled": false,
	}


func _default_dining_table_region_state(region: String) -> Dictionary:
	var default_color := Color(0.10, 0.14, 0.18)
	var emission_default := 0.0
	var powered := false
	match region:
		"Frame_PaintedMetal":
			default_color = Color(0.055, 0.10, 0.13)
		"Accent_Metal":
			default_color = Color(0.45, 0.22, 0.09)
		"Accent_Powered_Cyan":
			default_color = Color(0.02, 0.57, 0.68)
			emission_default = 0.90
			powered = true
		"Accent_Powered_Magenta":
			default_color = Color(0.72, 0.07, 0.43)
			emission_default = 0.55
			powered = true
	return {
		"color": default_color,
		"tint_strength": 1.0 if powered else 0.82,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": emission_default,
		"emission_enabled": powered,
	}


func _active_profile_regions(profile: String) -> Array:
	if profile == BED_PROFILE_ID:
		return BED_REGIONS
	if profile == BOOKSHELF_PROFILE_ID:
		return BOOKSHELF_REGIONS
	if profile == SECTIONAL_PROFILE_ID:
		return SECTIONAL_REGIONS
	if profile == DINING_TABLE_PROFILE_ID:
		return DINING_TABLE_REGIONS
	return []


func _default_active_region_state(profile: String, region: String) -> Dictionary:
	if profile == BOOKSHELF_PROFILE_ID:
		return _default_bookshelf_region_state(region)
	if profile == SECTIONAL_PROFILE_ID:
		return _default_sectional_region_state(region)
	if profile == DINING_TABLE_PROFILE_ID:
		return _default_dining_table_region_state(region)
	return _default_bed_region_state(region)


func _core_controls_ready() -> bool:
	return (
		is_instance_valid(region_picker)
		and is_instance_valid(palette_picker)
		and is_instance_valid(color_picker)
		and is_instance_valid(tint_strength)
		and is_instance_valid(brightness)
		and is_instance_valid(roughness_offset)
	)


func _module_has_property(module: Object, property_name: StringName) -> bool:
	for property in module.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _module_variant_material(module: Node3D) -> Material:
	if module == null or not _module_has_property(module, &"variant_material"):
		return null
	return module.get("variant_material") as Material


func _is_right_sectional(module: Node3D) -> bool:
	if module == null or _module_profile(module) != SECTIONAL_PROFILE_ID:
		return false
	return (
		str(module.get_meta("sectional_orientation", "")) == "right"
		or str(module.get_meta("module_variant", "")) == "STK_PROP_Couch_L4_Right"
	)


func _sectional_template_material_path(module: Node3D) -> String:
	return SECTIONAL_RIGHT_TEMPLATE_MATERIAL_PATH if _is_right_sectional(module) else SECTIONAL_TEMPLATE_MATERIAL_PATH


func _sectional_base_scene_path(module: Node3D) -> String:
	return SECTIONAL_RIGHT_BASE_SCENE_PATH if _is_right_sectional(module) else SECTIONAL_BASE_SCENE_PATH


func _sectional_asset_stem(module: Node3D) -> String:
	return "Couch_L4_Right" if _is_right_sectional(module) else "Couch_L4_Left"


func _shader_color(material: ShaderMaterial, parameter: StringName, fallback: Color) -> Color:
	var value: Variant = material.get_shader_parameter(parameter)
	if value is Vector3:
		var vector := value as Vector3
		return Color(vector.x, vector.y, vector.z)
	if value is Color:
		return value as Color
	return fallback


func _bed_region_state_from_material(material: ShaderMaterial, prefix: String, fallback_color: Color) -> Dictionary:
	return {
		"color": _shader_color(material, StringName(prefix + "_tint"), fallback_color),
		"tint_strength": float(material.get_shader_parameter(prefix + "_strength")),
		"brightness": float(material.get_shader_parameter(prefix + "_brightness")),
		"roughness_offset": float(material.get_shader_parameter(prefix + "_roughness_offset")),
		"metallic_offset": 0.0,
		"emission_strength": 1.25,
		"emission_enabled": true,
	}


func _load_bed_state_from_scene_override(module: Node3D) -> void:
	if not bool(module.get_meta(SCENE_OVERRIDE_META, false)):
		return
	var material := _module_variant_material(module) as ShaderMaterial
	if material == null:
		return
	bed_region_state["Bedding_Main"] = _bed_region_state_from_material(material, "bedding_main", Color(0.28, 0.055, 0.065))
	bed_region_state["Bedding_Secondary"] = _bed_region_state_from_material(material, "bedding_secondary", Color(0.38, 0.35, 0.34))
	var frame_state := _bed_region_state_from_material(material, "frame_paint", Color(0.075, 0.135, 0.17))
	frame_state["metallic_offset"] = float(material.get_shader_parameter("frame_paint_metallic_offset"))
	bed_region_state["Frame_PaintedMetal"] = frame_state
	bed_region_state["Accent_Powered"] = {
		"color": _shader_color(material, &"accent_powered_tint", Color(0.02, 0.57, 0.68)),
		"tint_strength": 1.0,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": float(material.get_shader_parameter("emission_strength")),
		"emission_enabled": float(material.get_shader_parameter("emission_enabled")) > 0.5,
	}


func _load_bookshelf_state_from_scene_override(module: Node3D) -> void:
	if not bool(module.get_meta(SCENE_OVERRIDE_META, false)):
		return
	var material := _module_variant_material(module) as ShaderMaterial
	if material == null:
		return
	var frame_state := _bed_region_state_from_material(material, "frame", Color(0.055, 0.10, 0.13))
	frame_state["metallic_offset"] = float(material.get_shader_parameter("frame_metallic_offset"))
	bed_region_state["Frame_PaintedMetal"] = frame_state
	bed_region_state["Shelf_PaintedMetal"] = _bed_region_state_from_material(material, "shelf", Color(0.035, 0.055, 0.065))
	bed_region_state["Accent_Powered"] = {
		"color": _shader_color(material, &"accent_tint", Color(0.02, 0.57, 0.68)),
		"tint_strength": 1.0,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": float(material.get_shader_parameter("emission_strength")),
		"emission_enabled": float(material.get_shader_parameter("emission_enabled")) > 0.5,
	}


func _load_sectional_state_from_scene_override(module: Node3D) -> void:
	if not bool(module.get_meta(SCENE_OVERRIDE_META, false)):
		return
	var material := _module_variant_material(module) as ShaderMaterial
	if material == null:
		return
	bed_region_state["Cushion_Leather"] = _bed_region_state_from_material(material, "cushion", Color(0.28, 0.055, 0.065))
	var frame_state := _bed_region_state_from_material(material, "frame", Color(0.055, 0.10, 0.13))
	frame_state["metallic_offset"] = float(material.get_shader_parameter("frame_metallic_offset"))
	bed_region_state["Frame_PaintedMetal"] = frame_state
	var accent_state := _bed_region_state_from_material(material, "accent", Color(0.45, 0.22, 0.09))
	accent_state["metallic_offset"] = float(material.get_shader_parameter("accent_metallic_offset"))
	accent_state["emission_strength"] = 0.0
	accent_state["emission_enabled"] = false
	bed_region_state["Accent_Metal"] = accent_state


func _load_dining_table_state_from_scene_override(module: Node3D) -> void:
	if not bool(module.get_meta(SCENE_OVERRIDE_META, false)):
		return
	var material := _module_variant_material(module) as ShaderMaterial
	if material == null:
		return
	var tabletop_state := _bed_region_state_from_material(material, "tabletop", Color(0.10, 0.14, 0.18))
	tabletop_state["metallic_offset"] = float(material.get_shader_parameter("tabletop_metallic_offset"))
	bed_region_state["Tabletop_DarkSurface"] = tabletop_state
	var frame_state := _bed_region_state_from_material(material, "frame", Color(0.055, 0.10, 0.13))
	frame_state["metallic_offset"] = float(material.get_shader_parameter("frame_metallic_offset"))
	bed_region_state["Frame_PaintedMetal"] = frame_state
	var metal_state := _bed_region_state_from_material(material, "accent_metal", Color(0.45, 0.22, 0.09))
	metal_state["metallic_offset"] = float(material.get_shader_parameter("accent_metal_metallic_offset"))
	bed_region_state["Accent_Metal"] = metal_state
	bed_region_state["Accent_Powered_Cyan"] = {
		"color": _shader_color(material, &"accent_cyan_tint", Color(0.02, 0.57, 0.68)),
		"tint_strength": 1.0,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": float(material.get_shader_parameter("emission_cyan_strength")),
		"emission_enabled": float(material.get_shader_parameter("emission_cyan_enabled")) > 0.5,
	}
	bed_region_state["Accent_Powered_Magenta"] = {
		"color": _shader_color(material, &"accent_magenta_tint", Color(0.72, 0.07, 0.43)),
		"tint_strength": 1.0,
		"brightness": 1.0,
		"roughness_offset": 0.0,
		"metallic_offset": 0.0,
		"emission_strength": float(material.get_shader_parameter("emission_magenta_strength")),
		"emission_enabled": float(material.get_shader_parameter("emission_magenta_enabled")) > 0.5,
	}


func _load_couch_controls_from_scene_override(module: Node3D) -> void:
	if not bool(module.get_meta(SCENE_OVERRIDE_META, false)) or not _core_controls_ready():
		return
	var material := _module_variant_material(module) as ShaderMaterial
	if material == null:
		return
	region_ui_change_in_progress = true
	palette_picker.selected = 0
	color_picker.color = _shader_color(material, &"upholstery_tint", Color(0.055, 0.285, 0.305))
	tint_strength.value = float(material.get_shader_parameter("tint_strength"))
	brightness.value = float(material.get_shader_parameter("brightness"))
	roughness_offset.value = float(material.get_shader_parameter("roughness_offset"))
	region_ui_change_in_progress = false


func _capture_active_region_state() -> void:
	var module := _selected_supported_module()
	if module == null:
		return
	var profile := _module_profile(module)
	if not _active_profile_regions(profile).has(active_region) or not _core_controls_ready():
		return
	bed_region_state[active_region] = {
		"color": color_picker.color,
		"tint_strength": float(tint_strength.value),
		"brightness": float(brightness.value),
		"roughness_offset": float(roughness_offset.value),
		"metallic_offset": float(metallic_offset.value) if is_instance_valid(metallic_offset) else 0.0,
		"emission_strength": float(emission_strength.value) if is_instance_valid(emission_strength) else 1.25,
		"emission_enabled": emission_enabled.button_pressed if is_instance_valid(emission_enabled) else true,
	}


func _load_active_region_controls() -> void:
	var module := _selected_supported_module()
	if module == null:
		return
	var profile := _module_profile(module)
	if not _active_profile_regions(profile).has(active_region) or not _core_controls_ready():
		return
	var state: Dictionary = bed_region_state.get(active_region, _default_active_region_state(profile, active_region))
	region_ui_change_in_progress = true
	palette_picker.selected = 0
	color_picker.color = state.get("color", Color.WHITE)
	tint_strength.value = float(state.get("tint_strength", 0.94))
	brightness.value = float(state.get("brightness", 1.0))
	roughness_offset.value = float(state.get("roughness_offset", 0.0))
	if is_instance_valid(metallic_offset):
		metallic_offset.value = float(state.get("metallic_offset", 0.0))
	if is_instance_valid(emission_strength):
		emission_strength.value = float(state.get("emission_strength", 1.25))
	if is_instance_valid(emission_enabled):
		emission_enabled.button_pressed = bool(state.get("emission_enabled", true))
	region_ui_change_in_progress = false


func _on_palette_selected(index: int) -> void:
	if region_ui_change_in_progress:
		return
	var preset: Variant = palette_picker.get_item_metadata(index)
	if preset is Color:
		palette_change_in_progress = true
		color_picker.color = preset as Color
		palette_change_in_progress = false
		_update_active_preview()


func _on_custom_color_changed(_color: Color) -> void:
	if palette_change_in_progress or region_ui_change_in_progress:
		return
	palette_picker.selected = 0
	_update_active_preview()


func _on_control_changed(_value: float) -> void:
	if region_ui_change_in_progress:
		return
	_update_active_preview()


func _on_emission_toggled(_enabled: bool) -> void:
	if region_ui_change_in_progress:
		return
	_update_active_preview()


func _make_variant_material() -> ShaderMaterial:
	var module := _selected_supported_module()
	if module == null:
		return null
	var profile := _module_profile(module)
	var template_path := COUCH_TEMPLATE_MATERIAL_PATH
	if profile == BED_PROFILE_ID:
		template_path = BED_TEMPLATE_MATERIAL_PATH
	elif profile == BOOKSHELF_PROFILE_ID:
		template_path = BOOKSHELF_TEMPLATE_MATERIAL_PATH
	elif profile == SECTIONAL_PROFILE_ID:
		template_path = _sectional_template_material_path(module)
	elif profile == DINING_TABLE_PROFILE_ID:
		template_path = DINING_TABLE_TEMPLATE_MATERIAL_PATH
	var template := load(template_path) as ShaderMaterial
	if template == null:
		return null
	var material := template.duplicate(true) as ShaderMaterial
	var chosen := color_picker.color
	if profile == BED_PROFILE_ID:
		for region in BED_REGIONS:
			if bed_region_state.has(region):
				_apply_bed_region_state(material, region, bed_region_state[region])
	elif profile == BOOKSHELF_PROFILE_ID:
		for region in BOOKSHELF_REGIONS:
			if bed_region_state.has(region):
				_apply_bookshelf_region_state(material, region, bed_region_state[region])
	elif profile == SECTIONAL_PROFILE_ID:
		for region in SECTIONAL_REGIONS:
			if bed_region_state.has(region):
				_apply_sectional_region_state(material, region, bed_region_state[region])
	elif profile == DINING_TABLE_PROFILE_ID:
		for region in DINING_TABLE_REGIONS:
			if bed_region_state.has(region):
				_apply_dining_table_region_state(material, region, bed_region_state[region])
	else:
		material.set_shader_parameter("upholstery_tint", chosen)
		material.set_shader_parameter("tint_strength", float(tint_strength.value))
		material.set_shader_parameter("brightness", float(brightness.value))
		material.set_shader_parameter("roughness_offset", float(roughness_offset.value))
		material.set_shader_parameter("emission_strength", 1.0)
	return material


func _apply_bed_region_state(material: ShaderMaterial, region: String, state: Dictionary) -> void:
	var chosen: Color = state.get("color", Color.WHITE)
	match region:
		"Bedding_Main":
			_set_bed_region_parameters(material, "bedding_main", chosen, state)
		"Bedding_Secondary":
			_set_bed_region_parameters(material, "bedding_secondary", chosen, state)
		"Frame_PaintedMetal":
			_set_bed_region_parameters(material, "frame_paint", chosen, state)
			material.set_shader_parameter("frame_paint_metallic_offset", float(state.get("metallic_offset", 0.0)))
		"Accent_Powered":
			material.set_shader_parameter("accent_powered_tint", chosen)
			material.set_shader_parameter("accent_powered_strength", 1.0)
			material.set_shader_parameter("emission_strength", float(state.get("emission_strength", 1.25)))
			material.set_shader_parameter("emission_enabled", 1.0 if bool(state.get("emission_enabled", true)) else 0.0)


func _apply_bookshelf_region_state(material: ShaderMaterial, region: String, state: Dictionary) -> void:
	var chosen: Color = state.get("color", Color.WHITE)
	match region:
		"Frame_PaintedMetal":
			_set_bed_region_parameters(material, "frame", chosen, state)
			material.set_shader_parameter("frame_metallic_offset", float(state.get("metallic_offset", 0.0)))
		"Shelf_PaintedMetal":
			_set_bed_region_parameters(material, "shelf", chosen, state)
		"Accent_Powered":
			material.set_shader_parameter("accent_tint", chosen)
			material.set_shader_parameter("accent_strength", 1.0)
			material.set_shader_parameter("emission_strength", float(state.get("emission_strength", 1.10)))
			material.set_shader_parameter("emission_enabled", 1.0 if bool(state.get("emission_enabled", true)) else 0.0)


func _apply_sectional_region_state(material: ShaderMaterial, region: String, state: Dictionary) -> void:
	var chosen: Color = state.get("color", Color.WHITE)
	match region:
		"Cushion_Leather":
			_set_bed_region_parameters(material, "cushion", chosen, state)
		"Frame_PaintedMetal":
			_set_bed_region_parameters(material, "frame", chosen, state)
			material.set_shader_parameter("frame_metallic_offset", float(state.get("metallic_offset", 0.0)))
		"Accent_Metal":
			_set_bed_region_parameters(material, "accent", chosen, state)
			material.set_shader_parameter("accent_metallic_offset", float(state.get("metallic_offset", 0.0)))


func _apply_dining_table_region_state(material: ShaderMaterial, region: String, state: Dictionary) -> void:
	var chosen: Color = state.get("color", Color.WHITE)
	match region:
		"Tabletop_DarkSurface":
			_set_bed_region_parameters(material, "tabletop", chosen, state)
			material.set_shader_parameter("tabletop_metallic_offset", float(state.get("metallic_offset", 0.0)))
		"Frame_PaintedMetal":
			_set_bed_region_parameters(material, "frame", chosen, state)
			material.set_shader_parameter("frame_metallic_offset", float(state.get("metallic_offset", 0.0)))
		"Accent_Metal":
			_set_bed_region_parameters(material, "accent_metal", chosen, state)
			material.set_shader_parameter("accent_metal_metallic_offset", float(state.get("metallic_offset", 0.0)))
		"Accent_Powered_Cyan":
			material.set_shader_parameter("accent_cyan_tint", chosen)
			material.set_shader_parameter("emission_cyan_strength", float(state.get("emission_strength", 0.90)))
			material.set_shader_parameter("emission_cyan_enabled", 1.0 if bool(state.get("emission_enabled", true)) else 0.0)
		"Accent_Powered_Magenta":
			material.set_shader_parameter("accent_magenta_tint", chosen)
			material.set_shader_parameter("emission_magenta_strength", float(state.get("emission_strength", 0.55)))
			material.set_shader_parameter("emission_magenta_enabled", 1.0 if bool(state.get("emission_enabled", true)) else 0.0)


func _set_bed_region_parameters(material: ShaderMaterial, prefix: String, chosen: Color, state: Dictionary) -> void:
	material.set_shader_parameter(prefix + "_tint", chosen)
	material.set_shader_parameter(prefix + "_strength", float(state.get("tint_strength", 0.94)))
	material.set_shader_parameter(prefix + "_brightness", float(state.get("brightness", 1.0)))
	material.set_shader_parameter(prefix + "_roughness_offset", float(state.get("roughness_offset", 0.0)))


func _mesh_accepts_variant_preview(module: Node3D, mesh_instance: MeshInstance3D) -> bool:
	if _module_profile(module) != BOOKSHELF_PROFILE_ID:
		return true
	return mesh_instance.name in ["ProjectedShell", "STK_PROP_Bookshelf_A_Mesh", "STK_PROP_Bookshelf_A"]


func _preview_selected() -> void:
	var module := _selected_supported_module()
	if module == null:
		_set_status("Select a supported couch, bed, bookshelf, sectional, or dining table first.")
		return
	_capture_active_region_state()
	_revert_preview(false)
	preview_material = _make_variant_material()
	if preview_material == null:
		_set_status("The template material could not be loaded.")
		return
	preview_target = module
	for child in module.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or not _mesh_accepts_variant_preview(module, mesh_instance):
			continue
		preview_original_materials[mesh_instance] = mesh_instance.material_override
		mesh_instance.material_override = preview_material
	if preview_original_materials.is_empty():
		preview_target = null
		preview_material = null
		_set_status("No render mesh was found beneath the selection.")
		return
	_set_status("Previewing %s on %s. This does not change geometry or collision." % [_selected_region(), module.name])


func _update_active_preview() -> void:
	_capture_active_region_state()
	if preview_target == null or preview_original_materials.is_empty():
		return
	preview_material = _make_variant_material()
	if preview_material == null:
		return
	for mesh_instance in preview_original_materials.keys():
		if is_instance_valid(mesh_instance):
			(mesh_instance as MeshInstance3D).material_override = preview_material


func _revert_preview(show_status: bool = true) -> void:
	for mesh_instance in preview_original_materials.keys():
		if is_instance_valid(mesh_instance):
			(mesh_instance as MeshInstance3D).material_override = preview_original_materials[mesh_instance]
	preview_original_materials.clear()
	preview_target = null
	preview_material = null
	if show_status and is_instance_valid(status_label):
		_set_status("Preview reverted. No production asset was changed.")


func _scene_directly_owns_module(module: Node3D) -> bool:
	var edited_root := get_editor_interface().get_edited_scene_root()
	return edited_root != null and module.owner == edited_root


func _apply_to_scene() -> void:
	var module := _selected_supported_module()
	if module == null:
		_set_status("Select a supported couch, bed, bookshelf, sectional, or dining table first.")
		return
	if not _scene_directly_owns_module(module):
		_set_status("Open the scene that directly contains this prop, such as the v02 apartment assembly, then select it there.")
		return
	if not _module_has_property(module, &"variant_material"):
		_set_status("This prop wrapper does not yet support scene-local material overrides.")
		return
	_capture_active_region_state()
	var material := _make_variant_material()
	if material == null:
		_set_status("The template material could not be loaded.")
		return
	material.resource_local_to_scene = true
	material.resource_name = "%s Scene Material" % module.name

	var old_material := _module_variant_material(module)
	var old_override := bool(module.get_meta(SCENE_OVERRIDE_META, false))
	var old_base_path := str(module.get_meta(SCENE_OVERRIDE_BASE_PATH_META, ""))
	var base_path := old_base_path
	if not old_override:
		base_path = old_material.resource_path if old_material != null else ""

	_revert_preview(false)
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Apply Steamtek Material To This Scene")
	undo_redo.add_do_property(module, "variant_material", material)
	undo_redo.add_undo_property(module, "variant_material", old_material)
	undo_redo.add_do_method(module, "set_meta", SCENE_OVERRIDE_META, true)
	undo_redo.add_undo_method(module, "set_meta", SCENE_OVERRIDE_META, old_override)
	undo_redo.add_do_method(module, "set_meta", SCENE_OVERRIDE_BASE_PATH_META, base_path)
	undo_redo.add_undo_method(module, "set_meta", SCENE_OVERRIDE_BASE_PATH_META, old_base_path)
	undo_redo.commit_action()
	_set_status("Applied to %s in this scene only. Press Ctrl+S to save the scene." % module.name)


func _remove_scene_override() -> void:
	var module := _selected_supported_module()
	if module == null:
		_set_status("Select a supported couch, bed, bookshelf, sectional, or dining table first.")
		return
	if not _scene_directly_owns_module(module):
		_set_status("Open the scene that directly contains this prop before removing its scene override.")
		return
	if not bool(module.get_meta(SCENE_OVERRIDE_META, false)):
		_set_status("The selected prop has no scene-only material override.")
		return

	var old_material := _module_variant_material(module)
	var base_path := str(module.get_meta(SCENE_OVERRIDE_BASE_PATH_META, ""))
	var base_material: Material = null
	if not base_path.is_empty():
		base_material = load(base_path) as Material
	_revert_preview(false)
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Remove Steamtek Scene Material Override")
	undo_redo.add_do_property(module, "variant_material", base_material)
	undo_redo.add_undo_property(module, "variant_material", old_material)
	undo_redo.add_do_method(module, "set_meta", SCENE_OVERRIDE_META, false)
	undo_redo.add_undo_method(module, "set_meta", SCENE_OVERRIDE_META, true)
	undo_redo.commit_action()
	if _module_profile(module) == BED_PROFILE_ID or _module_profile(module) == BOOKSHELF_PROFILE_ID or _module_profile(module) == SECTIONAL_PROFILE_ID or _module_profile(module) == DINING_TABLE_PROFILE_ID:
		bed_region_state.clear()
	_set_status("Removed the scene-only material from %s. Press Ctrl+S to save the scene." % module.name)


func _save_variant() -> void:
	var module := _selected_supported_module()
	if module == null:
		_set_status("Select a supported couch, bed, bookshelf, sectional, or dining table first.")
		return
	_capture_active_region_state()
	var clean_name := _clean_variant_name(variant_name.text)
	if clean_name.is_empty():
		_set_status("Enter a short variant name, such as Midnight Teal.")
		return
	var suffix := clean_name.to_pascal_case()
	var profile := _module_profile(module)
	var is_bed := profile == BED_PROFILE_ID
	var is_bookshelf := profile == BOOKSHELF_PROFILE_ID
	var is_sectional := profile == SECTIONAL_PROFILE_ID
	var is_dining_table := profile == DINING_TABLE_PROFILE_ID
	var asset_stem := "Couch_A"
	if is_bed:
		asset_stem = "Bed_A"
	elif is_bookshelf:
		asset_stem = "Bookshelf_A"
	elif is_sectional:
		asset_stem = _sectional_asset_stem(module)
	elif is_dining_table:
		asset_stem = "Table_Dining_Rect_01"
	var variant_id := "STK_PROP_%s_%s" % [asset_stem, suffix]
	var material_id := "STK_MAT_%s_%s" % [asset_stem, suffix]
	var material_path := "%s/%s.tres" % [GENERATED_MATERIAL_DIR, material_id]
	var scene_path := "%s/%s.tscn" % [GENERATED_SCENE_DIR, variant_id]
	if FileAccess.file_exists(material_path) or FileAccess.file_exists(scene_path):
		_set_status("That variant already exists. Choose another name; existing files were not overwritten.")
		return
	if not _ensure_output_directories():
		_set_status("The generated-variant folders could not be created.")
		return

	var material := _make_variant_material()
	if material == null:
		_set_status("The template material could not be loaded.")
		return
	var material_error := ResourceSaver.save(material, material_path)
	if material_error != OK:
		_set_status("The material could not be saved. Error %d." % material_error)
		return

	var region := _selected_region()
	var color_variant := clean_name.to_snake_case() + "_" + region.to_snake_case()
	var asset_label := "Couch"
	var base_scene_path := COUCH_BASE_SCENE_PATH
	var variant_script_path := VARIANT_SCRIPT_PATH
	if is_bed:
		asset_label = "Bed"
		base_scene_path = BED_BASE_SCENE_PATH
	elif is_bookshelf:
		asset_label = "Bookshelf"
		base_scene_path = BOOKSHELF_BASE_SCENE_PATH
		variant_script_path = BOOKSHELF_VARIANT_SCRIPT_PATH
	elif is_sectional:
		asset_label = "Sectional"
		base_scene_path = _sectional_base_scene_path(module)
	elif is_dining_table:
		asset_label = "Dining Table"
		base_scene_path = DINING_TABLE_BASE_SCENE_PATH
	var builder_label := "Apartment - %s %s" % [asset_label, clean_name.capitalize()]
	var scene_text := _build_variant_scene_text(variant_id, material_path, color_variant, builder_label, base_scene_path, profile, region, variant_script_path)
	var scene_file := FileAccess.open(scene_path, FileAccess.WRITE)
	if scene_file == null:
		_set_status("The modular scene could not be saved. Error %d." % FileAccess.get_open_error())
		return
	scene_file.store_string(scene_text)
	scene_file.close()

	_revert_preview(false)
	get_editor_interface().get_resource_filesystem().scan()
	_set_status("Saved %s. In the Builder, click Refresh module list." % variant_id)


func _ensure_output_directories() -> bool:
	for path in [GENERATED_MATERIAL_DIR, GENERATED_SCENE_DIR]:
		var absolute_path := ProjectSettings.globalize_path(path)
		var error := DirAccess.make_dir_recursive_absolute(absolute_path)
		if error != OK and error != ERR_ALREADY_EXISTS:
			return false
	return true


func _clean_variant_name(raw_name: String) -> String:
	var regex := RegEx.new()
	if regex.compile("[^A-Za-z0-9]+") != OK:
		return ""
	var words := regex.sub(raw_name.strip_edges(), " ", true).strip_edges()
	if words.is_empty():
		return ""
	if words[0].is_valid_int():
		words = "Variant " + words
	return words


func _build_variant_scene_text(variant_id: String, material_path: String, color_variant: String, builder_label: String, base_scene_path: String, profile: String, region: String, variant_script_path: String = VARIANT_SCRIPT_PATH) -> String:
	var lines := PackedStringArray([
		"[gd_scene load_steps=4 format=3]",
		"",
		"[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]" % base_scene_path,
		"[ext_resource type=\"Script\" path=\"%s\" id=\"2_script\"]" % variant_script_path,
		"[ext_resource type=\"Material\" path=\"%s\" id=\"3_material\"]" % material_path,
		"",
		"[node name=\"%s\" instance=ExtResource(\"1_base\")]" % variant_id,
		"script = ExtResource(\"2_script\")",
		"variant_material = ExtResource(\"3_material\")",
		"metadata/module_variant = \"%s\"" % variant_id,
		"metadata/material_variant_profile = \"%s\"" % profile,
		"metadata/recolor_region = \"%s\"" % region,
		"metadata/color_variant = \"%s\"" % color_variant,
		"metadata/variant_contract = \"shared_production_mesh_collision_and_sockets_material_override_only\"",
		"metadata/material_variant_generated = true",
		"metadata/builder_label = \"%s\"" % builder_label,
		"metadata/builder_parent = \"Furniture\"",
		"metadata/production_status = \"generated_material_variant_pending_normal_editor_f6_review\"",
		"",
	])
	return "\n".join(lines)


func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
