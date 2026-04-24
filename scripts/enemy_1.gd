extends CharacterBody2D

@export var coin_scene: PackedScene
@export var move_speed: float = 60.0
@export var wobble_intensity: float = 1.5
@export var wobble_speed: float = 3.0
@export var damage: int = 20
## Damage reduction: each hit is reduced by this amount (0 = no armor)
@export var armor: int = 0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var wall: StaticBody2D

var hp: int = 100
var max_hp: int = 100
var original_y: float
var time_offset: float
var is_moving: bool = true
var is_attacking: bool = false
var target_to_attack: Node = null
var has_applied_damage: bool = false
var last_attack_frame: int = -1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Base coins dropped by this enemy
var base_coins: int = 2
## If true, this enemy's coin drops are doubled (set by wave events)
var coin_multiplier: int = 1

signal died
signal hit_occurred(hit_position: Vector2)

func die() -> void:
	emit_signal("died")
	_shake_camera(4.0, 0.12)
	spawn_coin()
	global_var.coins_earned += coin_multiplier
	queue_free()

func spawn_coin() -> void:
	if coin_scene:
		var total_coins: int = base_coins * coin_multiplier
		for _i in range(total_coins):
			var coin_instance: Node2D = coin_scene.instantiate()
			get_parent().add_child(coin_instance)
			coin_instance.global_position = sprite.global_position + Vector2(randf_range(-10, 10), randf_range(-5, 5))

func get_current_frame() -> int:
	if sprite:
		return sprite.frame
	return 0

func _ready() -> void:
	rng.randomize()
	add_to_group("enemies")
	add_to_group("enemy1")

	max_hp = hp
	original_y = position.y
	time_offset = rng.randf() * 2.0 * PI
	velocity.x = -move_speed

	if sprite:
		sprite.play("run")
		sprite.animation_finished.connect(_on_animation_finished)

@warning_ignore("unused_parameter")
func _physics_process(_delta: float) -> void:
	if is_moving:
		move_and_slide()
	if hp <= 0:
		die()

	# Check for attack animation frame to apply damage
	if is_attacking and not has_applied_damage and sprite:
		var attack_anim := _get_attack_animation()
		if sprite.animation == attack_anim:
			var total_frames := sprite.sprite_frames.get_frame_count(attack_anim)
			# Apply damage when we reach the last frame
			if sprite.frame >= total_frames - 1:
				apply_attack_damage()
				has_applied_damage = true
				last_attack_frame = sprite.frame

	# Reset damage flag when animation loops back to frame 0
	if is_attacking and has_applied_damage and sprite:
		var attack_anim := _get_attack_animation()
		if sprite.animation == attack_anim:
			if sprite.frame == 0 and last_attack_frame > 0:
				has_applied_damage = false
				last_attack_frame = -1

func _get_attack_animation() -> String:
	if sprite.sprite_frames.has_animation("attack"):
		return "attack"
	elif sprite.sprite_frames.has_animation("default"):
		return "default"
	else:
		return "idle"

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.name == "wallarea" or area.name == "tower") and not is_attacking:
		start_attack(area)

func start_attack(target: Node) -> void:
	is_attacking = true
	target_to_attack = target
	has_applied_damage = false
	velocity.x = 0.0
	is_moving = false

	var attack_anim := _get_attack_animation()
	sprite.play(attack_anim)

func _on_animation_finished() -> void:
	# Reset damage flag when animation loops
	if is_attacking:
		has_applied_damage = false
		# Restart attack animation if still in contact with target
		if target_to_attack != null and is_instance_valid(target_to_attack):
			sprite.play(_get_attack_animation())
		else:
			is_attacking = false
			velocity.x = -move_speed
			is_moving = true
			if sprite:
				sprite.play("run")

func apply_attack_damage() -> void:
	var wall_hit := get_node_or_null("wall_hit")
	if wall_hit:
		wall_hit.play()

	if target_to_attack and is_instance_valid(target_to_attack):
		var parent_body = target_to_attack.get_parent()
		if parent_body and parent_body.has_method("take_damage"):
			parent_body.take_damage(damage)
		elif target_to_attack.has_method("take_damage"):
			target_to_attack.take_damage(damage)

func take_damage(dmg: int) -> void:
	hit_flash()
	var actual_damage: int = maxi(dmg - armor, 1)  # Armor reduces damage, minimum 1
	hp -= actual_damage
	hit_occurred.emit(global_position)

@warning_ignore("unused_parameter")
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "wallarea" or area.name == "tower":
		is_attacking = false
		target_to_attack = null
		has_applied_damage = false
		velocity.x = -move_speed
		is_moving = true
		if sprite:
			sprite.play("run")

func hit_flash() -> void:
	var animation_player := get_node_or_null("AnimationPlayer")
	if animation_player:
		animation_player.play("hit flash")


func _shake_camera(amount: float, duration: float) -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var camera: Camera2D = parent_node.get_node_or_null("Camera2D") as Camera2D
	if camera and camera.has_method("shake"):
		camera.shake(amount, duration)
