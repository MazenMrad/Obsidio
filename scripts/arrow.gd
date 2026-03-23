extends RigidBody2D

@onready var trail: Line2D = $Line2D

@export var damage: int = 20
@export var speed: float = 300.0
@export var max_trail_points: int = 32
@export var min_point_distance: float = 4.0
@export var min_trail_width: float = 0.6
@export var max_trail_width: float = 3.0
@export var speed_for_max_width: float = 900.0
@export var trail_tail_offset: float = 10.0
@export var stick_lifetime: float = 2.5
@export var ground_embed_distance: float = 3.0
@export var ground_stick_time: float = 0.08

var _trail_points: PackedVector2Array = PackedVector2Array()
var _is_fading_out: bool = false
var _is_stuck_in_ground: bool = false
var _last_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	trail.visible = true
	trail.top_level = true
	trail.position = Vector2.ZERO
	trail.rotation = 0.0
	trail.scale = Vector2.ONE
	trail.points = PackedVector2Array()

func shoot(dir: Vector2, speed_multiplier: float = 1.0) -> void:
	sleeping = false
	freeze = false
	gravity_scale = 1.0
	linear_velocity = dir * speed * speed_multiplier
	_trail_points.clear()
	trail.points = _trail_points
	trail.visible = true
	_is_fading_out = false
	_is_stuck_in_ground = false
	_last_velocity = linear_velocity

func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	if linear_velocity.length() > 10.0:
		_last_velocity = linear_velocity
		rotation = linear_velocity.angle()

func _process(_delta: float) -> void:
	if _is_fading_out or _is_stuck_in_ground:
		return
	
	var v_len := linear_velocity.length()
	var base_pos := global_position
	var current_pos := base_pos
	if v_len > 0.1:
		current_pos = base_pos - linear_velocity.normalized() * trail_tail_offset
	
	if _trail_points.is_empty() or _trail_points[_trail_points.size() - 1].distance_to(current_pos) >= min_point_distance:
		_trail_points.append(current_pos)
		if _trail_points.size() > max_trail_points:
			_trail_points.remove_at(0)
		trail.points = _trail_points
	
	var t := clampf(v_len / speed_for_max_width, 0.0, 1.0)
	trail.width = lerpf(min_trail_width, max_trail_width, t)
	trail.modulate = Color(1, 1, 1, clampf(0.25 + 0.75 * t, 0.25, 1.0))

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var enemy_hit := get_node_or_null("enemy_hit")
		if enemy_hit:
			enemy_hit.play()
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_start_fade_out()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ground") and not _is_stuck_in_ground and not _is_fading_out:
		_stick_in_ground()


func _stick_in_ground() -> void:
	_is_stuck_in_ground = true
	var impact_direction := _last_velocity.normalized() if _last_velocity.length() > 0.1 else Vector2.RIGHT
	var target_position := global_position + impact_direction * ground_embed_distance
	rotation = impact_direction.angle()
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_mask = 0
	collision_layer = 0
	trail.visible = false
	trail.points = PackedVector2Array()
	_trail_points.clear()
	sleeping = true

	var tw := create_tween()
	tw.tween_property(self, "global_position", target_position, ground_stick_time)
	tw.tween_interval(stick_lifetime)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()

func _start_fade_out() -> void:
	_is_fading_out = true
	var tw := create_tween()
	while _trail_points.size() > 8:
		_trail_points.remove_at(0)
	trail.points = _trail_points
	
	tw.tween_property(trail, "modulate", Color(trail.modulate.r, trail.modulate.g, trail.modulate.b, 0.0), 0.35).set_trans(Tween.TRANS_LINEAR)
	tw.parallel().tween_property(trail, "width", 0.0, 0.35)
	
	sleeping = true
	linear_velocity = Vector2.ZERO
	
	await tw.finished
	queue_free()
