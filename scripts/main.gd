
extends Node2D

@export var enemy = load("res://scenes/characters/enemy.tscn")

func _on_timer_timeout() -> void:
	var ene= enemy.instantiate()
	ene.position=position
	get_parent().get_node("Enemy spawner").add_child(ene)
	do_spawn()
	pass # Replace with function body.
func _ready():
	do_spawn()
func do_spawn():
	var ene= enemy.instantiate()
	add_child(ene)
