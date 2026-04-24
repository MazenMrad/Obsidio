extends Control

var _player: CharacterBody2D
var _tower: StaticBody2D
var _flag: Sprite2D

func _ready() -> void:
	var root: Node = get_tree().current_scene
	if root:
		_player = root.get_node_or_null("Player") as CharacterBody2D
		_tower = _get_active_tower(root)
		_flag = root.get_node_or_null("Flag") as Sprite2D
	
	# Save run stats and update high scores before displaying
	global_var.save_run_stats()
	
	# Populate stat labels
	var wave_label := get_node_or_null("CenterContainer/VBoxContainer/StatsContainer/wave")
	var enemy_label := get_node_or_null("CenterContainer/VBoxContainer/StatsContainer/enemy")
	var coin_label := get_node_or_null("CenterContainer/VBoxContainer/StatsContainer/coins")
	if wave_label:
		wave_label.text = "Waves Survived: %d" % global_var.waves
	if enemy_label:
		enemy_label.text = "Enemies Killed: %d" % global_var.enemy_killed
	if coin_label:
		coin_label.text = "Coins Earned: %d" % global_var.coins_earned
	
	# Populate high score labels
	var best_wave_label := get_node_or_null("CenterContainer/VBoxContainer/BestStatsContainer/best_wave")
	var best_kills_label := get_node_or_null("CenterContainer/VBoxContainer/BestStatsContainer/best_kills")
	var best_coins_label := get_node_or_null("CenterContainer/VBoxContainer/BestStatsContainer/best_coins")
	if best_wave_label:
		best_wave_label.text = "Best Wave: %d" % global_var.best_wave
	if best_kills_label:
		best_kills_label.text = "Best Kills: %d" % global_var.best_kills
	if best_coins_label:
		best_coins_label.text = "Best Coins: %d" % global_var.best_coins

func _on_restart_pressed() -> void:
	global_var.reset()
	get_tree().reload_current_scene()

func _on_restart_button_up() -> void:
	pass

func _on_button_pressed() -> void:
	pass


func _get_active_tower(root: Node) -> StaticBody2D:
	for tower_name: String in ["tower", "tower2", "tower3", "tower4", "tower5", "tower6"]:
		var tower: StaticBody2D = root.get_node_or_null(tower_name) as StaticBody2D
		if tower and tower.visible:
			return tower
	return null
