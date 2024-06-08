extends Node2D

const DEAL_DURATION = 2.0

var _deck: Array[Card] = []

@onready var _camera: Camera2D = $Camera
@onready var _deal_origin: Marker2D = $DealOrigin
@onready var _columns: Array[Column] = [
	$Column1,
	$Column2,
	$Column3,
	$Column4,
	$Column5,
	$Column6,
	$Column7,
]


func _ready():
	_deck = _generate_deck()
	_deal()


func _generate_deck() -> Array[Card]:
	var deck: Array[Card] = []
	var card_scene := preload("res://card/card.tscn")

	for suit in Card.SUITS:
		for rank in range(1, 14):
			var card: Card = card_scene.instantiate()
			card.name = "%s-%s" % [Card.Suit.find_key(suit), rank]
			card.suit = suit
			card.rank = rank
			card.is_face_up = false
			card.can_interact = false
			card.position = _deal_origin.position
			deck.append(card)
			add_child(card)

	return deck


func _deal():
	var to_deal = _deck.duplicate()
	to_deal.shuffle()

	# Used to create the deal animation
	var tween = create_tween() \
			.set_parallel(false) \
			.set_ease(Tween.EASE_OUT)

	var num_rows = 10
	var num_cols = _columns.size()

	for row_idx in num_rows:
		for col_idx in num_cols:
			if col_idx <= 1 and row_idx >= 1:
				# The first two columns only have one card each
				continue
			else:
				var card = to_deal.pop_front()
				var column = _columns[col_idx]
				var is_face_down = col_idx > 1 and row_idx < 2
				tween.tween_callback(func(): card.is_face_up = not is_face_down)
				column.add_card(card, tween, DEAL_DURATION / 52)

	assert(to_deal.size() == 0)
