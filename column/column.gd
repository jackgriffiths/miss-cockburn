class_name Column
extends Node2D

const CARD_OFFSET = Vector2(0, 50)

var _last_card: Card = null
var _next_card_position = Vector2.ZERO

@onready var _dropzone = $Dropzone


func add_card(card: Card, tween: Tween, animation_duration: float) -> PropertyTweener:
	# This is to support ALLOW_INVALID_MOVES=true, where a card could be
	# placed on top of a face down card.
	if _last_card and _last_card.can_make_face_up:
		_last_card.can_make_face_up = false

	# Make the card a child of the column so the column can keep track
	# of which cards belong to it.
	if card.get_parent():
		card.reparent(self)
	else:
		add_child(card)

	# Move the card in to position and place the dropzone on top of the card.
	var position_tween = tween.tween_property(card, "position", _next_card_position, animation_duration)
	_dropzone.position = _next_card_position

	_last_card = card
	_next_card_position += CARD_OFFSET

	return position_tween


func after_cards_removed() -> void:
	_last_card = null

	for child in get_children():
		if child is Card:
			_last_card = child

	if _last_card:
		_next_card_position = _last_card.position + CARD_OFFSET
		_dropzone.position = _last_card.position
	else:
		_next_card_position = Vector2.ZERO
		_dropzone.position = Vector2.ZERO

	if _last_card and not _last_card.is_face_up:
		_last_card.can_make_face_up = true


func get_cards_after(card: Card) -> Array[Card]:
	var found_initial = false
	var after: Array[Card] = []

	for child in get_children():
		if child == card:
			found_initial = true
		elif found_initial and child is Card:
			after.append(child)

	return after


func get_last_card() -> Card:
	return _last_card


func disable_dropzone():
	_dropzone.disable()


func enable_dropzone():
	_dropzone.enable()


func get_size() -> Vector2:
	# The dropzone is always the last item in the column so
	# its position (and size) can be used to calculate the
	# size of the column.
	var width = _dropzone.get_size().x
	var height = _dropzone.position.y + _dropzone.get_size().y
	return Vector2(width, height)
