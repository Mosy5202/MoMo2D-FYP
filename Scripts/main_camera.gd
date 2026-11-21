
class_name MainCamera
extends Camera3D

@export var target: Node3D
@export var lerp_speed: float

# Mouse settings
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_degrees: float = -45.0
@export var max_pitch_degrees: float = 65.0

var camera_yaw: float = 0.0
var camera_pitch: float = 0.0
var rotating: bool = false


func _ready() -> void:
	# Preserve the camera's initial rotation.
	camera_yaw = rotation.y
	camera_pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:

	# Hold right mouse button to rotate.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

			Input.mouse_mode = (
				Input.MOUSE_MODE_CAPTURED
				if rotating
				else Input.MOUSE_MODE_VISIBLE
			)

	# Escape releases the mouse.
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			rotating = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Apply mouse rotation.
	elif event is InputEventMouseMotion and rotating:

		camera_yaw -= (
			event.screen_relative.x * mouse_sensitivity
		)

		camera_pitch -= (
			event.screen_relative.y * mouse_sensitivity
		)

		camera_pitch = clampf(
			camera_pitch,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)

		rotation.y = camera_yaw
		rotation.x = camera_pitch


func _process(delta: float) -> void:
	if target == null:
		return

	# Original tutorial's smooth camera-follow behaviour.
	global_position = global_position.lerp(
		target.global_position,
		lerp_speed
	)
