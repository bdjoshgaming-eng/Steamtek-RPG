extends Node

# ============================================================
# Quest.gd
# ============================================================
# Central quest management system. Pulled out of main.gd so all
# quest logic, state, and data lives in one place. Designed to
# handle any number of quests from a data table rather than
# hardcoding each one -- adding a new quest is data, not new code.
#
# Instantiated by main.gd's _build_quest_system(), which sets
# `main` below before calling setup(). Hook calls from main.gd
# (on_enemy_killed, on_dumpster_looted, etc.) feed into here.
#
# QUEST DATA SCHEMA:
# Each quest entry in QUEST_DEFINITIONS is keyed by a quest_id string.
#   "title"          String  -- display name
#   "accept_text"    String  -- shown when player accepts quest
#   "complete_text"  String  -- shown on turn-in
#   "source_node"    String  -- unique node name (%QuestBook etc)
#   "interact_range" float   -- how close player must be to interact
#   "reward_cogs"    int     -- cogs given on completion
#   "objectives"     Dict    -- see below
#
# OBJECTIVES SCHEMA (each key is an objective_id):
#   "type"   String  -- "kill_enemies" | "loot_dumpster" | more later
#   "goal"   int     -- how many needed (1 for boolean objectives)
#   "label"  String  -- shown in progress messages
# ============================================================

var main

# --- Quest Definitions (data table) ---
const QUEST_DEFINITIONS: Dictionary = {
	"notice_in_the_dark": {
		"title": "Notice in the Dark",
		"popup_text": "Defeat 2 enemies and loot the dumpster.\n\nReward: 235 Cogs",
		"accept_text": "Quest accepted: Defeat 2 enemies and loot the dumpster. Return here when done.",
		"complete_text": "Quest complete! You received 235 Cogs.",
		"source_node": "QuestBook",
		"interact_range": 150.0,
		"reward_cogs": 235,
		"objectives": {
			"kill_enemies": {
				"type": "kill_enemies",
				"goal": 2,
				"label": "enemies defeated"
			},
			"loot_dumpster": {
				"type": "loot_dumpster",
				"goal": 1,
				"label": "dumpster looted"
			}
		}
	}
}

# --- Runtime State ---
# quest_states[quest_id] = "NOT_STARTED" | "IN_PROGRESS" | "COMPLETE"
# quest_progress[quest_id][objective_id] = int (current count)
var quest_states: Dictionary = {}
var quest_progress: Dictionary = {}

# Dialogue popup -- built once, reused for both accept and turn-in.
# Button rows are swapped based on quest state.
var quest_popup: Control = null
var quest_popup_title: Label = null
var quest_popup_body: Label = null
var quest_popup_accept_btn: Button = null
var quest_popup_decline_btn: Button = null
var quest_popup_complete_btn: Button = null
var quest_popup_close_btn: Button = null
var quest_popup_pending_quest_id: String = ""

func setup() -> void:
	for quest_id in QUEST_DEFINITIONS.keys():
		quest_states[quest_id] = "NOT_STARTED"
		quest_progress[quest_id] = {}
		for obj_id in QUEST_DEFINITIONS[quest_id]["objectives"].keys():
			quest_progress[quest_id][obj_id] = 0
	_build_quest_popup()

func _build_quest_popup() -> void:
	quest_popup = Control.new()
	quest_popup.name = "QuestDialoguePopup"
	quest_popup.anchor_right = 1
	quest_popup.anchor_bottom = 1
	quest_popup.visible = false
	quest_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.get_node("UILayer").add_child(quest_popup)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.anchor_right = 1
	backdrop.anchor_bottom = 1
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_popup.add_child(backdrop)

	var panel = Panel.new()
	panel.position = Vector2(560, 280)
	panel.size = Vector2(400, 300)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", main._make_flat_style(Color(0.043, 0.086, 0.086)))
	quest_popup.add_child(panel)

	var icon_label = Label.new()
	icon_label.text = "[ NOTICE ]"
	icon_label.position = Vector2(20, 12)
	icon_label.modulate = Color(0.85, 0.7, 0.3)
	icon_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(icon_label)

	quest_popup_title = Label.new()
	quest_popup_title.position = Vector2(20, 32)
	quest_popup_title.size = Vector2(360, 30)
	quest_popup_title.modulate = Color(0.6, 0.9, 0.9)
	quest_popup_title.add_theme_font_size_override("font_size", 16)
	panel.add_child(quest_popup_title)

	var divider = ColorRect.new()
	divider.color = Color(0.2, 0.35, 0.35)
	divider.position = Vector2(20, 66)
	divider.size = Vector2(360, 1)
	panel.add_child(divider)

	quest_popup_body = Label.new()
	quest_popup_body.position = Vector2(20, 76)
	quest_popup_body.size = Vector2(360, 140)
	quest_popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	quest_popup_body.modulate = Color(0.85, 0.9, 0.9)
	panel.add_child(quest_popup_body)

	quest_popup_accept_btn = Button.new()
	quest_popup_accept_btn.text = "Accept"
	quest_popup_accept_btn.position = Vector2(20, 240)
	quest_popup_accept_btn.custom_minimum_size = Vector2(170, 40)
	quest_popup_accept_btn.focus_mode = Control.FOCUS_NONE
	quest_popup_accept_btn.pressed.connect(_on_quest_popup_accept)
	panel.add_child(quest_popup_accept_btn)

	quest_popup_decline_btn = Button.new()
	quest_popup_decline_btn.text = "Decline"
	quest_popup_decline_btn.position = Vector2(210, 240)
	quest_popup_decline_btn.custom_minimum_size = Vector2(170, 40)
	quest_popup_decline_btn.focus_mode = Control.FOCUS_NONE
	quest_popup_decline_btn.pressed.connect(_on_quest_popup_decline)
	panel.add_child(quest_popup_decline_btn)

	quest_popup_complete_btn = Button.new()
	quest_popup_complete_btn.text = "Complete"
	quest_popup_complete_btn.position = Vector2(20, 240)
	quest_popup_complete_btn.custom_minimum_size = Vector2(170, 40)
	quest_popup_complete_btn.focus_mode = Control.FOCUS_NONE
	quest_popup_complete_btn.pressed.connect(_on_quest_popup_complete)
	panel.add_child(quest_popup_complete_btn)

	quest_popup_close_btn = Button.new()
	quest_popup_close_btn.text = "Close"
	quest_popup_close_btn.position = Vector2(210, 240)
	quest_popup_close_btn.custom_minimum_size = Vector2(170, 40)
	quest_popup_close_btn.focus_mode = Control.FOCUS_NONE
	quest_popup_close_btn.pressed.connect(_on_quest_popup_close)
	panel.add_child(quest_popup_close_btn)

func _show_quest_popup(quest_id: String) -> void:
	var def = QUEST_DEFINITIONS[quest_id]
	quest_popup_pending_quest_id = quest_id
	quest_popup_title.text = def["title"]
	quest_popup.visible = true

	var state = quest_states[quest_id]
	if state == "NOT_STARTED":
		quest_popup_body.text = def.get("popup_text", def["accept_text"])
		quest_popup_accept_btn.visible = true
		quest_popup_decline_btn.visible = true
		quest_popup_complete_btn.visible = false
		quest_popup_close_btn.visible = false
	elif state == "IN_PROGRESS":
		var all_done = _all_objectives_met(quest_id)
		if all_done:
			quest_popup_body.text = "All objectives complete!\n\nReward: " + str(def["reward_cogs"]) + " Cogs"
		else:
			quest_popup_body.text = "Still in progress:\n" + _get_missing_text(quest_id) + "\n\nReturn when all done to collect your reward."
		quest_popup_accept_btn.visible = false
		quest_popup_decline_btn.visible = false
		quest_popup_complete_btn.visible = true
		quest_popup_complete_btn.disabled = not all_done
		quest_popup_complete_btn.modulate = Color(1, 1, 1) if all_done else Color(0.5, 0.5, 0.5)
		quest_popup_close_btn.visible = true

func _on_quest_popup_accept() -> void:
	quest_popup.visible = false
	if quest_popup_pending_quest_id == "":
		return
	var quest_id = quest_popup_pending_quest_id
	quest_popup_pending_quest_id = ""
	quest_states[quest_id] = "IN_PROGRESS"
	main._show_combat_message(QUEST_DEFINITIONS[quest_id]["accept_text"])

func _on_quest_popup_decline() -> void:
	quest_popup.visible = false
	quest_popup_pending_quest_id = ""
	main._show_combat_message("You closed the notice.")

func _on_quest_popup_complete() -> void:
	quest_popup.visible = false
	if quest_popup_pending_quest_id == "":
		return
	var quest_id = quest_popup_pending_quest_id
	quest_popup_pending_quest_id = ""
	if not _all_objectives_met(quest_id):
		return
	var def = QUEST_DEFINITIONS[quest_id]
	quest_states[quest_id] = "COMPLETE"
	main.cogs += def["reward_cogs"]
	main._update_cogs_display()
	main._show_combat_message(def["complete_text"])
	_on_quest_completed(quest_id)

func _on_quest_popup_close() -> void:
	quest_popup.visible = false
	quest_popup_pending_quest_id = ""

# --- Interaction ---
# Called by main._attempt_interact_quest_book() (and any future book node).
# Finds which quest, if any, is attached to the node the player just pressed E near.
func try_interact(source_node_name: String) -> void:
	for quest_id in QUEST_DEFINITIONS.keys():
		var def = QUEST_DEFINITIONS[quest_id]
		if def["source_node"] != source_node_name:
			continue
		var source_node = main.get_node_or_null("%" + source_node_name)
		if not source_node:
			push_warning("Quest: could not find node %" + source_node_name)
			continue
		var dist = main.player.global_position.distance_to(source_node.global_position)
		if dist > def["interact_range"]:
			main._show_combat_message("Move closer to read the notice.")
			return
		_interact_quest(quest_id)
		return

func _interact_quest(quest_id: String) -> void:
	match quest_states[quest_id]:
		"NOT_STARTED":
			_show_quest_popup(quest_id)
		"IN_PROGRESS":
			_show_quest_popup(quest_id)
		"COMPLETE":
			main._show_combat_message("You have already completed this quest.")

func _all_objectives_met(quest_id: String) -> bool:
	var def = QUEST_DEFINITIONS[quest_id]
	for obj_id in def["objectives"].keys():
		var obj = def["objectives"][obj_id]
		if quest_progress[quest_id][obj_id] < obj["goal"]:
			return false
	return true

func _get_missing_text(quest_id: String) -> String:
	var def = QUEST_DEFINITIONS[quest_id]
	var parts: Array = []
	for obj_id in def["objectives"].keys():
		var obj = def["objectives"][obj_id]
		var current = quest_progress[quest_id][obj_id]
		var goal = obj["goal"]
		if current < goal:
			parts.append(str(current) + "/" + str(goal) + " " + obj["label"])
	return ", ".join(parts)

func _get_progress_message(quest_id: String) -> String:
	var def = QUEST_DEFINITIONS[quest_id]
	if _all_objectives_met(quest_id):
		return "All objectives complete -- return to the book!"
	var parts: Array = []
	for obj_id in def["objectives"].keys():
		var obj = def["objectives"][obj_id]
		var current = quest_progress[quest_id][obj_id]
		var goal = obj["goal"]
		parts.append(str(current) + "/" + str(goal) + " " + obj["label"])
	return ", ".join(parts)

const QUEST_REPEAT_COOLDOWN_SEC = 300.0

func _on_quest_completed(quest_id: String) -> void:
	var source_node_name = QUEST_DEFINITIONS[quest_id]["source_node"]
	var visual = main.get_node_or_null("%" + source_node_name + "Visual")
	if visual:
		visual.color = Color(0.4, 0.4, 0.4)

	var timer = main.get_tree().create_timer(QUEST_REPEAT_COOLDOWN_SEC)
	timer.timeout.connect(func():
		quest_states[quest_id] = "NOT_STARTED"
		for obj_id in QUEST_DEFINITIONS[quest_id]["objectives"].keys():
			quest_progress[quest_id][obj_id] = 0
		if visual:
			visual.color = Color(0.85, 0.1, 0.1)
		main._show_combat_message("A new notice has appeared.")
	)

# --- Objective Hooks ---
# Called by main.gd when things happen in the world. Each hook checks
# all in-progress quests for matching objective types and advances them.

func on_enemy_killed() -> void:
	_advance_objective_type("kill_enemies", 1)

func on_dumpster_looted() -> void:
	_advance_objective_type("loot_dumpster", 1)

func _advance_objective_type(obj_type: String, amount: int) -> void:
	for quest_id in QUEST_DEFINITIONS.keys():
		if quest_states[quest_id] != "IN_PROGRESS":
			continue
		var def = QUEST_DEFINITIONS[quest_id]
		for obj_id in def["objectives"].keys():
			var obj = def["objectives"][obj_id]
			if obj["type"] != obj_type:
				continue
			var current = quest_progress[quest_id][obj_id]
			var goal = obj["goal"]
			if current >= goal:
				continue
			quest_progress[quest_id][obj_id] = min(current + amount, goal)
			main._show_combat_message("Quest: " + _get_progress_message(quest_id))

# --- Save / Load ---

func get_save_data() -> Dictionary:
	return {
		"quest_states": quest_states,
		"quest_progress": quest_progress
	}

func load_save_data(data: Dictionary) -> void:
	quest_states = data.get("quest_states", {})
	quest_progress = data.get("quest_progress", {})
	# Ensure any quests added since this save exist with default state
	for quest_id in QUEST_DEFINITIONS.keys():
		if not quest_states.has(quest_id):
			quest_states[quest_id] = "NOT_STARTED"
		if not quest_progress.has(quest_id):
			quest_progress[quest_id] = {}
			for obj_id in QUEST_DEFINITIONS[quest_id]["objectives"].keys():
				quest_progress[quest_id][obj_id] = 0
	# Re-apply any visual state changes for completed quests
	for quest_id in QUEST_DEFINITIONS.keys():
		if quest_states[quest_id] == "COMPLETE":
			_on_quest_completed(quest_id)
