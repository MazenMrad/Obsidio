
extends Node2D

@export var enemy = load("res://scenes/characters/enemy.tscn")
@onready var coin_label: Label = $"../coin_label"
func _process(delta: float) -> void:
	coin_label.text="collected coins="+str(global_var.coins)
	
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
