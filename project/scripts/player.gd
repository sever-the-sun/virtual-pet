extends CharacterBody2D

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D


const SPEED: float = 300.0
const ACCEL: float = 50.0

const JUMP: float = 500.0
const GRAVITY: float = 20.0
const MAX_FALL_SPEED: float = 400.0

var input_hori: float = 0.0
var accel_mult: float = 1.0


func _physics_process(delta: float) -> void:
	if is_zero_approx(input_hori):
		velocity.x = move_toward(velocity.x, 0, ACCEL * accel_mult)
	else:
		velocity.x = clampf(velocity.x + (input_hori * ACCEL * accel_mult), -SPEED, SPEED)
		sprite_2d.flip_h = input_hori < 0
	
	velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, GRAVITY)
	
	if ray_cast.is_colliding():
		accel_mult = 1.0
		if Input.is_action_just_pressed(&"jump"):
			velocity.y = -JUMP
	else:
		accel_mult = 0.25
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	input_hori = Input.get_axis(&"move_left", &"move_right")
	if Input.is_action_just_pressed(&"meow"):
		print("meow")
	if Input.is_action_just_pressed(&"hiss"):
		print("hiss")
