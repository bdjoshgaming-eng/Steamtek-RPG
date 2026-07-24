@tool
extends EditorPlugin

const SNAP_TOLERANCE := 160.0
const ENABLE_ASSET_LIBRARY_DOCK := false
const FOUNDATION_SNAP_TOLERANCE := 220.0
const FOUNDATION_AXIS_A := Vector2(313.534, -90.509)
const FOUNDATION_AXIS_B := Vector2(-181.020, -156.768)
const SNAP_OCCUPANCY_TOLERANCE := 6.0
const GRID_AXIS_A := Vector2(313.534, -90.509)
const GRID_AXIS_B := Vector2(-181.020, -156.768)
const ASSET_LIBRARY_FOLDERS := {
	"Walls": "res://scenes/modular_v4/modules/walls",
	"Roofs": "res://scenes/modular_v4/modules/roofs",
	"Corners and Caps": "res://scenes/modular_v4/modules/corners",
	"Buildings": "res://scenes/modular_v4/buildings",
	"Props": "res://scenes/props/surface",
}
const COMPATIBLE := {
	"Snap_Left": ["Snap_Right", "Snap_Base", "Snap_CornerSide", "Snap_EndJoin", "Snap_RoofEdge", "Snap_Parapet"],
	"Snap_Right": ["Snap_Left", "Snap_Base", "Snap_CornerFront", "Snap_EndJoin"],
	"Snap_Base": ["Snap_Left", "Snap_Right"],
	"Snap_CornerFront": ["Snap_Right"],
	"Snap_CornerSide": ["Snap_Left"],
	"Snap_EndJoin": ["Snap_Left", "Snap_Right"],
	"Snap_RoofEdge": ["Snap_Left"],
	"Snap_Parapet": ["Snap_Left"],
	"Snap_Upper": ["Snap_Lower"],
	"Snap_Lower": ["Snap_Upper"],
	"Snap_NE": ["Snap_SW"],
	"Snap_SW": ["Snap_NE"],
	"Snap_NW": ["Snap_SE"],
	"Snap_SE": ["Snap_NW"],
	"Attach_Facade": ["Attach_Facade"],
	"Attach_Ladder": ["Attach_Platform"],
	"Attach_Platform": ["Attach_Ladder"],
	"Attach_FoundationFront": ["Attach_WallFront"],
	"Attach_WallFront": ["Attach_FoundationFront"],
	"Attach_FoundationSide": ["Attach_WallSide"],
	"Attach_WallSide": ["Attach_FoundationSide"],
}

var snap_enabled := true
var toggle_button: Button
var snap_button: Button
var grid_button: Button
var asset_dock: VBoxContainer
var asset_filter: OptionButton
var asset_search: LineEdit
var asset_list: ItemList


func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()

	toggle_button = Button.new()
	toggle_button.text = "STK: ON"
	toggle_button.tooltip_text = "Automatically snap compatible Steamtek markers when a module is released."
	toggle_button.toggle_mode = true
	toggle_button.button_pressed = true
	toggle_button.toggled.connect(_on_toggle_changed)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toggle_button)

	snap_button = Button.new()
	snap_button.text = "Snap"
	snap_button.tooltip_text = "Snap the selected Steamtek module to its nearest compatible marker."
	snap_button.pressed.connect(_snap_selected.bind(true))
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, snap_button)

	grid_button = Button.new()
	grid_button.text = "Grid"
	grid_button.tooltip_text = "Snap the selected Steamtek V4 module root to the locked 60-degree off-axis lattice."
	grid_button.pressed.connect(_snap_selected_to_grid)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, grid_button)

	# The optional library dock is disabled by default because its minimum height
	# can crowd Godot's bottom panel on some editor layouts. FileSystem drag/drop
	# remains available and all snap controls stay active.
	if ENABLE_ASSET_LIBRARY_DOCK:
		_create_asset_dock()


func _exit_tree() -> void:
	if is_instance_valid(toggle_button):
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, toggle_button)
		toggle_button.queue_free()
	if is_instance_valid(snap_button):
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, snap_button)
		snap_button.queue_free()
	if is_instance_valid(grid_button):
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, grid_button)
		grid_button.queue_free()
	if is_instance_valid(asset_dock):
		remove_control_from_docks(asset_dock)
		asset_dock.queue_free()


func _create_asset_dock() -> void:
	asset_dock = VBoxContainer.new()
	asset_dock.name = "Steamtek Modular Assets"
	asset_dock.custom_minimum_size = Vector2(280.0, 360.0)

	var title := Label.new()
	title.text = "Steamtek Modular Assets"
	title.tooltip_text = "Double-click an approved module to add it to the edited scene."
	asset_dock.add_child(title)

	asset_filter = OptionButton.new()
	asset_filter.add_item("All")
	for category in ASSET_LIBRARY_FOLDERS.keys():
		asset_filter.add_item(category)
	asset_filter.item_selected.connect(_on_asset_filter_changed)
	asset_dock.add_child(asset_filter)

	asset_search = LineEdit.new()
	asset_search.placeholder_text = "Filter by ID or name..."
	asset_search.text_changed.connect(_on_asset_search_changed)
	asset_dock.add_child(asset_search)

	asset_list = ItemList.new()
	asset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	asset_list.allow_reselect = true
	asset_list.item_activated.connect(_on_asset_activated)
	asset_dock.add_child(asset_list)

	var buttons := HBoxContainer.new()
	var add_button := Button.new()
	add_button.text = "Add Selected"
	add_button.pressed.connect(_add_selected_asset)
	buttons.add_child(add_button)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(_refresh_asset_library)
	buttons.add_child(refresh_button)
	asset_dock.add_child(buttons)

	var help := Label.new()
	help.text = "Add, drag near a socket, and release.\nSnap Selected and Grid remain available above."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	asset_dock.add_child(help)

	add_control_to_dock(DOCK_SLOT_LEFT_BR, asset_dock)
	_refresh_asset_library()


func _on_asset_filter_changed(_index: int) -> void:
	_refresh_asset_library()


func _on_asset_search_changed(_text: String) -> void:
	_refresh_asset_library()


func _refresh_asset_library() -> void:
	if not is_instance_valid(asset_list):
		return
	asset_list.clear()
	var selected_category := "All"
	if is_instance_valid(asset_filter):
		selected_category = asset_filter.get_item_text(asset_filter.selected)
	var query := asset_search.text.strip_edges().to_lower() if is_instance_valid(asset_search) else ""
	var entries: Array[Dictionary] = []
	for category in ASSET_LIBRARY_FOLDERS.keys():
		if selected_category != "All" and selected_category != category:
			continue
		var folder: String = ASSET_LIBRARY_FOLDERS[category]
		for file_name in DirAccess.get_files_at(folder):
			if not file_name.ends_with(".tscn"):
				continue
			var label := file_name.get_basename().replace("_", " ")
			if not query.is_empty() and query not in label.to_lower():
				continue
			entries.append({
				"category": category,
				"label": label,
				"path": folder.path_join(file_name),
			})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["category"] + a["label"]) < (b["category"] + b["label"])
	)
	for entry in entries:
		var index := asset_list.add_item("[%s] %s" % [entry["category"], entry["label"]])
		asset_list.set_item_metadata(index, entry["path"])


func _on_asset_activated(_index: int) -> void:
	_add_selected_asset()


func _add_selected_asset() -> void:
	if not is_instance_valid(asset_list):
		return
	var selected := asset_list.get_selected_items()
	if selected.is_empty():
		return
	var scene_path: String = asset_list.get_item_metadata(selected[0])
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Steamtek asset could not be loaded: " + scene_path)
		return
	var edited_root := get_editor_interface().get_edited_scene_root()
	if edited_root == null:
		push_warning("Open or create a 2D scene before adding a Steamtek module.")
		return
	var parent := _asset_parent_for_path(edited_root, scene_path)
	var instance := packed.instantiate()
	if instance is Node2D:
		instance.position = Vector2.ZERO
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Add Steamtek Module")
	undo_redo.add_do_method(parent, "add_child", instance, true)
	undo_redo.add_do_method(instance, "set_owner", edited_root)
	undo_redo.add_undo_method(parent, "remove_child", instance)
	undo_redo.commit_action()
	var selection := get_editor_interface().get_selection()
	selection.clear()
	selection.add_node(instance)


func _asset_parent_for_path(edited_root: Node, scene_path: String) -> Node:
	var preferred := "Architecture"
	if "/ground/" in scene_path:
		preferred = "GroundModules"
	elif "/props/" in scene_path:
		preferred = "Props"
	var candidate := edited_root.get_node_or_null(NodePath(preferred))
	return candidate if candidate != null else edited_root


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if snap_enabled and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			call_deferred("_snap_selected", false)
	return false


func _on_toggle_changed(enabled: bool) -> void:
	snap_enabled = enabled
	toggle_button.text = "STK: ON" if enabled else "STK: OFF"


func _snap_selected(force_nearest := false) -> void:
	var selection := get_editor_interface().get_selection().get_selected_nodes()
	if selection.is_empty():
		return

	var edited_root := get_editor_interface().get_edited_scene_root()
	if edited_root == null:
		return

	var module := _find_module_root(selection[0], edited_root)
	if module == null:
		return
	if _is_foundation_module(module):
		_snap_foundation_to_lattice(module, edited_root, force_nearest)
		return

	var own_markers: Array[Marker2D] = []
	_collect_markers(module, own_markers)
	if own_markers.is_empty():
		return

	var scene_markers: Array[Marker2D] = []
	_collect_markers(edited_root, scene_markers)

	var best_source: Marker2D
	var best_target: Marker2D
	var best_distance := INF

	for source in own_markers:
		if not COMPATIBLE.has(source.name):
			continue
		var required_names: Array = COMPATIBLE[source.name]
		for target in scene_markers:
			if module == target or module.is_ancestor_of(target):
				continue
			if target.name not in required_names:
				continue
			var target_module := _find_module_root(target, edited_root)
			if target_module == null or target_module == module:
				continue
			if _marker_is_occupied(target, module, scene_markers, edited_root):
				continue
			var distance := source.global_position.distance_to(target.global_position)
			if distance < best_distance:
				best_distance = distance
				best_source = source
				best_target = target

	if best_source == null or best_target == null:
		_snap_module_to_grid(module, edited_root)
		return
	if not force_nearest and best_distance > SNAP_TOLERANCE:
		_snap_module_to_grid(module, edited_root)
		return

	var old_position: Vector2 = module.position
	var global_delta: Vector2 = best_target.global_position - best_source.global_position
	var new_global_position: Vector2 = module.global_position + global_delta
	var module_parent := module.get_parent() as Node2D
	if module_parent == null:
		return
	var new_position: Vector2 = module_parent.to_local(new_global_position)
	if old_position.is_equal_approx(new_position):
		return

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Snap Steamtek Module")
	undo_redo.add_do_property(module, "position", new_position)
	undo_redo.add_undo_property(module, "position", old_position)
	undo_redo.commit_action()


func _snap_foundation_to_lattice(module: Node2D, edited_root: Node, force_nearest: bool) -> bool:
	var foundations: Array[Node2D] = []
	_collect_foundation_modules(edited_root, foundations)
	var reference: Node2D
	for foundation in foundations:
		if foundation != module:
			reference = foundation
			break
	if reference == null:
		return _snap_module_to_grid(module, edited_root)

	var axes := _foundation_axes_for(reference)
	var candidate: Vector2 = _nearest_lattice_point(
		module.global_position,
		reference.global_position,
		axes[0],
		axes[1]
	)
	var distance := module.global_position.distance_to(candidate)
	if not force_nearest and distance > FOUNDATION_SNAP_TOLERANCE:
		return true
	if _foundation_position_is_occupied(candidate, module, foundations):
		if force_nearest:
			push_warning("Steamtek foundation cell is already occupied; module was not moved.")
		return true
	var module_parent := module.get_parent() as Node2D
	if module_parent == null:
		return false
	var old_position := module.position
	var new_position := module_parent.to_local(candidate)
	if old_position.is_equal_approx(new_position):
		return true

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Snap Steamtek Foundation")
	undo_redo.add_do_property(module, "position", new_position)
	undo_redo.add_undo_property(module, "position", old_position)
	undo_redo.commit_action()
	return true


func _foundation_position_is_occupied(candidate: Vector2, moving: Node2D, foundations: Array[Node2D]) -> bool:
	for foundation in foundations:
		if foundation != moving and foundation.global_position.distance_to(candidate) < 8.0:
			return true
	return false


func _snap_selected_to_grid() -> void:
	var selection := get_editor_interface().get_selection().get_selected_nodes()
	if selection.is_empty():
		return

	var edited_root := get_editor_interface().get_edited_scene_root()
	if edited_root == null:
		return

	var module := _find_module_root(selection[0], edited_root)
	if module == null:
		return
	if _is_foundation_module(module):
		_snap_foundation_to_lattice(module, edited_root, true)
		return
	_snap_module_to_grid(module, edited_root)


func _snap_module_to_grid(module: Node2D, edited_root: Node) -> bool:
	var custom_axes := _grid_axes_for(module)
	var custom_origin := Vector2.ZERO
	if edited_root is Node2D:
		custom_origin = (edited_root as Node2D).global_position
	var custom_candidate := _nearest_lattice_point(
		module.global_position,
		custom_origin,
		custom_axes[0],
		custom_axes[1]
	)
	var module_parent := module.get_parent() as Node2D
	if module_parent == null:
		return false
	var old_position := module.position
	var custom_position := module_parent.to_local(custom_candidate)
	if _is_v4_module(module):
		if not old_position.is_equal_approx(custom_position):
			var v4_undo_redo := get_undo_redo()
			v4_undo_redo.create_action("Snap Steamtek V4 Module to 60-Degree Lattice")
			v4_undo_redo.add_do_property(module, "position", custom_position)
			v4_undo_redo.add_undo_property(module, "position", old_position)
			v4_undo_redo.commit_action()
		return true

	var layers: Array[TileMapLayer] = []
	_collect_tilemap_layers(edited_root, layers)
	if layers.is_empty():
		if not old_position.is_equal_approx(custom_position):
			var fallback_undo_redo := get_undo_redo()
			fallback_undo_redo.create_action("Snap Steamtek Module to Lattice")
			fallback_undo_redo.add_do_property(module, "position", custom_position)
			fallback_undo_redo.add_undo_property(module, "position", old_position)
			fallback_undo_redo.commit_action()
		return true

	var best_global := module.global_position
	var best_distance := INF
	for layer in layers:
		if layer.tile_set == null:
			continue
		if layer.tile_set.tile_shape != TileSet.TILE_SHAPE_ISOMETRIC:
			continue
		var local_origin := layer.map_to_local(Vector2i.ZERO)
		var origin := layer.to_global(local_origin)
		var axis_a := layer.to_global(local_origin + GRID_AXIS_A) - origin
		var axis_b := layer.to_global(local_origin + GRID_AXIS_B) - origin
		var candidate := _nearest_lattice_point(module.global_position, origin, axis_a, axis_b)
		var distance := module.global_position.distance_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best_global = candidate

	if best_distance == INF:
		return false

	var new_position := module_parent.to_local(best_global)
	if old_position.is_equal_approx(new_position):
		return true

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Snap Steamtek Module to TileMap Grid")
	undo_redo.add_do_property(module, "position", new_position)
	undo_redo.add_undo_property(module, "position", old_position)
	undo_redo.commit_action()
	return true


func _nearest_lattice_point(point: Vector2, origin: Vector2, axis_a: Vector2, axis_b: Vector2) -> Vector2:
	var determinant := axis_a.x * axis_b.y - axis_a.y * axis_b.x
	if is_zero_approx(determinant):
		return point
	var relative := point - origin
	var coordinate_a := (relative.x * axis_b.y - relative.y * axis_b.x) / determinant
	var coordinate_b := (axis_a.x * relative.y - axis_a.y * relative.x) / determinant
	return origin + axis_a * roundf(coordinate_a) + axis_b * roundf(coordinate_b)


func _find_module_root(node: Node, edited_root: Node) -> Node2D:
	var current := node
	while current != null:
		if current is Node2D and current.is_in_group("steamtek_modular"):
			return current
		if current == edited_root:
			break
		current = current.get_parent()
	return null


func _collect_markers(node: Node, output: Array[Marker2D]) -> void:
	if node is Marker2D and node.is_in_group("steamtek_snap"):
		output.append(node)
	for child in node.get_children():
		_collect_markers(child, output)


func _collect_foundation_modules(node: Node, output: Array[Node2D]) -> void:
	if node is Node2D and node.is_in_group("steamtek_modular") and _is_foundation_module(node):
		output.append(node)
	for child in node.get_children():
		_collect_foundation_modules(child, output)


func _is_foundation_module(node: Node2D) -> bool:
	return node.name.begins_with("SMV2_F") or node.name.begins_with("SMV3_F") or node.name.begins_with("SMV4_F")


func _is_v4_module(node: Node2D) -> bool:
	return node.name.begins_with("SMV4_") or node.is_in_group("steamtek_modular_v4")


func _grid_axes_for(module: Node2D) -> Array[Vector2]:
	var axis_a := GRID_AXIS_A
	var axis_b := GRID_AXIS_B
	if module.has_meta("steamtek_lattice_axis_a"):
		var custom_a: Variant = module.get_meta("steamtek_lattice_axis_a")
		if custom_a is Vector2:
			axis_a = custom_a
	if module.has_meta("steamtek_lattice_axis_b"):
		var custom_b: Variant = module.get_meta("steamtek_lattice_axis_b")
		if custom_b is Vector2:
			axis_b = custom_b
	return [axis_a, axis_b]


func _foundation_axes_for(module: Node2D) -> Array[Vector2]:
	var axis_a := FOUNDATION_AXIS_A
	var axis_b := FOUNDATION_AXIS_B
	if module.has_meta("steamtek_lattice_axis_a"):
		var custom_a: Variant = module.get_meta("steamtek_lattice_axis_a")
		if custom_a is Vector2:
			axis_a = custom_a
	if module.has_meta("steamtek_lattice_axis_b"):
		var custom_b: Variant = module.get_meta("steamtek_lattice_axis_b")
		if custom_b is Vector2:
			axis_b = custom_b
	return [axis_a, axis_b]


func _marker_is_occupied(
	target: Marker2D,
	moving_module: Node2D,
	all_markers: Array[Marker2D],
	edited_root: Node
) -> bool:
	var target_module := _find_module_root(target, edited_root)
	for marker in all_markers:
		if marker == target:
			continue
		if moving_module == marker or moving_module.is_ancestor_of(marker):
			continue
		var marker_module := _find_module_root(marker, edited_root)
		if marker_module == null or marker_module == target_module:
			continue
		if marker.global_position.distance_to(target.global_position) <= SNAP_OCCUPANCY_TOLERANCE:
			return true
	return false


func _collect_tilemap_layers(node: Node, output: Array[TileMapLayer]) -> void:
	if node is TileMapLayer:
		output.append(node)
	for child in node.get_children():
		_collect_tilemap_layers(child, output)
