extends CharacterBody2D

# === Constants ===
const KEY_Q: int = 81
const BOW_UI: Texture2D = preload("res://assets/GUI/bow_ui.png")
const ROCK_UI: Texture2D = preload("res://assets/GUI/rock_ui.png")
const KNIFE_UI: Texture2D = preload("res://assets/GUI/knife_ui.png")
const AXE_UI: Texture2D = preload("res://assets/GUI/axe_ui.png")
const SPEAR_UI: Texture2D = preload("res://assets/GUI/spear_ui.png")
const ARROW_SCENE: PackedScene = preload("res://scenes/arrow.tscn")
const ROCK_SCENE: PackedScene = preload("res://scenes/rock.tscn")
const KNIFE_SCENE: PackedScene = preload("res://scenes/knife.tscn")
const AXE_SCENE: PackedScene = preload("res://scenes/throwing_axe.tscn")
const SPEAR_SCENE: PackedScene = preload("res://scenes/spear.tscn")
const WEAPON_ORDER: Array[String] = ["rock", "bow", "knife", "axe", "spear"]

# === Exports ===
@export var trajectory_points: int = 150
@export var trajectory_gravity: float = 980.0
@export var max_drag_distance: float = 220.0
@export var max_launch_power: float = 1.9
@export var trajectory_preview_length: float = 320.0
@export var trajectory_tip_length: float = 28.0

# === Onready ===
@onready var shoot_point: Marker2D = $arrowspawn
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var weapon_ui: TextureRect = $"../CanvasLayer/Control/weapon_ui"
@onready var equip_sound: AudioStreamPlayer2D = $"../Audio/equip"
@onready var upgrade_map: Control = $"../CanvasLayer/upgrade_map"

# === Private State ===
var _mouse_in_button: bool = false
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO

var _weapon_scenes: Dictionary = {}
var _weapon_icons: Dictionary = {}
var _weapon_enum_by_name: Dictionary = {}
var _weapon_name_by_enum: Dictionary = {}
var _weapon_base_speeds: Dictionary = {}
var _weapon_linear_damps: Dictionary = {}
var _physics_step: float = 1.0 / 60.0
var _project_gravity: float = 980.0
var _current_weapon: global_var.Weapon = global_var.Weapon.BOW
var _trajectory_tip: Line2D = null


func _ready() -> void:
	print("Enhanced Player system loaded")
	trajectory_line.visible = false
	trajectory_line.top_level = true
	trajectory_line.position = Vector2.ZERO
	trajectory_line.width = 2.0
	trajectory_line.default_color = Color.WHITE
	_trajectory_tip = Line2D.new()
	_trajectory_tip.visible = false
	_trajectory_tip.top_level = true
	_trajectory_tip.antialiased = true
	_trajectory_tip.width = 3.5
	_trajectory_tip.default_color = Color(1, 1, 1, 0.8)
	add_child(_trajectory_tip)

	_initialize_weapon_data()
	_cache_projectile_stats()
	_project_gravity = (
		ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
		if ProjectSettings.has_setting("physics/2d/default_gravity")
		else 980.0
	)
	trajectory_gravity = _project_gravity
	_physics_step = 1.0 / maxf(1.0, float(ProjectSettings.get_setting("physics/2d/physics_fps", 60)))

	_connect_to_buttons_signal()
	_set_current_weapon(_coerce_weapon_state(global_var.state), false)


func _connect_to_buttons_signal() -> void:
	var buttons: Control = get_parent().get_node_or_null("CanvasLayer/Control")
	if buttons and buttons.has_signal("button_hover_changed"):
		buttons.button_hover_changed.connect(_on_button_hover_changed)


func _initialize_weapon_data() -> void:
	_weapon_scenes = {
		"rock": ROCK_SCENE,
		"bow": ARROW_SCENE,
		"knife": KNIFE_SCENE,
		"axe": AXE_SCENE,
		"spear": SPEAR_SCENE
	}
	_weapon_icons = {
		"rock": ROCK_UI,
		"bow": BOW_UI,
		"knife": KNIFE_UI,
		"axe": AXE_UI,
		"spear": SPEAR_UI
	}
	_weapon_enum_by_name = {
		"rock": global_var.Weapon.ROCK,
		"bow": global_var.Weapon.BOW,
		"knife": global_var.Weapon.KNIFE,
		"axe": global_var.Weapon.AXE,
		"spear": global_var.Weapon.SPEAR
	}
	_weapon_name_by_enum = {
		global_var.Weapon.ROCK: "rock",
		global_var.Weapon.BOW: "bow",
		global_var.Weapon.KNIFE: "knife",
		global_var.Weapon.AXE: "axe",
		global_var.Weapon.SPEAR: "spear"
	}


func _cache_projectile_stats() -> void:
	for weapon_name in _weapon_scenes.keys():
		var projectile_scene: PackedScene = _weapon_scenes[weapon_name] as PackedScene
		var projectile: Node = projectile_scene.instantiate()
		if projectile != null:
			_weapon_base_speeds[weapon_name] = float(projectile.get("speed"))
			_weapon_linear_damps[weapon_name] = float(projectile.get("linear_damp"))
			projectile.queue_free()


func _on_button_hover_changed(is_hovering: bool) -> void:
	_mouse_in_button = is_hovering


func _process(_delta: float) -> void:
	var desired_weapon: global_var.Weapon = _coerce_weapon_state(global_var.state)
	if desired_weapon != _current_weapon:
		_set_current_weapon(desired_weapon, false)

	var pointer_blocking: bool = _is_pointer_over_blocking_ui()
	_mouse_in_button = pointer_blocking

	if _is_input_blocked_by_menu():
		if _is_dragging:
			_cancel_drag()
		_mouse_in_button = true
		return

	if _is_dragging:
		update_trajectory()
	else:
		if _trajectory_tip != null:
			_trajectory_tip.visible = false

	if Input.is_action_just_pressed("KEY_Q"):
		switch_weapon()
	handle_drag_shooting_current_weapon()


func switch_weapon() -> void:
	var available_weapons: Array[String] = _get_available_weapons()
	if available_weapons.is_empty():
		return

	var current_name: String = _get_current_weapon_name()
	var current_index: int = available_weapons.find(current_name)
	if current_index == -1:
		current_index = 0
	var next_index: int = (current_index + 1) % available_weapons.size()
	var next_weapon: global_var.Weapon = int(_weapon_enum_by_name[available_weapons[next_index]])
	_set_current_weapon(next_weapon)


func handle_drag_shooting_current_weapon() -> void:
	if _mouse_in_button or _is_pointer_over_blocking_ui() or not _can_shoot_current_weapon():
		return

	if Input.is_action_pressed("MOUSE_BUTTON_LEFT") and not _is_dragging:
		start_drag()
	elif _is_dragging and Input.is_action_pressed("MOUSE_BUTTON_LEFT"):
		update_trajectory()
	elif _is_dragging and Input.is_action_just_released("MOUSE_BUTTON_LEFT"):
		release_drag()


func start_drag() -> void:
	if _is_pointer_over_blocking_ui():
		return
	_is_dragging = true
	_drag_start_pos = get_global_mouse_position()
	trajectory_line.visible = true

	if _current_weapon == global_var.Weapon.BOW:
		$bow_draw.play()
		$AnimatedSprite2D.play("hold arrow idle")
	else:
		$AnimatedSprite2D.play("throw_idle", false)


func update_trajectory() -> void:
	if not _is_dragging:
		return

	var drag_end_pos: Vector2 = get_global_mouse_position()
	var drag_vector: Vector2 = _drag_start_pos - drag_end_pos
	var raw_distance: float = drag_vector.length()
	var clamped_distance: float = minf(raw_distance, max_drag_distance)
	var power_ratio: float = clamped_distance / maxf(max_drag_distance, 0.001)
	var power: float = _get_launch_power(power_ratio)
	var direction: Vector2 = drag_vector.normalized() if drag_vector.length() > 0 else Vector2.ZERO

	var weapon_name: String = _get_current_weapon_name()
	var base_speed: float = float(_weapon_base_speeds.get(weapon_name, 300.0))
	var linear_damp: float = float(_weapon_linear_damps.get(weapon_name, 0.0))
	var damp_factor: float = exp(-linear_damp * _physics_step) if linear_damp > 0.0 else 1.0

	var points: PackedVector2Array = PackedVector2Array()
	var current_pos: Vector2 = shoot_point.global_position
	var current_vel: Vector2 = direction * base_speed * power
	var preview_distance: float = 0.0

	for _i in range(trajectory_points):
		points.append(current_pos)
		current_vel.y += trajectory_gravity * _physics_step
		current_vel *= damp_factor
		var next_pos: Vector2 = current_pos + current_vel * _physics_step
		preview_distance += current_pos.distance_to(next_pos)
		current_pos = next_pos

		if preview_distance >= trajectory_preview_length or current_pos.y > get_viewport_rect().size.y + 100:
			break

	trajectory_line.points = points
	_update_trajectory_tip(points, power)

	var alpha: float = lerpf(0.35, 0.9, power)
	var width: float = lerpf(1.5, 4.0, power)
	trajectory_line.modulate = Color(1.0, 1.0, 1.0, alpha)
	trajectory_line.width = width * 0.5


func _update_trajectory_tip(points: PackedVector2Array, power: float) -> void:
	if _trajectory_tip == null:
		return
	if points.size() < 2:
		_trajectory_tip.visible = false
		return

	var last_index: int = points.size() - 1
	var direction: Vector2 = points[last_index] - points[last_index - 1]
	if direction.length_squared() == 0.0:
		_trajectory_tip.visible = false
		return

	direction = direction.normalized()
	var tip_length: float = lerpf(10.0, trajectory_tip_length, power)
	var tip_start: Vector2 = points[last_index] - direction * tip_length
	_trajectory_tip.points = PackedVector2Array([tip_start, points[last_index]])
	_trajectory_tip.visible = true


func _ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


func _get_launch_power(power_ratio: float) -> float:
	return lerpf(0.2, max_launch_power, _ease_out_cubic(power_ratio))


func release_drag() -> void:
	var drag_force: Vector2 = _drag_start_pos - get_global_mouse_position()
	var clamped_distance: float = minf(drag_force.length(), max_drag_distance)
	var power_ratio: float = clamped_distance / maxf(max_drag_distance, 0.001)
	var power: float = _get_launch_power(power_ratio)

	if _current_weapon == global_var.Weapon.BOW:
		$bow_draw.stop()
		$bow_release.play()
		$AnimatedSprite2D.play("loose", false)
		_shoot_projectile("bow", drag_force, power)
	else:
		$AnimatedSprite2D.play("throw", false)
		_shoot_projectile(_get_current_weapon_name(), drag_force, power)

	_is_dragging = false
	trajectory_line.visible = false
	_trajectory_tip.visible = false
	_trajectory_tip.points = PackedVector2Array()

	await get_tree().create_timer(0.14).timeout
	$AnimatedSprite2D.play("idle")


func _cancel_drag() -> void:
	_is_dragging = false
	trajectory_line.visible = false
	_trajectory_tip.visible = false
	_trajectory_tip.points = PackedVector2Array()
	$bow_draw.stop()
	$AnimatedSprite2D.play("idle")


func _is_input_blocked_by_menu() -> bool:
	return upgrade_map != null and upgrade_map.visible


func _can_shoot_current_weapon() -> bool:
	return _current_weapon != global_var.Weapon.BOW or global_var.arrows > 0


func _coerce_weapon_state(weapon_state: global_var.Weapon) -> global_var.Weapon:
	var weapon_name: String = str(_weapon_name_by_enum.get(weapon_state, "bow"))
	if weapon_name in global_var.unlocked_weapons:
		return weapon_state
	return global_var.Weapon.BOW if "bow" in global_var.unlocked_weapons else global_var.Weapon.ROCK


func _get_available_weapons() -> Array[String]:
	var available_weapons: Array[String] = []
	for weapon_name in WEAPON_ORDER:
		if weapon_name in global_var.unlocked_weapons:
			available_weapons.append(weapon_name)
	return available_weapons


func _get_current_weapon_name() -> String:
	return str(_weapon_name_by_enum.get(_current_weapon, "bow"))


func _set_current_weapon(new_weapon: global_var.Weapon, play_sound: bool = true) -> void:
	_current_weapon = new_weapon
	global_var.state = new_weapon
	weapon_ui.texture = _weapon_icons.get(_get_current_weapon_name(), BOW_UI) as Texture2D
	if play_sound:
		equip_sound.play()


func _is_pointer_over_blocking_ui() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false

	var hud_root: Control = get_parent().get_node_or_null("CanvasLayer/Control")
	if hud_root != null and hud_root.is_ancestor_of(hovered):
		if hovered is BaseButton:
			return true

	if upgrade_map != null and (hovered == upgrade_map or upgrade_map.is_ancestor_of(hovered)):
		return true

	return false


func _shoot_projectile(weapon_name: String, drag_force: Vector2, power: float) -> void:
	if weapon_name == "bow" and global_var.arrows <= 0:
		return

	var projectile_scene: PackedScene = _weapon_scenes.get(weapon_name, ARROW_SCENE) as PackedScene
	var projectile: Node = projectile_scene.instantiate()
	projectile.global_position = shoot_point.global_position
	get_tree().root.add_child(projectile)
	var direction: Vector2 = drag_force.normalized() if drag_force.length() > 0 else Vector2.RIGHT
	projectile.set("linear_damp", _weapon_linear_damps.get(weapon_name, 0.0))
	if projectile.has_method("shoot"):
		projectile.shoot(direction, power)
	if weapon_name == "bow":
		global_var.arrows -= 1
