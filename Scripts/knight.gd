extends Node3D

@export var speed = 10
@export var fall_acceleration = 75
@export var jump_impulse = 20


func _process(delta):
		
	if Input.is_action_pressed("move_forward"):
		position.z -= speed * delta
	if Input.is_action_pressed("move_backward"):
		position.z += speed * delta
	if Input.is_action_pressed("move_left"):
		position.x -= speed * delta
	if Input.is_action_pressed("move_right"):
		position.x += speed * delta
	if Input.is_action_pressed("move_forward"):
		position.x += speed * delta
	if Input.is_action_pressed("move_forward"):
		position.x += speed * delta
