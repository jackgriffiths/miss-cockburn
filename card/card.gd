class_name Card
extends Node2D

signal drag_started
signal drag_ended

enum Suit {
	CLUBS,
	DIAMONDS,
	HEARTS,
	SPADES,
}

const SUITS = [
	Suit.CLUBS,
	Suit.DIAMONDS,
	Suit.HEARTS,
	Suit.SPADES,
]

var suit: Suit
var rank = 1
var is_face_up = false: set = _set_is_face_up
var can_interact = false
var can_make_face_up = false

var _is_dragging = false
var _drag_offset = Vector2.ZERO
var _entered_dropzones: Array[Dropzone] = []

@onready var _collision_shape: CollisionShape2D = $CollisionShape
@onready var _sprite: TextureRect = $Sprite


func _ready() -> void:
	connect("area_entered", _on_entered_dropzone)
	connect("area_exited", _on_exited_dropzone)
	_sprite.connect("gui_input", _handle_input)
	_update_sprite_texture()


func get_overlapping_dropzone() -> Dropzone:
	return _entered_dropzones[0] if not _entered_dropzones.is_empty() else null


func _update_sprite_texture() -> void:
	if _sprite:
		_sprite.texture = load(_get_texture_path())


func _get_texture_path() -> String:
	if not is_face_up:
		return "res://card/assets/back.png"

	match suit:
		Suit.CLUBS:
			return "res://card/assets/clubs_%d.png" % rank
		Suit.DIAMONDS:
			return "res://card/assets/diamonds_%d.png" % rank
		Suit.HEARTS:
			return "res://card/assets/hearts_%d.png" % rank
		Suit.SPADES:
			return "res://card/assets/spades_%d.png" % rank
		_:
			assert(false, "Unhandled suit")
			return "res://card/assets/back.png"


func _handle_input(event: InputEvent):
	if not can_interact:
		return

	if is_face_up:
		if event.is_action_pressed("click"):
			_is_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
			_collision_shape.set_deferred("disabled", false)
			drag_started.emit()
		elif event.is_action_released("click") && _is_dragging: 
			_is_dragging = false
			_drag_offset = Vector2.ZERO
			_collision_shape.set_deferred("disabled", true)
			drag_ended.emit()
	elif can_make_face_up:
		if event.is_action_pressed("click"):
			is_face_up = true
			can_make_face_up = false
			_update_sprite_texture()


func _process(_delta: float) -> void:
	if _is_dragging:
		global_position = get_global_mouse_position() - _drag_offset


func _set_is_face_up(value: bool) -> void:
	is_face_up = value
	_update_sprite_texture()


func _on_entered_dropzone(dropzone: Dropzone) -> void:
	var is_first = _entered_dropzones.is_empty()
	_entered_dropzones.append(dropzone)

	if is_first:
		dropzone.highlight()

func _on_exited_dropzone(dropzone: Dropzone) -> void:
	var idx = _entered_dropzones.find(dropzone)
	if idx != -1:
		_entered_dropzones.remove_at(idx)
		dropzone.remove_highlight()

		if not _entered_dropzones.is_empty():
			_entered_dropzones[0].highlight()
