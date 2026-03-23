extends RigidBody2D

@export var bounce_force: float = 100.0
@export var spin_force: float = 200.0
@export var max_bounces: int = 3

var bounce_count: int = 0
var is_collected: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	apply_central_impulse(Vector2(rng.randf_range(-50.0, 50.0), -bounce_force))
	apply_torque_impulse(rng.randf_range(-spin_force, spin_force))
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ground") or body.is_in_group("walls"):
		bounce_count += 1
		if bounce_count >= max_bounces:
			linear_velocity *= 0.3
			angular_velocity *= 0.3

func _on_mouse_entered() -> void:
	if not is_collected:
		is_collected = true
		print("coin collected")
		var coin_sound := get_node_or_null("coin_sound")
		if coin_sound:
			coin_sound.play()
		global_var.coins += 1
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)
