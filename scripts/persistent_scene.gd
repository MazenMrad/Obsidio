extends Node

## Scene Manager - Handles scene transitions with wipe effect
## Following Godot best practices for scene management

signal transition_started
signal transition_finished
signal scene_changed(scene_path: String)

const PERSISTENT_SCENE := preload("res://scenes/persistent_foreground_scene.tscn")

var _foreground_canvas: CanvasLayer
var _transition_effect: ColorRect
var _transition_tween: Tween
var _is_transitioning: bool = false
const _RADIUS_REVEALED: float = 1.2
const _RADIUS_COVERED: float = 0.01
const _CENTER_ONSCREEN: Vector2 = Vector2(0.5, 0.5)
const _CENTER_OFFSCREEN: Vector2 = Vector2(-10.0, -10.0)

func _ready() -> void:
	_setup_transition_overlay()


func _setup_transition_overlay() -> void:
	_foreground_canvas = CanvasLayer.new()
	_foreground_canvas.layer = 1000
	add_child(_foreground_canvas)
	
	var scene: Node = null
	var ok: bool = false
	if ResourceLoader.exists("res://scenes/persistent_foreground_scene.tscn"):
		scene = PERSISTENT_SCENE.instantiate()
		ok = scene != null
	
	if not ok or scene == null:
		push_error("[PersistentScene] Failed to instantiate persistent_foreground_scene.tscn — transitions disabled")
		return
	
	_foreground_canvas.add_child(scene)
	
	# Get the transition effect by path (not unique name)
	_transition_effect = scene.get_node_or_null("TransitionEffect")
	if _transition_effect:
		_transition_effect.visible = false
	else:
		push_error("[PersistentScene] Could not find TransitionEffect node!")


## Main method to change scenes with transition
func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	
	if _transition_effect == null or _transition_effect.material == null:
		push_warning("[PersistentScene] Transition effect not found, changing scene directly")
		get_tree().change_scene_to_file(scene_path)
		scene_changed.emit(scene_path)
		return
	
	_is_transitioning = true
	transition_started.emit()
	
	# Kill any existing tween
	if _transition_tween:
		_transition_tween.kill()
	
	# Keep shader parameters in sync with the active viewport.
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_transition_effect.material.set_shader_parameter("resolution", viewport_size)
	_transition_effect.material.set_shader_parameter("invert", true)
	_transition_effect.material.set_shader_parameter("color", Color(0, 0, 0, 1))

	# Start revealed (large radius).
	_transition_effect.material.set_shader_parameter("center", _CENTER_ONSCREEN)
	_transition_effect.material.set_shader_parameter("radius", _RADIUS_REVEALED)
	_transition_effect.visible = true
	
	# Cover the screen by shrinking the reveal radius.
	_transition_tween = create_tween()
	var tween_duration := 0.4
	_transition_tween.tween_method(
		_set_radius.bind(_transition_effect),
		_RADIUS_REVEALED,
		_RADIUS_COVERED,
		tween_duration
	)
	await _transition_tween.finished

	# Ensure fully covered (remove tiny center hole).
	_transition_effect.material.set_shader_parameter("center", _CENTER_OFFSCREEN)
	
	# Change the scene while screen is covered
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(scene_path)
	
	# Wait a frame for scene to load
	await get_tree().process_frame
	
	# Reveal the new scene (expand reveal radius back to full).
	_transition_effect.material.set_shader_parameter("center", _CENTER_ONSCREEN)
	_transition_effect.material.set_shader_parameter("radius", _RADIUS_COVERED)
	_transition_tween = create_tween()
	_transition_tween.tween_method(
		_set_radius.bind(_transition_effect),
		_RADIUS_COVERED,
		_RADIUS_REVEALED,
		0.3
	)
	await _transition_tween.finished
	_on_fade_out_complete()

func _set_radius(value: float, effect: ColorRect) -> void:
	if effect and effect.material:
		effect.material.set_shader_parameter("radius", value)


func _on_fade_out_complete() -> void:
	if _transition_effect:
		if _transition_effect.material:
			_transition_effect.material.set_shader_parameter("radius", _RADIUS_REVEALED)
			_transition_effect.material.set_shader_parameter("center", _CENTER_ONSCREEN)
		_transition_effect.visible = false
	
	_is_transitioning = false
	transition_finished.emit()


## Quick scene change without transition
func change_scene_instant(scene_path: String) -> void:
	if _is_transitioning:
		return
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(scene_path)


## Check if currently transitioning
func is_transitioning() -> bool:
	return _is_transitioning


## Reload current scene
func reload_current_scene() -> void:
	var current := get_tree().current_scene
	if current:
		change_scene(current.scene_file_path)


## Restart the game (go to main menu)
func go_to_main_menu() -> void:
	change_scene("res://scenes/main_menu.tscn")
