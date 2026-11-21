
extends CharacterBody3D

# Movement settings
@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var acceleration: float = 12.0
@export var turn_speed: float = 5.0
@export var gravity: float = 18.0

# Jump settings
@export var jump_velocity: float = 4.5
@export var long_jump_velocity: float = 6.0
@export var long_jump_speed: float = 7.0

# Interaction settings
@export var interaction_animation_duration: float = 1.2
var interaction_time_remaining: float = 0.0

# Animation references
@onready var animation_tree: AnimationTree = (
	find_child("AnimationTree", true, false) as AnimationTree
)

var state_machine: AnimationNodeStateMachinePlayback
var in_air: bool = false


func _ready() -> void:
	if animation_tree == null:
		push_error("AnimationTree was not found inside Player.")
		set_physics_process(false)
		return

	animation_tree.active = true

	state_machine = animation_tree.get(
        "parameters/StateMachine/playback"
	) as AnimationNodeStateMachinePlayback

	if state_machine == null:
		state_machine = animation_tree.get(
            "parameters/playback"
		) as AnimationNodeStateMachinePlayback

	if state_machine == null:
		push_error("AnimationTree playback state machine was not found.")
		set_physics_process(false)
		return

	_play_state(&"Idle", true)


func _physics_process(delta: float) -> void:
	if state_machine == null:
		return

	# Read movement input
	var input_vector: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	var moving: bool = input_vector.length_squared() > 0.001

	var running: bool = (
		InputMap.has_action("run")
		and Input.is_action_pressed("run")
	)

	var was_on_floor: bool = is_on_floor()
	var launched_long_jump: bool = false

	# Get the active camera's horizontal direction
	var active_camera: Camera3D = get_viewport().get_camera_3d()
	var camera_forward: Vector3
	var camera_right: Vector3

	if active_camera != null:
		camera_forward = -active_camera.global_basis.z
		camera_right = active_camera.global_basis.x
	else:
		# Fallback if no active camera is available
		camera_forward = -global_basis.z
		camera_right = global_basis.x

	# Ignore the camera's vertical angle for ground movement
	camera_forward.y = 0.0
	camera_right.y = 0.0

	if camera_forward.length_squared() > 0.001:
		camera_forward = camera_forward.normalized()
	else:
		camera_forward = Vector3.FORWARD

	if camera_right.length_squared() > 0.001:
		camera_right = camera_right.normalized()
	else:
		camera_right = Vector3.RIGHT

	# Calculate movement relative to the camera
	var direction: Vector3 = (
		camera_right * input_vector.x
		- camera_forward * input_vector.y
	).normalized()

	# Apply gravity
	if not was_on_floor:
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Play interaction without stopping movement
	if (
		InputMap.has_action("interact")
		and Input.is_action_just_pressed("interact")
	):
		interaction_time_remaining = maxf(
			interaction_animation_duration, 0.1
		)
		_play_state(&"Player_Interact", true)

	# Jumping
	if was_on_floor:
		if Input.is_action_just_pressed("long_jump"):
			var jump_direction: Vector3 = direction

			if not moving:
				jump_direction = -global_basis.z
				jump_direction.y = 0.0
				jump_direction = jump_direction.normalized()

			velocity.y = long_jump_velocity
			velocity.x = jump_direction.x * long_jump_speed
			velocity.z = jump_direction.z * long_jump_speed

			in_air = true
			launched_long_jump = true
			_play_state(&"Jump_Long", true)

		elif Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			in_air = true

			if moving:
				_play_state(&"Jump_Short", true)
			else:
				_play_state(&"Jump_Idle", true)

	# Walking, running, and turning
	if moving:
		if was_on_floor and not launched_long_jump:
			var current_speed: float = (
				run_speed if running else walk_speed
			)
			var target_velocity: Vector3 = direction * current_speed

			velocity.x = move_toward(
				velocity.x,
				target_velocity.x,
				acceleration * delta
			)

			velocity.z = move_toward(
				velocity.z,
				target_velocity.z,
				acceleration * delta
			)

		var target_yaw: float = atan2(
			-direction.x,
			-direction.z
		)

		global_rotation.y = rotate_toward(
			global_rotation.y,
			target_yaw,
			turn_speed * delta
		)

	elif was_on_floor and not launched_long_jump:
		velocity.x = move_toward(
			velocity.x, 0.0, acceleration * delta
		)
		velocity.z = move_toward(
			velocity.z, 0.0, acceleration * delta
		)

	# Move the character
	move_and_slide()

	# Check for landing
	if not is_on_floor():
		in_air = true
	elif in_air and velocity.y <= 0.0:
		in_air = false

	# Keep the interaction animation visible for its duration
	if interaction_time_remaining > 0.0:
		interaction_time_remaining = maxf(
			interaction_time_remaining - delta, 0.0
		)

		if not (
			Input.is_action_just_pressed("jump")
			or Input.is_action_just_pressed("long_jump")
		):
			_play_state(&"Player_Interact")
			return

	# Normal animations
	if not in_air:
		if moving:
			if running:
				_play_state(&"Running")
			else:
				_play_state(&"Walking")
		else:
			_play_state(&"Idle")


func _play_state(
	state_name: StringName,
	restart: bool = false
) -> void:
	if state_machine == null:
		return

	var current_state: StringName = state_machine.get_current_node()

	if current_state == state_name and not restart:
		return

	if restart:
		state_machine.start(state_name)
	else:
		state_machine.travel(state_name)
