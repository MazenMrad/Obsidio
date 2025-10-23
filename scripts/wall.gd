# wall.gd
extends StaticBody2D

@export var max_hp: int = 100
@export var damage_per_second: int = 20
var enemy_touching=false
var current_hp: int = 100
var enemy_nearby: bool = false
var damage_timer: float = 0

# Hit effect variables
@onready var wall_sprite: Sprite2D = $Wall
var hit_material: ShaderMaterial
var hit_tween: Tween

func _ready():
	current_hp = max_hp
	setup_hit_shader()

func setup_hit_shader():
	# Create shader material for hit effects
	hit_material = ShaderMaterial.new()
	var shader = load("res://scenes/shaders/wall_hit_effect.gdshader")
	hit_material.shader = shader
	
	# Set initial shader parameters
	hit_material.set_shader_parameter("hit_intensity", 0.0)
	hit_material.set_shader_parameter("hit_radius", 30.0)
	hit_material.set_shader_parameter("hit_position", Vector2(0.5, 0.5))
	hit_material.set_shader_parameter("time_since_hit", 0.0)
	hit_material.set_shader_parameter("hit_color", Color(1.0, 0.3, 0.0, 1.0))
	hit_material.set_shader_parameter("shake_intensity", 3.0)
	hit_material.set_shader_parameter("crack_intensity", 0.0)
	
	# Apply material to wall sprite
	wall_sprite.material = hit_material

func _process(delta):
	if enemy_nearby:
		damage_timer += delta
		# Deal damage every second
		if damage_timer >= 1.0:
			take_damage(damage_per_second)
			damage_timer = 0

func take_damage(damage: int):
	if current_hp <= 0:
		destroy_wall()
	else:
		current_hp -= damage
		print("Wall HP: ", current_hp)
		
		# Trigger hit effect
		trigger_hit_effect()

func trigger_hit_effect():
	# Random hit position on the wall
	var hit_pos = Vector2(randf_range(0.2, 0.8), randf_range(0.3, 0.7))
	
	if hit_material:
		hit_material.set_shader_parameter("hit_position", hit_pos)
		hit_material.set_shader_parameter("hit_intensity", 1.0)
		hit_material.set_shader_parameter("time_since_hit", 0.0)
		
		# Increase crack intensity based on damage
		var crack_level = 1.0 - (float(current_hp) / float(max_hp))
		hit_material.set_shader_parameter("crack_intensity", crack_level * 0.5)
		
		# Animate hit effect fade out
		if hit_tween:
			hit_tween.kill()
		hit_tween = create_tween()
		hit_tween.parallel().tween_method(update_hit_time, 0.0, 2.0, 1.5)
		hit_tween.parallel().tween_method(update_hit_intensity, 1.0, 0.0, 1.0)
		
		# Create particle effect
		create_hit_particles(hit_pos)

func update_hit_time(value: float):
	if hit_material:
		hit_material.set_shader_parameter("time_since_hit", value)

func update_hit_intensity(value: float):
	if hit_material:
		hit_material.set_shader_parameter("hit_intensity", value)

func create_hit_particles(hit_pos: Vector2):
	# Create simple particle effect using multiple sprites
	for i in range(5):
		var particle = Sprite2D.new()
		var dust_texture = preload("res://assets/map/rocks .png") # Using existing asset
		particle.texture = dust_texture
		particle.scale = Vector2(0.1, 0.1)
		
		# Position relative to wall
		var wall_size = wall_sprite.texture.get_size() * wall_sprite.scale
		var world_hit_pos = wall_sprite.global_position + Vector2(
			(hit_pos.x - 0.5) * wall_size.x,
			(hit_pos.y - 0.5) * wall_size.y
		)
		particle.global_position = world_hit_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		get_tree().root.add_child(particle)
		
		# Animate particle
		var particle_tween = create_tween()
		particle_tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(randf_range(-50, 50), randf_range(-30, -80)), 1.0)
		particle_tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		particle_tween.parallel().tween_property(particle, "scale", Vector2.ZERO, 1.0)
		particle_tween.tween_callback(particle.queue_free)

func destroy_wall():
	global_var.set_wall_destroyed()
	print("Wall destroyed!")
	
	# Final destruction effect
	if hit_material:
		hit_material.set_shader_parameter("crack_intensity", 1.0)
		hit_material.set_shader_parameter("hit_intensity", 0.8)
		
	# Create more destruction particles
	for i in range(15):
		create_hit_particles(Vector2(randf_range(0.2, 0.8), randf_range(0.2, 0.8)))
	
	queue_free()

func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("enemies"):
		enemy_touching = true
		damage_timer = 0
		take_damage(damage_per_second)

func _on_wallarea_area_entered(area: Area2D) -> void:
	if area.name=="enemy1":
		enemy_nearby=true
		take_damage(damage_per_second)

func _on_wallarea_area_exited(area: Area2D) -> void:
	if area.name=="enemy1":
		enemy_nearby=false

func _on_repair_pressed() -> void:
	if current_hp>0:
		if current_hp==max_hp:
			print("attempted repair")
			return
		else:
			print("repaired")
			current_hp+=60
			$build_sound.play()
			if current_hp>max_hp:
				current_hp=max_hp
			
			# Reduce crack intensity when repaired
			if hit_material:
				var crack_level = 1.0 - (float(current_hp) / float(max_hp))
				hit_material.set_shader_parameter("crack_intensity", crack_level * 0.5)
	else:
		return
