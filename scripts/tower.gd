extends StaticBody2D

@export var max_hp: int = 200
@export var damage_per_second: int = 15
@export var upgrade_level: int = 1
@export var max_upgrade_level: int = 4
@export var enable_destruction_particles: bool = false

var upgrade_costs: Array[int] = [0, 50, 120, 200]

var tower_stats: Array[Dictionary] = [
	{},
	{"hp": 200, "damage": 15, "texture": "res://assets/map/props/towers/tower.png"},
	{"hp": 350, "damage": 25, "texture": "res://assets/map/props/towers/tower_lvl2.png"},
	{"hp": 500, "damage": 40, "texture": "res://assets/map/props/towers/tower_lvl3.png"},
	{"hp": 750, "damage": 60, "texture": "res://assets/map/props/towers/tower_lvl4.png"}
]

var enemy_touching: bool = false
var current_hp: int = 200
var enemy_nearby: bool = false
var damage_timer: float = 0.0
var number_enemies: int = 0
@onready var tower_sprite: Sprite2D = $Tower
@onready var death_gui: Control = $"../CanvasLayer/death"
@onready var lost_audio: AudioStreamPlayer2D = $"../CanvasLayer/death/lost"
@onready var upgrade_btn: Button = $"../CanvasLayer/Control/actions/upgrade_tower"
var hit_tween: Tween
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	if death_gui:
		death_gui.hide()
	
	apply_upgrade_stats()
	
	if upgrade_btn:
		if not upgrade_btn.pressed.is_connected(_on_upgrade_tower_pressed):
			upgrade_btn.pressed.connect(_on_upgrade_tower_pressed)

func apply_upgrade_stats() -> void:
	if upgrade_level <= 0 or upgrade_level > max_upgrade_level:
		upgrade_level = 1
	
	var stats: Dictionary = tower_stats[upgrade_level]
	max_hp = stats["hp"]
	current_hp = max_hp
	damage_per_second = stats["damage"]
	
	var new_texture: Texture2D = load(stats["texture"])
	tower_sprite.texture = new_texture
	
	print("Tower upgraded to level %d - HP: %d DPS: %d" % [upgrade_level, max_hp, damage_per_second])

func get_upgrade_text() -> String:
	if upgrade_level >= max_upgrade_level:
		return "MAX LEVEL"
	
	var cost: int = upgrade_costs[upgrade_level] if upgrade_level < upgrade_costs.size() else 999
	return "Upgrade Tower (%d coins)" % cost

func can_upgrade() -> bool:
	if upgrade_level >= max_upgrade_level:
		return false
	
	var cost: int = upgrade_costs[upgrade_level] if upgrade_level < upgrade_costs.size() else 999
	return global_var.coins >= cost

func _process(delta: float) -> void:
	if enemy_nearby:
		damage_timer += delta
		if damage_timer >= 1.0:
			take_damage(damage_per_second)
			damage_timer = 0.0
	
	if upgrade_btn:
		upgrade_btn.text = get_upgrade_text()
		upgrade_btn.disabled = not can_upgrade()

func take_damage(damage: int) -> void:
	current_hp -= damage + number_enemies
	print("Tower HP: %d" % current_hp)
	trigger_hit_effect()
	if current_hp <= 0:
		destroy_tower()

func trigger_hit_effect() -> void:
	if hit_tween:
		hit_tween.kill()
	
	hit_tween = create_tween()
	hit_tween.tween_property(tower_sprite, "modulate", Color.RED, 0.1)
	hit_tween.tween_property(tower_sprite, "modulate", Color.WHITE, 0.1)

func destroy_tower() -> void:
	print("tower destroyed!")
	if enable_destruction_particles:
		create_destruction_particles()

	if lost_audio:
		lost_audio.play()

	var player: Node = get_parent().get_node_or_null("Player")
	if player:
		player.queue_free()

	if death_gui:
		death_gui.show()

	enemy_nearby = false
	set_process(false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	collision_layer = 0
	collision_mask = 0
	if upgrade_btn:
		upgrade_btn.disabled = true
	queue_free()

func create_destruction_particles() -> void:
	for i in range(20):
		var particle := Sprite2D.new()
		var rock_texture: Texture2D = preload("res://assets/map/rocks .png")
		particle.texture = rock_texture
		particle.scale = Vector2(0.2, 0.2)
		particle.global_position = global_position + Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-30.0, 30.0))
		
		get_tree().root.add_child(particle)
		
		var tween := create_tween()
		tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-50.0, -150.0)), 2.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 2.0)
		tween.parallel().tween_property(particle, "rotation", rng.randf_range(-10.0, 10.0), 2.0)
		tween.tween_callback(particle.queue_free)

func _on_upgrade_tower_pressed() -> void:
	if not can_upgrade():
		print("Cannot upgrade tower - insufficient coins or max level reached")
		return
	
	var cost: int = upgrade_costs[upgrade_level]
	global_var.coins -= cost
	upgrade_level += 1
	
	apply_upgrade_stats()
	create_upgrade_particles()
	
	if has_node("../wall/build_sound"):
		var build_sound := get_node("../wall/build_sound")
		build_sound.play()

func create_upgrade_particles() -> void:
	for i in range(10):
		var particle := Sprite2D.new()
		var coin_texture: Texture2D = preload("res://assets/map/props/coin.png")
		particle.texture = coin_texture
		particle.scale = Vector2(0.3, 0.3)
		particle.modulate = Color.GOLD
		particle.global_position = global_position + Vector2(rng.randf_range(-40.0, 40.0), rng.randf_range(-40.0, 40.0))
		
		get_tree().root.add_child(particle)
		
		var tween := create_tween()
		tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-80.0, -120.0)), 1.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.5)
		tween.parallel().tween_property(particle, "scale", Vector2(0.1, 0.1), 1.5)
		tween.parallel().tween_property(particle, "rotation", rng.randf_range(0.0, 6.28), 1.5)
		tween.tween_callback(particle.queue_free)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "enemy1":
		number_enemies += 1
		enemy_nearby = true
		take_damage(damage_per_second)
		print("Enemy entered tower area")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "enemy1":
		number_enemies = maxi(0, number_enemies - 1)
		if number_enemies == 0:
			enemy_nearby = false

func update_progress(value: float) -> void:
	if material:
		material.set_shader_parameter("progress", value)
