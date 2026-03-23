extends CharacterBody2D

@export var coin_scene: PackedScene
@export var move_speed: float = 60.0
@export var wobble_intensity: float = 1.5
@export var wobble_speed: float = 3.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var wall: StaticBody2D

var hp: int = 100
var original_y: float
var time_offset: float
var is_moving: bool = true
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

signal died

func die() -> void:
	emit_signal("died")
	spawn_coin()
	queue_free()

func spawn_coin() -> void:
	if coin_scene:
		var coin_instance: Node2D = coin_scene.instantiate()
		get_parent().add_child(coin_instance)
		coin_instance.global_position = sprite.global_position
		print(global_var.coins)
		print("coin", coin_instance.global_position)

func get_current_frame() -> int:
	if sprite:
		return sprite.frame
	return 0

func _ready() -> void:
	rng.randomize()
	add_to_group("enemies")
	add_to_group("enemy1")
	
	original_y = position.y
	time_offset = rng.randf() * 2.0 * PI
	velocity.x = -move_speed
	
	if sprite:
		sprite.play("run")

@warning_ignore("unused_parameter")
func _physics_process(_delta: float) -> void:
	if is_moving:
		move_and_slide()
	if hp <= 0:
		die()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "wallarea" or area.name == "tower":
		var attack_anim: String = "attack" if sprite.sprite_frames.has_animation("attack") else ("default" if sprite.sprite_frames.has_animation("default") else "idle")
		sprite.play(attack_anim)
		var wall_hit := get_node_or_null("wall_hit")
		if wall_hit:
			wall_hit.play()
		velocity.x = 0.0
		is_moving = false

func take_damage(dmg: int) -> void:
	hit_flash()
	hp -= dmg

@warning_ignore("unused_parameter")
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "wallarea" or area.name == "tower":
		velocity.x = -move_speed
		is_moving = true
		if sprite:
			sprite.play("run")

func hit_flash() -> void:
	var animation_player := get_node_or_null("AnimationPlayer")
	if animation_player:
		animation_player.play("hit flash")
