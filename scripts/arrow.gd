
extends RigidBody2D
# arrow.gd

@export var damage = 20
@export var speed = 500
var direction = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta

func shoot(dir, power):
	direction = dir		
	# Set initial position and direction from player

func _on_area_2d_body_entered(body) -> void:
	#print("=== ARROW HIT DEBUG ===")
	#print("Hit object: ", body.name)
	#print("Hit object type: ", body.get_class())
	#print("Is in enemies group: ", body.is_in_group("enemies"))
	#print("Has take_damage: ", body.has_method("take_damage"))
	
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		print("Applying damage...")
		body.take_damage(damage)
		queue_free()
	  # Destroy arrow on hit
	else:
		print("false")
	pass # Replace with function body.
