extends Node

# ============================================================
# KeystoneViewer.gd -- Steamtek RPG Keystone Panel
# ============================================================
# Full-screen cluster UI modelled on the reference mockup.
# Center diamond = Street Thug class node. Click it to expand
# or collapse the whole profession view.
#
# Collapsed: only the Street Thug diamond shows.
# Expanded: the diamond, its 4 keystone clusters, and an
# advancement branch running up to Enforcer / Specialist
# (the two professions that require a mastered Street Thug).
#
# Each keystone hex has:
#  - a tight bright triangle of ability nodes right next to it
#    (Melee and Ranged only -- Crafting and Auxiliary have no
#    ability nodes and never show this cluster)
#  - an outer ring of stat nodes, grouped by category (Accuracy,
#    Speed, Crit Damage, Survey Rate, etc) with a label per group
#
# Hover any node, keystone, the diamond, or an advancement box
# for a tooltip. Click for the purchase popup.
# ============================================================

var main

# --- Palette ---
const BG_COLOR      = Color(0.06, 0.02, 0.04)
const COLORS = {
	"Melee":     Color(0.95, 0.20, 0.20),
	"Ranged":    Color(0.15, 0.90, 0.95),
	"Crafting":  Color(0.70, 0.25, 0.95),
	"Auxiliary": Color(0.95, 0.60, 0.05)
}
const CENTER_COLOR    = Color(0.30, 0.55, 1.00)
const LOCKED_GREY     = Color(0.42, 0.42, 0.42)
const OWNED_TAG_COLOR = Color(0.55, 0.95, 0.55)
const ABILITY_TAG_COLOR = Color(1.00, 0.92, 0.55)

# --- Geometry ---
const CENTER         = Vector2(960, 540)
const KS_OFFSETS = {
	"Melee":     Vector2(-300, -260),
	"Ranged":    Vector2( 300, -260),
	"Crafting":  Vector2(-300,  260),
	"Auxiliary": Vector2( 300,  260)
}
const KS_RADIUS         = 48.0
const NODE_RADIUS       = 24.0
const ABILITY_RADIUS    = 28.0
const CENTER_SIZE       = 90.0
const CATEGORY_GAP      = 0.10  # radians of empty space between stat node groups

# --- Advancement branch (Street Thug -> Enforcer / Specialist) ---
const NEXT_TIER_OFFSETS = {
	"Enforcer":   Vector2(-170, -360),
	"Specialist": Vector2( 170, -360)
}
const NEXT_TIER_SIZE = 46.0

# --- State ---
var canvas: Control
var popup_panel: Panel
var popup_title: Label
var popup_body: Label
var popup_cost_label: Label
var popup_buy_btn: Button
var popup_close_btn: Button
var hud_xp: Label
var hud_status: Label
var tooltip_panel: Panel
var tooltip_label: Label
var selected_ks: String = ""
var selected_node: String = ""
var expanded: bool = false

func setup(parent: Control) -> void:
	_build_ui(parent)
	_rebuild_graph()

# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui(parent: Control) -> void:
	var bg = ColorRect.new()
	bg.color = BG_COLOR
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)

	canvas = Control.new()
	canvas.anchor_right = 1.0
	canvas.anchor_bottom = 1.0
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(canvas)

	# HUD -- top strip
	var hud_strip = ColorRect.new()
	hud_strip.color = Color(0.04, 0.04, 0.08, 0.9)
	hud_strip.position = Vector2(0, 0)
	hud_strip.size = Vector2(1920, 58)
	hud_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hud_strip)

	hud_xp = Label.new()
	hud_xp.position = Vector2(30, 14)
	hud_xp.add_theme_font_size_override("font_size", 18)
	hud_xp.modulate = Color(0.5, 0.95, 0.6)
	parent.add_child(hud_xp)

	hud_status = Label.new()
	hud_status.position = Vector2(560, 8)
	hud_status.add_theme_font_size_override("font_size", 16)
	hud_status.modulate = Color(0.8, 0.8, 0.9)
	parent.add_child(hud_status)

	var title_lbl = Label.new()
	title_lbl.text = "TALENTS"
	title_lbl.position = Vector2(1780, 8)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.modulate = Color(0.7, 0.75, 1.0)
	parent.add_child(title_lbl)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(1865, 6)
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.focus_mode = Control.FOCUS_NONE
	var cs = _flat_style(Color(0.3, 0.08, 0.08), Color(0.8, 0.2, 0.2), 2)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.add_theme_stylebox_override("hover", _flat_style(Color(0.5, 0.1, 0.1), Color(1.0, 0.3, 0.3), 2))
	close_btn.add_theme_stylebox_override("pressed", cs)
	close_btn.add_theme_stylebox_override("focus", cs)
	close_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): parent.visible = false)
	parent.add_child(close_btn)

	_build_popup(parent)
	_build_tooltip(parent)

func _build_popup(parent: Control) -> void:
	popup_panel = Panel.new()
	popup_panel.position = Vector2(660, 330)
	popup_panel.size = Vector2(600, 380)
	popup_panel.visible = false
	popup_panel.z_index = 10
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.10)
	ps.border_color = Color(0.35, 0.40, 0.65)
	ps.set_border_width_all(2)
	ps.corner_radius_top_left = 10
	ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10
	ps.corner_radius_bottom_right = 10
	popup_panel.add_theme_stylebox_override("panel", ps)
	parent.add_child(popup_panel)

	popup_title = Label.new()
	popup_title.position = Vector2(24, 18)
	popup_title.size = Vector2(552, 36)
	popup_title.add_theme_font_size_override("font_size", 24)
	popup_panel.add_child(popup_title)

	var div = ColorRect.new()
	div.color = Color(0.25, 0.30, 0.50)
	div.position = Vector2(24, 60)
	div.size = Vector2(552, 1)
	popup_panel.add_child(div)

	popup_body = Label.new()
	popup_body.position = Vector2(24, 72)
	popup_body.size = Vector2(552, 180)
	popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup_body.modulate = Color(0.80, 0.85, 0.95)
	popup_body.add_theme_font_size_override("font_size", 16)
	popup_panel.add_child(popup_body)

	popup_cost_label = Label.new()
	popup_cost_label.position = Vector2(24, 258)
	popup_cost_label.size = Vector2(552, 28)
	popup_cost_label.modulate = Color(0.65, 0.90, 0.65)
	popup_cost_label.add_theme_font_size_override("font_size", 15)
	popup_panel.add_child(popup_cost_label)

	popup_buy_btn = Button.new()
	popup_buy_btn.text = "Purchase"
	popup_buy_btn.position = Vector2(24, 300)
	popup_buy_btn.custom_minimum_size = Vector2(270, 52)
	popup_buy_btn.focus_mode = Control.FOCUS_NONE
	popup_buy_btn.add_theme_font_size_override("font_size", 16)
	popup_buy_btn.pressed.connect(_on_buy_pressed)
	popup_panel.add_child(popup_buy_btn)

	popup_close_btn = Button.new()
	popup_close_btn.text = "Close"
	popup_close_btn.position = Vector2(306, 300)
	popup_close_btn.custom_minimum_size = Vector2(270, 52)
	popup_close_btn.focus_mode = Control.FOCUS_NONE
	popup_close_btn.add_theme_font_size_override("font_size", 16)
	popup_close_btn.pressed.connect(func(): popup_panel.visible = false)
	popup_panel.add_child(popup_close_btn)

func _build_tooltip(parent: Control) -> void:
	tooltip_panel = Panel.new()
	tooltip_panel.visible = false
	tooltip_panel.z_index = 20
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts = StyleBoxFlat.new()
	ts.bg_color = Color(0.04, 0.04, 0.08, 0.96)
	ts.border_color = Color(0.5, 0.55, 0.8)
	ts.set_border_width_all(1)
	ts.corner_radius_top_left = 6
	ts.corner_radius_top_right = 6
	ts.corner_radius_bottom_left = 6
	ts.corner_radius_bottom_right = 6
	ts.content_margin_left = 10
	ts.content_margin_right = 10
	ts.content_margin_top = 8
	ts.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", ts)
	parent.add_child(tooltip_panel)

	tooltip_label = Label.new()
	tooltip_label.position = Vector2(0, 0)
	tooltip_label.size = Vector2(300, 90)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tooltip_label.add_theme_font_size_override("font_size", 14)
	tooltip_label.modulate = Color(0.9, 0.9, 0.95)
	tooltip_panel.add_child(tooltip_label)
	tooltip_panel.custom_minimum_size = Vector2(300, 90)
	tooltip_panel.size = Vector2(300, 90)

func _show_tooltip(text: String, near_pos: Vector2) -> void:
	tooltip_label.text = text
	var box_size = Vector2(300, 90)
	var pos = near_pos + Vector2(18, 18)
	if pos.x + box_size.x > 1900:
		pos.x = near_pos.x - box_size.x - 18
	if pos.y + box_size.y > 1060:
		pos.y = near_pos.y - box_size.y - 18
	tooltip_panel.position = pos
	tooltip_panel.size = box_size
	tooltip_panel.visible = true

func _hide_tooltip() -> void:
	tooltip_panel.visible = false

# ============================================================
# GRAPH DRAWING
# ============================================================

func _rebuild_graph() -> void:
	for child in canvas.get_children():
		child.queue_free()
	_draw_graph()
	_update_hud()

func _toggle_expanded() -> void:
	expanded = not expanded
	_hide_tooltip()
	_rebuild_graph()

func _orbit_radius(node_count: int) -> float:
	return max(120.0, 120.0 + max(0, node_count - 10) * 6.0)

# Splits a node name like "Accuracy 3" into category "Accuracy".
# Ability nodes are grouped under "Abilities" instead.
func _node_category(node_name: String, node_data: Dictionary) -> String:
	if node_data.get("type", "") == "ability":
		return "Abilities"
	var last_space = node_name.rfind(" ")
	if last_space == -1:
		return node_name
	var suffix = node_name.substr(last_space + 1)
	if suffix.is_valid_int():
		return node_name.substr(0, last_space)
	return node_name

# Groups node names (in original dict order) into
# [{ "category": String, "members": Array }] preserving order of
# first appearance so Accuracy/Speed/Crit stay clustered and any
# Abilities group is separated out by the caller.
func _build_category_groups(node_names: Array, nodes: Dictionary) -> Array:
	var groups: Array = []
	var index_by_category: Dictionary = {}
	for node_name in node_names:
		var node_data = nodes[node_name]
		var category = _node_category(node_name, node_data)
		if not index_by_category.has(category):
			index_by_category[category] = groups.size()
			groups.append({"category": category, "members": []})
		groups[index_by_category[category]]["members"].append(node_name)
	return groups

func _is_profession_mastered(profession_name: String) -> bool:
	var prof_data = GameData.novice_professions.get(profession_name, {})
	var keystones = prof_data.get("keystones", {})
	if keystones.is_empty():
		return false
	for ks_name in keystones.keys():
		var ks = keystones[ks_name]
		if ks.get("points_spent", 0) < ks.get("points_max", 0):
			return false
	return true

func _draw_graph() -> void:
	var prof_data = GameData.novice_professions.get("Street Thug", {})
	var keystones = prof_data.get("keystones", {})

	var combat_spent = 0
	var combat_max = 0
	var crafting_spent = 0
	var crafting_max = 0
	for ks_name in keystones.keys():
		var ks = keystones[ks_name]
		if ks.get("xp_type", "Combat XP") == "Crafting XP":
			crafting_spent += ks.get("points_spent", 0)
			crafting_max += ks.get("points_max", 0)
		else:
			combat_spent += ks.get("points_spent", 0)
			combat_max += ks.get("points_max", 0)

	if not expanded:
		var street_thug_mastered = _is_profession_mastered("Street Thug")
		_draw_advancement_branch(street_thug_mastered)
		_diamond(CENTER, CENTER_SIZE, CENTER_COLOR, "STREET\nTHUG", combat_spent, combat_max, crafting_spent, crafting_max)
		return

	var diamond_corners = {
		"Melee":     CENTER + Vector2(-CENTER_SIZE * 0.75, -CENTER_SIZE * 0.35),
		"Ranged":    CENTER + Vector2( CENTER_SIZE * 0.75, -CENTER_SIZE * 0.35),
		"Crafting":  CENTER + Vector2(-CENTER_SIZE * 0.75,  CENTER_SIZE * 0.35),
		"Auxiliary": CENTER + Vector2( CENTER_SIZE * 0.75,  CENTER_SIZE * 0.35)
	}

	_diamond(CENTER, CENTER_SIZE, CENTER_COLOR, "STREET\nTHUG", combat_spent, combat_max, crafting_spent, crafting_max)

	for ks_name in KS_OFFSETS.keys():
		if not keystones.has(ks_name):
			continue
		var ks_data = keystones[ks_name]
		var col = COLORS.get(ks_name, Color.WHITE)
		var ks_pos = CENTER + KS_OFFSETS[ks_name]
		var ks_unlocked = ks_data.get("unlocked", false)
		var corner = diamond_corners.get(ks_name, CENTER)

		_line(corner, ks_pos, col, 4.0, 0.65 if ks_unlocked else 0.35)

		var nodes = ks_data.get("nodes", {})
		var node_names = nodes.keys()
		var all_groups = _build_category_groups(node_names, nodes)

		var stat_groups: Array = []
		var ability_group = null
		for group in all_groups:
			if group["category"] == "Abilities":
				ability_group = group
			else:
				stat_groups.append(group)

		var stat_node_count = 0
		for group in stat_groups:
			stat_node_count += group["members"].size()
		var orbit_radius = _orbit_radius(stat_node_count)
		# If this keystone has an ability triangle, make sure the stat
		# ring starts outside it -- otherwise the innermost ring nodes
		# would overlap the triangle's outer edge.
		if ability_group != null:
			var triangle_clearance = KS_RADIUS + (ABILITY_RADIUS * 2.0) + 8.0 + NODE_RADIUS + 12.0
			orbit_radius = max(orbit_radius, triangle_clearance)

		var gap_total = CATEGORY_GAP * stat_groups.size()
		var usable_angle = TAU - gap_total
		var per_node_angle = usable_angle / max(1, stat_node_count)

		# Pass 1: connector lines + category labels for the stat ring
		var current_angle = -PI / 2.0
		for group in stat_groups:
			var start_angle = current_angle
			for node_name in group["members"]:
				var node_pos = ks_pos + Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
				_line(ks_pos, node_pos, col, 2.0, 0.55 if ks_unlocked else 0.25)
				current_angle += per_node_angle
			var end_angle = current_angle - per_node_angle
			var mid_angle = (start_angle + end_angle) / 2.0
			var label_pos = ks_pos + Vector2(cos(mid_angle), sin(mid_angle)) * (orbit_radius + NODE_RADIUS + 28)
			_category_label(label_pos, group["category"], col, ks_unlocked)
			current_angle += CATEGORY_GAP

		# Ability triangle: 3 ability hexes sit at the vertices of an
		# actual equilateral triangle (top, bottom-left, bottom-right),
		# connected to each other by triangle-edge lines, with the
		# keystone hex centered inside. Only keystones that actually
		# have ability nodes (Melee, Ranged) get this -- Crafting and
		# Auxiliary have none and simply skip straight to their stat ring.
		var ability_vertex_positions: Array = []
		if ability_group != null:
			var members = ability_group["members"]
			var triangle_radius = KS_RADIUS + ABILITY_RADIUS + 8.0
			var base_angles = [-PI / 2.0, PI * 5.0 / 6.0, PI / 6.0]  # top, bottom-left, bottom-right
			for i in range(members.size()):
				var ang = base_angles[i] if i < base_angles.size() else (-PI / 2.0 + i * TAU / members.size())
				ability_vertex_positions.append(ks_pos + Vector2(cos(ang), sin(ang)) * triangle_radius)
			for i in range(ability_vertex_positions.size()):
				var next_i = (i + 1) % ability_vertex_positions.size()
				_line(ability_vertex_positions[i], ability_vertex_positions[next_i], ABILITY_TAG_COLOR, 2.5, 0.65 if ks_unlocked else 0.3)

		# Keystone hex drawn on top of the triangle edges and ring lines,
		# centered inside the ability triangle, under all the nodes.
		_keystone_hex(ks_pos, KS_RADIUS, col, ks_name, ks_data)

		# Ability nodes drawn last so they sit on top of everything.
		if ability_group != null:
			var members2 = ability_group["members"]
			for i in range(members2.size()):
				_ability_hex(ability_vertex_positions[i], ABILITY_RADIUS, col, members2[i], nodes[members2[i]], ks_data, ks_name)

		# Pass 3: stat ring nodes
		current_angle = -PI / 2.0
		for group in stat_groups:
			for node_name in group["members"]:
				var node_data = nodes[node_name]
				var node_pos = ks_pos + Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
				_node_hex(node_pos, NODE_RADIUS, col, node_name, node_data, ks_data, ks_name)
				current_angle += per_node_angle
			current_angle += CATEGORY_GAP

func _draw_advancement_branch(street_thug_mastered: bool) -> void:
	var top_vertex = CENTER + Vector2(0, -CENTER_SIZE)
	for profession_name in NEXT_TIER_OFFSETS.keys():
		var box_pos = CENTER + NEXT_TIER_OFFSETS[profession_name]
		_line(top_vertex, box_pos, CENTER_COLOR, 3.0, 0.7 if street_thug_mastered else 0.3)
		_advancement_box(box_pos, profession_name, street_thug_mastered)

func _advancement_box(pos: Vector2, profession_name: String, unlocked: bool) -> void:
	var display_color = CENTER_COLOR if unlocked else LOCKED_GREY
	var pts = _hex_points(pos, NEXT_TIER_SIZE)

	var poly = Polygon2D.new()
	poly.polygon = pts
	poly.color = Color(display_color.r, display_color.g, display_color.b, 0.22 if unlocked else 0.10)
	canvas.add_child(poly)

	var border = Line2D.new()
	var bpts = pts
	bpts.append(pts[0])
	border.points = bpts
	border.default_color = display_color
	border.width = 3.0
	canvas.add_child(border)

	var lbl = Label.new()
	lbl.text = profession_name.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos - Vector2(NEXT_TIER_SIZE * 1.3, 22)
	lbl.size = Vector2(NEXT_TIER_SIZE * 2.6, 22)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", display_color if unlocked else Color(0.65, 0.65, 0.65))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)

	var status_lbl = Label.new()
	status_lbl.text = "AVAILABLE" if unlocked else "LOCKED"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_lbl.position = pos - Vector2(NEXT_TIER_SIZE * 1.3, -2)
	status_lbl.size = Vector2(NEXT_TIER_SIZE * 2.6, 16)
	status_lbl.add_theme_font_size_override("font_size", 10)
	status_lbl.add_theme_color_override("font_color", OWNED_TAG_COLOR if unlocked else Color(0.8, 0.6, 0.6))
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_lbl)

	var btn = Button.new()
	btn.position = pos - Vector2(NEXT_TIER_SIZE, NEXT_TIER_SIZE)
	btn.size = Vector2(NEXT_TIER_SIZE * 2, NEXT_TIER_SIZE * 2)
	btn.focus_mode = Control.FOCUS_NONE
	var blank = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", blank)
	btn.add_theme_stylebox_override("hover", blank)
	btn.add_theme_stylebox_override("pressed", blank)
	btn.add_theme_stylebox_override("focus", blank)
	btn.modulate.a = 0.0
	var tip = profession_name + "\n"
	if unlocked:
		tip += "Street Thug is mastered -- " + profession_name + " is available to train at a trainer NPC."
	else:
		tip += "Requires a mastered Street Thug (every keystone fully spent)."
	btn.mouse_entered.connect(func(): _show_tooltip(tip, pos))
	btn.mouse_exited.connect(_hide_tooltip)
	btn.pressed.connect(func(): _on_next_profession_clicked(profession_name, unlocked))
	canvas.add_child(btn)

func _on_next_profession_clicked(profession_name: String, unlocked: bool) -> void:
	popup_title.text = profession_name.to_upper()
	popup_title.modulate = CENTER_COLOR
	if unlocked:
		popup_body.text = "Street Thug has been mastered!\n\n" + profession_name + " is available to train at a trainer NPC.\n\n(Its own talent tree will appear here in a future update.)"
	else:
		popup_body.text = "Master every keystone in Street Thug -- spend all points in Melee, Ranged, Crafting, and Auxiliary -- to unlock " + profession_name + "."
	popup_cost_label.text = ""
	popup_buy_btn.visible = false
	popup_panel.visible = true

func _line(from: Vector2, to: Vector2, color: Color, width: float, alpha: float) -> void:
	var l = Line2D.new()
	l.points = PackedVector2Array([from, to])
	l.default_color = Color(color.r, color.g, color.b, alpha)
	l.width = width
	canvas.add_child(l)

func _category_label(pos: Vector2, text: String, color: Color, unlocked: bool) -> void:
	var lbl = Label.new()
	lbl.text = text.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos - Vector2(70, 10)
	lbl.size = Vector2(140, 20)
	lbl.add_theme_font_size_override("font_size", 13)
	var c = color.lightened(0.3) if unlocked else Color(0.5, 0.5, 0.5)
	lbl.add_theme_color_override("font_color", c)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)

func _diamond(pos: Vector2, size: float, color: Color, label: String, combat_spent: int, combat_max: int, crafting_spent: int, crafting_max: int) -> void:
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size * 0.75, 0),
		pos + Vector2(0, size),
		pos + Vector2(-size * 0.75, 0)
	])
	poly.color = Color(color.r, color.g, color.b, 0.18)
	canvas.add_child(poly)

	var outline = Line2D.new()
	outline.points = PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size * 0.75, 0),
		pos + Vector2(0, size),
		pos + Vector2(-size * 0.75, 0),
		pos + Vector2(0, -size)
	])
	outline.default_color = color
	outline.width = 4.0
	canvas.add_child(outline)

	var glow = Line2D.new()
	glow.points = outline.points
	glow.default_color = Color(color.r, color.g, color.b, 0.3)
	glow.width = 10.0
	canvas.add_child(glow)

	var lbl = Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos - Vector2(80, 34)
	lbl.size = Vector2(160, 48)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color.lightened(0.4))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)

	var sub_lbl = Label.new()
	var action_hint = "click to collapse" if expanded else "click to expand"
	sub_lbl.text = "CXP " + str(combat_spent) + "/" + str(combat_max) + "   CFT " + str(crafting_spent) + "/" + str(crafting_max) + " -- " + action_hint
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_lbl.position = pos + Vector2(-130, 14)
	sub_lbl.size = Vector2(260, 20)
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.95))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sub_lbl)

	var btn = Button.new()
	btn.position = pos - Vector2(size * 0.75, size)
	btn.size = Vector2(size * 1.5, size * 2)
	btn.focus_mode = Control.FOCUS_NONE
	var blank = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", blank)
	btn.add_theme_stylebox_override("hover", blank)
	btn.add_theme_stylebox_override("pressed", blank)
	btn.add_theme_stylebox_override("focus", blank)
	btn.modulate.a = 0.0
	var tip = "Street Thug -- base profession.\nCombat XP spent: " + str(combat_spent) + " / " + str(combat_max) + "\nCrafting XP spent: " + str(crafting_spent) + " / " + str(crafting_max)
	if expanded:
		tip += "\n\nClick to collapse."
	else:
		tip += "\n\nClick to expand and see the four keystones."
	btn.mouse_entered.connect(func(): _show_tooltip(tip, pos))
	btn.mouse_exited.connect(_hide_tooltip)
	btn.pressed.connect(_toggle_expanded)
	canvas.add_child(btn)

func _keystone_hex(pos: Vector2, radius: float, color: Color, ks_name: String, ks_data: Dictionary) -> void:
	var unlocked = ks_data.get("unlocked", false)
	var display_color = color if unlocked else LOCKED_GREY

	var pts = _hex_points(pos, radius)
	var poly = Polygon2D.new()
	poly.polygon = pts
	poly.color = Color(display_color.r, display_color.g, display_color.b, 0.22 if unlocked else 0.10)
	canvas.add_child(poly)

	var border = Line2D.new()
	var border_pts = pts
	border_pts.append(pts[0])
	border.points = border_pts
	border.default_color = display_color if unlocked else Color(display_color.r, display_color.g, display_color.b, 0.6)
	border.width = 3.5
	canvas.add_child(border)

	var glow = Line2D.new()
	glow.points = border.points
	glow.default_color = Color(display_color.r, display_color.g, display_color.b, 0.22 if unlocked else 0.08)
	glow.width = 10.0
	canvas.add_child(glow)

	var lbl = Label.new()
	lbl.text = ks_name.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos - Vector2(radius * 1.3, 26)
	lbl.size = Vector2(radius * 2.6, 24)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", color if unlocked else Color(0.65, 0.65, 0.65))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)

	var status_lbl = Label.new()
	var spent = ks_data.get("points_spent", 0)
	var max_pts = ks_data.get("points_max", 10)
	if unlocked:
		status_lbl.text = "UNLOCKED -- " + str(spent) + "/" + str(max_pts) + " PTS"
		status_lbl.add_theme_color_override("font_color", OWNED_TAG_COLOR)
	else:
		var xp_cost = ks_data.get("xp_cost", 10)
		var xp_type = ks_data.get("xp_type", "Combat XP")
		status_lbl.text = "LOCKED -- " + str(xp_cost) + " " + xp_type
		status_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_lbl.position = pos - Vector2(radius * 1.3, -2)
	status_lbl.size = Vector2(radius * 2.6, 18)
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_lbl)

	var btn = Button.new()
	btn.position = pos - Vector2(radius, radius)
	btn.size = Vector2(radius * 2, radius * 2)
	btn.focus_mode = Control.FOCUS_NONE
	var blank = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", blank)
	btn.add_theme_stylebox_override("hover", blank)
	btn.add_theme_stylebox_override("pressed", blank)
	btn.add_theme_stylebox_override("focus", blank)
	btn.modulate.a = 0.0
	var node_count = ks_data.get("nodes", {}).size()
	var tip = ks_name + " Keystone\n"
	if unlocked:
		tip += "Unlocked -- " + str(spent) + " / " + str(max_pts) + " points spent across " + str(node_count) + " nodes."
	else:
		tip += "Locked. Costs " + str(ks_data.get("xp_cost", 10)) + " " + ks_data.get("xp_type", "Combat XP") + " to unlock.\nOnce unlocked, spend up to " + str(max_pts) + " points across " + str(node_count) + " nodes."
	btn.mouse_entered.connect(func(): _show_tooltip(tip, pos))
	btn.mouse_exited.connect(_hide_tooltip)
	btn.pressed.connect(func(): _on_keystone_clicked(ks_name))
	canvas.add_child(btn)

# Ability nodes render brighter and larger than stat nodes, and sit
# in a tight triangle right next to the keystone hex instead of on
# the outer stat ring. Only Melee and Ranged currently have any.
func _ability_hex(pos: Vector2, radius: float, category_color: Color, node_name: String, node_data: Dictionary, ks_data: Dictionary, ks_name: String) -> void:
	var purchased = node_data.get("purchased", false)
	var cost = node_data.get("cost", 2)
	var ks_unlocked = ks_data.get("unlocked", false)
	var spent = ks_data.get("points_spent", 0)
	var max_pts = ks_data.get("points_max", 10)
	var remaining = max_pts - spent
	var xp_type = ks_data.get("xp_type", "Combat XP")
	var available_xp = main.xp_pools.get(xp_type, 0)
	var affordable = ks_unlocked and not purchased and remaining >= cost and available_xp >= cost

	var display_color: Color
	var fill_alpha: float
	var border_width: float
	if not ks_unlocked:
		display_color = LOCKED_GREY
		fill_alpha = 0.10
		border_width = 2.0
	elif purchased:
		display_color = ABILITY_TAG_COLOR
		fill_alpha = 0.65
		border_width = 4.0
	elif affordable:
		display_color = ABILITY_TAG_COLOR
		fill_alpha = 0.32
		border_width = 3.0
	else:
		display_color = category_color
		fill_alpha = 0.14
		border_width = 2.0

	var pts = _hex_points(pos, radius)
	var poly = Polygon2D.new()
	poly.polygon = pts
	poly.color = Color(display_color.r, display_color.g, display_color.b, fill_alpha)
	canvas.add_child(poly)

	var border = Line2D.new()
	var bpts = pts
	bpts.append(pts[0])
	border.points = bpts
	border.default_color = display_color
	border.width = border_width
	canvas.add_child(border)

	if purchased or affordable:
		var glow = Line2D.new()
		glow.points = border.points
		glow.default_color = Color(display_color.r, display_color.g, display_color.b, 0.35)
		glow.width = 10.0
		canvas.add_child(glow)

	var abl_tag = Label.new()
	abl_tag.text = "ABILITY"
	abl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abl_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	abl_tag.position = pos - Vector2(radius, radius + 22)
	abl_tag.size = Vector2(radius * 2, 16)
	abl_tag.add_theme_font_size_override("font_size", 9)
	abl_tag.add_theme_color_override("font_color", ABILITY_TAG_COLOR if ks_unlocked else Color(0.6, 0.6, 0.6))
	abl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(abl_tag)

	var num_lbl = Label.new()
	num_lbl.text = str(cost)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num_lbl.position = pos - Vector2(radius, radius * 0.5)
	num_lbl.size = Vector2(radius * 2, radius)
	num_lbl.add_theme_font_size_override("font_size", 19)
	num_lbl.add_theme_color_override("font_color", display_color if ks_unlocked else Color(0.6, 0.6, 0.6))
	num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(num_lbl)

	if purchased:
		var tag_lbl = Label.new()
		tag_lbl.text = "OWNED"
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag_lbl.position = pos - Vector2(radius, -radius * 0.15)
		tag_lbl.size = Vector2(radius * 2, 16)
		tag_lbl.add_theme_font_size_override("font_size", 9)
		tag_lbl.add_theme_color_override("font_color", OWNED_TAG_COLOR)
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(tag_lbl)

	var btn = Button.new()
	btn.position = pos - Vector2(radius, radius)
	btn.size = Vector2(radius * 2, radius * 2)
	btn.focus_mode = Control.FOCUS_NONE
	var blank = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", blank)
	btn.add_theme_stylebox_override("hover", blank)
	btn.add_theme_stylebox_override("pressed", blank)
	btn.add_theme_stylebox_override("focus", blank)
	btn.modulate.a = 0.0
	var tip = node_name + "\nAbility: " + node_data.get("ability", node_name)
	var upgrade = node_data.get("mastery_upgrade", "")
	if upgrade != "":
		tip += "\nMastery upgrade: " + upgrade
	tip += "\nCost: " + str(cost) + " " + xp_type
	if not ks_unlocked:
		tip += "\n[ Keystone locked ]"
	elif purchased:
		tip += "\n[ OWNED ]"
	elif remaining < cost:
		tip += "\n[ Not enough room left in keystone -- " + str(remaining) + " remaining ]"
	elif available_xp < cost:
		tip += "\n[ Not enough " + xp_type + " -- have " + str(available_xp) + ", need " + str(cost) + " ]"
	btn.mouse_entered.connect(func(): _show_tooltip(tip, pos))
	btn.mouse_exited.connect(_hide_tooltip)
	btn.pressed.connect(func(): _on_node_clicked(ks_name, node_name))
	canvas.add_child(btn)

func _node_hex(pos: Vector2, radius: float, category_color: Color, node_name: String, node_data: Dictionary, ks_data: Dictionary, ks_name: String) -> void:
	var purchased = node_data.get("purchased", false)
	var cost = node_data.get("cost", 1)
	var ks_unlocked = ks_data.get("unlocked", false)
	var spent = ks_data.get("points_spent", 0)
	var max_pts = ks_data.get("points_max", 10)
	var remaining = max_pts - spent
	var xp_type = ks_data.get("xp_type", "Combat XP")
	var available_xp = main.xp_pools.get(xp_type, 0)
	var affordable = ks_unlocked and not purchased and remaining >= cost and available_xp >= cost

	var display_color: Color
	var fill_alpha: float
	var border_width: float
	if not ks_unlocked:
		display_color = LOCKED_GREY
		fill_alpha = 0.06
		border_width = 1.5
	elif purchased:
		display_color = category_color
		fill_alpha = 0.5
		border_width = 3.0
	elif affordable:
		display_color = category_color
		fill_alpha = 0.16
		border_width = 2.5
	else:
		display_color = category_color
		fill_alpha = 0.08
		border_width = 1.5

	var pts = _hex_points(pos, radius)
	var poly = Polygon2D.new()
	poly.polygon = pts
	poly.color = Color(display_color.r, display_color.g, display_color.b, fill_alpha)
	canvas.add_child(poly)

	var border = Line2D.new()
	var bpts = pts
	bpts.append(pts[0])
	border.points = bpts
	border.default_color = display_color if (purchased or (ks_unlocked and affordable)) else Color(display_color.r, display_color.g, display_color.b, 0.5)
	border.width = border_width
	canvas.add_child(border)

	if purchased:
		var glow = Line2D.new()
		glow.points = border.points
		glow.default_color = Color(display_color.r, display_color.g, display_color.b, 0.3)
		glow.width = 8.0
		canvas.add_child(glow)

	var num_lbl = Label.new()
	num_lbl.text = str(cost)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num_lbl.position = pos - Vector2(radius, radius * 0.5)
	num_lbl.size = Vector2(radius * 2, radius)
	num_lbl.add_theme_font_size_override("font_size", 18)
	var num_color = display_color if ks_unlocked else Color(0.6, 0.6, 0.6)
	num_lbl.add_theme_color_override("font_color", num_color)
	num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(num_lbl)

	if purchased:
		var tag_lbl = Label.new()
		tag_lbl.text = "OWNED"
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag_lbl.position = pos - Vector2(radius, -radius * 0.15)
		tag_lbl.size = Vector2(radius * 2, 16)
		tag_lbl.add_theme_font_size_override("font_size", 9)
		tag_lbl.add_theme_color_override("font_color", OWNED_TAG_COLOR)
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(tag_lbl)

	var btn = Button.new()
	btn.position = pos - Vector2(radius, radius)
	btn.size = Vector2(radius * 2, radius * 2)
	btn.focus_mode = Control.FOCUS_NONE
	var blank = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", blank)
	btn.add_theme_stylebox_override("hover", blank)
	btn.add_theme_stylebox_override("pressed", blank)
	btn.add_theme_stylebox_override("focus", blank)
	btn.modulate.a = 0.0
	var tip = node_name + "\nGrants: +" + str(node_data.get("amount", 0)) + " " + node_data.get("stat", "")
	tip += "\nCost: " + str(cost) + " " + xp_type
	if not ks_unlocked:
		tip += "\n[ Keystone locked ]"
	elif purchased:
		tip += "\n[ OWNED ]"
	elif remaining < cost:
		tip += "\n[ Not enough room left in keystone -- " + str(remaining) + " remaining ]"
	elif available_xp < cost:
		tip += "\n[ Not enough " + xp_type + " -- have " + str(available_xp) + ", need " + str(cost) + " ]"
	btn.mouse_entered.connect(func(): _show_tooltip(tip, pos))
	btn.mouse_exited.connect(_hide_tooltip)
	btn.pressed.connect(func(): _on_node_clicked(ks_name, node_name))
	canvas.add_child(btn)

func _hex_points(center: Vector2, radius: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(6):
		var angle = PI / 6.0 + (TAU / 6.0) * i
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts

# ============================================================
# INTERACTION
# ============================================================

func _on_keystone_clicked(ks_name: String) -> void:
	selected_ks = ks_name
	selected_node = ""
	var prof_data = GameData.novice_professions.get("Street Thug", {})
	var ks_data = prof_data.get("keystones", {}).get(ks_name, {})
	var col = COLORS.get(ks_name, Color.WHITE)
	popup_title.text = ks_name.to_upper()
	popup_title.modulate = col

	var unlocked = ks_data.get("unlocked", false)
	var spent = ks_data.get("points_spent", 0)
	var max_pts = ks_data.get("points_max", 10)
	var xp_cost = ks_data.get("xp_cost", 10)
	var xp_type = ks_data.get("xp_type", "Combat XP")
	var current_xp = main.xp_pools.get(xp_type, 0)

	if unlocked:
		popup_body.text = "Keystone unlocked.\nPoints spent: " + str(spent) + " / " + str(max_pts) + "\n\nClick a node to purchase it."
		popup_cost_label.text = ""
		popup_buy_btn.visible = false
	else:
		popup_body.text = "Unlock this keystone to begin training.\n\nOnce unlocked you can spend up to " + str(max_pts) + " points across " + str(ks_data.get("nodes", {}).size()) + " nodes."
		popup_cost_label.text = "Unlock cost: " + str(xp_cost) + " " + xp_type + "  (You have: " + str(current_xp) + ")"
		popup_buy_btn.text = "Unlock Keystone"
		popup_buy_btn.visible = true
		popup_buy_btn.disabled = current_xp < xp_cost

	popup_panel.visible = true

func _on_node_clicked(ks_name: String, node_name: String) -> void:
	selected_ks = ks_name
	selected_node = node_name
	var prof_data = GameData.novice_professions.get("Street Thug", {})
	var ks_data = prof_data.get("keystones", {}).get(ks_name, {})
	var node_data = ks_data.get("nodes", {}).get(node_name, {})
	var col = COLORS.get(ks_name, Color.WHITE)

	popup_title.text = node_name
	popup_title.modulate = col

	var purchased = node_data.get("purchased", false)
	var cost = node_data.get("cost", 1)
	var ks_unlocked = ks_data.get("unlocked", false)
	var spent = ks_data.get("points_spent", 0)
	var max_pts = ks_data.get("points_max", 10)
	var remaining = max_pts - spent
	var xp_type = ks_data.get("xp_type", "Combat XP")
	var available_xp = main.xp_pools.get(xp_type, 0)

	var desc = ""
	if node_data.get("type", "") == "ability":
		desc = "Ability: " + node_data.get("ability", node_name)
		var upgrade = node_data.get("mastery_upgrade", "")
		if upgrade != "":
			desc += "\n\nMastery upgrade:\n" + upgrade
	else:
		desc = "Grants: +" + str(node_data.get("amount", 0)) + " " + node_data.get("stat", "")

	if purchased:
		desc += "\n\n[ PURCHASED ]"
	popup_body.text = desc

	if not ks_unlocked:
		popup_cost_label.text = "Unlock the " + ks_name + " keystone first."
		popup_buy_btn.visible = false
	elif purchased:
		popup_cost_label.text = "Already purchased."
		popup_buy_btn.visible = false
	elif remaining < cost:
		popup_cost_label.text = "No room left in this keystone. " + str(remaining) + " remaining, need " + str(cost) + "."
		popup_buy_btn.visible = false
	elif available_xp < cost:
		popup_cost_label.text = "Not enough " + xp_type + " earned yet. You have " + str(available_xp) + ", need " + str(cost) + "."
		popup_buy_btn.visible = false
	else:
		popup_cost_label.text = "Cost: " + str(cost) + " " + xp_type + "   --   " + str(remaining) + " remaining in keystone   --   " + str(available_xp) + " " + xp_type + " available"
		popup_buy_btn.text = "Purchase Node"
		popup_buy_btn.visible = true
		popup_buy_btn.disabled = false

	popup_panel.visible = true

func _on_buy_pressed() -> void:
	var prof_data = GameData.novice_professions.get("Street Thug", {})
	var keystones = prof_data.get("keystones", {})

	if selected_node == "":
		var ks_data = keystones.get(selected_ks, {})
		var xp_type = ks_data.get("xp_type", "Combat XP")
		var xp_cost = ks_data.get("xp_cost", 10)
		if main.xp_pools.get(xp_type, 0) < xp_cost:
			return
		main.xp_pools[xp_type] -= xp_cost
		ks_data["unlocked"] = true
		main._show_combat_message(selected_ks + " keystone unlocked!")
	else:
		var ks_data = keystones.get(selected_ks, {})
		var node_data = ks_data.get("nodes", {}).get(selected_node, {})
		var cost = node_data.get("cost", 1)
		var spent = ks_data.get("points_spent", 0)
		if spent + cost > ks_data.get("points_max", 10):
			return
		var xp_type = ks_data.get("xp_type", "Combat XP")
		if main.xp_pools.get(xp_type, 0) < cost:
			return
		main.xp_pools[xp_type] -= cost
		node_data["purchased"] = true
		ks_data["points_spent"] = spent + cost
		if node_data.get("type", "") == "ability":
			main._show_combat_message("Learned: " + node_data.get("ability", selected_node) + "!")
		else:
			main._show_combat_message("+" + str(node_data.get("amount", 0)) + " " + node_data.get("stat", ""))
		_check_mastery(selected_ks, ks_data)

	popup_panel.visible = false
	_hide_tooltip()
	_rebuild_graph()

func _check_mastery(ks_name: String, ks_data: Dictionary) -> void:
	if ks_data.get("points_spent", 0) < ks_data.get("points_max", 10):
		return
	for node_name in ks_data.get("nodes", {}).keys():
		var nd = ks_data["nodes"][node_name]
		if nd.get("type", "") == "ability" and nd.get("purchased", false):
			var upgrade = nd.get("mastery_upgrade", "")
			if upgrade != "":
				main._show_combat_message(node_name + " upgraded: " + upgrade)
	main._show_combat_message(ks_name + " keystone mastered!")

# ============================================================
# HUD
# ============================================================

func _refresh() -> void:
	_update_hud()

func _update_hud() -> void:
	hud_xp.text = "Combat XP: " + str(main.xp_pools.get("Combat XP", 0)) + "     Crafting XP: " + str(main.xp_pools.get("Crafting XP", 0))

	var prof_data = GameData.novice_professions.get("Street Thug", {})
	var keystones = prof_data.get("keystones", {})
	var parts: Array = []
	for ks_name in ["Melee", "Ranged", "Crafting", "Auxiliary"]:
		if not keystones.has(ks_name):
			continue
		var ks_data = keystones[ks_name]
		if ks_data.get("unlocked", false):
			parts.append(ks_name + ": " + str(ks_data.get("points_spent", 0)) + "/" + str(ks_data.get("points_max", 0)))
		else:
			parts.append(ks_name + ": locked")
	hud_status.text = "   |   ".join(parts)

# ============================================================
# HELPERS
# ============================================================

func _flat_style(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	return s
