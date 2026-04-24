extends Node2D
## Destruction Effect - Plays a shader-based disintegration animation
## Can be spawned when towers, walls, or other objects are destroyed

const DESTRUCTION_SHADER: Shader = preload("res://scenes/shaders/destruction_effect.gdshader")

@export var duration: float = 1.0  ## How long the destruction effect plays
@export var texture: Texture2D  ## The sprite texture to use (set before adding to scene)
@export var start_scale: Vector2 = Vector2.ONE  ## Initial scale of the effect
@export var particle_count: int = 15  ## Number of debris particles to spawn
@export var use_particles: bool = true  ## Whether to spawn debris particles

var _material: ShaderMaterial
var _sprite: Sprite2D
var _tween: Tween
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var rng: RandomNumberGenerator = _rng


func _ready() -> void:
	_rng.randomize()
	_sprite = get_node_or_null("Sprite2D")
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite)
	
	_setup_material()
	_apply_texture()
	_play_destruction_animation()


func _setup_material() -> void:
	_material = ShaderMaterial.new()
	_material.shader = DESTRUCTION_SHADER
	_material.set_shader_parameter("strength", 0.0)
	_material.set_shader_parameter("seed", randf_range(0.1, 0.9))
	_material.set_shader_parameter("direction", Vector2(randf_range(-1.0, 0.0), randf_range(-0.5, 0.5)))
	_material.set_shader_parameter("mask_vignette_strength", randf_range(0.3, 0.7))
	_material.set_shader_parameter("mask_vignette_center", Vector2(0.5, randf_range(0.2, 0.5)))
	_material.set_shader_parameter("time", 0.0)
	_sprite.material = _material
	_sprite.scale = start_scale


func _apply_texture() -> void:
	if texture != null:
		_sprite.texture = texture


func _play_destruction_animation() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	
	# Animate shader strength from 0 to 1
	_tween.tween_method(_set_shader_strength, 0.0, 1.0, duration)
	
	# Optional: Add scale pulse
	_tween.parallel().tween_property(_sprite, "scale", start_scale * 1.2, duration * 0.3)
	_tween.parallel().tween_property(_sprite, "scale", Vector2.ZERO, duration * 0.7).set_delay(duration * 0.3)
	
	# Spawn debris particles if enabled
	if use_particles:
		_spawn_debris_particles()
	
	# Clean up after animation
	_tween.tween_callback(queue_free)


func _set_shader_strength(value: float) -> void:
	if _material:
		_material.set_shader_parameter("strength", value)
		_material.set_shader_parameter("time", value * duration)


func _spawn_debris_particles() -> void:
	var texture_to_use: Texture2D = texture if texture else null
	if texture_to_use == null:
		return
	
	for i in range(particle_count):
		var particle := Sprite2D.new()
		particle.texture = texture_to_use
		particle.scale = Vector2(_rng.randf_range(0.1, 0.25), _rng.randf_range(0.1, 0.25))
		particle.global_position = global_position + Vector2(
			_rng.randf_range(-30.0, 30.0),
			_rng.randf_range(-30.0, 10.0)
		)
		particle.rotation = _rng.randf_range(0, TAU)
		
		get_tree().root.add_child(particle)
		
		var particle_tween := create_tween()
		var target_pos: Vector2 = particle.global_position + Vector2(
			_rng.randf_range(-80.0, 80.0),
			_rng.randf_range(-100.0, -200.0)
		)

		particle_tween.parallel().tween_property(particle, "global_position", target_pos, duration * 0.8)
		particle_tween.parallel().tween_property(particle, "modulate:a", 0.0, duration * 0.6).set_delay(duration * 0.2)
		particle_tween.parallel().tween_property(particle, "rotation", _rng.randf_range(-15.0, 15.0), duration * 0.8)
		particle_tween.tween_callback(particle.queue_free).set_delay(duration * 0.85)


## Factory function to create and spawn a destruction effect at a position
static func spawn(at_position: Vector2, with_texture: Texture2D, scale: Vector2 = Vector2.ONE, duration: float = 1.0) -> Node2D:
	var effect := new()
	effect.texture = with_texture
	effect.global_position = at_position
	effect.start_scale = scale
	effect.duration = duration
	
	# Auto-duplicate texture if needed to avoid resource sharing issues
	if with_texture:
		effect.texture = with_texture
	
	# Need to add to scene tree manually after this call
	return effect
