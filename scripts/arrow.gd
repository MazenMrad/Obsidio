extends RigidBody2D

@onready var trail = $Line2D

@export var damage = 20
@export var speed = 500
@export var drag = 0.02

# Trail settings
@export var max_trail_points: int = 32
@export var min_point_distance: float = 4.0
@export var min_trail_width: float = 0.6
@export var max_trail_width: float = 3.0
@export var speed_for_max_width: float = 900.0
@export var trail_tail_offset: float = 10.0

var _trail_points: PackedVector2Array = PackedVector2Array()
var _is_fading_out: bool = false

func _ready():
	trail.visible = true
	trail.top_level = true # feed global positions directly
	# Ensure no transform offset when using global points
	trail.position = Vector2.ZERO
	trail.rotation = 0.0
	trail.scale = Vector2.ONE
	trail.points = PackedVector2Array()

# Called when launched
func shoot(dir, speed_multiplier = 1.0):
	linear_velocity = dir * speed * speed_multiplier
	# reset trail when shooting
	_trail_points.clear()
	trail.points = _trail_points
	trail.visible = true
	_is_fading_out = false

# Align arrow with movement direction
func _integrate_forces(_state):
	if linear_velocity.length() > 10:
		rotation = linear_velocity.angle()

func _process(_delta):
	if _is_fading_out:
		return
	
	# Append current global position to trail when moved enough
	var v_len: float = linear_velocity.length()
	var base_pos: Vector2 = global_position
	var current_pos: Vector2 = base_pos
	if v_len > 0.1:
		current_pos = base_pos - linear_velocity.normalized() * trail_tail_offset
	
	if _trail_points.size() == 0 or _trail_points[_trail_points.size() - 1].distance_to(current_pos) >= min_point_distance:
		_trail_points.append(current_pos)
		if _trail_points.size() > max_trail_points:
			_trail_points.remove_at(0)
		trail.points = _trail_points
	
	# Width and alpha scale with speed
	var t: float = clamp(v_len / speed_for_max_width, 0.0, 1.0)
	trail.width = lerp(min_trail_width, max_trail_width, t)
	trail.modulate = Color(1, 1, 1, clamp(0.25 + 0.75 * t, 0.25, 1.0))

# On hit
func _on_area_2d_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		_start_fade_out()

func _start_fade_out():
	_is_fading_out = true
	var tw = create_tween()
	# Keep the last few points to show a short tail during fade
	while _trail_points.size() > 8:
		_trail_points.remove_at(0)
	trail.points = _trail_points
	
	# Fade color to transparent and shrink width
	tw.tween_property(trail, "modulate", Color(trail.modulate.r, trail.modulate.g, trail.modulate.b, 0.0), 0.35).set_trans(Tween.TRANS_LINEAR)
	tw.parallel().tween_property(trail, "width", 0.0, 0.35)
	
	# Stop physics and hide sprite during fade
	sleeping = true
	linear_velocity = Vector2.ZERO
	
	await tw.finished
	queue_free()
