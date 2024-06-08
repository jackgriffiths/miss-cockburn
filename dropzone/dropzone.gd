class_name Dropzone
extends Area2D

@export var column: Column

@onready var _highlight: ColorRect = $Highlight
@onready var _collision_shape: CollisionShape2D = $CollisionShape


func enable():
	_collision_shape.set_deferred("disabled", false)


func disable():
	remove_highlight()
	_collision_shape.set_deferred("disabled", true)


func highlight():
	_highlight.visible = true


func remove_highlight():
	_highlight.visible = false
