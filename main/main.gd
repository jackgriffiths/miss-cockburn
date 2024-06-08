extends Node2D

@onready var _table = $Table
@onready var _menu = $Menu


func _ready() -> void:
	_menu.connect("new_game_started", _new_game)


func _new_game() -> void:
	_table.start_new_game()
