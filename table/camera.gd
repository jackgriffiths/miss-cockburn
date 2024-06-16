extends Camera2D

const SCROLL_STEP = 50
const AUTO_SCROLL_STEP = 20
const AUTO_SCROLL_THRESHOLD = 100

var auto_scroll = false

var _viewport_rect: Rect2
var _is_dragging = false
var _drag_start_position = Vector2.ZERO
var _drag_start_origin = Vector2.ZERO


func _ready():
	_viewport_rect = get_viewport_rect()


func _unhandled_input(event: InputEvent):
	if _is_dragging:
		if event.is_action_released("click"):
			_is_dragging = false
			_drag_start_position = Vector2.ZERO
			_drag_start_origin = Vector2.ZERO
			position_smoothing_enabled = true
	else:
		if event.is_action_pressed("click"):
			_is_dragging = true
			_drag_start_position = position
			_drag_start_origin = get_global_mouse_position() - global_position
			position_smoothing_enabled = false
		if event.is_action_released("scroll_down"):
			_move_within_limits(position.y + SCROLL_STEP)
		elif event.is_action_released("scroll_up"):
			_move_within_limits(position.y - SCROLL_STEP)


func _process(_delta):
	if _is_dragging:
		var distance_moved = get_local_mouse_position().y - _drag_start_origin.y
		_move_within_limits(_drag_start_position.y - distance_moved)
	elif auto_scroll:
		var local_mouse_position = get_local_mouse_position()
		var mouse_within_viewport = _viewport_rect.has_point(local_mouse_position)

		if mouse_within_viewport:
			if local_mouse_position.y < AUTO_SCROLL_THRESHOLD:
				_move_within_limits(position.y - AUTO_SCROLL_STEP)
			elif local_mouse_position.y > _viewport_rect.size.y - AUTO_SCROLL_THRESHOLD:
				_move_within_limits(position.y + AUTO_SCROLL_STEP)


func adjust_limits_for_table_height(height: float):
	var height_with_margin = height + 50

	if height_with_margin <= _viewport_rect.size.y:
		limit_bottom = int(_viewport_rect.size.y)
	else:
		limit_bottom = int(height_with_margin)


func _move_within_limits(y: float):
	# Even though the limits stop the camera from showing
	# the user beyond the limit rectangle, the camera's
	# position property is not limited. It is necessary
	# to manually clamp the position within the limits.
	var min_y = limit_top
	var max_y = limit_bottom - _viewport_rect.size.y
	position.y = clamp(y, min_y, max_y)
