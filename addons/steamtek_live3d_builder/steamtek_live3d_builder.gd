@tool
extends EditorPlugin

const EXTERIOR_GRID_STEP_M := 2.4
const INTERIOR_GRID_STEP_M := 1.2
const FURNITURE_GRID_STEP_M := 0.3
const PROP_GRID_STEP_M := 0.1
const STOREY_STEP_M := 3.2
const MAX_SOCKET_SNAP_DISTANCE_M := 1.5
const MAX_SIDE_SOCKET_SNAP_DISTANCE_M := 2.6
const SOCKET_OCCUPANCY_TOLERANCE_M := 0.025
const MODULE_GROUP := "steamtek_live3d_modular"
const SOCKET_GROUP := "steamtek_live3d_snap"
const MODULE_SYSTEM := "live3d_meter_v1"
const PROFILE_EXTERIOR_STRUCTURE := "exterior_structure"
const PROFILE_INTERIOR_STRUCTURE := "interior_structure"
const PROFILE_FURNITURE := "furniture"
const PROFILE_SMALL_PROPS := "small_props"
const GENERATED_MATERIAL_VARIANT_DIR := "res://scenes/environment/live3d/props/apartment_interior/generated_variants"

var dock: VBoxContainer
var module_picker: OptionButton
var profile_picker: OptionButton
var module_search: LineEdit
var status_label: Label
var auto_snap_drag_enabled := true
var auto_snap_pending := false
var last_selected_module_id := 0
var watched_module_id := 0
var watched_transform := Transform3D.IDENTITY
var watched_transform_valid := false
var stable_transform_frames := 0
var snap_attempted_for_transform := false


func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()
	set_process(true)
	get_editor_interface().get_selection().selection_changed.connect(_on_editor_selection_changed)
	_create_dock()


func _exit_tree() -> void:
	set_process(false)
	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_editor_selection_changed):
		selection.selection_changed.disconnect(_on_editor_selection_changed)
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.queue_free()


func _process(_delta: float) -> void:
	if not auto_snap_drag_enabled:
		_reset_auto_snap_watch()
		return
	var module := _selected_module()
	if module == null:
		_reset_auto_snap_watch()
		return

	var module_id := module.get_instance_id()
	if module_id != watched_module_id:
		watched_module_id = module_id
		watched_transform = module.transform
		watched_transform_valid = true
		stable_transform_frames = 0
		snap_attempted_for_transform = false
		return

	if not watched_transform_valid or not module.transform.is_equal_approx(watched_transform):
		watched_transform = module.transform
		watched_transform_valid = true
		stable_transform_frames = 0
		snap_attempted_for_transform = false
		return

	if snap_attempted_for_transform:
		return
	stable_transform_frames += 1
	if stable_transform_frames < 2:
		return

	snap_attempted_for_transform = true
	if _snap_module_to_nearest_socket(module, false):
		watched_transform = module.transform
		stable_transform_frames = 0


func _reset_auto_snap_watch() -> void:
	watched_module_id = 0
	watched_transform_valid = false
	stable_transform_frames = 0
	snap_attempted_for_transform = false


func _module_library() -> Array:
	var library := [
		{
			"label": "Interior - Floor Tile 1.2m",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Floor_120_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Floor Tile 2.4m Macro",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Floor_240_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Floor Service Grate 1.2m",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Floor_Grate_120_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Wall Solid 1.2m",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Solid_120x300_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Wall Solid 2.4m Macro",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Solid_240x300_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Wall Door 2.4m",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Door_240x300_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Wall Window 1.2m",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Window_120x300_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Corner Column",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Column_Corner_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Service Pipe Run 2.4m",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Pipe_Run_240_A.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Facade - Solid",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekFacadeBaySolid3D.tscn",
		},
		{
			"label": "Facade - Window",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekFacadeBayWindow3D.tscn",
		},
		{
			"label": "Facade - Door",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekFacadeBayDoor3D.tscn",
		},
		{
			"label": "Facade - Corner Column",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekFacadeCornerColumn3D.tscn",
		},
		{
			"label": "Floor Tile",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekFloorTile3D.tscn",
		},
		{
			"label": "Roof Tile",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekRoofTile3D.tscn",
		},
		{
			"label": "Parapet - Straight",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekParapetStraight3D.tscn",
		},
		{
			"label": "Parapet - Corner",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekParapetCorner3D.tscn",
		},
		{
			"label": "Balcony",
			"path": "res://scenes/environment/live3d/kits/apartment_exterior/SteamtekBalconyModule3D.tscn",
		},
		{
			"label": "Street - Structural Wall 1.2m",
			"path": "res://assets/environment/street_kit/walls/STK_ENV_Street_Wall_1p2_A.tscn",
			"parent": "Architecture",
			"profile": PROFILE_EXTERIOR_STRUCTURE,
		},
		{
			"label": "Street - Structural Wall 2.4m",
			"path": "res://assets/environment/street_kit/walls/STK_ENV_Street_Wall_2p4_A.tscn",
			"parent": "Architecture",
			"profile": PROFILE_EXTERIOR_STRUCTURE,
		},
		{
			"label": "Street - Road Straight",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekRoadStraight4_8x2_4m3D.tscn",
		},
		{
			"label": "Street - Road Intersection",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekRoadIntersection4Way4_8m3D.tscn",
		},
		{
			"label": "Street - Sidewalk Straight",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekSidewalkStraight2_4m3D.tscn",
		},
		{
			"label": "Street - Sidewalk Corner",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekSidewalkCorner2_4m3D.tscn",
		},
		{
			"label": "Street - Sidewalk + Curb Opening",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekSidewalkCurbRamp2_4m3D.tscn",
			"parent": "Architecture",
			"profile": PROFILE_EXTERIOR_STRUCTURE,
		},
		{
			"label": "Street - Curb Straight",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekCurbStraight2_4m3D.tscn",
		},
		{
			"label": "Street - Curb Corner",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekCurbCorner90_3D.tscn",
		},
		{
			"label": "Street - Drain Bay",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekDrainBay2_4m3D.tscn",
		},
		{
			"label": "Street - Alley Tile",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekAlleyTile2_4m3D.tscn",
		},
		{
			"label": "Street - Fence Straight",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekFenceStraight2_4m3D.tscn",
		},
		{
			"label": "Street - Fence Corner",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekFenceCorner90_3D.tscn",
		},
		{
			"label": "Street - Fence Gate",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekFenceGate2_4m3D.tscn",
		},
		{
			"label": "Street - Lane Marked Road",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekRoadLaneMarkedStraight4_8x2_4m3D.tscn",
		},
		{
			"label": "Street - Crosswalk Road",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekRoadCrosswalk4_8x2_4m3D.tscn",
		},
		{
			"label": "Street - Alley Road Apron",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekAlleyRoadApron2_4m3D.tscn",
		},
		{
			"label": "Street - Alley Driveway Cut",
			"path": "res://scenes/environment/live3d/kits/street/SteamtekAlleyDrivewayCut2_4m3D.tscn",
		},
	]
	library.append_array(_production_apartment_library())
	library.append_array(_generated_material_variant_library())
	return library


func _production_apartment_library() -> Array:
	return [
	# APARTMENT_LIBRARY_D_BEGIN
		{
			"label": "Interior - Wall Door 300x270 Service",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Door_300x270_Service.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Wall Window Wide 300x270",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Window_Wide_300x270.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Interior - Wall Window Slot 300x270",
			"path": "res://scenes/environment/live3d/kits/apartment_interior/APT_Wall_Window_Slot_300x270.tscn",
			"parent": "Architecture",
		},
		{
			"label": "Apartment - Couch Meshy A",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_A.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Couch L4 Left",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Left.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Couch L4 Right",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Right.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Couch Deep Teal",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_A_DeepTeal.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Couch Electric Plum",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_A_ElectricPlum.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Couch Burnished Ochre",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_A_BurnishedOchre.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Workstation Meshy A",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Workstation_A.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Bed Meshy A",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bed_A.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Bookshelf A",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn",
			"parent": "Furniture",
		},
		{
			"label": "Apartment - Dining Table Rect 01",
			"path": "res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Table_Dining_Rect_01.tscn",
			"parent": "Furniture",
		},
	# APARTMENT_LIBRARY_D_END
	]


func _generated_material_variant_library() -> Array:
	var generated: Array = []
	var directory := DirAccess.open(GENERATED_MATERIAL_VARIANT_DIR)
	if directory == null:
		return generated
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "tscn":
			var scene_path := GENERATED_MATERIAL_VARIANT_DIR.path_join(file_name)
			var packed := load(scene_path) as PackedScene
			if packed != null:
				var instance := packed.instantiate()
				if instance != null and bool(instance.get_meta("material_variant_generated", false)):
					generated.append({
						"label": str(instance.get_meta("builder_label", file_name.get_basename().capitalize())),
						"path": scene_path,
						"parent": str(instance.get_meta("builder_parent", "Furniture")),
					})
				if instance != null:
					instance.free()
		file_name = directory.get_next()
	directory.list_dir_end()
	generated.sort_custom(_sort_library_entries)
	return generated


func _sort_library_entries(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("label", "")) < str(b.get("label", ""))


func _create_dock() -> void:
	dock = VBoxContainer.new()
	dock.name = "Steamtek Live3D Builder"
	dock.custom_minimum_size = Vector2(300.0, 420.0)

	var title := Label.new()
	title.text = "Steamtek Live3D Builder"
	title.tooltip_text = "Meter-scale placement for the approved live-3D environment kit."
	dock.add_child(title)

	var contract := Label.new()
	contract.text = "Exterior 2.4m | Interior 1.2m | Furniture 0.3m | Props 0.1m\n3.2m storeys | 90-degree root rotation | no mirroring"
	contract.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(contract)

	dock.add_child(HSeparator.new())

	var profile_label := Label.new()
	profile_label.text = "Placement profile"
	dock.add_child(profile_label)

	profile_picker = OptionButton.new()
	profile_picker.add_item("Exterior Structure — 2.4 m")
	profile_picker.set_item_metadata(0, {"id": PROFILE_EXTERIOR_STRUCTURE, "grid_step": EXTERIOR_GRID_STEP_M})
	profile_picker.add_item("Interior Structure — 1.2 m")
	profile_picker.set_item_metadata(1, {"id": PROFILE_INTERIOR_STRUCTURE, "grid_step": INTERIOR_GRID_STEP_M})
	profile_picker.add_item("Furniture — 0.3 m")
	profile_picker.set_item_metadata(2, {"id": PROFILE_FURNITURE, "grid_step": FURNITURE_GRID_STEP_M})
	profile_picker.add_item("Small Props — 0.1 m")
	profile_picker.set_item_metadata(3, {"id": PROFILE_SMALL_PROPS, "grid_step": PROP_GRID_STEP_M})
	profile_picker.selected = 1
	profile_picker.item_selected.connect(_on_profile_selected)
	dock.add_child(profile_picker)

	var picker_label := Label.new()
	picker_label.text = "Module to place (current profile only)"
	dock.add_child(picker_label)

	module_search = LineEdit.new()
	module_search.placeholder_text = "Search within the selected profile..."
	module_search.clear_button_enabled = true
	module_search.text_changed.connect(_refresh_module_picker)
	dock.add_child(module_search)

	var refresh_button := _make_button(
		"Refresh module list",
		"Reapplies the selected placement profile and reloads generated material variants.",
		_refresh_module_picker
	)
	dock.add_child(refresh_button)

	module_picker = OptionButton.new()
	dock.add_child(module_picker)
	_refresh_module_picker()

	var origin_button := _make_button(
		"Add First Module at Assembly Origin",
		"Adds the chosen module at the Architecture node origin.",
		_add_at_origin
	)
	dock.add_child(origin_button)

	var socket_button := _make_button(
		"Add Chosen Object at Next Free Surface Socket",
		"Places the chosen prop or object directly onto a selected table, shelf, workbench, wall, or floor socket.",
		_add_at_selected_surface_socket
	)
	dock.add_child(socket_button)

	var placement_label := Label.new()
	placement_label.text = "Place chosen module beside selected module"
	placement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(placement_label)

	var x_row := HBoxContainer.new()
	x_row.add_child(_make_button("-X", "Join the chosen module to the nearest compatible socket on the left; use the profile grid only when no socket pair exists.", _place_on_axis.bind(Vector3.LEFT)))
	x_row.add_child(_make_button("+X", "Join the chosen module to the nearest compatible socket on the right; use the profile grid only when no socket pair exists.", _place_on_axis.bind(Vector3.RIGHT)))
	x_row.add_child(_make_button("+ Storey", "Place one 3.2 m storey above.", _place_chosen.bind(Vector3(0, STOREY_STEP_M, 0))))
	dock.add_child(x_row)

	var z_row := HBoxContainer.new()
	z_row.add_child(_make_button("-Z", "Join the chosen module to the nearest compatible socket toward -Z; use the profile grid only when no socket pair exists.", _place_on_axis.bind(Vector3.FORWARD)))
	z_row.add_child(_make_button("+Z", "Join the chosen module to the nearest compatible socket toward +Z; use the profile grid only when no socket pair exists.", _place_on_axis.bind(Vector3.BACK)))
	z_row.add_child(_make_button("- Storey", "Place one 3.2 m storey below.", _place_chosen.bind(Vector3(0, -STOREY_STEP_M, 0))))
	dock.add_child(z_row)

	dock.add_child(HSeparator.new())

	var auto_snap_toggle := CheckBox.new()
	auto_snap_toggle.text = "Auto Snap FileSystem / Viewport Drag"
	auto_snap_toggle.tooltip_text = "When a live-3D module is dropped or moved in the 3D viewport, align compatible Marker3D sockets within 1 meter."
	auto_snap_toggle.button_pressed = auto_snap_drag_enabled
	auto_snap_toggle.toggled.connect(_on_auto_snap_drag_toggled)
	dock.add_child(auto_snap_toggle)

	var edit_row := HBoxContainer.new()
	edit_row.add_child(_make_button("Rotate +90", "Rotate the selected module root by exactly 90 degrees around Y.", _rotate_selected_90))
	edit_row.add_child(_make_button("Snap Nearest", "Align the nearest compatible Marker3D socket within 1 meter.", _snap_selected_to_nearest_socket))
	dock.add_child(edit_row)

	var help := Label.new()
	help.text = "Structure: use the 1.2m interior profile for floors and walls.\nFurniture: switch to 0.3m for room dressing.\nSmall props: select a table or shelf and use Add at Selected Surface Socket, or use the 0.1m profile.\nEvery object remains an independent scene and every operation supports Undo."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(help)

	status_label = Label.new()
	status_label.text = "Ready. Open a 3D assembly scene."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(status_label)

	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	call_deferred("_keep_builder_tab_first")


func _keep_builder_tab_first() -> void:
	await get_tree().process_frame
	if not is_instance_valid(dock):
		return
	var editor_dock := dock.get_parent()
	var tab_container := editor_dock.get_parent() if editor_dock != null else null
	if tab_container != null and editor_dock.get_index() != 0:
		(tab_container as TabContainer).get_tab_bar().move_tab(editor_dock.get_index(), 0)
		tab_container.emit_signal("active_tab_rearranged", 0)
	if tab_container is TabContainer:
		(tab_container as TabContainer).current_tab = 0


func _make_button(text: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button


func _forward_3d_gui_input(_viewport_camera: Camera3D, event: InputEvent) -> int:
	if not auto_snap_drag_enabled or auto_snap_pending or not event is InputEventMouseButton:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
		auto_snap_pending = true
		call_deferred("_auto_snap_after_viewport_drop")
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_auto_snap_drag_toggled(enabled: bool) -> void:
	auto_snap_drag_enabled = enabled
	last_selected_module_id = 0
	_set_status("Automatic viewport drag snapping enabled." if enabled else "Automatic viewport drag snapping disabled.")


func _on_editor_selection_changed() -> void:
	if not auto_snap_drag_enabled:
		return
	var module := _selected_module()
	if module == null:
		last_selected_module_id = 0
		return
	var module_id := module.get_instance_id()
	if module_id == last_selected_module_id:
		return
	last_selected_module_id = module_id
	call_deferred("_auto_snap_newly_selected_module", module_id)


func _auto_snap_newly_selected_module(expected_module_id: int) -> void:
	if not auto_snap_drag_enabled:
		return
	var module := _selected_module()
	if module == null or module.get_instance_id() != expected_module_id:
		return
	_snap_module_to_nearest_socket(module, false)


func _auto_snap_after_viewport_drop() -> void:
	auto_snap_pending = false
	if not auto_snap_drag_enabled:
		return
	var module := _selected_module()
	if module != null:
		_snap_module_to_nearest_socket(module, false)


func _refresh_module_picker(_unused_text := "") -> void:
	if not is_instance_valid(module_picker):
		return
	module_picker.clear()
	var query := ""
	if is_instance_valid(module_search):
		query = module_search.text.strip_edges().to_lower()
	for entry in _module_library():
		if not _module_matches_active_profile(entry):
			continue
		var label := str(entry.get("label", ""))
		if not query.is_empty() and query not in label.to_lower():
			continue
		var index := module_picker.item_count
		module_picker.add_item(label)
		module_picker.set_item_metadata(index, entry)
	if module_picker.item_count == 0:
		_set_status("No modules match the selected profile and search text.")
	else:
		_set_status("Showing %d %s modules." % [module_picker.item_count, _active_profile_display_name()])


func _on_profile_selected(_index: int) -> void:
	_refresh_module_picker()


func _active_profile_id() -> String:
	if not is_instance_valid(profile_picker):
		return PROFILE_INTERIOR_STRUCTURE
	var metadata: Variant = profile_picker.get_item_metadata(profile_picker.selected)
	if metadata is Dictionary:
		return str((metadata as Dictionary).get("id", PROFILE_INTERIOR_STRUCTURE))
	return PROFILE_INTERIOR_STRUCTURE


func _active_profile_display_name() -> String:
	match _active_profile_id():
		PROFILE_EXTERIOR_STRUCTURE:
			return "exterior structure"
		PROFILE_FURNITURE:
			return "furniture"
		PROFILE_SMALL_PROPS:
			return "small prop"
		_:
			return "interior structure"


func _module_matches_active_profile(entry: Dictionary) -> bool:
	return _module_profile_id(entry) == _active_profile_id()


func _module_profile_id(entry: Dictionary) -> String:
	var explicit_profile := str(entry.get("profile", ""))
	if not explicit_profile.is_empty():
		return explicit_profile

	var parent_name := str(entry.get("parent", "Architecture")).to_lower()
	if parent_name == "furniture":
		return PROFILE_FURNITURE
	if parent_name in ["props", "smallprops", "small_props"]:
		return PROFILE_SMALL_PROPS

	var scene_path := str(entry.get("path", "")).to_lower()
	if "/kits/apartment_exterior/" in scene_path or "/kits/street/" in scene_path or "/assets/environment/street_kit/" in scene_path:
		return PROFILE_EXTERIOR_STRUCTURE
	if "/kits/apartment_interior/" in scene_path:
		return PROFILE_INTERIOR_STRUCTURE
	if "/props/" in scene_path:
		return PROFILE_SMALL_PROPS
	return PROFILE_INTERIOR_STRUCTURE


func _chosen_scene_path() -> String:
	if not is_instance_valid(module_picker) or module_picker.item_count == 0:
		return ""
	var metadata: Variant = module_picker.get_item_metadata(module_picker.selected)
	if metadata is Dictionary:
		return str((metadata as Dictionary).get("path", ""))
	return str(metadata)


func _load_chosen_scene_fresh(scene_path: String) -> PackedScene:
	if scene_path.is_empty():
		return null
	# Builder placement is an asset-authoring workflow. Always replace the
	# ResourceLoader cache so a refreshed module scene is what gets tested,
	# rather than a PackedScene cached before the source file was updated.
	return ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene


func _chosen_parent_name() -> String:
	if not is_instance_valid(module_picker) or module_picker.item_count == 0:
		return "Architecture"
	var metadata: Variant = module_picker.get_item_metadata(module_picker.selected)
	if metadata is Dictionary:
		return str((metadata as Dictionary).get("parent", "Architecture"))
	return "Architecture"


func _active_grid_step() -> float:
	if not is_instance_valid(profile_picker):
		return INTERIOR_GRID_STEP_M
	var metadata: Variant = profile_picker.get_item_metadata(profile_picker.selected)
	if metadata is Dictionary:
		return float((metadata as Dictionary).get("grid_step", INTERIOR_GRID_STEP_M))
	return float(metadata)


func _edited_root_3d() -> Node3D:
	var edited_root := get_editor_interface().get_edited_scene_root()
	if edited_root is Node3D:
		return edited_root as Node3D
	_set_status("Open or create a 3D scene first.")
	return null


func _preferred_parent(edited_root: Node3D) -> Node3D:
	var preferred := edited_root.get_node_or_null(NodePath(_chosen_parent_name()))
	if preferred is Node3D:
		return preferred as Node3D
	return edited_root


func _selected_node_3d() -> Node3D:
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	if selected.is_empty():
		return null
	var current := selected[0]
	if current is Node3D:
		return current as Node3D
	return null


func _selected_module() -> Node3D:
	var edited_root := get_editor_interface().get_edited_scene_root()
	if edited_root == null:
		return null
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	if selected.is_empty():
		return null
	var current: Node = selected[0]
	while current != null:
		if current is Node3D and current.is_in_group(MODULE_GROUP):
			if str(current.get_meta("module_system", "")) == MODULE_SYSTEM:
				return current as Node3D
		if current == edited_root:
			break
		current = current.get_parent()
	return null


func _add_at_origin() -> void:
	var edited_root := _edited_root_3d()
	if edited_root == null:
		return
	var parent := _preferred_parent(edited_root)
	_instantiate_chosen(parent, Transform3D.IDENTITY, edited_root)


func _add_at_selected_surface_socket() -> void:
	var edited_root := _edited_root_3d()
	if edited_root == null:
		return
	var selected := _selected_node_3d()
	if selected == null:
		_set_status("Select a table, shelf, workbench, wall, or other socket host first.")
		return
	var markers: Array[Marker3D] = []
	_collect_markers(selected, markers)
	var target: Marker3D
	for marker in markers:
		if (
			str(marker.get_meta("socket_role", "")) in ["prop_surface", "wall_prop_surface", "floor_prop_surface"]
			and not _surface_socket_is_occupied(marker, edited_root)
		):
			target = marker
			break
	if target == null:
		_set_status("The selected object has no free prop placement socket.")
		return
	var parent := _preferred_parent(edited_root)
	var target_local := parent.global_transform.affine_inverse() * target.global_transform
	_instantiate_chosen(parent, target_local, edited_root)


func _surface_socket_is_occupied(marker: Marker3D, edited_root: Node3D) -> bool:
	var modules: Array[Node3D] = []
	_collect_modules(edited_root, modules)
	for module in modules:
		if module == marker.get_parent() or module.is_ancestor_of(marker):
			continue
		var family := str(module.get_meta("module_family", ""))
		if family in ["apartment_small_prop", "apartment_floor_prop", "apartment_wall_prop", "apartment_furniture_component"]:
			if module.global_position.distance_to(marker.global_position) < 0.075:
				return true
	return false


func _place_on_axis(axis: Vector3) -> void:
	if _place_chosen_at_directional_socket(axis):
		return
	_place_chosen(axis * _active_grid_step())
	_set_status("No compatible directional socket pair was available; placed on the active profile grid instead.")


func _place_chosen_at_directional_socket(axis: Vector3) -> bool:
	var edited_root := _edited_root_3d()
	if edited_root == null:
		return false
	var selected := _selected_module()
	if selected == null:
		return false
	var parent := selected.get_parent() as Node3D
	if parent == null:
		return false

	var scene_path := _chosen_scene_path()
	var packed := _load_chosen_scene_fresh(scene_path)
	if packed == null:
		return false
	var preview := packed.instantiate() as Node3D
	if preview == null:
		return false

	var target_markers: Array[Marker3D] = []
	var source_markers: Array[Marker3D] = []
	var existing_modules: Array[Node3D] = []
	_collect_markers(selected, target_markers)
	_collect_markers(preview, source_markers)
	_collect_modules(edited_root, existing_modules)
	var direction := axis.normalized()
	var best_target_position := Vector3.ZERO
	var best_source_position := Vector3.ZERO
	var best_yaw := 0.0
	var best_direct_global := Transform3D.IDENTITY
	var best_uses_direct_transform := false
	var best_score := -INF
	var found_pair := false

	for target in target_markers:
		if _socket_is_occupied_by_other(target, null, selected, existing_modules):
			continue
		var target_relative := selected.global_transform.affine_inverse() * target.global_transform
		var target_position := target_relative.origin
		var target_direction_score := target_position.dot(direction)
		if target_direction_score <= 0.0001:
			continue
		for source in source_markers:
			if not _socket_roles_compatible(source, target):
				continue
			var source_relative := _node_transform_relative_to_root(preview, source)
			var source_position := source_relative.origin
			if _socket_pair_uses_orientation(source, target):
				var direct_global := selected.global_transform * target_relative * source_relative.affine_inverse()
				if target_direction_score > best_score:
					best_score = target_direction_score
					best_direct_global = direct_global
					best_uses_direct_transform = true
					found_pair = true
				continue
			var source_horizontal := Vector3(source_position.x, 0.0, source_position.z)
			if source_horizontal.length_squared() <= 0.000001:
				continue
			var yaw := source_horizontal.normalized().signed_angle_to(-direction, Vector3.UP)
			var rotated_source := Basis(Vector3.UP, yaw) * source_position
			var source_edge_score := -rotated_source.dot(direction)
			if source_edge_score <= 0.0001:
				continue
			var score := target_direction_score + source_edge_score
			if score > best_score:
				best_score = score
				best_target_position = target_position
				best_source_position = source_position
				best_yaw = yaw
				best_uses_direct_transform = false
				found_pair = true

	preview.free()
	if not found_pair:
		return false

	var chosen_global := best_direct_global
	if not best_uses_direct_transform:
		var selected_basis := selected.global_basis.orthonormalized()
		var chosen_basis := selected_basis * Basis(Vector3.UP, best_yaw)
		var target_global_position := selected.global_transform * best_target_position
		var chosen_global_origin := target_global_position - chosen_basis * best_source_position
		chosen_global = Transform3D(chosen_basis, chosen_global_origin)
	var chosen_local := parent.global_transform.affine_inverse() * chosen_global
	_instantiate_chosen(parent, chosen_local, edited_root)
	_set_status("Placed at an exact compatible socket with no grid gap.")
	return true


func _node_transform_relative_to_root(root: Node3D, descendant: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node = descendant
	while current != null and current != root:
		if current is Node3D:
			chain.push_front(current as Node3D)
		current = current.get_parent()
	var relative := Transform3D.IDENTITY
	for node in chain:
		relative *= node.transform
	return relative


func _socket_pair_uses_orientation(source: Marker3D, target: Marker3D) -> bool:
	var source_role := str(source.get_meta("socket_role", ""))
	var target_role := str(target.get_meta("socket_role", ""))
	return (
		(source_role == "interior_wall_base" and target_role == "interior_wall_floor_edge")
		or (source_role == "interior_wall_floor_edge" and target_role == "interior_wall_base")
		or (source_role == "street_sidewalk_chain" and target_role == "street_sidewalk_chain")
	)


func _place_chosen(local_offset: Vector3) -> void:
	var edited_root := _edited_root_3d()
	if edited_root == null:
		return
	var selected := _selected_module()
	if selected == null:
		_set_status("Select a live-3D module first, or use Add First Module.")
		return
	var parent := selected.get_parent() as Node3D
	if parent == null:
		_set_status("The selected module needs a Node3D parent.")
		return
	var clean_basis := selected.global_basis.orthonormalized()
	var target_origin := selected.global_position + clean_basis * local_offset
	var target_global := Transform3D(clean_basis, target_origin)
	var target_local := parent.global_transform.affine_inverse() * target_global
	_instantiate_chosen(parent, target_local, edited_root)


func _instantiate_chosen(parent: Node3D, local_transform: Transform3D, edited_root: Node3D) -> void:
	var scene_path := _chosen_scene_path()
	if scene_path.is_empty():
		_set_status("Choose a module first.")
		return
	var packed := _load_chosen_scene_fresh(scene_path)
	if packed == null:
		_set_status("Could not load: " + scene_path)
		push_error("Steamtek Live3D Builder could not load: " + scene_path)
		return
	var instance := packed.instantiate() as Node3D
	if instance == null:
		_set_status("Chosen scene root is not Node3D.")
		return

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Add Steamtek Live3D Module")
	undo_redo.add_do_method(parent, "add_child", instance, true)
	undo_redo.add_do_method(instance, "set_owner", edited_root)
	undo_redo.add_do_property(instance, "transform", local_transform)
	undo_redo.add_undo_method(parent, "remove_child", instance)
	undo_redo.commit_action()

	var selection := get_editor_interface().get_selection()
	selection.clear()
	selection.add_node(instance)
	_set_status("Placed %s. The new module is selected." % instance.name)


func _rotate_selected_90() -> void:
	var module := _selected_module()
	if module == null:
		_set_status("Select a live-3D module to rotate.")
		return
	var old_rotation := module.rotation_degrees
	var new_rotation := old_rotation
	new_rotation.y = fposmod(roundf(old_rotation.y / 90.0) * 90.0 + 90.0, 360.0)
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Rotate Steamtek Live3D Module 90 Degrees")
	undo_redo.add_do_property(module, "rotation_degrees", new_rotation)
	undo_redo.add_undo_property(module, "rotation_degrees", old_rotation)
	undo_redo.commit_action()
	# A deliberate button rotation must not be interpreted as a finished
	# viewport drag and immediately snapped back to its previous orientation.
	# The next actual transform change re-arms automatic snapping in _process().
	watched_module_id = module.get_instance_id()
	watched_transform = module.transform
	watched_transform_valid = true
	stable_transform_frames = 0
	snap_attempted_for_transform = true
	auto_snap_pending = false
	_set_status("Rotated %s to %d degrees Y." % [module.name, int(new_rotation.y)])


func _snap_selected_to_nearest_socket() -> void:
	var module := _selected_module()
	if module == null:
		_set_status("Select a live-3D module to snap.")
		return
	_snap_module_to_nearest_socket(module, true)


func _snap_module_to_nearest_socket(module: Node3D, show_failures: bool) -> bool:
	var edited_root := _edited_root_3d()
	if edited_root == null:
		return false

	var own_markers: Array[Marker3D] = []
	_collect_markers(module, own_markers)
	if own_markers.is_empty():
		if show_failures:
			_set_status("Selected module has no live-3D snap markers.")
		return false

	var modules: Array[Node3D] = []
	_collect_modules(edited_root, modules)
	var best_source: Marker3D
	var best_target: Marker3D
	var best_target_host: Node3D
	var best_distance := INF

	for other_module in modules:
		if other_module == module:
			continue
		var other_markers: Array[Marker3D] = []
		_collect_markers(other_module, other_markers)
		for source in own_markers:
			for target in other_markers:
				if not _socket_roles_compatible(source, target):
					continue
				if _socket_is_occupied_by_other(target, module, other_module, modules):
					continue
				var distance := source.global_position.distance_to(target.global_position)
				if distance > _socket_pair_snap_distance(source, target):
					continue
				if distance < best_distance:
					best_distance = distance
					best_source = source
					best_target = target
					best_target_host = other_module

	if best_source == null or best_target == null:
		if show_failures:
			_set_status("No free compatible socket is close enough. Side attachments capture across a full 2.4 m module.")
		return false

	var parent := module.get_parent() as Node3D
	if parent == null:
		if show_failures:
			_set_status("The selected module needs a Node3D parent.")
		return false
	var old_transform := module.transform
	var new_global := module.global_transform
	if _socket_pair_uses_inferred_yaw(best_source, best_target):
		new_global = _socket_transform_with_inferred_yaw(module, best_source, best_target_host, best_target)
	elif _socket_pair_uses_orientation(best_source, best_target):
		var source_relative := module.global_transform.affine_inverse() * best_source.global_transform
		new_global = best_target.global_transform * source_relative.affine_inverse()
	else:
		new_global.origin += best_target.global_position - best_source.global_position
	var new_transform := parent.global_transform.affine_inverse() * new_global
	if old_transform.is_equal_approx(new_transform):
		if show_failures:
			_set_status("The selected sockets are already aligned.")
		return false

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Snap Steamtek Live3D Marker Sockets")
	undo_redo.add_do_property(module, "transform", new_transform)
	undo_redo.add_undo_property(module, "transform", old_transform)
	undo_redo.commit_action()
	_set_status("Snapped %s to %s." % [best_source.name, best_target.name])
	return true


func _socket_pair_snap_distance(source: Marker3D, target: Marker3D) -> float:
	if _socket_pair_uses_inferred_yaw(source, target):
		return MAX_SIDE_SOCKET_SNAP_DISTANCE_M
	return MAX_SOCKET_SNAP_DISTANCE_M


func _socket_pair_uses_inferred_yaw(source: Marker3D, target: Marker3D) -> bool:
	var source_role := str(source.get_meta("socket_role", ""))
	var target_role := str(target.get_meta("socket_role", ""))
	return (
		(source_role == "street_curb_road_edge" and target_role == "street_road_edge")
		or (source_role == "street_road_edge" and target_role == "street_curb_road_edge")
		or (source_role == "street_curb_sidewalk_edge" and target_role == "street_sidewalk_road_edge")
		or (source_role == "street_sidewalk_road_edge" and target_role == "street_curb_sidewalk_edge")
		or (source_role == "street_curb_ramp_road_edge" and target_role == "street_road_edge")
		or (source_role == "street_road_edge" and target_role == "street_curb_ramp_road_edge")
	)


func _socket_transform_with_inferred_yaw(
	moving_module: Node3D,
	source: Marker3D,
	target_host: Node3D,
	target: Marker3D
) -> Transform3D:
	var source_position := moving_module.to_local(source.global_position)
	var target_position := target_host.to_local(target.global_position)
	var source_normal: Vector3 = source.get_meta("socket_normal_local", source_position)
	var target_normal: Vector3 = target.get_meta("socket_normal_local", target_position)
	var source_horizontal := Vector3(source_normal.x, 0.0, source_normal.z)
	var target_horizontal := Vector3(target_normal.x, 0.0, target_normal.z)
	if source_horizontal.length_squared() <= 0.000001 or target_horizontal.length_squared() <= 0.000001:
		var translated := moving_module.global_transform
		translated.origin += target.global_position - source.global_position
		return translated

	var clean_basis := moving_module.global_basis.orthonormalized()
	var target_basis := target_host.global_basis.orthonormalized()
	var current_direction := (clean_basis * source_horizontal).normalized()
	var desired_direction := -(target_basis * target_horizontal).normalized()
	var yaw := current_direction.signed_angle_to(desired_direction, Vector3.UP)
	var rotated_basis := Basis(Vector3.UP, yaw) * clean_basis
	var rotated_source_offset := rotated_basis * source_position
	return Transform3D(rotated_basis, target.global_position - rotated_source_offset)


func _socket_is_occupied_by_other(
	target: Marker3D,
	moving_module: Node3D,
	host_module: Node3D,
	modules: Array[Node3D]
) -> bool:
	for candidate_module in modules:
		if candidate_module == moving_module or candidate_module == host_module:
			continue
		var candidate_markers: Array[Marker3D] = []
		_collect_markers(candidate_module, candidate_markers)
		for candidate in candidate_markers:
			if not _socket_roles_compatible(candidate, target):
				continue
			if candidate.global_position.distance_to(target.global_position) <= SOCKET_OCCUPANCY_TOLERANCE_M:
				return true
	return false


func _collect_modules(node: Node, output: Array[Node3D]) -> void:
	if node is Node3D and node.is_in_group(MODULE_GROUP):
		if str(node.get_meta("module_system", "")) == MODULE_SYSTEM:
			output.append(node as Node3D)
			return
	for child in node.get_children():
		_collect_modules(child, output)


func _collect_markers(node: Node, output: Array[Marker3D], module_root: Node = null) -> void:
	if module_root == null:
		module_root = node
	elif node is Node3D and node.is_in_group(MODULE_GROUP):
		return
	if node is Marker3D and node.is_in_group(SOCKET_GROUP):
		output.append(node as Marker3D)
	for child in node.get_children():
		_collect_markers(child, output, module_root)


func _socket_roles_compatible(source: Marker3D, target: Marker3D) -> bool:
	var source_role := str(source.get_meta("socket_role", ""))
	var target_role := str(target.get_meta("socket_role", ""))
	if source_role.is_empty() or target_role.is_empty():
		return false
	if source_role == target_role:
		if source_role == "street_sidewalk_chain":
			var source_polarity := int(source.get_meta("socket_polarity", 0))
			var target_polarity := int(target.get_meta("socket_polarity", 0))
			return source_polarity != 0 and target_polarity != 0 and source_polarity == -target_polarity
		return source_role in [
			"facade_horizontal",
			"storey_vertical",
			"parapet_horizontal",
			"floor_horizontal",
			"roof_horizontal",
			"balcony_horizontal",
			"street_road_chain",
			"street_road_edge",
			"street_sidewalk_chain",
			"street_sidewalk_building_edge",
			"street_curb_chain",
			"street_drain_chain",
			"street_alley_chain",
			"street_fence_chain",
			"interior_floor_chain",
			"interior_wall_chain",
			"interior_partition_chain",
			"wall_service_chain",
			"furniture_chain",
		]
	if source_role == "facade_horizontal" and target_role == "corner_wall_attachment":
		return true
	if source_role == "corner_wall_attachment" and target_role == "facade_horizontal":
		return true
	if source_role == "parapet_horizontal" and target_role == "parapet_corner_attachment":
		return true
	if source_role == "parapet_corner_attachment" and target_role == "parapet_horizontal":
		return true
	if source_role == "street_road_edge" and target_role == "street_curb_road_edge":
		return true
	if source_role == "street_curb_road_edge" and target_role == "street_road_edge":
		return true
	if source_role == "street_sidewalk_road_edge" and target_role == "street_curb_sidewalk_edge":
		return true
	if source_role == "street_curb_sidewalk_edge" and target_role == "street_sidewalk_road_edge":
		return true
	if source_role == "street_curb_ramp_road_edge" and target_role == "street_road_edge":
		return true
	if source_role == "street_road_edge" and target_role == "street_curb_ramp_road_edge":
		return true
	if source_role == "prop_anchor" and target_role in ["prop_surface", "wall_prop_surface", "floor_prop_surface"]:
		return true
	if target_role == "prop_anchor" and source_role in ["prop_surface", "wall_prop_surface", "floor_prop_surface"]:
		return true
	if source_role == "interior_wall_base" and target_role == "interior_wall_floor_edge":
		return true
	if target_role == "interior_wall_base" and source_role == "interior_wall_floor_edge":
		return true
	return false


func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
