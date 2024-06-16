class_name Dropzone
extends Area2D

@export var column: Column

var _size: Vector2

@onready var _highlight: Panel = $Highlight
@onready var _collision_shape: CollisionShape2D = $CollisionShape


func _ready():
	_size = (_collision_shape.shape as RectangleShape2D).size


func get_size() -> Vector2:
	return _size


func enable():
	_collision_shape.set_deferred("disabled", false)


func disable():
	remove_highlight()
	_collision_shape.set_deferred("disabled", true)


func highlight():
	_highlight.visible = true


func remove_highlight():
	_highlight.visible = false
