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
const AIM_UP_DOT_THRESHOLD: float = -0.35
const WEAPON_AMMO_COSTS: Dictionary = {
	"rock": 0,   # Free - always available fallback
	"bow": 1,    # Baseline ranged - fair
	"knife": 1,  # Fast throw, short range — cheap
	"axe": 2,    # Medium range, arc, good damage — moderate
	"spear": 2   # Long range, pierce, highest damage — moderate
}

const ANIM_IDLE_FALLBACK: StringName = &"idle"
const ANIM_IDLE_BREATH_FALLBACK: StringName = &"idlebreathing"
const ANIM_BOW_DRAW_FALLBACK: StringName = &"bowdraw"
const ANIM_BOW_HOLD_FALLBACK: StringName = &"bowhold"
const ANIM_BOW_RELEASE_FALLBACK: StringName = &"bowrelease"
const ANIM_BOW_UP_DRAW_FALLBACK: StringName = &"bowupdraw"
const ANIM_BOW_UP_HOLD_FALLBACK: StringName = &"bowuphold"
const ANIM_BOW_UP_RELEASE_FALLBACK: StringName = &"bowuprelease"
const ANIM_THROW_DRAW_FALLBACK: StringName = &"throw"
const ANIM_THROW_HOLD_FALLBACK: StringName = &"throwhold"
const ANIM_THROW_RELEASE_FALLBACK: StringName = &"throw_release"

# === Exports ===
@export var trajectory_points: int = 150
@export var trajectory_gravity: float = 980.0
@export var max_drag_distance: float = 220.0
@export var max_launch_power: float = 1.9
@export var trajectory_preview_length: float = 320.0
@export var trajectory_tip_length: float = 40.0
@export var trajectory_min_dot_distance: float = 6.0 ## Min pixel distance between trajectory dots (closer = denser dots)
@export var trajectory_dot_size: float = 0.6 ## Size multiplier for dots (smaller = finer dots)
@export var bow_trajectory_build_time: float = 1.2 ## Time in seconds to fully build up bow trajectory (longer = more deliberate feel)
@export var rock_trajectory_points: int = 12 ## Limited dots for rock throw
@export var anim_idle: StringName = &"idle"
@export var anim_idle_breath: StringName = &"idlebreathing"
@export var anim_bow_draw: StringName = &"bowdraw"
@export var anim_bow_hold: StringName = &"bowhold"
@export var anim_bow_release: StringName = &"bowrelease"
@export var anim_bow_up_draw: StringName = &"bowupdraw"
@export var anim_bow_up_hold: StringName = &"bowuphold"
@export var anim_bow_up_release: StringName = &"bowuprelease"
@export var anim_throw_draw: StringName = &"throw"
@export var anim_throw_hold: StringName = &"throwhold"
@export var anim_throw_release: StringName = &"throw_release"
@export var idle_breath_min_delay: float = 6.0
@export var idle_breath_max_delay: float = 12.0

# === Onready ===
@onready var shoot_point: Marker2D = $arrowspawn
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_ui: TextureRect = $"../CanvasLayer/Control/weapon_ui"
@onready var equip_sound: AudioStreamPlayer2D = $"../Audio/equip"
@onready var buy_sound: AudioStreamPlayer2D = $"../Audio/buy_sound"
@onready var action_blocked_sound: AudioStreamPlayer2D = $action_blocked
@onready var upgrade_map: Control = $"../CanvasLayer/upgrade_map"

# === Private State ===
var _mouse_in_button: bool = false
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_time: float = 0.0 ## Time spent dragging (for bow trajectory buildup)

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
enum AnimPhase { IDLE, DRAW, HOLD, RELEASE }
enum BowPose { NORMAL, UP }

var _post_release_idle_anim: StringName = ANIM_IDLE_FALLBACK
var _anim_phase: AnimPhase = AnimPhase.IDLE
var _bow_pose: BowPose = BowPose.NORMAL
var _animation_token: int = 0
var _idle_breath_token: int = 0

# Trajectory tip dots (for drawing connected dots at trajectory end)
var _tip_dot_a: Vector2 = Vector2.ZERO
var _tip_dot_b: Vector2 = Vector2.ZERO
var _tip_dot_c: Vector2 = Vector2.ZERO


func _ready() -> void:
	print("Enhanced Player system loaded")
	trajectory_line.visible = false
	trajectory_line.top_level = true
	trajectory_line.position = Vector2.ZERO
	trajectory_line.width = 1.5
	trajectory_line.default_color = Color.WHITE
	_trajectory_tip = Line2D.new()
	_trajectory_tip.visible = false
	_trajectory_tip.top_level = true
	_trajectory_tip.antialiased = true
	_trajectory_tip.width = 2.5
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
	_sync_idle_animation()


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

	# Handle weapon change hotkey (Q)
	if Input.is_action_just_pressed("change_weapon"):
		switch_weapon()

	# Handle buy weapon hotkey (B)
	if Input.is_action_just_pressed("buy_weapon"):
		_buy_arrows()

	# Handle drag/shooting - MUST be called every frame
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
	
	# Play weapon swap animation
	_play_weapon_swap_animation(next_weapon)


func _buy_arrows() -> void:
	# Buy arrows for 1 coin each
	if global_var.coins >= 1:
		global_var.coins -= 1
		global_var.arrows += 1
		if buy_sound != null:
			buy_sound.play()


func handle_drag_shooting_current_weapon() -> void:
	if _mouse_in_button or _is_pointer_over_blocking_ui():
		return
	if not _can_shoot_current_weapon():
		# Show no-ammo feedback when player tries to shoot
		if Input.is_action_just_pressed("MOUSE_BUTTON_LEFT"):
			_show_no_ammo_feedback()
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
	_drag_time = 0.0 # Reset drag time for trajectory buildup
	# Make trajectory line invisible (we draw dots via _draw instead)
	trajectory_line.visible = false
	trajectory_line.top_level = true
	trajectory_line.position = Vector2.ZERO

	if _current_weapon == global_var.Weapon.BOW:
		$bow_draw.play()
		_bow_pose = BowPose.NORMAL
		_play_phase_animation(AnimPhase.DRAW, _get_bow_draw_anim(_bow_pose), AnimPhase.HOLD, _get_bow_hold_anim(_bow_pose))
	else:
		_play_phase_animation(AnimPhase.DRAW, _get_throw_draw_anim(), AnimPhase.HOLD, _get_throw_hold_anim())


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
	if _current_weapon == global_var.Weapon.BOW:
		var new_pose: BowPose = _get_bow_pose_from_drag(drag_vector)
		if new_pose != _bow_pose:
			_bow_pose = new_pose
			if _anim_phase == AnimPhase.HOLD:
				_play_animation(_get_bow_hold_anim(_bow_pose))
			elif _anim_phase == AnimPhase.DRAW:
				_play_phase_animation(AnimPhase.DRAW, _get_bow_draw_anim(_bow_pose), AnimPhase.HOLD, _get_bow_hold_anim(_bow_pose))

	var weapon_name: String = _get_current_weapon_name()
	var base_speed: float = float(_weapon_base_speeds.get(weapon_name, 300.0))
	var linear_damp: float = float(_weapon_linear_damps.get(weapon_name, 0.0))
	var damp_factor: float = exp(-linear_damp * _physics_step) if linear_damp > 0.0 else 1.0

	var all_points: PackedVector2Array = PackedVector2Array()
	var current_pos: Vector2 = shoot_point.global_position
	var current_vel: Vector2 = direction * base_speed * power
	var preview_distance: float = 0.0

	# Determine max points based on weapon and buildup progress
	var max_points: int = trajectory_points
	if weapon_name == "rock":
		# Rock has very limited trajectory preview
		max_points = rock_trajectory_points
	elif weapon_name == "bow":
		# Bow builds up trajectory over time
		_drag_time += _physics_step
		var buildup: float = clampf(_drag_time / bow_trajectory_build_time, 0.0, 1.0)
		# Use a slower ease-in for more noticeable buildup (cubic ease)
		buildup = buildup * buildup * buildup  # Cubic ease-in: starts slow, speeds up
		# Start with just 5 dots and build to full trajectory_points
		max_points = int(lerpf(5.0, float(trajectory_points), buildup))

	for _i in range(max_points):
		all_points.append(current_pos)
		current_vel.y += trajectory_gravity * _physics_step
		current_vel *= damp_factor
		var next_pos: Vector2 = current_pos + current_vel * _physics_step
		preview_distance += current_pos.distance_to(next_pos)
		current_pos = next_pos

		if weapon_name == "rock":
			# Rock trajectory stops early
			if preview_distance >= trajectory_preview_length * 0.4:
				break
		else:
			# Other weapons use normal preview length
			if preview_distance >= trajectory_preview_length or current_pos.y > get_viewport_rect().size.y + 100:
				break

	trajectory_line.points = all_points
	trajectory_line.visible = false # Hide the line itself, we'll draw dots in _draw()
	_update_trajectory_tip(all_points, power, weapon_name)
	queue_redraw()

	var alpha: float = lerpf(0.35, 0.9, power)
	var width: float = lerpf(1.0, 2.5, power)
	trajectory_line.modulate = Color(1.0, 1.0, 1.0, alpha)
	trajectory_line.width = width


func _update_trajectory_tip(points: PackedVector2Array, power: float, weapon_name: String) -> void:
	if _trajectory_tip == null:
		return
	if points.size() < 3:
		_trajectory_tip.visible = false
		return

	# Rock has no extended tip - trajectory is too short
	if weapon_name == "rock":
		_trajectory_tip.visible = false
		return

	var last_index: int = points.size() - 1
	var second_last: int = points.size() - 2
	
	var direction: Vector2 = points[last_index] - points[second_last]
	if direction.length_squared() == 0.0:
		_trajectory_tip.visible = false
		return

	direction = direction.normalized()
	var tip_length: float = lerpf(8.0, trajectory_tip_length, power)
	
	# Instead of a line, use 2 connected dots at the tip
	var tip_end: Vector2 = points[last_index]
	var tip_mid: Vector2 = tip_end - direction * (tip_length * 0.5)
	var tip_start: Vector2 = tip_end - direction * tip_length
	
	# Store tip points for drawing in _draw()
	_tip_dot_a = tip_start
	_tip_dot_b = tip_mid
	_tip_dot_c = tip_end
	_trajectory_tip.visible = false # We draw these manually in _draw instead


func _ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


func _get_launch_power(power_ratio: float) -> float:
	return lerpf(0.2, max_launch_power, _ease_out_cubic(power_ratio))


func release_drag() -> void:
	var drag_force: Vector2 = _drag_start_pos - get_global_mouse_position()
	var clamped_distance: float = minf(drag_force.length(), max_drag_distance)
	var power_ratio: float = clamped_distance / maxf(max_drag_distance, 0.001)
	var power: float = _get_launch_power(power_ratio)
	var aim_up: bool = _is_aiming_up(drag_force)

	if _current_weapon == global_var.Weapon.BOW:
		$bow_draw.stop()
		$bow_release.play()
		_play_bow_release_animation(aim_up)
		_shoot_projectile("bow", drag_force, power)
	else:
		_play_throw_release_animation()
		_shoot_projectile(_get_current_weapon_name(), drag_force, power)

	_is_dragging = false
	_drag_time = 0.0
	trajectory_line.visible = false
	trajectory_line.points = PackedVector2Array()
	_trajectory_tip.visible = false
	_trajectory_tip.points = PackedVector2Array()
	queue_redraw()

func _cancel_drag() -> void:
	_is_dragging = false
	_drag_time = 0.0
	trajectory_line.visible = false
	trajectory_line.points = PackedVector2Array()
	_trajectory_tip.visible = false
	_trajectory_tip.points = PackedVector2Array()
	$bow_draw.stop()
	_animation_token += 1
	_anim_phase = AnimPhase.IDLE
	_sync_idle_animation()
	queue_redraw()


func _is_input_blocked_by_menu() -> bool:
	return upgrade_map != null and upgrade_map.visible


func _can_shoot_current_weapon() -> bool:
	var weapon_name: String = _get_current_weapon_name()
	var ammo_cost: int = _get_weapon_ammo_cost(weapon_name)
	return global_var.arrows >= ammo_cost


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


var _no_ammo_tween: Tween = null
var _has_shown_no_ammo_hint: bool = false

func _show_no_ammo_feedback() -> void:
	# Play action blocked sound
	if action_blocked_sound:
		action_blocked_sound.play()
	# Flash the arrow counter red
	var arrows_label: Label = get_parent().get_node_or_null("CanvasLayer/Control/indicators/arrows")
	if arrows_label:
		if _no_ammo_tween:
			_no_ammo_tween.kill()
		_no_ammo_tween = create_tween()
		_no_ammo_tween.tween_property(arrows_label, "modulate", Color.RED, 0.08)
		_no_ammo_tween.tween_property(arrows_label, "modulate", Color.WHITE, 0.2)
	# Flash the weapon UI icon
	if weapon_ui:
		var ui_tween := create_tween()
		ui_tween.tween_property(weapon_ui, "modulate", Color(1.0, 0.5, 0.5), 0.08)
		ui_tween.tween_property(weapon_ui, "modulate", Color.WHITE, 0.2)
	# Show hint on first no-ammo event
	if not _has_shown_no_ammo_hint:
		_has_shown_no_ammo_hint = true
		_show_floating_hint("No ammo! Press B to buy arrows")


func _show_floating_hint(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font := load("res://fonts/Fool.ttf") as FontFile
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color(1.0, 0.4, 0.4) # Reddish hint
	label.custom_minimum_size = Vector2(200, 24)
	label.z_index = 100
	get_parent().add_child(label)
	
	# Wait a frame for label to size, then center above tower
	await get_tree().process_frame
	
	# Position the hint centered above the active tower (not the player)
	var tower_pos: Vector2 = _get_active_tower_top_position()
	label.global_position = tower_pos - Vector2(label.size.x / 2.0, label.size.y + 10)
	
	var tween := create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 30, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(label.queue_free)


## Returns the world-space position on top of the active tower.
## Uses the PlayerMount marker (where the player stands) and offsets above it.
## Falls back to the player's position if no active tower is found.
func _get_active_tower_top_position() -> Vector2:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return global_position
	for tower_name: String in ["tower", "tower2", "tower3", "tower4", "tower5", "tower6"]:
		var tower: StaticBody2D = parent_node.get_node_or_null(tower_name) as StaticBody2D
		if tower and tower.visible:
			var mount: Marker2D = tower.get_node_or_null("PlayerMount") as Marker2D
			if mount:
				return mount.global_position + Vector2(0, -30)
			# Fallback: use tower's own global position + upward offset
			return tower.global_position + Vector2(0, -60)
	return global_position


func _set_current_weapon(new_weapon: global_var.Weapon, play_sound: bool = true) -> void:
	_current_weapon = new_weapon
	global_var.state = new_weapon
	weapon_ui.texture = _weapon_icons.get(_get_current_weapon_name(), BOW_UI) as Texture2D
	if play_sound:
		equip_sound.play()
	if not _is_dragging:
		_anim_phase = AnimPhase.IDLE
		_sync_idle_animation()


func _play_weapon_swap_animation(next_weapon: global_var.Weapon) -> void:
	# Cancel any ongoing animation state
	_animation_token += 1
	_cancel_idle_breath()
	
	# Play weapon_swap animation if it exists
	var swap_anim: StringName = &"weapon_swap"
	if _has_animation(swap_anim):
		sprite.play(swap_anim)
		# Wait for animation to finish, then switch weapon
		await sprite.animation_finished
	
	# Now switch to the new weapon
	_set_current_weapon(next_weapon)


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


func _on_animated_sprite_2d_animation_finished() -> void:
	if _anim_phase != AnimPhase.IDLE:
		return
	var breath_anim: StringName = _get_idle_breath_anim()
	if breath_anim != &"" and sprite.animation == breath_anim:
		_play_animation(_get_idle_anim_for_weapon())
		_schedule_idle_breath()


func _sync_idle_animation() -> void:
	_cancel_idle_breath()
	_play_animation(_get_idle_anim_for_weapon())
	_schedule_idle_breath()


func _play_animation(anim: StringName) -> void:
	if not _has_animation(anim):
		return
	sprite.play(anim)


func _play_phase_animation(
	phase: AnimPhase,
	anim: StringName,
	next_phase: AnimPhase = AnimPhase.IDLE,
	next_anim: StringName = &""
) -> void:
	_animation_token += 1
	var token: int = _animation_token
	_anim_phase = phase
	_play_animation(anim)

	var duration: float = _get_animation_duration(anim)
	if duration <= 0.0 or next_anim == &"":
		return

	_advance_phase_after_delay(token, duration, next_phase, next_anim)


func _advance_phase_after_delay(
	token: int,
	delay: float,
	next_phase: AnimPhase,
	next_anim: StringName
) -> void:
	await get_tree().create_timer(delay).timeout
	if token != _animation_token:
		return
	_anim_phase = next_phase
	if next_anim != &"":
		_play_animation(next_anim)


func _has_animation(anim: StringName) -> bool:
	if sprite.sprite_frames == null:
		return false
	return sprite.sprite_frames.has_animation(anim)


func _get_animation_duration(anim: StringName) -> float:
	if not _has_animation(anim):
		return 0.0
	var frame_count: int = sprite.sprite_frames.get_frame_count(anim)
	if frame_count <= 0:
		return 0.0
	var fps: float = sprite.sprite_frames.get_animation_speed(anim)
	if fps <= 0.0:
		return 0.0
	return float(frame_count) / fps


func _get_idle_anim_for_weapon() -> StringName:
	return _resolve_anim(anim_idle, ANIM_IDLE_FALLBACK)


func _get_idle_breath_anim() -> StringName:
	var breath_anim: StringName = _resolve_anim(anim_idle_breath, ANIM_IDLE_BREATH_FALLBACK)
	return breath_anim if _has_animation(breath_anim) else &""


func _get_throw_hold_anim() -> StringName:
	var hold_anim: StringName = _resolve_anim(anim_throw_hold, ANIM_THROW_HOLD_FALLBACK)
	return hold_anim if _has_animation(hold_anim) else _resolve_anim(anim_idle, ANIM_IDLE_FALLBACK)


func _get_bow_draw_anim(pose: BowPose) -> StringName:
	if pose == BowPose.UP:
		var up_draw: StringName = _resolve_anim(anim_bow_up_draw, ANIM_BOW_UP_DRAW_FALLBACK)
		if _has_animation(up_draw):
			return up_draw
	return _resolve_anim(anim_bow_draw, ANIM_BOW_DRAW_FALLBACK)


func _get_bow_hold_anim(pose: BowPose) -> StringName:
	if pose == BowPose.UP:
		var up_hold: StringName = _resolve_anim(anim_bow_up_hold, ANIM_BOW_UP_HOLD_FALLBACK)
		if _has_animation(up_hold):
			return up_hold
	return _resolve_anim(anim_bow_hold, ANIM_BOW_HOLD_FALLBACK)


func _get_bow_release_anim(pose: BowPose) -> StringName:
	if pose == BowPose.UP:
		var up_release: StringName = _resolve_anim(anim_bow_up_release, ANIM_BOW_UP_RELEASE_FALLBACK)
		if _has_animation(up_release):
			return up_release
	return _resolve_anim(anim_bow_release, ANIM_BOW_RELEASE_FALLBACK)


func _play_bow_release_animation(aim_up: bool) -> void:
	_bow_pose = BowPose.UP if aim_up else BowPose.NORMAL
	var release_anim: StringName = _get_bow_release_anim(_bow_pose)
	_post_release_idle_anim = _get_idle_anim_for_weapon()
	_play_phase_animation(AnimPhase.RELEASE, release_anim, AnimPhase.IDLE, _post_release_idle_anim)


func _play_throw_release_animation() -> void:
	_post_release_idle_anim = _get_idle_anim_for_weapon()
	var release_anim: StringName = _resolve_anim(anim_throw_release, ANIM_THROW_RELEASE_FALLBACK)
	if not _has_animation(release_anim):
		release_anim = _post_release_idle_anim
	_play_phase_animation(AnimPhase.RELEASE, release_anim, AnimPhase.IDLE, _post_release_idle_anim)


func _is_aiming_up(drag_force: Vector2) -> bool:
	if drag_force.length_squared() <= 0.001:
		return false
	var dir: Vector2 = drag_force.normalized()
	return dir.y <= AIM_UP_DOT_THRESHOLD


func _get_bow_pose_from_drag(drag_force: Vector2) -> BowPose:
	return BowPose.UP if _is_aiming_up(drag_force) else BowPose.NORMAL


func _get_throw_draw_anim() -> StringName:
	return _resolve_anim(anim_throw_draw, ANIM_THROW_DRAW_FALLBACK)


func _resolve_anim(primary: StringName, fallback: StringName) -> StringName:
	if _has_animation(primary):
		return primary
	if _has_animation(fallback):
		return fallback
	return primary


func _cancel_idle_breath() -> void:
	_idle_breath_token += 1


func _schedule_idle_breath() -> void:
	var breath_anim: StringName = _get_idle_breath_anim()
	if breath_anim == &"":
		return
	var min_delay: float = minf(idle_breath_min_delay, idle_breath_max_delay)
	var max_delay: float = maxf(idle_breath_min_delay, idle_breath_max_delay)
	var delay: float = randf_range(min_delay, max_delay)
	var token: int = _idle_breath_token
	_play_idle_breath_after_delay(token, delay, breath_anim)


func _play_idle_breath_after_delay(token: int, delay: float, breath_anim: StringName) -> void:
	await get_tree().create_timer(delay).timeout
	if token != _idle_breath_token:
		return
	if _anim_phase != AnimPhase.IDLE or _is_dragging:
		return
	if _is_input_blocked_by_menu():
		_schedule_idle_breath()
		return
	_play_animation(breath_anim)


func _shoot_projectile(weapon_name: String, drag_force: Vector2, power: float) -> void:
	var ammo_cost: int = _get_weapon_ammo_cost(weapon_name)
	if global_var.arrows < ammo_cost:
		return

	var projectile_scene: PackedScene = _weapon_scenes.get(weapon_name, ARROW_SCENE) as PackedScene
	var projectile: Node = projectile_scene.instantiate()
	projectile.global_position = shoot_point.global_position
	get_tree().root.add_child(projectile)
	var direction: Vector2 = drag_force.normalized() if drag_force.length() > 0 else Vector2.RIGHT
	projectile.set("linear_damp", _weapon_linear_damps.get(weapon_name, 0.0))
	if projectile.has_method("shoot"):
		projectile.shoot(direction, power)
	global_var.arrows -= ammo_cost


func _draw() -> void:
	# Draw dotted trajectory points when dragging
	if not _is_dragging or trajectory_line.points.size() < 2:
		return
	
	var points: PackedVector2Array = trajectory_line.points
	var dot_color: Color = trajectory_line.default_color
	var dot_radius: float = trajectory_line.width * trajectory_dot_size
	var min_distance: float = trajectory_min_dot_distance
	
	var last_drawn_pos: Vector2 = points[0]
	
	# Draw trajectory dots with fade
	for i in range(points.size()):
		# Skip points that are too close together (creates dotted effect)
		if i > 0 and points[i].distance_to(last_drawn_pos) < min_distance:
			continue
		
		# Draw a small circle for each dot
		var global_pos: Vector2 = points[i]
		var local_pos: Vector2 = to_local(global_pos)
		var progress: float = float(i) / float(points.size())
		var alpha: float = lerpf(0.5, 1.0, progress)
		draw_circle(local_pos, dot_radius, Color(dot_color.r, dot_color.g, dot_color.b, alpha))
		last_drawn_pos = points[i]


func _get_weapon_ammo_cost(weapon_name: String) -> int:
	return int(WEAPON_AMMO_COSTS.get(weapon_name, 0))
