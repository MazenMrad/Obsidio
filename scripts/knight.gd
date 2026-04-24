extends "res://scripts/enemy_1.gd"
# Knight enemy - armored tank variant
# Slower, tougher (armor reduces incoming damage), hits harder, drops more coins

@export var knight_hp: int = 200 # 2x basic enemy
@export var knight_speed: float = 35.0 # ~60% of basic enemy (60)
@export var knight_damage: int = 35 # 1.75x basic enemy (20)
@export var knight_armor: int = 5 # Reduces each hit by 5 damage (was 8)
@export var knight_coin_drop: int = 2 # Drops 2 coins instead of 1

func _ready() -> void:
	super._ready()
	# Override base stats after parent _ready sets them
	hp = knight_hp
	max_hp = knight_hp
	move_speed = knight_speed
	damage = knight_damage
	armor = knight_armor
	velocity.x = -move_speed # Update velocity after speed change
	# Remove from enemy1 group and add to knight group
	remove_from_group("enemy1")
	add_to_group("knight")

## Override coin drop to spawn multiple coins (knights give bonus coins)
func spawn_coin() -> void:
	if coin_scene:
		var total_coins: int = knight_coin_drop * coin_multiplier * base_coins
		for _i in range(total_coins):
			var coin_instance: Node2D = coin_scene.instantiate()
			get_parent().add_child(coin_instance)
			coin_instance.global_position = sprite.global_position + Vector2(randf_range(-15, 15), randf_range(-10, 10))
