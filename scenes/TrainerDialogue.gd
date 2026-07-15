extends Control

# ============================================================
# TrainerDialogue.gd
# ============================================================
# The SWG-style trainer popup, pulled out of main.gd (part of the
# ongoing split — see GameData.gd and TalentViewer.gd for earlier
# passes).
#
# UNLIKE the other panels (Talent Viewer, Ability Book, etc.), this
# one is NOT instantiated by main.gd — it's attached directly to the
# existing TrainerUI scene node (the one already built with
# DialogueLayout/TrainInfoLabel/TrainerOptions/TrainResultLabel
# children). One manual step is required in the Godot editor: select
# the TrainerUI node in the Scene tree and attach this script to it
# (right-click -> Attach Script -> select TrainerDialogue.gd). main.gd
# sets `main` on it (trainer_ui.main = self) right after that.
#
# Several things stayed in main.gd instead of moving here, since
# they're shared with the profession-selection flow and the legacy
# debug skill tree: professions_unlocked, has_chosen_starting_profession,
# xp_pools, trainers, active_trainer_index, trainer_dialogue_state,
# selected_profession, selected_path, _learn_trainer_profession(),
# _on_spend_point_pressed(), _is_prereq_met(), _get_box_cost(),
# _get_talent_box_label(), _get_points_available(), _points_pool_label().
# Every reference to those below is prefixed with "main." accordingly.
# ============================================================

var main

@onready var dialogue_layout: VBoxContainer = $DialogueLayout
@onready var train_info_label: Label = $DialogueLayout/TrainInfoLabel
@onready var trainer_options: VBoxContainer = $DialogueLayout/TrainerOptions
@onready var train_result_label: Label = $DialogueLayout/TrainResultLabel

var trainer_result_text: String = ""

func _ready() -> void:
	visible = false
	dialogue_layout.add_theme_constant_override("separation", 10)
	train_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	train_info_label.custom_minimum_size = Vector2(340, 0)

# --- Trainer Dialogue (popup, SWG-style) ---
# Replaces the old Tree/Button pane. Rather than a static UI layout that
# can overflow with long labels, this drives a single Panel through three
# states — GREETING, SKILL_LIST, CONFIRM — clearing and rebuilding the
# option buttons in trainer_options each time the state changes.

func _clear_trainer_options() -> void:
	for child in trainer_options.get_children():
		child.queue_free()

func _add_trainer_option(label_text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = label_text
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callback)
	trainer_options.add_child(btn)

func _refresh_trainer_dialogue() -> void:
	_clear_trainer_options()

	if main.active_trainer_index == -1:
		return

	match main.trainer_dialogue_state:
		"GREETING":
			_show_trainer_greeting()
		"SKILL_LIST":
			_show_trainer_skill_list()
		"CONFIRM":
			_show_trainer_confirm()

func _show_trainer_greeting() -> void:
	var trainer_name = main.trainers[main.active_trainer_index]["name"]
	train_info_label.text = trainer_name + "\n\n\"I can teach you what I know, if you're interested.\""

	_add_trainer_option("I'm interested in learning a skill.", _on_trainer_option_start_learning)
	_add_trainer_option("Stop Conversing", _on_trainer_option_stop_conversing)

func _on_trainer_option_start_learning() -> void:
	main.trainer_dialogue_state = "SKILL_LIST"
	_refresh_trainer_dialogue()

func _on_trainer_option_stop_conversing() -> void:
	visible = false
	main.active_trainer_index = -1

func _show_trainer_skill_list() -> void:
	var this_trainer_profession = main.trainers[main.active_trainer_index]["profession"]

	if not main.professions_unlocked.get(this_trainer_profession, false):
		train_info_label.text = "What would you like to learn?"

		var cost_text: String
		if main.has_chosen_starting_profession:
			cost_text = str(main.PROFESSION_ENTRY_COST) + " " + main._points_pool_label(this_trainer_profession) + ", " + str(main.ADDITIONAL_PROFESSION_COGS_COST) + " Cogs"
		else:
			cost_text = str(main.PROFESSION_ENTRY_COST) + " " + main._points_pool_label(this_trainer_profession) + " (Free starting profession!)"

		_add_trainer_option("Learn " + this_trainer_profession + " (" + cost_text + ")", _make_trainer_confirm_callback(this_trainer_profession, "LEARN_PROFESSION"))
		_add_trainer_option("Back", _on_trainer_option_back_to_greeting)
		return

	var anything_shown = false

	for path_name in GameData.novice_professions[this_trainer_profession]["paths"].keys():
		var path_data = GameData.novice_professions[this_trainer_profession]["paths"][path_name]
		var unlocked = path_data["unlocked_nodes"]
		var max_nodes = path_data.get("max_nodes", main.NODES_PER_PATH)

		if unlocked >= max_nodes:
			continue

		if not main._is_prereq_met(this_trainer_profession, path_data):
			continue

		var costs = main._get_box_cost(path_data)
		var xp_type = path_data["xp_type"]
		var current_xp = main.xp_pools[xp_type]

		if current_xp < costs["xp_cost"]:
			continue
		if main._get_points_available(this_trainer_profession) < costs["point_cost"]:
			continue
		if main.cogs < costs["cogs_cost"]:
			continue

		var display_text = main._get_talent_box_label(this_trainer_profession, path_name) + " (" + str(unlocked) + "/" + str(max_nodes) + ")"
		_add_trainer_option(display_text, _make_trainer_confirm_callback(this_trainer_profession, path_name))
		anything_shown = true

	if anything_shown:
		train_info_label.text = "What would you like to learn?"
	else:
		train_info_label.text = "Nothing available to train right now.\nEarn more XP, Points, or Cogs."

	_add_trainer_option("Back", _on_trainer_option_back_to_greeting)

func _on_trainer_option_back_to_greeting() -> void:
	main.trainer_dialogue_state = "GREETING"
	_refresh_trainer_dialogue()

# Returns a Callable bound to a specific profession/path so each skill-list
# button opens the confirm screen for that exact entry, without needing a
# Tree's selected-item metadata to look up afterward.
func _make_trainer_confirm_callback(profession_name: String, path_name: String) -> Callable:
	return func():
		main.selected_profession = profession_name
		main.selected_path = path_name
		main.trainer_dialogue_state = "CONFIRM"
		_refresh_trainer_dialogue()

func _show_trainer_confirm() -> void:
	if main.selected_path == "LEARN_PROFESSION":
		if main.has_chosen_starting_profession:
			train_info_label.text = "This will cost " + str(main.ADDITIONAL_PROFESSION_COGS_COST) + " Cogs. Are you sure?"
		else:
			train_info_label.text = "This is your free starting profession. Are you sure?"
	else:
		train_info_label.text = _build_trainer_confirm_text(main.selected_profession, main.selected_path)

	_add_trainer_option("Yes", _on_trainer_confirm_yes)
	_add_trainer_option("No", _on_trainer_confirm_no)

# Lean, SWG-style confirm line for the trainer popup — just the main.cogs cost,
# no rank/node/XP detail. (The Talent Viewer's _build_skill_info_text still
# shows the full breakdown elsewhere — this is a separate, simpler string
# used only for this one screen.)
func _build_trainer_confirm_text(profession_name: String, path_name: String) -> String:
	var path_data = GameData.novice_professions[profession_name]["paths"][path_name]
	var costs = main._get_box_cost(path_data)
	return "This skill will cost " + str(costs["cogs_cost"]) + " Cogs. Are you sure?"

func _on_trainer_confirm_yes() -> void:
	if main.selected_path == "LEARN_PROFESSION":
		main._learn_trainer_profession()
		trainer_result_text = train_result_label.text
	else:
		main._on_spend_point_pressed()
		trainer_result_text = main.skill_result_label.text

	main.trainer_dialogue_state = "GREETING"
	_refresh_trainer_dialogue()
	_show_train_result(trainer_result_text)

func _on_trainer_confirm_no() -> void:
	main.trainer_dialogue_state = "SKILL_LIST"
	_refresh_trainer_dialogue()


func _show_train_result(text: String) -> void:
	train_result_label.text = text
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if train_result_label.text == text:
			train_result_label.text = ""
	)
