extends CharacterBody2D

const SPEED: float = 200.0

# The pre-built 8-direction walk-cycle sub-scene from the art pipeline.
# Its SpriteFrames resource already defines all 8 named animations at
# 8 FPS, and its own "Visual" child already carries the correct scale
# (0.73, 0.73) and offset (0, -110) per the confirmed art spec — this
# script only ever calls .play()/.stop() on it, it doesn't touch
# transform values that belong to the art-authored sub-scene.
@onready var walk_visual: AnimatedSprite2D = $Steamtek_C001_WalkVisual/Visual

# Maps each of the 8 compass directions to the matching animation name
# baked into the Steamtek_C001_WalkVisual SpriteFrames resource.
const DIRECTION_ANIMATIONS := {
	"S": "walk_south",
	"SW": "walk_south_west",
	"W": "walk_west",
	"NW": "walk_north",
	"N": "walk_north",
	"NE": "walk_north",
	"E": "walk_east",
	"SE": "walk_south_west",
}

var facing_direction: String = "S"

func _physics_process(_delta: float) -> void:
	var input_direction := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_direction.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1.0
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1.0
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1.0

	input_direction = input_direction.normalized()
	velocity = input_direction * SPEED
	move_and_slide()

	if input_direction != Vector2.ZERO:
		facing_direction = _get_direction_name(input_direction)
		
		# The generated southeast row has the wrong viewing angle.
		# Mirror the southwest animation until a true southeast render exists.
		walk_visual.flip_h = facing_direction == "SE"

		var anim_name: String = DIRECTION_ANIMATIONS[facing_direction]

		# Only re-trigger play() when the direction actually changes —
		# calling it every physics frame would restart the walk cycle
		# from frame 0 constantly instead of animating smoothly.
		if walk_visual.animation != anim_name or not walk_visual.is_playing():
			walk_visual.play(anim_name)
	else:
		# Stopped moving — hold a clean pose (frame 0 of the current
		# direction) instead of freezing mid-stride on whatever frame
		# the walk cycle happened to be on.
		if walk_visual.is_playing():
			walk_visual.stop()
			walk_visual.frame = 0

# Converts a movement vector into one of 8 compass directions by
# rounding its angle to the nearest 45-degree increment.
func _get_direction_name(direction: Vector2) -> String:
	var angle_deg = rad_to_deg(direction.angle())
	# angle() returns -180..180 with 0 = right (+X), 90 = down (+Y),
	# since Y increases downward in Godot's 2D coordinate space.
	var octant = int(round(angle_deg / 45.0)) % 8
	if octant < 0:
		octant += 8

	var octant_names = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	return octant_names[octant]
