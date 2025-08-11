extends RigidBody2D

@onready var trail = $Line2D

@export var damage = 20
@export var speed = 500
@export var drag = 0.02

# Called when launched
func shoot(dir, speed_multiplier = 1.0):
	linear_velocity = dir * speed * speed_multiplier

# Align arrow with movement direction
func _integrate_forces(state):
	if linear_velocity.length() > 10:
		rotation = linear_velocity.angle()

func _process(delta):
	# Update Line2D to show trail behind arrow
	trail.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(-20, 0)
	])

# On hit
func _on_area_2d_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		_start_fade_out()
		queue_free()

func _start_fade_out():
	var tw = create_tween()

	# Fade color from yellow-orange to transparent red
	tw.tween_property(trail, "modulate", Color(1.0, 0.0, 0.0, 0.0), 1.5).set_trans(Tween.TRANS_LINEAR)
	


	# Optional: shrink trail width
	tw.tween_property(trail, "width", 0.0, 1.5)

	# Destroy arrow after fade
	await tw.finished
	queue_free()
