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
	# Reconnect the enemy1 Area2D signals to THIS script (parent _ready connects to parent methods)
	_reconnect_area_signals()

## Reconnect enemy1 Area2D signals so wall detection works through inheritance
func _reconnect_area_signals() -> void:
	var area: Area2D = get_node_or_null("enemy1")
	if area == null:
		return
	# Disconnect existing connections (from parent _ready)
	if area.area_entered.is_connected(_on_area_2d_area_entered):
		area.area_entered.disconnect(_on_area_2d_area_entered)
	if area.area_exited.is_connected(_on_area_2d_area_exited):
		area.area_exited.disconnect(_on_area_2d_area_exited)
	if area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.disconnect(_on_area_2d_body_entered)

	# Reconnect to self (these will resolve to the enemy_1.gd methods via super)
	area.area_entered.connect(_on_area_2d_area_entered)
	area.area_exited.connect(_on_area_2d_area_exited)
	area.body_entered.connect(_on_area_2d_body_entered)


## Override coin drop to spawn multiple coins (knights give bonus coins)
func spawn_coin() -> void:
	if coin_scene:
		var total_coins: int = knight_coin_drop * coin_multiplier * base_coins
		for _i in range(total_coins):
			var coin_instance: Node2D = coin_scene.instantiate()
			get_parent().add_child(coin_instance)
			coin_instance.global_position = sprite.global_position + Vector2(randf_range(-15, 15), randf_range(-10, 10))
