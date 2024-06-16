extends Node2D

@onready var _table = $Table
@onready var _menu_button = $UI/Buttons/MenuButton
@onready var _menu = $Menu


func _ready() -> void:
	_menu_button.connect("pressed", _menu.show)
	_menu.connect("visibility_changed", _update_menu_button)
	_menu.connect("new_game_started", _new_game)


func _update_menu_button():
	_menu_button.visible = not _menu.visible


func _new_game() -> void:
	_table.start_new_game()
