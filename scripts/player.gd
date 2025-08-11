extends CharacterBody2D
@onready var arrow_scene = preload("res://scenes/arrow.tscn")
@onready var shoot_point: Marker2D = $Marker2D
var hp=100
# Player.gd
var current_aim_direction = "front" 
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var max_drag_distance = 100  #CHANGE THIS TO DETERMINE DRAG DISTANCE THE EXPORT METHOD HAS SOME ISSUES

func _ready():
	#$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))
	print("Animation signal connected")

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
	print(to_mouse)
	# Check mouse position relative to player
	if to_mouse.y <= -100:  # Mouse is above player
		$AnimatedSprite2D.play("up arrow fire", false)
		print("Aiming up")
	else:  # Mouse is at or below player level
		$AnimatedSprite2D.play("hold arrow", false)
		print("Aiming forward")
	
	drag_start_pos = get_global_mouse_position()

func update_drag():
	if not is_dragging:
		return
	
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	var current_progress = $AnimatedSprite2D.frame
	# Update animation based on mouse position while dragging
	if to_mouse.y <= 10:  # Mouse is above player
		$AnimatedSprite2D.play("up arrow fire idle")
		current_progress = $AnimatedSprite2D.frame
	else:  # Mouse is at player level or below
		$AnimatedSprite2D.play("hold arrow idle")

func release_drag():
	is_dragging = false
	$AnimatedSprite2D.play("loose", true)
	var drag_end_pos = get_global_mouse_position()
	var drag_vector = drag_start_pos - drag_end_pos
	
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
