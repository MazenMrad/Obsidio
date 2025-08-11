extends Node2D

@export var spawn_count: int = 5
@export var enemy = preload("res://scenes/characters/enemy.tscn")  # Use preload
@onready var spawn_text: Label = $"../spawn_text"
@onready var coin_label: Label = $"../coin_label"

func _process(delta):
	coin_label.text = "Coins: " + str(global_var.coins)

# Called when Timer times out
func _on_timer_timeout():
	do_spawn()

# Spawn `spawn_count` enemies
func do_spawn():
	for i in range(spawn_count):
		var ene = enemy.instantiate()
		get_parent().add_child(ene)
		ene.position =  Vector2(randf_range(-10,-60), 83.005)
		update_enemy_count()

func _ready():
	# Count enemies (after spawn)
	update_enemy_count()

func update_enemy_count():
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	print("Enemies alive: ", enemy_count)
