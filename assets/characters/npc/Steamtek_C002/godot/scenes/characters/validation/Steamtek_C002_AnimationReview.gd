extends Node2D

const DIRECTIONS := [
	"south",
	"south_west",
	"west",
	"north_west",
	"north",
	"north_east",
	"east",
	"south_east",
]

@onready var visual: AnimatedSprite2D = $ReviewStage/Steamtek_C002_NPC/CharacterVisual/Visual
@onready var status_label: Label = $ReviewUI/Panel/Margin/VBox/Status
@onready var auto_label: Label = $ReviewUI/Panel/Margin/VBox/AutoCycle

var direction_index := 0
var animation_state := "idle"
var auto_cycle := true
var cycle_elapsed := 0.0


func _ready() -> void:
	_apply_animation()


func _process(delta: float) -> void:
	if auto_cycle:
		cycle_elapsed += delta
		if cycle_elapsed >= 1.5:
			cycle_elapsed = 0.0
			direction_index = (direction_index + 1) % DIRECTIONS.size()
			_apply_animation()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			_cycle_direction(-1)
		KEY_RIGHT, KEY_D:
			_cycle_direction(1)
		KEY_UP, KEY_W:
			_set_direction("north")
		KEY_DOWN, KEY_S:
			_set_direction("south")
		KEY_SPACE:
			animation_state = "walk" if animation_state == "idle" else "idle"
			_apply_animation()
		KEY_TAB:
			auto_cycle = not auto_cycle
			cycle_elapsed = 0.0
			_update_labels()


func _cycle_direction(amount: int) -> void:
	auto_cycle = false
	direction_index = wrapi(direction_index + amount, 0, DIRECTIONS.size())
	_apply_animation()


func _set_direction(direction: String) -> void:
	auto_cycle = false
	direction_index = DIRECTIONS.find(direction)
	_apply_animation()


func _apply_animation() -> void:
	var animation_name := "%s_%s" % [animation_state, DIRECTIONS[direction_index]]
	if not visual.sprite_frames.has_animation(animation_name):
		push_error("Missing C002 review animation: %s" % animation_name)
		return
	visual.flip_h = false
	visual.play(animation_name)
	_update_labels()


func _update_labels() -> void:
	status_label.text = "Animation: %s    Direction: %s" % [animation_state, DIRECTIONS[direction_index]]
	auto_label.text = "Auto-cycle: %s" % ("ON" if auto_cycle else "OFF")
