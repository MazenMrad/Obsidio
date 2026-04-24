extends "res://scripts/enemy_1.gd"
# Enemy2 — Skirmisher variant
# Fast, low HP, lower damage — hits quick and gets to the wall first

@export var skirmisher_hp: int = 50 # Half of basic enemy (100)
@export var skirmisher_speed: float = 95.0 # ~1.6x basic enemy (60)
@export var skirmisher_damage: int = 12 # Lower damage per hit

func _ready() -> void:
	super._ready()
	# Override base stats after parent _ready
	hp = skirmisher_hp
	max_hp = skirmisher_hp
	move_speed = skirmisher_speed
	damage = skirmisher_damage
	velocity.x = -move_speed
	# Remove from enemy1 group and add to enemy2 group
	remove_from_group("enemy1")
	add_to_group("enemy2")

## Skirmishers die faster — smaller camera shake
func _shake_camera(_amount: float, _duration: float) -> void:
	super._shake_camera(2.0, 0.08)
