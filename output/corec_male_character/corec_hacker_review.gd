extends Node3D

@export var review_target := Vector3(0.0, 0.9, 0.0)
@export var start_distance := 3.2
@export var min_distance := 1.4
@export var max_distance := 7.0
@export var pan_speed := 1.4
var distance := 3.2
var target := Vector3.ZERO
var camera: Camera3D
var view_yaw := 20.0
var animation_player: AnimationPlayer
const IDLE_ANIMATION := "STK_Idle_Mixamo_01"

func _ready() -> void:
	target = review_target
	distance = start_distance
	camera = $ReviewCamera
	_update_camera()
	animation_player = $Character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	$HUD/Panel/VBox/PlayStop.pressed.connect(_toggle_idle)
	if animation_player and animation_player.has_animation(IDLE_ANIMATION):
		animation_player.get_animation(IDLE_ANIMATION).loop_mode = Animation.LOOP_LINEAR
		animation_player.play(IDLE_ANIMATION)
		_update_play_button()
	else:
		$HUD/Panel/VBox/PlayStop.disabled = true
		$HUD/Panel/VBox/Status.text = "Idle animation not found"

func _process(delta: float) -> void:
	var pan := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if pan.length() > 0.0:
		target += Vector3(pan.x, 0.0, pan.y) * pan_speed * delta
		_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(min_distance, distance * 0.88)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(max_distance, distance * 1.14)
			_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_idle()
			return
		var preset := -1
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			preset = event.keycode - KEY_1
		if preset >= 0:
			var presets := [Vector3(0, 0.95, 0), Vector3(0, 1.0, 0), Vector3(0, 1.0, 0), Vector3(0.0, 0.95, 0.0), Vector3(0.0, 1.55, 0.0), Vector3(0.0, 0.25, 0.0)]
			var yaws := [0.0, 90.0, 180.0, 45.0, 0.0, 0.0]
			target = presets[preset]
			view_yaw = yaws[preset]
			distance = [3.2, 3.0, 3.2, 3.2, 2.0, 2.0][preset]
			_update_camera()

func _update_camera() -> void:
	if not camera:
		return
	var yaw := deg_to_rad(view_yaw)
	var offset := Vector3(sin(yaw) * distance, 0.55, cos(yaw) * distance)
	camera.position = target + offset
	camera.look_at(target, Vector3.UP)

func _toggle_idle() -> void:
	if not animation_player or not animation_player.has_animation(IDLE_ANIMATION):
		return
	if animation_player.is_playing():
		animation_player.pause()
	else:
		animation_player.play(IDLE_ANIMATION)
	_update_play_button()

func _update_play_button() -> void:
	var playing := animation_player != null and animation_player.is_playing()
	$HUD/Panel/VBox/PlayStop.text = "Stop Idle" if playing else "Play Idle"
	$HUD/Panel/VBox/Status.text = "%s — looping" % IDLE_ANIMATION if playing else "%s — paused" % IDLE_ANIMATION