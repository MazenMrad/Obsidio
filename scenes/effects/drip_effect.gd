extends SubViewportContainer

@export var target_path: NodePath
@export var fall_speed: float = 0.008
@export var auto_paint: bool = true  # Auto-paint at random positions
@export var paint_interval: float = 0.5  # Seconds between paint strokes

@onready var sub_viewport: SubViewport = $SubViewport
@onready var color_rect: ColorRect = $SubViewport/ColorRect
@onready var noise_texture: Texture2D = preload("res://assets/textures/noise.png")

var elapsed: float = 0.0
var paint_timer: float = 0.0

func _ready() -> void:
	# Set the noise texture on the shader
	if color_rect.material:
		color_rect.material.set_shader_parameter("noise_texture", noise_texture)
	get_viewport().size_changed.connect(_sync_to_viewport)
	_sync_to_viewport()


func _sync_to_viewport() -> void:
	var viewport_size: Vector2i = get_viewport_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return

	sub_viewport.size = viewport_size
	if color_rect.material:
		color_rect.material.set_shader_parameter("texture_size", Vector2(viewport_size))

func _process(delta: float) -> void:
	# Calculate fall speed with frame-rate independence
	elapsed += delta
	var advance := 0.0
	if elapsed > fall_speed:
		advance = floor(elapsed / fall_speed)
		elapsed -= advance * fall_speed
	
	# Update shader parameters
	if color_rect.material:
		color_rect.material.set_shader_parameter("advance", advance)
	
	# Auto-paint if enabled
	if auto_paint:
		paint_timer += delta
		if paint_timer >= paint_interval:
			paint_timer = 0.0
			paint_at_random()
	
	# Track target if set
	var target = get_node_or_null(target_path)
	if target:
		if color_rect.material:
			color_rect.material.set_shader_parameter("brush_position", to_viewport_uv(target.global_position))

func paint_at_random() -> void:
	# Paint at a random position within the viewport
	var random_uv = Vector2(randf(), randf() * 0.3)  # Start from top area
	if color_rect.material:
		color_rect.material.set_shader_parameter("brush_position", random_uv)

func to_viewport_uv(pos: Vector2) -> Vector2:
	var viewport_rect = get_global_rect()
	var relative_pos = pos - viewport_rect.position
	return relative_pos / viewport_rect.size

# Call this to paint at a specific world position
func paint_at(world_pos: Vector2) -> void:
	if color_rect.material:
		color_rect.material.set_shader_parameter("brush_position", to_viewport_uv(world_pos))

# Set the color (white by default)
func set_color(new_color: Color) -> void:
	if color_rect.material:
		color_rect.material.set_shader_parameter("water_color", new_color)

# Adjust brush size
func set_brush_size(size: float) -> void:
	if color_rect.material:
		color_rect.material.set_shader_parameter("brush_size", size)
