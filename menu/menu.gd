extends CanvasLayer

@onready var _continue_button: Button = $Content/Column/ContinueButton
@onready var _quit_button: Button = $Content/Column/QuitButton


func _ready() -> void:
	_continue_button.connect("pressed", _continue)
	_quit_button.connect("pressed", _quit)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu"):
		visible = not visible


func _continue():
	visible = false


func _quit():
	get_tree().quit()
