extends CharacterBody2D
class_name SteamtekPlayer

const SPEED: float = 200.0

# --- Dodge Roll (active defensive ability, ranged-only combat redesign) ---
# Replaces the old passive per-hit enemy Dodge stat: a directional dash
# with full i-frames, rolling toward held movement input or backstepping
# opposite the current facing if no direction is held. main.gd checks
# is_invulnerable before applying enemy attack damage.
const DODGE_SPEED: float = 520.0
const DODGE_DURATION: float = 0.3
const DODGE_COOLDOWN: float = 2.0

var is_invulnerable: bool = false
var _dodge_timer: float = 0.0
var _dodge_cooldown_timer: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO

# Set by main.gd while a chargeable ability (e.g. Charged Shot) is being
# held -- movement is slowed, not locked, per the charge-shot design.
# Reset to 1.0 the moment the charge resolves or gets interrupted.
var movement_speed_mult: float = 1.0

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

func _physics_process(delta: float) -> void:
	if _dodge_cooldown_timer > 0.0:
		_dodge_cooldown_timer -= delta

	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		velocity = _dodge_direction * DODGE_SPEED
		move_and_slide()
		if _dodge_timer <= 0.0:
			is_invulnerable = false
		return

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

	if InputMap.has_action("dodge_roll") and Input.is_action_just_pressed("dodge_roll") and _dodge_cooldown_timer <= 0.0:
		_dodge_direction = input_direction if input_direction != Vector2.ZERO else -_facing_vector()
		_dodge_timer = DODGE_DURATION
		_dodge_cooldown_timer = DODGE_COOLDOWN
		is_invulnerable = true
		velocity = _dodge_direction * DODGE_SPEED
		move_and_slide()
		return

	velocity = input_direction * SPEED * movement_speed_mult
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

# Inverse of _get_direction_name -- turns the current facing direction
# back into a unit vector, used for the Dodge Roll's backstep when no
# movement input is held.
func _facing_vector() -> Vector2:
	const FACING_VECTORS := {
		"E": Vector2(1, 0), "SE": Vector2(1, 1), "S": Vector2(0, 1), "SW": Vector2(-1, 1),
		"W": Vector2(-1, 0), "NW": Vector2(-1, -1), "N": Vector2(0, -1), "NE": Vector2(1, -1),
	}
	return FACING_VECTORS.get(facing_direction, Vector2(0, 1)).normalized()
