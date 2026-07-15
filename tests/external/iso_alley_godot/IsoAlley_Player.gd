extends CharacterBody2D
## Placeholder player for iso movement testing.
## Sprite scale 0.09, footprint 28x18, root at boots.

@export var speed: float = 200.0

# 2:1 isometric axis vectors (world -> screen).
const ISO_X := Vector2(1.0, 0.5)
const ISO_Y := Vector2(-1.0, 0.5)

func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)
	# Convert cartesian input into 2:1 iso screen motion.
	var move := (ISO_X * input.x + ISO_Y * -input.y).normalized() * speed
	velocity = move
	move_and_slide()
