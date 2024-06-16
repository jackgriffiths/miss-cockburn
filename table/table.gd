extends Node2D

enum State {
	INITIALIZING,
	INITIALIZED,
	DEALING,
	PLAYING,
}

const DEAL_DURATION = 3.0
const GATHER_DURATION = 1.0
const CARD_MOVE_DURATION = 0.1
const CARD_MOVE_STAGGER_DURATION = 0.05
const ALLOW_INVALID_MOVES = false

var _state = State.INITIALIZING
var _deck: Array[Card] = []

@onready var _camera = $Camera
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
@onready var _shuffle_audio_player = $ShuffleAudioPlayer
@onready var _card_contact_audio_player = $CardContactAudioPlayer


func _ready():
	_state = State.INITIALIZING
	_deck = _generate_deck()
	_state = State.INITIALIZED


func start_new_game() -> void:
	if _state == State.INITIALIZED or _state == State.PLAYING:
		var should_gather_cards = _state == State.PLAYING

		_state = State.DEALING
		_disable_card_interactions()

		if should_gather_cards:
			await _gather_cards()

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

	_shuffle_audio_player.play()
	to_deal.shuffle()
	await _shuffle_audio_player.finished

	# Temporarily adjust the z-indexes of all the cards.
	# As the cards are dealt, their z-indexes will be reset
	# back to 0, making it look like the cards are being
	# drawn from the top of the deck.
	for card_idx in to_deal.size():
		to_deal[card_idx].z_index = -1

	# Used to create the deal animation
	var tween = create_tween() \
			.set_parallel(false) \
			.set_ease(Tween.EASE_OUT)

	# Add a short delay between the shuffle sound and the deal animation
	tween.tween_interval(0.2)

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
				tween.tween_callback(func():
					card.is_face_up = not is_face_down
					# Reset the z-index so that the card appears to be
					# drawn from the top of the deck.
					card.z_index = 0
				)
				column.add_card(card, tween, DEAL_DURATION / 52)
				tween.tween_callback(_card_contact_audio_player.play)

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

	_update_camera_limits()

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

	# Auto scroll will allow the user to drag the card
	# on to cards which may initially be out of view.
	_camera.auto_scroll = true

	await dragged_card.drag_ended

	# Auto scroll should only be on while a card is being dragged.
	_camera.auto_scroll = false

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
			var card = cards_moving[card_idx]

			# Staggers the cards
			var movement_delay = card_idx * CARD_MOVE_STAGGER_DURATION
			new_column.add_card(card, tween, CARD_MOVE_DURATION) \
					.set_delay(movement_delay)

			# Play the sound when the card reaches its destination.
			tween.tween_callback(_card_contact_audio_player.play) \
					.set_delay(movement_delay + CARD_MOVE_DURATION)

		initial_column.after_cards_removed()
		_update_camera_limits()
	else:
		# Move the cards back to where they were started.
		for card_idx in cards_moving.size():
			var card = cards_moving[card_idx]
			var initial_position = initial_positions[card_idx]

			# Staggers the cards
			var movement_delay = card_idx * CARD_MOVE_STAGGER_DURATION
			tween.tween_property(card, "position", initial_position, CARD_MOVE_DURATION) \
					.set_delay(movement_delay)

			# Play the sound when the card reaches its destination
			tween.tween_callback(_card_contact_audio_player.play) \
					.set_delay(movement_delay + CARD_MOVE_DURATION)

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


func _update_camera_limits():
	var table_height = _columns \
			.map(func(c: Column): return c.position.y + c.get_size().y) \
			.max()

	_camera.adjust_limits_for_table_height(table_height)
