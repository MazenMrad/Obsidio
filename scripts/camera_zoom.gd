extends Camera2D

@export var zoom_step: float = 0.1
@export var max_zoom_in: float = 3.0
@export var max_shake_offset: float = 18.0

var _default_zoom: float = 1.0
var _base_offset: Vector2 = Vector2.ZERO
var _shake_tween: Tween


func _ready() -> void:
	_default_zoom = zoom.x
	_base_offset = offset


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


func shake(amount: float, duration: float) -> void:
	var clamped_amount: float = clampf(amount, 0.0, max_shake_offset)
	if clamped_amount <= 0.0 or duration <= 0.0:
		return

	if _shake_tween:
		_shake_tween.kill()

	_shake_tween = create_tween()
	_shake_tween.tween_method(_apply_shake_step, clamped_amount, 0.0, duration)
	_shake_tween.finished.connect(_reset_shake, CONNECT_ONE_SHOT)


func _apply_shake_step(value: float) -> void:
	offset = _base_offset + Vector2(randf_range(-value, value), randf_range(-value, value))


func _reset_shake() -> void:
	offset = _base_offset
