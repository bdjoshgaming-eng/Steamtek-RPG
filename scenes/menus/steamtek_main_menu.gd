extends Control

const APARTMENT_SCENE_PATH := "res://scenes/levels/apartment_3d/SteamtekApartment.tscn"
const FADE_SECONDS := 0.6

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var fade_rect: ColorRect = $Fade

var _transitioning := false


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, FADE_SECONDS)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8:
		get_tree().quit()


func _on_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	play_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_SECONDS)
	await tween.finished
	var error := get_tree().change_scene_to_file(APARTMENT_SCENE_PATH)
	if error != OK:
		push_error("Steamtek main menu: failed to load %s" % APARTMENT_SCENE_PATH)
		_transitioning = false
		play_button.disabled = false
		fade_rect.color.a = 0.0
