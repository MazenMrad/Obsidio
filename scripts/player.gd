# Enhanced Player.gd with Improved Shooting Precision
extends CharacterBody2D

const KEY_Q = 81
const BOW_UI = preload("res://assets/GUI/bow_ui.png")
const ROCK_UI = preload("res://assets/GUI/rock_ui.png")

@onready var arrow_scene = preload("res://scenes/arrow.tscn")
@onready var rock_scene = preload("res://scenes/rock.tscn")
@onready var shoot_point: Marker2D = $arrowspawn
@onready var trajectory_line: Line2D = $TrajectoryLine

# Player state variables
var mouse_in_button: bool = false
var hp: int = 100
var current_aim_direction = "front" 
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var max_drag_distance = 120  # Slightly increased for better control
var is_initial_drag = false
var current_weapon = global_var.Weapon.BOW

# Trajectory prediction settings
@export var trajectory_points: int = 25  # More points for smoother curve
@export var trajectory_step_time: float = 0.08  # Smaller steps for accuracy
@export var trajectory_gravity: float = 980.0

func _ready():
	print("Enhanced Player system loaded")
	trajectory_line.visible = false
	trajectory_line.top_level = true
	trajectory_line.position = Vector2.ZERO
	
	# Set initial trajectory line properties
	trajectory_line.width = 2.0
	trajectory_line.default_color = Color.YELLOW

func _process(delta):
	if is_dragging:
		update_drag()

	# Weapon switching with Q key
	if Input.is_action_just_pressed("KEY_Q"):
		switch_weapon()

	# Handle shooting based on current weapon
	match current_weapon:
		global_var.Weapon.ROCK:
			handle_drag_shooting_rock()
		global_var.Weapon.BOW:
			handle_drag_shooting_arrow()

func switch_weapon():
	if current_weapon == global_var.Weapon.BOW:
		current_weapon = global_var.Weapon.ROCK
		$"../Control/weapon_ui".texture = ROCK_UI
		$"../Control/equip".play()
		print("Switched weapon to ROCK")
	else:
		current_weapon = global_var.Weapon.BOW
		$"../Control/weapon_ui".texture = BOW_UI
		$"../Control/equip".play()
		print("Switched weapon to BOW")
	global_var.state = current_weapon

#################### ROCK DRAG SHOOTING ##########################
func handle_drag_shooting_rock():
	if mouse_in_button:
		return
		
	if Input.is_action_pressed("MOUSE_BUTTON_LEFT") and not is_dragging:
		start_drag()
	elif is_dragging and Input.is_action_pressed("MOUSE_BUTTON_LEFT"):
		update_drag()
	elif is_dragging and Input.is_action_just_released("MOUSE_BUTTON_LEFT"):
		release_drag()

#################### BOW DRAG SHOOTING ##########################
func handle_drag_shooting_arrow():
	if global_var.arrows <= 0 or mouse_in_button:
		return
		
	if Input.is_action_pressed("MOUSE_BUTTON_LEFT") and not is_dragging:
		start_drag()
	elif is_dragging and Input.is_action_pressed("MOUSE_BUTTON_LEFT"):
		update_drag()
	elif is_dragging and Input.is_action_just_released("MOUSE_BUTTON_LEFT"):
		release_drag()

func start_drag():
	is_dragging = true
	is_initial_drag = true
	drag_start_pos = get_global_mouse_position()
	trajectory_line.visible = true
	
	if current_weapon == global_var.Weapon.BOW:
		$bow_draw.play()
		$AnimatedSprite2D.play("hold arrow idle")
	else:
		$AnimatedSprite2D.play("throw_idle", false)
	
	print("Drag started at: ", drag_start_pos)

func update_drag():
	if not is_dragging:
		return
	
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	# Determine aim direction with better precision
	var new_aim_direction = "front"
	if to_mouse.y <= -110:
		new_aim_direction = "up"
	
	# Handle direction changes
	if new_aim_direction != current_aim_direction:
		current_aim_direction = new_aim_direction
		print("Direction changed to: ", current_aim_direction)
	
	# Update trajectory with enhanced precision
	update_trajectory_enhanced()

func update_trajectory_enhanced():
	var drag_end_pos = get_global_mouse_position()
	var drag_vector = drag_start_pos - drag_end_pos
	
	# Enhanced drag distance calculation
	var raw_distance = drag_vector.length()
	var clamped_distance = min(raw_distance, max_drag_distance)
	
	# Smooth power scaling for better control (ease-out cubic)
	var power_ratio = clamped_distance / max_drag_distance
	var power = ease_out_cubic(power_ratio)
	
	var direction = drag_vector.normalized()
	
	# Weapon-specific speed calculations
	var arrow_speed = 1300.0  # Increased for better range
	var rock_speed = 900.0    # Increased for consistency
	var initial_velocity: Vector2
	
	if current_weapon == global_var.Weapon.BOW:
		initial_velocity = direction * arrow_speed * power
	else:
		initial_velocity = direction * rock_speed * power
	
	# Enhanced trajectory calculation with air resistance
	var trajectory_points_array = PackedVector2Array()
	var current_pos = shoot_point.global_position
	var current_vel = initial_velocity
	var air_resistance = 0.998  # Subtle air resistance
	
	for i in range(trajectory_points):
		trajectory_points_array.append(current_pos)
		
		# Apply physics
		current_vel.y += trajectory_gravity * trajectory_step_time
		current_vel *= air_resistance
		current_pos += current_vel * trajectory_step_time
		
		# Stop if trajectory goes too far off-screen
		if current_pos.y > get_viewport_rect().size.y + 100:
			break
	
	trajectory_line.points = trajectory_points_array
	
	# Dynamic visual feedback based on power and weapon
	var alpha = lerp(0.5, 1.0, power)
	var width = lerp(2.0, 5.0, power)
	
	if current_weapon == global_var.Weapon.BOW:
		trajectory_line.modulate = Color(0.2, 1.0, 0.3, alpha)  # Bright green
	else:
		trajectory_line.modulate = Color(1.0, 0.4, 0.1, alpha)  # Orange
	
	trajectory_line.width = width

# Smooth easing function for better control feel
func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)

func release_drag():
	var drag_force = drag_start_pos - get_global_mouse_position()
	
	# Enhanced power calculation with the same scaling
	var clamped_distance = min(drag_force.length(), max_drag_distance)
	var power_ratio = clamped_distance / max_drag_distance
	var enhanced_power = ease_out_cubic(power_ratio)
	
	if current_weapon == global_var.Weapon.BOW:
		$bow_draw.stop()
		$bow_release.play()
		$AnimatedSprite2D.play("loose", false)
		shoot_arrow_enhanced(drag_force, enhanced_power)
	else:
		$AnimatedSprite2D.play("throw", false)
		shoot_rock_enhanced(drag_force, enhanced_power)
	
	# Reset dragging state
	is_dragging = false
	is_initial_drag = false
	trajectory_line.visible = false
	
	print("Released drag - Force: ", drag_force.length(), " Power: ", enhanced_power)
	
	# Return to idle animation
	await get_tree().create_timer(0.14).timeout
	$AnimatedSprite2D.play("idle")

######################## ENHANCED PROJECTILES ###############

func shoot_arrow_enhanced(drag_force: Vector2, enhanced_power: float):
	var arrow = arrow_scene.instantiate()
	arrow.global_position = shoot_point.global_position
	
	var direction = drag_force.normalized()
	# Use enhanced power for consistent feel with trajectory
	get_tree().root.add_child(arrow)
	arrow.shoot(direction, enhanced_power)
	global_var.arrows -= 1

func shoot_rock_enhanced(drag_force: Vector2, enhanced_power: float):
	var rock = rock_scene.instantiate()
	rock.global_position = shoot_point.global_position
	
	var direction = drag_force.normalized()
	get_tree().root.add_child(rock)
	rock.shoot(direction, enhanced_power)

################# UI INTERACTION FIXES #################

func _on_upgrade_wall_mouse_entered() -> void:
	mouse_in_button = true

func _on_upgrade_wall_mouse_exited() -> void:
	mouse_in_button = false

func _on_buy_arrow_mouse_entered() -> void:
	mouse_in_button = true

func _on_buy_arrow_mouse_exited() -> void:
	mouse_in_button = false

# Add tower upgrade button interactions
func _on_upgrade_tower_mouse_entered() -> void:
	mouse_in_button = true

func _on_upgrade_tower_mouse_exited() -> void:
	mouse_in_button = false
