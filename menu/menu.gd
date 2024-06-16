extends CanvasLayer

signal new_game_started

const USER_PREFERENCES_PATH = "user://preferences.cfg"
const AUDIO_PREFERENCES_SECTION = "audio"
const AUDIO_PREFERENCES_MUTED_KEY = "muted"

var _config = ConfigFile.new()
@onready var _continue_button: Button = $Content/Column/Buttons/ContinueButton
@onready var _new_game_button: Button = $Content/Column/Buttons/NewGameButton
@onready var _mute_button: Button = $Content/Column/Buttons/MuteButton
@onready var _quit_button: Button = $Content/Column/Buttons/QuitButton


func _ready() -> void:
	_continue_button.connect("pressed", _continue)
	_new_game_button.connect("pressed", _new_game)
	_mute_button.connect("pressed", _toggle_mute)
	_quit_button.visible = not OS.has_feature("web")
	_quit_button.connect("pressed", _quit)
	_config.load(USER_PREFERENCES_PATH)
	_apply_audio_preferences()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu"):
		visible = not visible


func _continue():
	visible = false


func _new_game():
	new_game_started.emit()
	visible = false
	_continue_button.visible = true


func _apply_audio_preferences():
	var is_muted = _is_muted()
	AudioServer.set_bus_mute(0, is_muted)
	_mute_button.text = "Unmute" if is_muted else "Mute"


func _is_muted():
	return _config.get_value(AUDIO_PREFERENCES_SECTION, AUDIO_PREFERENCES_MUTED_KEY, false)


func _toggle_mute():
	_config.set_value(AUDIO_PREFERENCES_SECTION, AUDIO_PREFERENCES_MUTED_KEY, not _is_muted())
	_config.save(USER_PREFERENCES_PATH)
	_apply_audio_preferences()


func _quit():
	get_tree().quit()
