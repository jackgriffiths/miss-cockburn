extends Node2D

enum State {
	INITIALIZING,
	DEALING,
	PLAYING,
}

const DEAL_DURATION = 2.0
const GATHER_DURATION = 1.0
const ALLOW_INVALID_MOVES = false

var _state = State.INITIALIZING
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
	# Initialize
	_state = State.INITIALIZING
	_deck = _generate_deck()
	
	# Deal
	_state = State.DEALING
	await _deal()
	
	# Play
	_state = State.PLAYING
	_enable_card_interactions()


func start_new_game() -> void:
	if _state == State.PLAYING:
		_state = State.DEALING
		_disable_card_interactions()
		await _gather_cards()
		await get_tree().create_timer(0.5).timeout
		await _deal()
		_enable_card_interactions()
		_state = State.PLAYING


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
			card.can_make_face_up = false
			card.can_interact = false
			card.position = _deal_origin.position
			card.connect("drag_started", _on_card_drag.bind(card))

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
	await tween.finished


func _gather_cards() -> void:
	var tween = create_tween() \
			.set_parallel(true) \
			.set_ease(Tween.EASE_OUT)

	for card in _deck:
		# Detach the card from the column
		card.reparent(self)

		# Animate the card back to where it will be dealt from
		tween.tween_property(card, "position", _deal_origin.position, GATHER_DURATION)

	for column in _columns:
		column.after_cards_removed()

	await tween.finished

	for card in _deck:
		card.is_face_up = false


func _enable_card_interactions():
	for card in _deck:
		card.can_interact = true


func _disable_card_interactions():
	for card in _deck:
		card.can_interact = false


func _on_card_drag(dragged_card: Card):
	# Prevent the user from interacting with any other cards while
	# this card is being dragged.
	for card in _deck:
		if card != dragged_card:
			card.can_interact = false
	
	var initial_column = dragged_card.get_parent() as Column

	# Disable the dropzone so the dragged card can't interact with the
	# dropzone in its current column.
	initial_column.disable_dropzone()

	# To move the cards beneath the card being dragged, remote transforms
	# are attached as children of the card being dragged.
	var cards_moving: Array[Card] = [dragged_card]
	var remote_transforms: Array[RemoteTransform2D] = []
	
	for card in initial_column.get_cards_after(dragged_card):
		var remote_transform = RemoteTransform2D.new()
		remote_transform.remote_path = card.get_path()
		remote_transform.position = cards_moving.size() * Column.CARD_OFFSET
		dragged_card.add_child(remote_transform)
		remote_transforms.append(remote_transform)
		cards_moving.append(card)

	# Store the intial positions so that if necessary we can reset the
	# cards back to where they started.
	var initial_positions = cards_moving.map(func(c): return c.position)

	# The cards moving need to appear on top of all the
	# other cards and dropzones.
	for card in cards_moving:
		card.z_index = 2

	await dragged_card.drag_ended

	# Prevent the user from interacting with this card again while
	# we handle what to do after the drag is completed.
	dragged_card.can_interact = false

	# The cards should move independently now so the
	# remote transforms aren't required.
	for remote_tranform in remote_transforms:
		remote_tranform.queue_free()

	var dropzone = dragged_card.get_overlapping_dropzone()
	var is_valid_move = dropzone && _is_valid_move(dragged_card, dropzone)

	# A parallel tween is used so that the cards all begin to move
	# to their destination in a staggered way.
	var tween = create_tween() \
			.set_parallel(true) \
			.set_ease(Tween.EASE_OUT)

	if is_valid_move:
		for card_idx in cards_moving.size():
			var new_column = dropzone.column
			var position_tweener = new_column.add_card(cards_moving[card_idx], tween, 0.1)
			position_tweener.set_delay(card_idx * 0.05)

		initial_column.after_cards_removed()
	else:
		# Move the cards back to where they were started.
		for card_idx in cards_moving.size():
			var card = cards_moving[card_idx]
			var initial_position = initial_positions[card_idx] as Vector2
			var delay = card_idx * 0.05
			tween.tween_property(card, "position", initial_position, 0.1).set_delay(delay)

	await tween.finished

	initial_column.enable_dropzone()

	for card in _deck:
		card.can_interact = true
		card.z_index = 0


func _is_valid_move(moved_card: Card, dropzone: Dropzone):
	if ALLOW_INVALID_MOVES:
		return true

	var target_card = dropzone.column.get_last_card()

	if target_card == null:
		return moved_card.rank == 13
	else:
		return moved_card.suit == target_card.suit and moved_card.rank == target_card.rank - 1
