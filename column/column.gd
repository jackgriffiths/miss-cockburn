class_name Column
extends Node2D

const CARD_OFFSET = Vector2(0, 50)

var _last_card: Card = null
var _next_card_position = Vector2.ZERO


func add_card(card: Card, tween: Tween, animation_duration: float) -> PropertyTweener:
	if card.get_parent():
		card.reparent(self)
	else:
		add_child(card)

	var position_tween = tween.tween_property(card, "position", _next_card_position, animation_duration)

	_last_card = card
	_next_card_position += CARD_OFFSET

	return position_tween


func get_cards_after(card: Card) -> Array[Card]:
	var found_initial = false
	var after: Array[Card] = []

	for child in get_children():
		if child == card:
			found_initial = true
		elif found_initial and child is Card:
			after.append(child)

	return after
