extends Control

func _ready() -> void:
	# Save run stats and update high scores before displaying
	global_var.save_run_stats()

	# Populate run stat labels
	var wave_label := get_node_or_null("wave")
	var enemy_label := get_node_or_null("enemy")
	var coin_label := get_node_or_null("coins")
	if wave_label:
		wave_label.text = "Waves Survived: %d" % global_var.waves
	if enemy_label:
		enemy_label.text = "Enemies Defeated: %d" % global_var.enemy_killed
	if coin_label:
		coin_label.text = "Coins Earned: %d" % global_var.coins_earned

	# Populate high score labels
	var best_wave_label := get_node_or_null("best_wave")
	var best_kills_label := get_node_or_null("best_kills")
	var best_coins_label := get_node_or_null("best_coins")
	if best_wave_label:
		best_wave_label.text = "Best Wave: %d" % global_var.best_wave
	if best_kills_label:
		best_kills_label.text = "Best Kills: %d" % global_var.best_kills
	if best_coins_label:
		best_coins_label.text = "Best Coins: %d" % global_var.best_coins

	# Setup persistent upgrade button
	_setup_bonus_arrows_button()

func _setup_bonus_arrows_button() -> void:
	var bonus_btn := get_node_or_null("BonusArrows")
	if bonus_btn == null:
		return
	bonus_btn.text = "+3 Starting Arrows (3 coins)"
	bonus_btn.pressed.connect(_on_bonus_arrows_pressed)
	_update_bonus_button_state()

func _update_bonus_button_state() -> void:
	var bonus_btn := get_node_or_null("BonusArrows")
	if bonus_btn == null:
		return
	if global_var.coins >= 3:
		bonus_btn.disabled = false
		bonus_btn.modulate = Color.WHITE
	else:
		bonus_btn.disabled = true
		bonus_btn.modulate = Color(0.5, 0.5, 0.5)

func _on_bonus_arrows_pressed() -> void:
	if global_var.purchase_bonus_arrows(3):
		var bonus_label := get_node_or_null("bonus_status")
		if bonus_label:
			bonus_label.text = "Next run starts with %d arrows" % (10 + global_var.persistent_bonus_arrows)
		var coin_label := get_node_or_null("coins")
		if coin_label:
			coin_label.text = "Coins Earned: %d" % global_var.coins_earned
		_update_bonus_button_state()


func _on_play_again_pressed() -> void:
	global_var.reset()
	get_tree().reload_current_scene()
