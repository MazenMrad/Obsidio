extends Camera2D

@export var zoom_step: float = 0.1
@export var max_zoom_in: float = 3.0

var _default_zoom: float = 1.0


func _ready() -> void:
	_default_zoom = zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom_value(zoom.x + zoom_step)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom_value(zoom.x - zoom_step)


func _set_zoom_value(value: float) -> void:
	var clamped := clampf(value, _default_zoom, max_zoom_in)
	zoom = Vector2(clamped, clamped)
