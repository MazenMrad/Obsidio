extends CharacterBody2D

@export var move_speed: float = 60.0
@export var wobble_intensity: float = 1.5
@export var wobble_speed: float = 3.0
@onready var sprite = $AnimatedSprite2D
@export var spawn_on_death: PackedScene
@export var spawn_count: int = 2
@export var wall: StaticBody2D
signal wall_dmg

var hp=100
var original_y: float
var time_offset: float
var is_moving: bool = true
signal died

func die():
	if spawn_on_death:
		for i in range(spawn_count):
			var smaller_enemy = spawn_on_death.instantiate()
			smaller_enemy.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			get_parent().add_child(smaller_enemy)

	emit_signal("died")
	queue_free()

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


func _physics_process(delta):
	if is_moving:
		move_and_slide()
	if hp<=0:
		queue_free()
############################### ARROW HIT #############################
func _on_area_2d_body_entered(body: Node2D) -> void:
		# Connect this to an Area2D that detects when to stop
	if body.has_method("shoot"):
		print("got shot")
		hp=hp-20
		print(hp)
	pass 

func take_damage(damage_amount):
	hp=hp-20
	pass

#####
#func _on_area_2d_body_exited(body: Node2D) -> void:
	#velocity.x = -move_speed
	#pass # Replace with function body.

############################### WALL DETECTION ##################################


func _on_area_2d_area_entered(area: Area2D) -> void:
	$AnimatedSprite2D.play("default")
	velocity.x=0
	pass # Replace with function body.


func _on_area_2d_area_exited(area: Area2D) -> void:
	velocity.x = -move_speed
	$AnimatedSprite2D.play("idle")
	pass # Replace with function body.
