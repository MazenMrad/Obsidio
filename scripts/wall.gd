extends StaticBody2D

const DESTRUCTION_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/destruction_effect.tscn")
const HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar.tscn")

@export var max_hp: int = 100
@export var damage_per_second: int = 20
@export var enable_destruction_particles: bool = false
@export var enable_hit_particles: bool = false

var enemy_touching: bool = false
var current_hp: int = 100
var enemy_nearby: bool = false
var damage_timer: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _health_bar: Node2D = null

@onready var wall_sprite: Sprite2D = $Wall
var hit_material: ShaderMaterial
var hit_tween: Tween

func _ready() -> void:
	rng.randomize()
	current_hp = max_hp
	setup_hit_shader()
	_setup_health_bar()

func setup_hit_shader() -> void:
	hit_material = ShaderMaterial.new()
	var shader: Shader = load("res://scenes/shaders/wall_hit_effect.gdshader")
	hit_material.shader = shader
	
	hit_material.set_shader_parameter("hit_intensity", 0.0)
	hit_material.set_shader_parameter("hit_radius", 30.0)
	hit_material.set_shader_parameter("hit_position", Vector2(0.5, 0.5))
	hit_material.set_shader_parameter("time_since_hit", 0.0)
	hit_material.set_shader_parameter("hit_color", Color(1.0, 0.3, 0.0, 1.0))
	hit_material.set_shader_parameter("shake_intensity", 3.0)
	hit_material.set_shader_parameter("crack_intensity", 0.0)
	
	wall_sprite.material = hit_material

func _process(_delta: float) -> void:
	pass

func take_damage(damage: int) -> void:
	current_hp -= damage
	print("Wall HP: %d" % current_hp)
	trigger_hit_effect()
	_shake_camera(8.0, 0.18)
	_update_health_bar()

	if current_hp <= 0:
		destroy_wall()

func trigger_hit_effect() -> void:
	var hit_pos := Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.3, 0.7))
	
	if hit_material:
		hit_material.set_shader_parameter("hit_position", hit_pos)
		hit_material.set_shader_parameter("hit_intensity", 1.0)
		hit_material.set_shader_parameter("time_since_hit", 0.0)
		
		var crack_level: float = 1.0 - (float(current_hp) / float(max_hp))
		hit_material.set_shader_parameter("crack_intensity", crack_level * 0.5)
		
		if hit_tween:
			hit_tween.kill()
		hit_tween = create_tween()
		hit_tween.parallel().tween_method(update_hit_time, 0.0, 2.0, 1.5)
		hit_tween.parallel().tween_method(update_hit_intensity, 1.0, 0.0, 1.0)
		
		if enable_hit_particles:
			create_hit_particles(hit_pos)

func update_hit_time(value: float) -> void:
	if hit_material:
		hit_material.set_shader_parameter("time_since_hit", value)

func update_hit_intensity(value: float) -> void:
	if hit_material:
		hit_material.set_shader_parameter("hit_intensity", value)

func create_hit_particles(hit_pos: Vector2) -> void:
	for i in range(5):
		var particle := Sprite2D.new()
		var dust_texture: Texture2D = preload("res://assets/map/rocks .png")
		particle.texture = dust_texture
		particle.scale = Vector2(0.1, 0.1)
		
		var wall_size: Vector2 = wall_sprite.texture.get_size() * wall_sprite.scale
		var world_hit_pos := wall_sprite.global_position + Vector2(
			(hit_pos.x - 0.5) * wall_size.x,
			(hit_pos.y - 0.5) * wall_size.y
		)
		particle.global_position = world_hit_pos + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0))
		
		get_tree().root.add_child(particle)
		
		var particle_tween := create_tween()
		particle_tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(-30.0, -80.0)), 1.0)
		particle_tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		particle_tween.parallel().tween_property(particle, "scale", Vector2.ZERO, 1.0)
		particle_tween.tween_callback(particle.queue_free)

func destroy_wall() -> void:
	global_var.set_wall_destroyed()
	print("Wall destroyed!")
	
	# Play destruction shader effect
	_spawn_destruction_effect()
	
	if hit_material:
		hit_material.set_shader_parameter("crack_intensity", 1.0)
		hit_material.set_shader_parameter("hit_intensity", 0.8)
	
	if enable_destruction_particles:
		for i in range(15):
			create_hit_particles(Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8)))
	
	queue_free()


func _spawn_destruction_effect() -> void:
	var wall_texture: Texture2D = null
	if wall_sprite:
		wall_texture = wall_sprite.texture
	
	if DESTRUCTION_EFFECT_SCENE and wall_texture:
		var effect := DESTRUCTION_EFFECT_SCENE.instantiate()
		effect.texture = wall_texture
		effect.global_position = global_position
		effect.start_scale = wall_sprite.scale if wall_sprite else Vector2.ONE
		effect.duration = 0.8
		effect.use_particles = enable_destruction_particles
		get_tree().root.add_child(effect)

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass

func _on_wallarea_area_entered(area: Area2D) -> void:
	# Check parent body — all enemies are in the "enemies" group
	var parent_body: Node2D = area.get_parent()
	if parent_body and parent_body.is_in_group("enemies"):
		enemy_nearby = true

func _on_wallarea_area_exited(area: Area2D) -> void:
	var parent_body: Node2D = area.get_parent()
	if parent_body and parent_body.is_in_group("enemies"):
		enemy_nearby = false

func _on_repair_pressed() -> void:
	if current_hp > 0:
		if current_hp == max_hp:
			print("attempted repair")
			return
		else:
			print("repaired")
			current_hp += 60
			var build_sound := get_node_or_null("build_sound")
			if build_sound:
				build_sound.play()
	if current_hp > max_hp:
		current_hp = max_hp
	_update_health_bar()
			
	if hit_material:
		var crack_level: float = 1.0 - (float(current_hp) / float(max_hp))
		hit_material.set_shader_parameter("crack_intensity", crack_level * 0.5)


func _shake_camera(amount: float, duration: float) -> void:
	var camera: Camera2D = get_parent().get_node_or_null("Camera2D") as Camera2D
	if camera and camera.has_method("shake"):
		camera.shake(amount, duration)


func _setup_health_bar() -> void:
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	add_child(_health_bar)
	# Position above the wall sprite
	if wall_sprite:
		var wall_size: Vector2 = wall_sprite.texture.get_size() * wall_sprite.scale
		_health_bar.position = Vector2(0, -wall_size.y - 16).round()
	else:
		_health_bar.position = Vector2(0, -80).round()
	_health_bar.update_hp(current_hp, max_hp)


func _update_health_bar() -> void:
	if _health_bar:
		_health_bar.update_hp(current_hp, max_hp)
