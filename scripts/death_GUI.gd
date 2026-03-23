extends Control

var _player: CharacterBody2D
var _tower: StaticBody2D
var _flag: Sprite2D

func _ready() -> void:
	_player = get_node_or_null("../player")
	_tower = get_node_or_null("../tower")
	_flag = get_node_or_null("../Flag")
	
	var wave_label := get_node_or_null("wave")
	var enemy_label := get_node_or_null("enemy")
	if wave_label:
		wave_label.text = "waves survived %d" % global_var.waves
	if enemy_label:
		enemy_label.text = "enemies killed %d" % global_var.enemy_killed

func _on_restart_pressed() -> void:
	print("restarting")
	global_var.reset()
	get_tree().reload_current_scene()

func _on_restart_button_up() -> void:
	pass

func _on_button_pressed() -> void:
	pass
