class_name Card
extends Node2D

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
var is_face_up = false

@onready var _sprite: TextureRect = $Sprite


func _ready() -> void:
	_update_sprite_texture()


func _update_sprite_texture() -> void:
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
