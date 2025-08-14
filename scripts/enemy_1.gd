extends CharacterBody2D

@export var coin_scene: PackedScene
@export var move_speed: float = 60.0
@export var wobble_intensity: float = 1.5
@export var wobble_speed: float = 3.0
@onready var sprite = $AnimatedSprite2D
@export var wall: StaticBody2D

var hp=100
var original_y: float
var time_offset: float
var is_moving: bool = true
signal died

func die():
#	debug
	#print("Enemy node: ", name)
	#print("Enemy position: ", position)
	#print("Enemy global_position: ", global_position)
	#print("sprite global_position: ", sprite.global_position)
	#print("Is enemy in tree? ", is_inside_tree())
	emit_signal("died")  # Emit the died signal
	spawn_coin()
	queue_free()

	
func spawn_coin():
	var coin_instance=coin_scene.instantiate()
	get_parent().add_child(coin_instance)
	coin_instance.global_position=sprite.global_position
	print(global_var.coins)
	print("coin",coin_instance.global_position)
	
func get_current_frame():
	if sprite:
		return sprite.frame
	return 0

func _ready():
	add_to_group("enemies")
	###DEBUG SHIT
	#print("ENEMY READY: ", name, " added to enemies group")
	#print("Group members: ", get_tree().get_nodes_in_group("enemies").size())
	original_y = position.y
	time_offset = randf() * 2 * PI
	velocity.x = -move_speed  # Move left


@warning_ignore("unused_parameter")
func _physics_process(delta):
	if is_moving:
		move_and_slide()
	if hp<=0:
		die()
############################### ARROW HIT #############################
func _on_area_2d_body_entered(body: Node2D) -> void:
		# Connect this to an Area2D that detects when to stop
	#if body.has_method("shoot"):
		#print("arrows")
		#hp=hp-20
		#print(hp)
	pass 

#####
#func _on_area_2d_body_exited(body: Node2D) -> void:
	#velocity.x = -move_speed
	#pass # Replace with function body.
############################### WALL DETECTION #################################

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name=="wallarea" or area.name=="tower":
		$AnimatedSprite2D.play("default")
		velocity.x=0
	pass # Replace with function body.
 
func take_damage(dmg):
	hit_flash()
	hp-=dmg

@warning_ignore("unused_parameter")
func _on_area_2d_area_exited(area: Area2D) -> void:
	velocity.x = -move_speed
	$AnimatedSprite2D.play("run")
	pass # Replace with function body.
func hit_flash():
	$AnimationPlayer.play("hit flash")
