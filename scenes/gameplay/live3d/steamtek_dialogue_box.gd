extends Control
class_name SteamtekDialogueBox

## Generic NPC "chat box" for Live3D scenes. Modeled on the popup pattern
## already proven twice in this codebase (scenes/TrainerDialogue.gd,
## scenes/Quest.gd — title/body Label + a rebuilt list of option Buttons)
## but data-driven and self-contained instead of hardwired to main.gd.

@onready var portrait: SteamtekItemIcon = $Portrait
@onready var speaker_label: Label = $SpeakerLabel
@onready var body_label: Label = $BodyLabel
@onready var options_list: VBoxContainer = $OptionsList


func show_dialogue(speaker: String, text: String, options: Array) -> void:
	visible = true
	speaker_label.text = speaker
	portrait.set_item(speaker)
	body_label.text = text
	for child in options_list.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = String(option.get("label", ""))
		button.focus_mode = Control.FOCUS_NONE
		var callback: Callable = option.get("callback", Callable())
		if callback.is_valid():
			button.pressed.connect(callback)
		options_list.add_child(button)


func close() -> void:
	visible = false
