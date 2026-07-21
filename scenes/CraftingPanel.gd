extends Node

# ============================================================
# CraftingPanel.gd -- blueprint crafting UI
# Phases: 3c blueprint selection and material slots
#         4  experimentation (risk stance, point allocation, results)
#         5  mod sockets reported on the finished item
# ============================================================
# Built entirely in code, mirroring KeystoneViewer's pattern: main.gd
# instantiates this, hands it a parent Control, and it builds itself.
#
# Reads BLUEPRINTS from CraftingData and material batches from main. All
# state changes go through main._perform_craft(), which validates, consumes
# materials and grants the finished item -- this file never mutates state
# directly.
#
# NOTE: this script extends Node, NOT CanvasItem, so CanvasItem-only calls
# such as get_viewport_rect() are unavailable here. Sizes come from the
# parent Control.
# ============================================================

var main

var root: Control
var blueprint_list: VBoxContainer
var slot_container: VBoxContainer
var materials_list: VBoxContainer
var preview_label: Label
var craft_button: Button
var status_label: Label

var selected_blueprint_id: String = ""
# slot_id -> batch_id
var selections: Dictionary = {}

# --- Phase 4: experimentation ---
# category_id -> points allocated this craft.
var allocation: Dictionary = {}
var selected_risk_mode: String = CraftingData.DEFAULT_RISK_MODE
var available_points: int = 0
var points_breakdown: Dictionary = {}
# Results of the LAST craft, shown until the next one.
var last_results: Dictionary = {}
var last_socket_count: int = 0
var last_socket_tags: Array = []

var exp_container: VBoxContainer
var points_label: Label
var risk_buttons: Dictionary = {}
var results_label: Label

const PANEL_BG := Color(0.07, 0.08, 0.10, 0.96)
const ACCENT := Color(0.85, 0.62, 0.22)
const TEXT_DIM := Color(0.62, 0.66, 0.72)
const TEXT_OK := Color(0.55, 0.85, 0.55)
const TEXT_BAD := Color(0.90, 0.45, 0.40)


func setup(parent: Control) -> void:
	_build_ui(parent)
	refresh()


func _build_ui(parent: Control) -> void:
	root = parent

	# LAYOUT NOTE -- read before changing anything here.
	# Two earlier versions of this failed:
	#   1. absolute pixel offsets measured up from the bottom of the
	#      screen -- broke whenever the viewport was not the exact height
	#      they assumed, pushing the Craft button off-screen;
	#   2. containers filling the WHOLE screen -- they expand to fill, so
	#      sparse content got smeared across 1080px with huge dead gaps.
	# The fix is a FIXED-SIZE CENTERED window. Content sizes to the
	# window, not to the monitor. Do not make this full-screen again.
	# A third column (carried materials) was added. Widening the window to
	# fit it pushed the column off-screen on narrower viewports, so the
	# window stays at a size that fits and the columns are narrower
	# instead. Still a FIXED centered window -- do not make this
	# full-screen, and do not widen past what the viewport can show.
	var PANEL_W := 1180
	var PANEL_H := 764

	var backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.02, 0.03, 0.93)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.offset_right = 0.0
	backdrop.offset_bottom = 0.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	# --- the window itself, centred in whatever viewport we get ---
	var frame = PanelContainer.new()
	frame.anchor_left = 0.5
	frame.anchor_top = 0.5
	frame.anchor_right = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -PANEL_W / 2.0
	frame.offset_top = -PANEL_H / 2.0
	frame.offset_right = PANEL_W / 2.0
	frame.offset_bottom = PANEL_H / 2.0
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = PANEL_BG
	frame_style.border_color = Color(0.35, 0.28, 0.16)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(6)
	frame_style.set_content_margin_all(14)
	frame.add_theme_stylebox_override("panel", frame_style)
	root.add_child(frame)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	frame.add_child(outer)

	# --- header row ---
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	outer.add_child(header)

	var title = Label.new()
	title.text = "CRAFTING"
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", TEXT_DIM)
	header.add_child(status_label)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 34)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	# --- body: two columns ---
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	outer.add_child(body)

	# ---------- LEFT ----------
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(230, 0)
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left_col)

	left_col.add_child(_section_label("Blueprints"))

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_stretch_ratio = 2.0
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(left_scroll)

	blueprint_list = VBoxContainer.new()
	blueprint_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(blueprint_list)

	left_col.add_child(_section_label("Last Craft"))

	var results_scroll = ScrollContainer.new()
	results_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_scroll.size_flags_stretch_ratio = 1.0
	results_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(results_scroll)

	results_label = Label.new()
	results_label.custom_minimum_size = Vector2(215, 0)
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_label.add_theme_font_size_override("font_size", 12)
	results_label.add_theme_color_override("font_color", TEXT_DIM)
	results_scroll.add_child(results_label)

	# ---------- RIGHT ----------
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_col)

	right_col.add_child(_section_label("Materials"))

	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Materials needs more room than experimentation -- three slots with
	# their "accepts" lines run longer than five category rows.
	right_scroll.size_flags_stretch_ratio = 4.0
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_col.add_child(right_scroll)

	slot_container = VBoxContainer.new()
	slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(slot_container)

	_build_experimentation_ui(right_col)

	preview_label = Label.new()
	preview_label.custom_minimum_size = Vector2(0, 42)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.add_theme_font_size_override("font_size", 12)
	preview_label.add_theme_color_override("font_color", TEXT_DIM)
	right_col.add_child(preview_label)

	# ---------- CARRIED MATERIALS ----------
	# Material batches live in their own store (they carry quality, trait,
	# instability and provenance, so they are not plain inventory stacks).
	# Before this column they were only visible inside a slot dropdown,
	# which made scavenging feel like it produced nothing.
	var mats_col = VBoxContainer.new()
	mats_col.custom_minimum_size = Vector2(250, 0)
	mats_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(mats_col)

	mats_col.add_child(_section_label("Carried Materials"))

	var mats_scroll = ScrollContainer.new()
	mats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mats_col.add_child(mats_scroll)

	materials_list = VBoxContainer.new()
	materials_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	materials_list.add_theme_constant_override("separation", 8)
	mats_scroll.add_child(materials_list)

	craft_button = Button.new()
	craft_button.text = "Craft"
	craft_button.custom_minimum_size = Vector2(180, 36)
	craft_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	craft_button.pressed.connect(_on_craft_pressed)
	right_col.add_child(craft_button)


# Every section heading looks the same.
func _section_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", ACCENT)
	return l


# ------------------------------------------------------------
# Refresh
# ------------------------------------------------------------

func refresh() -> void:
	_refresh_materials_list()
	_refresh_blueprint_list()
	_refresh_slots()
	_refresh_experimentation()
	_refresh_preview()
	_refresh_results()
	_refresh_status()


func _refresh_status() -> void:
	if status_label == null:
		return
	var count = 0
	for bid in main.material_batches.keys():
		count += int(main.material_batches[bid].get("amount", 0))
	status_label.text = "Materials carried: " + str(count) + " units across " + str(main.material_batches.size()) + " batches"


func _refresh_blueprint_list() -> void:
	if blueprint_list == null:
		return
	for child in blueprint_list.get_children():
		child.queue_free()

	var ids = CraftingData.BLUEPRINTS.keys()
	ids.sort()
	for bp_id in ids:
		var bp = CraftingData.BLUEPRINTS[bp_id]
		var btn = Button.new()
		var craftable = _blueprint_is_craftable(String(bp_id))
		btn.text = String(bp.get("display_name", bp_id)) + ("" if craftable else "  (no materials)")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(290, 34)
		if String(bp_id) == selected_blueprint_id:
			btn.add_theme_color_override("font_color", ACCENT)
		elif not craftable:
			btn.add_theme_color_override("font_color", TEXT_DIM)
		btn.pressed.connect(_on_blueprint_selected.bind(String(bp_id)))
		blueprint_list.add_child(btn)


# True when every slot has at least one usable batch in the player's store.
func _blueprint_is_craftable(bp_id: String) -> bool:
	var bp = CraftingData.get_blueprint(bp_id)
	for slot in bp.get("material_slots", []):
		if main._batches_for_slot(slot).is_empty():
			return false
	return true


func _refresh_slots() -> void:
	if slot_container == null:
		return
	for child in slot_container.get_children():
		child.queue_free()

	if selected_blueprint_id == "":
		var hint = Label.new()
		hint.text = "Select a blueprint on the left."
		hint.add_theme_color_override("font_color", TEXT_DIM)
		slot_container.add_child(hint)
		return

	var bp = CraftingData.get_blueprint(selected_blueprint_id)
	for slot in bp.get("material_slots", []):
		var slot_id = String(slot.get("slot_id", ""))
		var row = VBoxContainer.new()

		var head = Label.new()
		head.text = String(slot.get("slot_name", slot_id)) + "  --  needs " + str(int(slot.get("amount", 1))) + " unit(s)"
		head.add_theme_color_override("font_color", ACCENT)
		row.add_child(head)

		var accepts: Array = slot.get("accepts", [])
		var accepts_lbl = Label.new()
		accepts_lbl.text = "   accepts: " + ", ".join(accepts)
		accepts_lbl.add_theme_color_override("font_color", TEXT_DIM)
		row.add_child(accepts_lbl)

		var options = main._batches_for_slot(slot)
		if options.is_empty():
			# Distinguish "wrong material" from "right material, not enough".
			# _batches_for_slot requires ONE batch holding the full amount, so
			# a player can be carrying plenty of an accepted family spread
			# across small batches and still see nothing offered here. Saying
			# "nothing suitable carried" in that case is actively misleading.
			var needed_units = int(slot.get("amount", 1))
			var best_held := 0
			var best_name := ""
			var total_held := 0
			for bid in main.material_batches.keys():
				var b = main.material_batches[bid]
				if not accepts.has(String(b.get("family_id", ""))):
					continue
				var amt = int(b.get("amount", 0))
				total_held += amt
				if amt > best_held:
					best_held = amt
					best_name = String(b.get("display_name", "material"))

			var none = Label.new()
			none.add_theme_color_override("font_color", TEXT_BAD)
			if best_held <= 0:
				none.text = "   nothing suitable carried"
			elif total_held > best_held:
				none.text = ("   not enough in one batch -- best is " + best_name
					+ " (" + str(best_held) + " of " + str(needed_units) + " needed)"
					+ ", " + str(total_held) + " held across all batches")
			else:
				none.text = ("   not enough -- " + best_name + ": "
					+ str(best_held) + " of " + str(needed_units) + " needed")
			row.add_child(none)
		else:
			var picker = OptionButton.new()
			picker.custom_minimum_size = Vector2(420, 32)
			var chosen_index = 0
			for i in range(options.size()):
				var b = options[i]
				picker.add_item(
					String(b.get("display_name", "material"))
					+ "  (Q" + str(int(b.get("quality", 0)))
					+ ", " + str(int(b.get("amount", 0))) + " held)"
				)
				picker.set_item_metadata(i, String(b.get("batch_id", "")))
				if selections.get(slot_id, "") == String(b.get("batch_id", "")):
					chosen_index = i
			picker.select(chosen_index)
			# Keep the model in step with what is displayed.
			selections[slot_id] = String(picker.get_item_metadata(chosen_index))
			picker.item_selected.connect(_on_slot_choice.bind(slot_id, picker))
			row.add_child(picker)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		row.add_child(spacer)
		slot_container.add_child(row)


func _refresh_preview() -> void:
	if preview_label == null or craft_button == null:
		return

	if selected_blueprint_id == "":
		preview_label.text = ""
		craft_button.disabled = true
		return

	var selection = _build_selection()
	var problems = CraftingService.validate_selection(selected_blueprint_id, selection)
	if not problems.is_empty():
		preview_label.add_theme_color_override("font_color", TEXT_BAD)
		preview_label.text = "Cannot craft yet:\n- " + "\n- ".join(problems)
		craft_button.disabled = true
		return

	var potential = CraftingService.compute_material_potential(selected_blueprint_id, selection)
	var tier_id = CraftingData.quality_tier_for(potential)
	var bp = CraftingData.get_blueprint(selected_blueprint_id)
	preview_label.add_theme_color_override("font_color", TEXT_OK)
	preview_label.text = (
		"Ready to craft: " + String(bp.get("display_name", selected_blueprint_id))
		+ "\nMaterial potential: " + str(int(round(potential))) + " / 100"
		+ "   (" + CraftingData.quality_tier_name(tier_id) + ")"
		+ "\nBetter materials raise this ceiling; experimentation below decides how much you realise."
	)
	craft_button.disabled = false


# Resolves the stored batch_id choices into the actual batch dictionaries
# CraftingService expects.
func _build_selection() -> Dictionary:
	var out: Dictionary = {}
	if selected_blueprint_id == "":
		return out
	var bp = CraftingData.get_blueprint(selected_blueprint_id)
	for slot in bp.get("material_slots", []):
		var slot_id = String(slot.get("slot_id", ""))
		var batch_id = String(selections.get(slot_id, ""))
		if batch_id != "" and main.material_batches.has(batch_id):
			out[slot_id] = main.material_batches[batch_id]
	return out


# ------------------------------------------------------------
# Signals
# ------------------------------------------------------------

func _on_blueprint_selected(bp_id: String) -> void:
	# Categories differ per blueprint, so a stale allocation would be
	# meaningless (and could exceed the new budget).
	allocation.clear()
	last_results.clear()
	last_socket_count = 0
	last_socket_tags = []
	selected_blueprint_id = bp_id
	selections.clear()
	refresh()


func _on_slot_choice(index: int, slot_id: String, picker: OptionButton) -> void:
	selections[slot_id] = String(picker.get_item_metadata(index))
	_refresh_preview()


func _on_craft_pressed() -> void:
	var selection = _build_selection()
	var crafted = main._perform_craft(selected_blueprint_id, selection, allocation, selected_risk_mode)
	if crafted.is_empty():
		refresh()
		return
	# Keep the results visible, then clear the allocation -- points are
	# generated fresh for each craft and do not carry over.
	last_results = crafted.get("experimentation_results", {})
	last_socket_count = int(crafted.get("socket_count", 0))
	last_socket_tags = crafted.get("socket_tags", [])
	allocation.clear()
	# Materials were consumed, so previous choices may no longer be valid.
	selections.clear()
	refresh()


func _on_close() -> void:
	if main != null:
		main.close_crafting_panel()


# ============================================================
# EXPERIMENTATION UI (Phase 4)
# ============================================================
# Sits between the material slots and the craft button. Three parts:
# the risk stance, the point budget (with its breakdown, so the player
# can see WHY they have the points they have), and per-category
# allocation rows.

func _build_experimentation_ui(col: VBoxContainer) -> void:
	col.add_child(_section_label("Experimentation"))

	points_label = Label.new()
	points_label.add_theme_color_override("font_color", TEXT_DIM)
	points_label.mouse_filter = Control.MOUSE_FILTER_STOP
	points_label.tooltip_text = ("Experimentation points to spend on this craft.\n\n"
		+ "More points come from knowing the blueprint well, from materials\n"
		+ "that suit what you are making, and later from workshops, tools\n"
		+ "and crafting keystones.\n\n"
		+ "Unspent points are wasted -- they do not carry to the next craft.")
	col.add_child(points_label)

	# --- risk stance ---
	var risk_row = HBoxContainer.new()
	risk_row.add_theme_constant_override("separation", 8)
	col.add_child(risk_row)
	for risk_id in ["stable", "standard", "aggressive"]:
		var mode = CraftingData.get_risk_mode(risk_id)
		var btn = Button.new()
		btn.text = String(mode.get("display_name", risk_id))
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(112, 30)
		btn.tooltip_text = (String(mode.get("display_name", risk_id)) + "\n\n"
			+ String(mode.get("description", "")) + "\n\n"
			+ "On failure: wasted points, "
			+ ("no risk of a flaw" if float(mode.get("instability_chance", 0.0)) <= 0.0
				else str(int(round(float(mode.get("instability_chance", 0.0)) * 100.0))) + "% chance of a permanent flaw")
			+ ", and reduced socket odds.")
		btn.pressed.connect(_on_risk_selected.bind(risk_id))
		risk_row.add_child(btn)
		risk_buttons[risk_id] = btn

	# --- per-category allocation rows ---
	var exp_scroll = ScrollContainer.new()
	exp_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_scroll.size_flags_stretch_ratio = 2.0
	exp_scroll.custom_minimum_size = Vector2(0, 150)
	exp_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(exp_scroll)

	exp_container = VBoxContainer.new()
	exp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_scroll.add_child(exp_container)


func _on_risk_selected(risk_id: String) -> void:
	selected_risk_mode = risk_id
	_refresh_experimentation()


# Adds or removes a point, clamped to what is actually available.
func _on_allocate(category_id: String, delta: int) -> void:
	var current = int(allocation.get(category_id, 0))
	var spent := 0
	for cid in allocation.keys():
		spent += int(allocation[cid])
	var next = current + delta
	if next < 0:
		next = 0
	if delta > 0 and spent >= available_points:
		return
	allocation[category_id] = next
	_refresh_experimentation()


func _refresh_experimentation() -> void:
	if exp_container == null:
		return

	for child in exp_container.get_children():
		child.queue_free()

	for risk_id in risk_buttons.keys():
		risk_buttons[risk_id].button_pressed = (risk_id == selected_risk_mode)

	if selected_blueprint_id == "":
		points_label.text = "Select a blueprint."
		return

	# Points depend on the materials chosen, so recompute on every refresh.
	var selection = _build_selection()
	var pts = CraftingService.generate_experimentation_points(selected_blueprint_id, selection, main.crafting_profile)
	available_points = int(pts["total"])
	points_breakdown = pts["breakdown"]

	var spent := 0
	for cid in allocation.keys():
		spent += int(allocation[cid])

	var parts: Array = []
	for k in points_breakdown.keys():
		if int(points_breakdown[k]) > 0:
			parts.append(String(k) + " +" + str(int(points_breakdown[k])))
	points_label.text = ("Points: " + str(spent) + " / " + str(available_points)
		+ "    (" + ", ".join(parts) + ")")

	# The compatibility hint is a ratio measured against the weight of
	# EVERY slot, so a part-filled selection can never score well no
	# matter how good the chosen material is -- Piston Blade's binding
	# slot is only 0.15 of the recipe, so a perfect match there still
	# reads "do not help". Only show the hint once the selection is
	# COMPLETE, when the number actually means something.
	var has_materials := true
	var bp_for_hint = CraftingData.get_blueprint(selected_blueprint_id)
	for slot_def in bp_for_hint.get("material_slots", []):
		var sid = String(slot_def.get("slot_id", ""))
		if not selection.has(sid) or (selection[sid] as Dictionary).is_empty():
			has_materials = false
			break

	for category_id in CraftingData.categories_for_blueprint(selected_blueprint_id):
		var cat = CraftingData.get_category(category_id)
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var tip = CraftingData.category_tooltip(category_id)

		var name_lbl = Label.new()
		name_lbl.text = String(cat.get("display_name", category_id))
		name_lbl.custom_minimum_size = Vector2(150, 0)
		name_lbl.tooltip_text = tip
		# Labels default to MOUSE_FILTER_IGNORE, which means they never
		# receive hover and their tooltip never appears. This is why the
		# category tooltips were silently doing nothing.
		name_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(name_lbl)

		var minus = Button.new()
		minus.text = "-"
		minus.custom_minimum_size = Vector2(32, 0)
		minus.tooltip_text = tip
		minus.pressed.connect(_on_allocate.bind(category_id, -1))
		row.add_child(minus)

		var count = Label.new()
		count.text = str(int(allocation.get(category_id, 0)))
		count.custom_minimum_size = Vector2(34, 0)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(count)

		var plus = Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(32, 0)
		plus.tooltip_text = tip
		plus.disabled = spent >= available_points
		plus.pressed.connect(_on_allocate.bind(category_id, 1))
		row.add_child(plus)

		# Material compatibility hint. Only shown once materials have
		# actually been chosen -- with empty slots every category would
		# read "materials do not help here", which looks like a warning
		# about a decision the player has not made yet.
		var hint = Label.new()
		hint.add_theme_font_size_override("font_size", 11)
		hint.mouse_filter = Control.MOUSE_FILTER_STOP
		hint.tooltip_text = tip
		if has_materials:
			var compat = CraftingService.material_compatibility(selected_blueprint_id, selection, category_id)
			if compat >= 0.66:
				hint.text = "  materials suit this well"
				hint.add_theme_color_override("font_color", TEXT_OK)
			elif compat >= 0.33:
				hint.text = "  materials partly suit this"
				hint.add_theme_color_override("font_color", TEXT_DIM)
			else:
				hint.text = "  materials do not help here"
				hint.add_theme_color_override("font_color", TEXT_BAD)
		else:
			hint.text = ""
		row.add_child(hint)

		exp_container.add_child(row)


# Renders the outcome of the last craft: each category's tier, plus any
# flaw the item picked up from a failure.
func _refresh_results() -> void:
	if results_label == null:
		return
	if last_results.is_empty() and last_socket_count <= 0:
		results_label.text = ""
		return

	var lines: Array = ["Last craft:"]
	if last_socket_count > 0:
		var tag_names: Array = []
		for t in last_socket_tags:
			tag_names.append(String(CraftingData.get_socket_tag(String(t)).get("display_name", t)))
		lines.append("  Sockets: " + str(last_socket_count)
			+ ("  [" + ", ".join(tag_names) + "]" if not tag_names.is_empty() else ""))
	var flaws: Array = []
	for cid in last_results.keys():
		var r = last_results[cid]
		var cat_name = String(CraftingData.get_category(cid).get("display_name", cid))
		lines.append("  " + cat_name + ": " + String(r.get("tier_name", "?"))
			+ " (" + str(int(r.get("allocated_points", 0))) + " pts)")
		var flaw = String(r.get("gained_instability", ""))
		if flaw != "":
			flaws.append(String(CraftingData.get_instability(flaw).get("display_name", flaw)))
	if not flaws.is_empty():
		lines.append("  Gained flaw: " + ", ".join(flaws))
	results_label.text = "\n".join(lines)


# Lists every material batch the player is carrying, with the provenance
# that makes a batch more than a stack: quality, trait, flaw and where it
# came from. Read-only -- selection still happens in the slot dropdowns.
func _refresh_materials_list() -> void:
	if materials_list == null:
		return
	for child in materials_list.get_children():
		child.queue_free()

	var batches = main.material_batches
	if batches.is_empty():
		var empty = Label.new()
		empty.text = "Nothing carried.\n\nScavenge the alley dumpster to recover materials."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(235, 0)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		materials_list.add_child(empty)
		return

	# Best quality first -- that is what a crafter actually looks for.
	var ids = batches.keys()
	ids.sort_custom(func(a, b): return int(batches[a].get("quality", 0)) > int(batches[b].get("quality", 0)))

	for bid in ids:
		var b: Dictionary = batches[bid]
		var entry = VBoxContainer.new()
		entry.add_theme_constant_override("separation", 0)

		var name_lbl = Label.new()
		name_lbl.text = String(b.get("display_name", "Material"))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(235, 0)
		name_lbl.add_theme_color_override("font_color", ACCENT)
		entry.add_child(name_lbl)

		var qty_lbl = Label.new()
		qty_lbl.text = "   Quality " + str(int(b.get("quality", 0))) + "/100     x" + str(int(b.get("amount", 0))) + " units"
		qty_lbl.add_theme_font_size_override("font_size", 12)
		qty_lbl.add_theme_color_override("font_color", TEXT_OK)
		entry.add_child(qty_lbl)

		var trait_id = String(b.get("primary_trait_id", ""))
		if trait_id != "":
			var tl = Label.new()
			tl.text = "   Trait: " + String(CraftingData.get_trait(trait_id).get("display_name", trait_id))
			tl.add_theme_font_size_override("font_size", 12)
			tl.add_theme_color_override("font_color", TEXT_DIM)
			entry.add_child(tl)

		var flaw_id = String(b.get("instability_id", ""))
		if flaw_id != "":
			var fl = Label.new()
			fl.text = "   Flaw: " + String(CraftingData.get_instability(flaw_id).get("display_name", flaw_id))
			fl.add_theme_font_size_override("font_size", 12)
			fl.add_theme_color_override("font_color", TEXT_BAD)
			entry.add_child(fl)

		var origin = String(b.get("floor_id", ""))
		if origin != "":
			var ol = Label.new()
			ol.text = "   Source: " + origin.capitalize()
			ol.add_theme_font_size_override("font_size", 11)
			ol.add_theme_color_override("font_color", TEXT_DIM)
			entry.add_child(ol)

		materials_list.add_child(entry)
