# Enhanced Tower with Upgrade System
extends StaticBody2D

@export var max_hp: int = 200
@export var damage_per_second: int = 15
@export var upgrade_level: int = 1
@export var max_upgrade_level: int = 4

# Tower upgrade costs
var upgrade_costs: Array[int] = [0, 50, 120, 200]

# Tower stats per level
var tower_stats: Array[Dictionary] = [
	{},
	{"hp": 200, "damage": 15, "texture": "res://assets/map/props/towers/tower.png"},
	{"hp": 350, "damage": 25, "texture": "res://assets/map/props/towers/tower_lvl2.png"},
	{"hp": 500, "damage": 40, "texture": "res://assets/map/props/towers/tower_lvl3.png"},
	{"hp": 750, "damage": 60, "texture": "res://assets/map/props/towers/tower_lvl4.png"}
]

var enemy_touching = false
var current_hp: int = 200
var enemy_nearby: bool = false
var damage_timer: float = 0
var number_enemies: int = 0
@onready var tower_sprite: Sprite2D = $Tower
var hit_tween: Tween

func _ready():
	var death_gui = $"../death"
	death_gui.hide()
	
	# Initialize tower with level 1 stats
	apply_upgrade_stats()
	
	# Connect upgrade button if it exists
	if has_node("../Control/upgrade_tower"):
		var upgrade_btn = $"../Control/upgrade_tower"
		if not upgrade_btn.pressed.is_connected(_on_upgrade_tower_pressed):
			upgrade_btn.pressed.connect(_on_upgrade_tower_pressed)

func apply_upgrade_stats():
	if upgrade_level <= 0 or upgrade_level > max_upgrade_level:
		upgrade_level = 1
	
	var stats = tower_stats[upgrade_level]
	max_hp = stats["hp"]
	current_hp = max_hp
	damage_per_second = stats["damage"]
	
	# Update texture
	var new_texture = load(stats["texture"])
	tower_sprite.texture = new_texture
	
	print("Tower upgraded to level ", upgrade_level, " - HP: ", max_hp, " DPS: ", damage_per_second)

func get_upgrade_text() -> String:
	if upgrade_level >= max_upgrade_level:
		return "MAX LEVEL"
	
	var cost = upgrade_costs[upgrade_level] if upgrade_level < upgrade_costs.size() else 999
	return "Upgrade Tower (" + str(cost) + " coins)"

func can_upgrade() -> bool:
	if upgrade_level >= max_upgrade_level:
		return false
	
	var cost = upgrade_costs[upgrade_level] if upgrade_level < upgrade_costs.size() else 999
	return global_var.coins >= cost

func _process(delta):
	if enemy_nearby:
		damage_timer += delta
		if damage_timer >= 1.0:
			take_damage(damage_per_second)
			damage_timer = 0
	
	# Update upgrade button text
	if has_node("../Control/upgrade_tower"):
		var upgrade_btn = $"../Control/upgrade_tower"
		upgrade_btn.text = get_upgrade_text()
		upgrade_btn.disabled = not can_upgrade()

func take_damage(damage: int):
	if current_hp <= 0:
		destroy_tower()
		$"../death/lost".play()
	else:
		current_hp -= damage + number_enemies
		print("Tower HP: ", current_hp)
		trigger_hit_effect()

func trigger_hit_effect():
	if hit_tween:
		hit_tween.kill()
	
	hit_tween = create_tween()
	hit_tween.tween_property(tower_sprite, "modulate", Color.RED, 0.1)
	hit_tween.tween_property(tower_sprite, "modulate", Color.WHITE, 0.1)

func destroy_tower():
	print("tower destroyed!")
	create_destruction_particles()
	
	queue_free()
	$"../player".queue_free()
	$"../death".show()
	$"../Flag".queue_free()

func create_destruction_particles():
	for i in range(20):
		var particle = Sprite2D.new()
		var rock_texture = preload("res://assets/map/rocks .png")
		particle.texture = rock_texture
		particle.scale = Vector2(0.2, 0.2)
		particle.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		
		get_tree().root.add_child(particle)
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(randf_range(-100, 100), randf_range(-50, -150)), 2.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 2.0)
		tween.parallel().tween_property(particle, "rotation", randf_range(-10, 10), 2.0)
		tween.tween_callback(particle.queue_free)

func _on_upgrade_tower_pressed():
	if not can_upgrade():
		print("Cannot upgrade tower - insufficient coins or max level reached")
		return
	
	var cost = upgrade_costs[upgrade_level]
	global_var.coins -= cost
	upgrade_level += 1
	
	apply_upgrade_stats()
	create_upgrade_particles()
	
	# Play upgrade sound
	if has_node("../wall1/build_sound"):
		$"../wall1/build_sound".play()

func create_upgrade_particles():
	for i in range(10):
		var particle = Sprite2D.new()
		var coin_texture = preload("res://assets/map/props/coin.png")
		particle.texture = coin_texture
		particle.scale = Vector2(0.3, 0.3)
		particle.modulate = Color.GOLD
		particle.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		
		get_tree().root.add_child(particle)
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(randf_range(-20, 20), randf_range(-80, -120)), 1.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.5)
		tween.parallel().tween_property(particle, "scale", Vector2(0.1, 0.1), 1.5)
		tween.parallel().tween_property(particle, "rotation", randf_range(0, 6.28), 1.5)
		tween.tween_callback(particle.queue_free)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "enemy1":
		number_enemies += 1
		enemy_nearby = true
		take_damage(damage_per_second)
		print("Enemy entered tower area")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "enemy1":
		number_enemies = max(0, number_enemies - 1)
		if number_enemies == 0:
			enemy_nearby = false

# Legacy dissolve shader functionality (keeping for compatibility)
var rng = RandomNumberGenerator.new()


func update_progress(value: float):
	if material:
		material.set_shader_parameter("progress", value)
