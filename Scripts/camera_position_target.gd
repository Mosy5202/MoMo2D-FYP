
class_name CameraPositionTarget
extends Node3D

var target: Node3D
var offset: Vector3


func _ready() -> void:
	target = get_parent_node_3d()

	if target != null:
		# Remember the initial offset from the player
		offset = global_position - target.global_position


func _process(_delta: float) -> void:
	if target != null:
		global_position = target.global_position + offset
