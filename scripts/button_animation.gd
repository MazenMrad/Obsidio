## Button Animation - Adds scale animations on hover and press
## Attach this script to any Button or TextureButton for polished feel
class_name ButtonAnimation
extends Control

## Scale factor when hovering (1.0 = no change)
@export var hover_scale: float = 1.05

## Scale factor when pressing (1.0 = no change)
@export var press_scale: float = 0.95

## Animation duration in seconds
@export var animation_duration: float = 0.1

## Whether to use elastic easing
@export var use_elastic: bool = true

var _target_button: Control
var _original_scale: Vector2
var _tween: Tween


func _ready() -> void:
	_target_button = get_parent() as Control
	if _target_button == null:
		push_warning("[ButtonAnimation] Parent is not a Control node")
		return
	
	_original_scale = _target_button.scale
	
	# Connect signals
	if not _target_button.mouse_entered.is_connected(_on_mouse_entered):
		_target_button.mouse_entered.connect(_on_mouse_entered)
	if not _target_button.mouse_exited.is_connected(_on_mouse_exited):
		_target_button.mouse_exited.connect(_on_mouse_exited)
	
	# Check if it's a Button (has pressed signal) or TextureButton
	if _target_button is Button:
		if not _target_button.button_down.is_connected(_on_button_down):
			_target_button.button_down.connect(_on_button_down)
		if not _target_button.button_up.is_connected(_on_button_up):
			_target_button.button_up.connect(_on_button_up)
	elif _target_button is TextureButton:
		if not _target_button.button_down.is_connected(_on_button_down):
			_target_button.button_down.connect(_on_button_down)
		if not _target_button.button_up.is_connected(_on_button_up):
			_target_button.button_up.connect(_on_button_up)


func _on_mouse_entered() -> void:
	_animate_to_scale(Vector2(hover_scale, hover_scale) * _original_scale)


func _on_mouse_exited() -> void:
	_animate_to_scale(_original_scale)


func _on_button_down() -> void:
	_animate_to_scale(Vector2(press_scale, press_scale) * _original_scale)


func _on_button_up() -> void:
	# Return to hover scale if still hovering, otherwise original
	if _target_button != null and _target_button.is_hovered():
		_animate_to_scale(Vector2(hover_scale, hover_scale) * _original_scale)
	else:
		_animate_to_scale(_original_scale)


func _animate_to_scale(target_scale: Vector2) -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	
	if use_elastic:
		_tween.set_trans(Tween.TRANS_BACK)
		_tween.set_ease(Tween.EASE_OUT)
	else:
		_tween.set_trans(Tween.TRANS_QUAD)
		_tween.set_ease(Tween.EASE_OUT)
	
	_tween.tween_property(_target_button, "scale", target_scale, animation_duration)
