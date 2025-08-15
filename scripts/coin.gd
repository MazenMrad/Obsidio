extends RigidBody2D

@export var bounce_force: float = 100.0
@export var spin_force: float = 200.0
@export var max_bounces: int = 3

var bounce_count: int = 0
var is_collected: bool = false

func _ready():
	# Add some random initial physics
	apply_central_impulse(Vector2(randf_range(-50, 50), -bounce_force))
	apply_torque_impulse(randf_range(-spin_force, spin_force))
	
	# Connect to collision signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("ground") or body.is_in_group("walls"):
		bounce_count += 1
		if bounce_count >= max_bounces:
			# Stop the coin after max bounces
			linear_velocity *= 0.3
			angular_velocity *= 0.3

func _on_mouse_entered() -> void:
	if not is_collected:
		is_collected = true
		print("coin collected")
		$coin_sound.play()
		global_var.coins += 1
		# Add a small collection effect
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)
