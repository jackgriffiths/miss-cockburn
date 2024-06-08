extends Node2D

var _deck: Array[Card] = []

@onready var camera = $Camera


func _ready():
	_deck = _generate_deck()
	_arrange_deck()


func _generate_deck() -> Array[Card]:
	var deck: Array[Card] = []
	var card_scene := preload("res://card/card.tscn")

	for suit in Card.SUITS:
		for rank in range(1, 14):
			var card: Card = card_scene.instantiate()
			card.name = "%s-%s" % [Card.Suit.find_key(suit), rank]
			card.suit = suit
			card.rank = rank
			card.is_face_up = true
			deck.append(card)

	return deck


func _arrange_deck() -> void:
	var cols = 12
	for i in _deck.size():
		var card = _deck[i]
		var row = i / cols
		var col = i % cols
		card.position = Vector2(col * 105, row * 140)
		add_child(card)
