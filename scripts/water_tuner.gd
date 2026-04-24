extends ColorRect

@export_range(0.0, 1.0, 0.01) var water_opacity: float = 0.12:
	set(value):
		water_opacity = value
		_update_shader()

@export_range(0.0, 0.5, 0.001) var water_speed: float = 0.04:
	set(value):
		water_speed = value
		_update_shader()

@export_range(0.0, 0.5, 0.001) var wave_distortion: float = 0.035:
	set(value):
		wave_distortion = value
		_update_shader()

@export_range(1, 20, 1) var wave_multiplyer: int = 10:
	set(value):
		wave_multiplyer = value
		_update_shader()

@export_range(0.0, 1.0, 0.01) var reflection_strength: float = 0.5:
	set(value):
		reflection_strength = value
		_update_shader()

@export_range(0.0, 1.0, 0.01) var line_threshold: float = 0.22:
	set(value):
		line_threshold = value
		_update_shader()

@export var noise_frequency: float = 0.008:
	set(value):
		noise_frequency = value
		_update_noise()

@export_range(0.0, 1.0, 0.01) var noise_gain: float = 0.6:
	set(value):
		noise_gain = value
		_update_noise()

func _ready() -> void:
	_update_shader()

func _update_shader() -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter("water_opacity", water_opacity)
		material.set_shader_parameter("water_speed", water_speed)
		material.set_shader_parameter("wave_distortion", wave_distortion)
		material.set_shader_parameter("wave_multiplyer", wave_multiplyer)

func _update_noise() -> void:
	# Get the noise texture
	if material and material is ShaderMaterial:
		var noise_tex = material.get_shader_parameter("noise_texture2")
		if noise_tex and noise_tex is NoiseTexture2D:
			var noise = noise_tex.noise
			if noise:
				noise.frequency = noise_frequency
				noise.fractal_gain = noise_gain

func randomize_water() -> void:
	"""Randomize parameters for unique water look"""
	water_opacity = randf_range(0.08, 0.2)
	water_speed = randf_range(0.02, 0.1)
	wave_distortion = randf_range(0.02, 0.08)
	wave_multiplyer = randi_range(8, 15)
	noise_frequency = randf_range(0.005, 0.02)
	noise_gain = randf_range(0.5, 0.8)

func set_sparse_lines(sparse: bool = true) -> void:
	"""Toggle between sparse (few lines) and dense (many lines)"""
	if sparse:
		# Sparse mode - fewer white lines
		noise_frequency = 0.006
		noise_gain = 0.75
		wave_multiplyer = 12
		water_opacity = 0.1
	else:
		# Dense mode - more white lines
		noise_frequency = 0.02
		noise_gain = 0.4
		wave_multiplyer = 8
		water_opacity = 0.2
