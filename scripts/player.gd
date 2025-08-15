extends CharacterBody2D
@onready var arrow_scene = preload("res://scenes/arrow.tscn")
@onready var shoot_point: Marker2D = $arrowspawn
@onready var trajectory_line: Line2D = $TrajectoryLine

var hp=100
# Player.gd
var current_aim_direction = "front" 
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var max_drag_distance = 100  #CHANGE THIS TO DETERMINE DRAG DISTANCE THE EXPORT METHOD HAS SOME ISSUES
var is_initial_drag = false  # Track if this is the first frame of dragging

# Trajectory prediction settings
@export var trajectory_points: int = 20
@export var trajectory_step_time: float = 0.1
@export var trajectory_gravity: float = 980.0

func _ready():
	#$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))
	print("Animation signal connected")
	trajectory_line.visible = false
	# Set trajectory line to use global coordinates
	trajectory_line.top_level = true
	trajectory_line.position = Vector2.ZERO

func _on_animated_sprite_2d_animation_finished() -> void:
	# This function is automatically called when animation finishes
	if $AnimatedSprite2D.animation == "up arrow fire":
		$AnimatedSprite2D.play("up arrow fire idle")
	elif $AnimatedSprite2D.animation == "hold arrow":
		$AnimatedSprite2D.play("hold arrow idle")
	pass # Replace with function body.

func _process(delta):
	#if is_dragging and $AnimatedSprite2D.animation=="hold arrow" and $AnimatedSprite2D.frame==9:
		#update_drag()
	handle_drag_shooting()

#############THE ANIMATION DISPLAY IS STILL BUGGED STILL SHT#######
func handle_drag_shooting():
	# Start dragging
	if Input.is_action_pressed("MOUSE_BUTTON_LEFT") and not is_dragging:
		start_drag()
	
	# Continue dragging (show aim line)
	if is_dragging and Input.is_action_pressed("MOUSE_BUTTON_LEFT"):
		update_drag()
	
	# Release - shoot arrow
	if is_dragging and Input.is_action_just_released("MOUSE_BUTTON_LEFT"):
		release_drag()

func start_drag():
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	is_dragging = true
	is_initial_drag = true
	print("Starting drag - Mouse offset: ", to_mouse)
	
	# Set initial aim direction based on mouse position
	if to_mouse.y <= -110:  # Mouse is above player
		current_aim_direction = "up"
		$AnimatedSprite2D.play("up arrow fire", false)
		print("Aiming up")
	else:  # Mouse is at or below player level
		current_aim_direction = "front"
		$AnimatedSprite2D.play("hold arrow", false)
		print("Aiming forward")
	
	drag_start_pos = get_global_mouse_position()
	trajectory_line.visible = true
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
		
		if current_aim_direction == "up":
			$AnimatedSprite2D.play("up arrow fire", false)
		else:
			$AnimatedSprite2D.play("hold arrow", false)
	
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
	
	print("Drag vector: ", drag_vector, " Power: ", power)
	
	# Calculate initial velocity using arrow's speed
	var arrow_speed = 820  # Default arrow speed from arrow scene
	var initial_velocity = direction * arrow_speed * power
	
	# Predict trajectory points using GLOBAL coordinates for the line
	var trajectory_points_array = PackedVector2Array()
	var current_pos = shoot_point.global_position  # Use global position for line
	var current_vel = initial_velocity
	
	for i in range(trajectory_points):
		trajectory_points_array.append(current_pos)
		
		# Apply gravity
		current_vel.y += trajectory_gravity * trajectory_step_time
		
		# Update position
		current_pos += current_vel * trajectory_step_time
	
	trajectory_line.points = trajectory_points_array
	
	# Update line color based on power
	var alpha = lerp(0.3, 1.0, power)
	trajectory_line.modulate = Color(1, 1, 0, alpha)

func release_drag():
	$AudioStreamPlayer2D.play()
	is_dragging = false
	is_initial_drag = false
	trajectory_line.visible = false
	$AnimatedSprite2D.play("loose", true)
	var drag_end_pos = get_global_mouse_position()
	var drag_vector = drag_start_pos - drag_end_pos
	
	print("Releasing drag - Vector: ", drag_vector, " Length: ", drag_vector.length())
	
	await get_tree().create_timer(0.14).timeout
	$AnimatedSprite2D.play("idle")
	
	# Limit drag distance
	if drag_vector.length() > max_drag_distance:
		drag_vector = drag_vector.normalized() * max_drag_distance
	
	shoot_arrow(drag_vector)

func shoot_arrow(drag_force):
	var arrow = arrow_scene.instantiate()
	arrow.global_position = shoot_point.global_position
	
	var direction = drag_force.normalized()
	var power = drag_force.length() / max_drag_distance
	
	get_tree().root.add_child(arrow)
	arrow.shoot(direction, power)
