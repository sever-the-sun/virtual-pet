extends CharacterBody2D

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


const SPEED: float = 300.0
const ACCEL: float = 50.0

const JUMP: float = 500.0
const GRAVITY: float = 20.0
const MAX_FALL_SPEED: float = 400.0

var input_hori: float = 0.0
var accel_mult: float = 1.0

@export var making_noise: bool = false
@export var cutscene_no_move: bool = true

var has_not_moved: bool = false

func _physics_process(delta: float) -> void:
	if cutscene_no_move:
		return
	if making_noise: # no move
		input_hori = 0
	
	if is_zero_approx(input_hori):
		velocity.x = move_toward(velocity.x, 0, ACCEL * accel_mult)
		if sprite.animation == &"move":
			sprite.pause()
	else:
		has_not_moved = false
		velocity.x = clampf(velocity.x + (input_hori * ACCEL * accel_mult), -SPEED, SPEED)
		sprite.flip_h = input_hori < 0
		sprite.play()
	
	velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, GRAVITY)
	
	if ray_cast.is_colliding(): # on the ground
		accel_mult = 1.0
		if sprite.animation == &"jump":
			sprite.play(&"move")
		if Input.is_action_just_pressed(&"jump"):
			velocity.y = -JUMP
	else:
		accel_mult = 0.25
		sprite.play(&"jump")

	move_and_slide()

func _input(event: InputEvent) -> void:
	if cutscene_no_move:
		return
	input_hori = Input.get_axis(&"move_left", &"move_right")
	if ray_cast.is_colliding():
		if Input.is_action_just_pressed(&"meow"):
			$AnimationPlayer.play(&"meow")
		if Input.is_action_just_pressed(&"hiss"):
			$AnimationPlayer.play(&"hiss")

func make_noise(meowing: bool) -> void:
	if meowing:
		get_parent().meow()
	else:
		get_parent().hiss()
