extends CharacterBody2D
const KEY_Q = 81
const BOW_UI = preload("res://assets/GUI/bow_ui.png")
const ROCK_UI = preload("res://assets/GUI/rock_ui.png")
@onready var arrow_scene = preload("res://scenes/arrow.tscn")
@onready var rock_scene = preload("res://scenes/rock.tscn")
@onready var shoot_point: Marker2D = $arrowspawn
@onready var trajectory_line: Line2D = $TrajectoryLine
var mouse_in_button: bool=false
var hp=100
# Player.gd
var current_aim_direction = "front" 
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var max_drag_distance = 100  #CHANGE THIS TO DETERMINE DRAG DISTANCE THE EXPORT METHOD HAS SOME ISSUES
var is_initial_drag = false  # Track if this is the first frame of dragging
var current_weapon = global_var.Weapon.BOW
# Trajectory prediction settings
@export var trajectory_points: int = 20
@export var trajectory_step_time: float = 0.1
@export var trajectory_gravity: float = 980.0



#I have been staring for the screen for 20 minutes my sanity reached room temprature
func _ready():
	#$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))
	print("Animation signal connected")
	trajectory_line.visible = false
	# Set trajectory line to use global coordinates
	trajectory_line.top_level = true
	trajectory_line.position = Vector2.ZERO

func _process(delta):
	if is_dragging:
		update_drag()

	if Input.is_action_just_pressed("KEY_Q"):
		if current_weapon == global_var.Weapon.BOW:
			current_weapon = global_var.Weapon.ROCK
			$"../Control/weapon_ui".texture=ROCK_UI
			$"../Control/equip".play()
			print("Switched weapon to ROCK")
		else:
			current_weapon = global_var.Weapon.BOW
			$"../Control/weapon_ui".texture=BOW_UI
			$"../Control/equip".play()
			print("Switched weapon to BOW")
		global_var.state = current_weapon

	match current_weapon:
		global_var.Weapon.ROCK:
			handle_drag_shooting_rock()
		global_var.Weapon.BOW:
			handle_drag_shooting_arrow()

##################ROCK DRAG SHOOTING ARROW##########################
func handle_drag_shooting_rock():
	current_weapon=global_var.Weapon.ROCK
	if mouse_in_button==false:
		if Input.is_action_pressed("MOUSE_BUTTON_LEFT") and not is_dragging:
			start_drag()
		if is_dragging and Input.is_action_pressed("MOUSE_BUTTON_LEFT"):
			update_drag()
		if is_dragging and Input.is_action_just_released("MOUSE_BUTTON_LEFT"):
			release_drag()
			return
	else:
		return

##################BOW DRAG SHOOTING ARROW##########################
func handle_drag_shooting_arrow():
	if global_var.arrows > 0:
		if mouse_in_button == false:
			if Input.is_action_pressed("MOUSE_BUTTON_LEFT") and not is_dragging:
				start_drag()
			if is_dragging and Input.is_action_pressed("MOUSE_BUTTON_LEFT"):
				update_drag()
			if is_dragging and Input.is_action_just_released("MOUSE_BUTTON_LEFT"):
				release_drag()
		else:
			return

func start_drag():
	is_dragging = true
	is_initial_drag = true
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	drag_start_pos = get_global_mouse_position()
	trajectory_line.visible = true
	if current_weapon==global_var.Weapon.BOW:
		$bow_draw.play()
		$AnimatedSprite2D.play("hold arrow idle")
		#print("Starting drag - Mouse offset: ", to_mouse) debug sht
		#if to_mouse.y <= -110:  # Mouse is above player
			#current_aim_direction = "up"
			#$AnimatedSprite2D.play("up arrow fire", false)
			#print("Aiming up")
		#else:  # Mouse is at or below player level
			#current_aim_direction = "front"
			#$AnimatedSprite2D.play("hold arrow", false)
			#print("Aiming forward")
		#print("Drag started at: ", drag_start_pos)
	else:
		$AnimatedSprite2D.play("throw_idle",false)
		print("Drag started at: ", drag_start_pos)
		
		 
func update_drag():
	if not is_dragging:
		return
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	# Determine current aim direction
	var new_aim_direction = "front"
	if to_mouse.y <= -110:  # Mouse is above player
		new_aim_direction = "up"
	
	# Handle direction changes
	
	if new_aim_direction != current_aim_direction:
		current_aim_direction = new_aim_direction
		print("Direction changed to: ", current_aim_direction)
	#if current_weapon==global_var.Weapon.BOW:
		#if current_aim_direction == "up":
			#$AnimatedSprite2D.play("up arrow fire", false)
		#else:
			#$AnimatedSprite2D.play("hold arrow", false)
	# Update trajectory prediction
	update_trajectory()
	

#this is the trajectory prediction
func update_trajectory():
	var drag_end_pos = get_global_mouse_position()
	var drag_vector = drag_start_pos - drag_end_pos
	
	# Limit drag distance
	if drag_vector.length() > max_drag_distance:
		drag_vector = drag_vector.normalized() * max_drag_distance
	
	var direction = drag_vector.normalized()
	var power = drag_vector.length() / max_drag_distance
	
	#print("Drag vector: ", drag_vector, " Power: ", power)
	
	var arrow_speed = 1000  # Default arrow speed from arrow scene
	var rock_speed = 700  # Default rock speed from rock scene
	var initial_velocity: Vector2
	if current_weapon == global_var.Weapon.BOW:
		initial_velocity = direction * arrow_speed * power
	else:
		initial_velocity = direction * rock_speed * power
	
	var trajectory_points_array = PackedVector2Array()
	var current_pos = shoot_point.global_position  # Use global position for line
	var current_vel = initial_velocity
	
	for i in range(trajectory_points):
		trajectory_points_array.append(current_pos)
		current_vel.y += trajectory_gravity * trajectory_step_time
		current_pos += current_vel * trajectory_step_time
	
	trajectory_line.points = trajectory_points_array
	
	# Update line color based on power
	var alpha = lerp(0.3, 1.0, power)
	trajectory_line.modulate = Color(1, 1, 0, alpha)

func release_drag():
	if current_weapon == global_var.Weapon.BOW:
		$bow_draw.stop()
		$bow_release.play()
		$AnimatedSprite2D.play("loose", false)
		shoot_arrow(drag_start_pos - get_global_mouse_position()) #this is is drag force 
	else:
		$AnimatedSprite2D.play("throw", false)
		shoot_rock(drag_start_pos - get_global_mouse_position())
	is_dragging = false
	is_initial_drag = false
	trajectory_line.visible = false	
	var drag_end_pos = get_global_mouse_position() 
	var drag_vector = drag_start_pos - drag_end_pos
	print("Releasing drag - Vector: ", drag_vector, " Length: ", drag_vector.length())
	await get_tree().create_timer(0.14).timeout
	$AnimatedSprite2D.play("idle")
	# Limit drag distance
	if drag_vector.length() > max_drag_distance:
		drag_vector = drag_vector.normalized() * max_drag_distance
	

		
########################PROJECTILES###############

func shoot_arrow(drag_force):
	var arrow = arrow_scene.instantiate()
	arrow.global_position = shoot_point.global_position
	
	var direction = drag_force.normalized()
	var power = drag_force.length() / max_drag_distance
	
	get_tree().root.add_child(arrow)
	arrow.shoot(direction, power)
	global_var.arrows -= 1

func shoot_rock(drag_force):
	var rock = rock_scene.instantiate()
	rock.global_position = shoot_point.global_position
	var direction = drag_force.normalized()
	var power = drag_force.length() / max_drag_distance
	
	get_tree().root.add_child(rock)
	rock.shoot(direction, power)

##################THIS IS TO FIX WHILE CLICKING UPGRADE BUTTON THE BOW WONT DRAG################
func _on_upgrade_wall_mouse_entered() -> void:
	mouse_in_button=true
	pass # Replace with function body.

func _on_upgrade_wall_mouse_exited() -> void:
	mouse_in_button=false
	pass # Replace with function body.


func _on_buy_arrow_mouse_entered() -> void:
	mouse_in_button=true
	pass # Replace with function body.


func _on_buy_arrow_mouse_exited() -> void:
	mouse_in_button=false
	pass # Replace with function body.

#################################################################################
