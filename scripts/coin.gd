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
			# Vary pitch and volume so rapid pickups don't sound identical
			coin_sound.pitch_scale = rng.randf_range(0.85, 1.25)
			coin_sound.volume_db = rng.randf_range(-4.0, 2.0)
			coin_sound.play()
		global_var.coins += 1
		_spawn_floating_text("+1")
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)


func _spawn_floating_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font := load("res://fonts/Fool.ttf") as FontFile
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(1.0, 0.85, 0.2) # Gold color
	label.position = Vector2(-24, -20)
	label.size = Vector2(48, 20)
	label.z_index = 100
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-24, -20).round()
	var tween := label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 30, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
