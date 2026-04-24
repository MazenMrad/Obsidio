extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/characters/enemy.tscn")
const ENEMY2_SCENE: PackedScene = preload("res://scenes/characters/enemy2.tscn")
const KNIGHT_SCENE: PackedScene = preload("res://scenes/characters/knight.tscn")
const WAVE_WIN: int = 15  # Victory at wave 15 completion

@onready var wave_timer: Timer = $Timer
@onready var hit_effect: GPUParticles2D = $"../hit_effect"
@onready var death1_sound: AudioStreamPlayer2D = $"../Audio/death1"
@onready var death2_sound: AudioStreamPlayer2D = $"../Audio/death2"
@onready var death3_sound: AudioStreamPlayer2D = $"../Audio/death3"
@onready var battle_music: AudioStreamPlayer = $"../Audio/battle"
@onready var prewave_music: AudioStreamPlayer = $"../AudioStreamPlayer"
@onready var victory_music: AudioStreamPlayer = $"../Audio/victory"
@onready var game_over_music: AudioStreamPlayer = $"../Audio/game_over"
var spawner_pos: Vector2

var spawn_text: Label
var coin_label: Label
var arrows_label: Label
var wave_progress_panel: TextureRect
var wave_progress_bar: TextureProgressBar
var wave_label: Label

const BREAK_TIME: float = 15.0

## Wave difficulty scaling - REDUCED for better balance
## HP multiplier grows per wave: 1.0 base, +4% per wave after wave 1 (was 8%)
const HP_SCALE_PER_WAVE: float = 0.04
## Speed multiplier grows per wave: 1.0 base, +2% per wave after wave 1 (was 3%)
const SPEED_SCALE_PER_WAVE: float = 0.02

## Wave events — special modifier applied every N waves
enum WaveEvent { NONE, DOUBLE_COINS, ARMORED_WAVE, FAST_WAVE }
var current_wave_event: WaveEvent = WaveEvent.NONE
var wave_event_description: String = ""

var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var is_wave_active: bool = false
var break_time_remaining: float = BREAK_TIME
var is_break_time: bool = false
var is_game_over: bool = false
var is_victory: bool = false
var _prev_coins: int = -1




func _ready() -> void:
	spawn_text = $"../CanvasLayer/Control/indicators/spawn_text"
	coin_label = $"../CanvasLayer/Control/indicators/coin_label"
	arrows_label = $"../CanvasLayer/Control/indicators/arrows"
	wave_progress_panel = $"../CanvasLayer/wave_progress_panel"
	wave_progress_bar = $"../CanvasLayer/wave_progress_panel/wave_progress_bar"
	wave_label = $"../CanvasLayer/wave_progress_panel/wave_label"

	spawner_pos = position
	wave_timer.wait_time = BREAK_TIME
	wave_timer.one_shot = true

	# Connect to all tower destroyed signals
	_connect_tower_signals()

	start_break_time()

func _connect_tower_signals() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	for tower_name: String in ["tower", "tower2", "tower3", "tower4", "tower5", "tower6"]:
		var tower: Node = parent_node.get_node_or_null(tower_name)
		if tower and tower.has_signal("tower_destroyed"):
			if not tower.tower_destroyed.is_connected(_trigger_game_over):
				tower.tower_destroyed.connect(_trigger_game_over)

func _on_timer_timeout() -> void:
	pass

func _process(delta: float) -> void:
	if coin_label:
		coin_label.text = str(global_var.coins)
		if global_var.coins != _prev_coins:
			_pulse_coin_label()
			_prev_coins = global_var.coins
	if arrows_label:
		arrows_label.text = str(global_var.arrows)
	if Input.is_action_just_pressed("ui_accept"):
		if global_var.coins > 0:
			global_var.coins -= 1
			global_var.arrows += 1
	
	if is_break_time:
		break_time_remaining -= delta
		if break_time_remaining <= 0:
			start_wave()
		else:
			_update_wave_progress_break()
	
	if is_wave_active:
		var current_enemies := get_tree().get_nodes_in_group("enemies").size()
		if current_enemies == 0 and enemies_spawned_this_wave > 0:
			complete_wave()

func _update_wave_progress_break() -> void:
	# During break: only update the countdown label text
	# Progress bar value is set by _update_wave_boss_progress() and stays fixed
	if wave_label:
		wave_label.text = "Wave %d / %d (starts in %ds)" % [current_wave, WAVE_WIN, int(break_time_remaining)]

func _update_wave_boss_progress() -> void:
	# Update progress toward final boss wave (wave 15)
	# Progress = (current_wave - 1) / (WAVE_WIN - 1) * 100
	if wave_progress_bar:
		var progress: float = float(current_wave - 1) / float(WAVE_WIN - 1)
		wave_progress_bar.value = progress * 100.0

func start_break_time() -> void:
	is_break_time = true
	is_wave_active = false
	break_time_remaining = BREAK_TIME
	if wave_progress_panel:
		wave_progress_panel.visible = true
	_update_wave_boss_progress()
	if wave_label:
		wave_label.text = "Wave %d / %d" % [current_wave, WAVE_WIN]
		wave_label.visible = true
	print("Break time started - Wave %d in 10 seconds" % current_wave)

func start_wave() -> void:
	is_break_time = false
	is_wave_active = true
	enemies_spawned_this_wave = 0
	enemies_killed_this_wave = 0

	# Determine wave event before spawning
	_determine_wave_event(current_wave)

	# Show progress bar during active wave
	if wave_progress_panel:
		wave_progress_panel.visible = true
	# Don't reset progress - it tracks boss wave progress, not wave completion
	# Progress is only updated when waves complete via _update_wave_boss_progress()
	if wave_label:
		wave_label.text = "Wave %d" % current_wave
		wave_label.visible = true
	print("Wave %d started with %d enemies (HP x%.2f, Speed x%.2f)" % [
		current_wave, enemies_per_wave,
		1.0 + (current_wave - 1) * HP_SCALE_PER_WAVE,
		1.0 + (current_wave - 1) * SPEED_SCALE_PER_WAVE
	])
	if current_wave_event != WaveEvent.NONE:
		print("  Wave Event: %s" % wave_event_description)

	spawn_wave_enemies()
	_play_battle_music()
	_show_wave_start_text()

	# Show wave event banner if active
	if current_wave_event != WaveEvent.NONE:
		_show_wave_event_banner()

func spawn_wave_enemies() -> void:
	$enemy_spawn_audio.play()
	var spawned_this_wave := { "enemy1": 0, "enemy2": 0, "knight": 0 }

	# Calculate wave scaling multipliers
	var hp_mult: float = 1.0 + (current_wave - 1) * HP_SCALE_PER_WAVE
	var speed_mult: float = 1.0 + (current_wave - 1) * SPEED_SCALE_PER_WAVE

	# Apply wave event overrides
	match current_wave_event:
		WaveEvent.ARMORED_WAVE:
			hp_mult *= 1.5  # 50% extra HP on armored wave
		WaveEvent.FAST_WAVE:
			speed_mult *= 1.4  # 40% extra speed on fast wave
		_:
			pass

	for i in range(enemies_per_wave):
		var enemy_type: String = _pick_enemy_type(current_wave, i, spawned_this_wave)
		var enemy_instance: CharacterBody2D = null

		match enemy_type:
			"knight":
				var knight := KNIGHT_SCENE.instantiate() as CharacterBody2D
				get_parent().add_child(knight)
				knight.position = spawner_pos + Vector2(randf_range(-10.0, -60.0), 0.0)
				knight.died.connect(_on_enemy_died)
				if knight.has_signal("hit_occurred"):
					knight.hit_occurred.connect(_on_enemy_hit)
				enemy_instance = knight
			"enemy2":
				var ene2 := ENEMY2_SCENE.instantiate() as CharacterBody2D
				get_parent().add_child(ene2)
				ene2.position = spawner_pos + Vector2(randf_range(-10.0, -60.0), 0.0)
				ene2.died.connect(_on_enemy_died)
				if ene2.has_signal("hit_occurred"):
					ene2.hit_occurred.connect(_on_enemy_hit)
				enemy_instance = ene2
			_:
				var ene := ENEMY_SCENE.instantiate() as CharacterBody2D
				get_parent().add_child(ene)
				ene.position = spawner_pos + Vector2(randf_range(-10.0, -60.0), 0.0)
				ene.died.connect(_on_enemy_died)
				ene.hit_occurred.connect(_on_enemy_hit)
				enemy_instance = ene

		# Apply wave scaling to the spawned enemy
		_apply_wave_scaling(enemy_instance, hp_mult, speed_mult)

		# Apply wave event modifiers to the spawned enemy
		_apply_wave_event_modifiers(enemy_instance)

		spawned_this_wave[enemy_type] += 1
		enemies_spawned_this_wave += 1
		update_enemy_count()


## Apply HP and speed multipliers to a freshly spawned enemy
func _apply_wave_scaling(enemy: CharacterBody2D, hp_mult: float, speed_mult: float) -> void:
	if enemy == null:
		return
	# Use set_meta / get pattern to access base enemy_1 properties
	if "hp" in enemy:
		var base_hp: int = enemy.hp
		enemy.hp = int(base_hp * hp_mult)
	if "max_hp" in enemy:
		enemy.max_hp = enemy.hp
	if "move_speed" in enemy:
		var base_speed: float = enemy.move_speed
		enemy.move_speed = base_speed * speed_mult
	if "velocity" in enemy:
		enemy.velocity.x = -enemy.move_speed


## Apply wave event specific modifiers
func _apply_wave_event_modifiers(enemy: CharacterBody2D) -> void:
	if enemy == null:
		return
	match current_wave_event:
		WaveEvent.DOUBLE_COINS:
			# All enemies drop double coins this wave
			if "coin_multiplier" in enemy:
				enemy.coin_multiplier = 2
		WaveEvent.ARMORED_WAVE:
			# All enemies gain +3 armor this wave (on top of knight's base armor)
			if "armor" in enemy:
				enemy.armor += 3
		WaveEvent.FAST_WAVE:
			# Speed already boosted via _apply_wave_scaling
			# Fast wave enemies also wobble faster for visual flair
			if "wobble_speed" in enemy:
				enemy.wobble_speed *= 1.5
		_:
			pass


## Pick enemy type for a given wave, slot index, and per-wave spawn counts.
## Uses a weighted table that shifts per wave for progressive difficulty.
func _pick_enemy_type(wave: int, index: int, spawned: Dictionary) -> String:
	# Build weighted table based on current wave
	var weights := _get_enemy_weights(wave)

	# Knights: guaranteed every 6th slot from wave 5+ (was every 4th from wave 3)
	if wave >= 5 and index % 6 == 5:
		return "knight"

	# Enemy2: appears from wave 2, after at least 2 enemy1s have spawned this wave
	if wave >= 2 and spawned["enemy1"] >= 2:
		# Weighted random between enemy1 and enemy2
		var total_weight: float = weights["enemy1"] + weights["enemy2"]
		if total_weight <= 0.0:
			return "enemy1"
		var roll: float = randf() * total_weight
		if roll < weights["enemy2"]:
			return "enemy2"
		return "enemy1"

	return "enemy1"


## Returns enemy type weights for a given wave.
## Higher wave = more enemy2 and knight presence.
func _get_enemy_weights(wave: int) -> Dictionary:
	# Base weights
	var w_enemy1: float = 10.0
	var w_enemy2: float = 0.0
	var w_knight: float = 0.0

	# Enemy2 starts appearing wave 2, weight ramps up
	if wave >= 2:
		w_enemy2 = 2.0 + (wave - 2) * 0.8  # 2.0 → 2.8 → 3.6 → ...
	# Knight weight (used for additional slots beyond the guaranteed every-4th)
	if wave >= 5:
		w_knight = 1.0 + (wave - 5) * 0.5

	# Reduce enemy1 weight as wave increases
	w_enemy1 = maxf(3.0, 10.0 - (wave - 1) * 0.6)

	return { "enemy1": w_enemy1, "enemy2": w_enemy2, "knight": w_knight }


## Determine if this wave should have a special event.
## Events start at wave 3, repeat every 3 waves.
func _determine_wave_event(wave: int) -> void:
	current_wave_event = WaveEvent.NONE
	wave_event_description = ""

	if wave < 3:
		return

	# Every 3rd wave gets a random event
	if wave % 3 == 0:
		var event_options: Array[WaveEvent] = [
			WaveEvent.DOUBLE_COINS,
			WaveEvent.ARMORED_WAVE,
			WaveEvent.FAST_WAVE
		]
		current_wave_event = event_options[randi() % event_options.size()]

		match current_wave_event:
			WaveEvent.DOUBLE_COINS:
				wave_event_description = "DOUBLE COINS WAVE!"
			WaveEvent.ARMORED_WAVE:
				wave_event_description = "ARMORED WAVE!"
			WaveEvent.FAST_WAVE:
				wave_event_description = "FAST WAVE!"

func complete_wave() -> void:
	is_wave_active = false
	enemies_killed_this_wave = enemies_spawned_this_wave
	print("Wave %d completed! Killed: %d/%d" % [current_wave, enemies_killed_this_wave, enemies_spawned_this_wave])

	# Update progress bar after wave completion
	_update_wave_boss_progress()
	if wave_label:
		wave_label.text = "Wave %d Clear!" % current_wave

	# Reset wave event
	current_wave_event = WaveEvent.NONE
	wave_event_description = ""

	_show_wave_complete_text()

	global_var.waves += 1

	# Check for victory (completed wave 15)
	if current_wave >= WAVE_WIN:
		_trigger_victory()
		return

	current_wave += 1
	enemies_per_wave = mini(5 + current_wave * 2, 15) # Cap at 15 enemies (was 20)

	_stop_battle_music()
	start_break_time()

func _on_enemy_died() -> void:
	enemies_killed_this_wave += 1
	global_var.enemy_killed += 1
	_play_death_sound()
	print("Total enemies killed: %d" % global_var.enemy_killed)

	update_enemy_count()
	if is_wave_active:
		var wave_label := get_node_or_null("../CanvasLayer/death/wave")
		var kill_label := get_node_or_null("../CanvasLayer/death/enemy")
		var coin_label := get_node_or_null("../CanvasLayer/death/coins")
		if wave_label:
			wave_label.text = "Waves Survived: %d" % global_var.waves
		if kill_label:
			kill_label.text = "Enemies Killed: %d" % global_var.enemy_killed
		if coin_label:
			coin_label.text = "Coins Earned: %d" % global_var.coins_earned

func update_enemy_count() -> void:
	var enemy_count := get_tree().get_nodes_in_group("enemies").size()
	print("Enemies alive: %d" % enemy_count)
	if is_wave_active:
		var remaining := enemies_spawned_this_wave - enemies_killed_this_wave
		# Update wave label with current wave progress
		if wave_label:
			wave_label.text = "Wave %d - %d left" % [current_wave, remaining]
	# Wave progress bar now tracks progress toward boss wave, not enemy kills
	# This is updated in _update_wave_boss_progress() when waves complete

func _on_enemy_hit(hit_position: Vector2) -> void:
	if hit_effect == null:
		return
	hit_effect.visible = true
	hit_effect.global_position = hit_position
	hit_effect.emitting = true
	hit_effect.restart()

func _play_death_sound() -> void:
	if death1_sound == null or death2_sound == null or death3_sound == null:
		return

	# Randomly pick one of the three death sounds
	var player: AudioStreamPlayer2D
	var choice := randi() % 3
	if choice == 0:
		player = death1_sound
	elif choice == 1:
		player = death2_sound
	else:
		player = death3_sound

	# Apply random pitch variation (0.8 to 1.2 = ±20% range)
	player.pitch_scale = randf_range(0.8, 1.2)

	# Play the sound
	player.play()

func _play_battle_music() -> void:
	if battle_music == null or is_game_over or is_victory:
		return

	# Fade out prewave music
	if prewave_music != null and prewave_music.playing:
		var prewave_tween := create_tween()
		prewave_tween.tween_property(prewave_music, "volume_db", -80.0, 0.5)
		prewave_tween.tween_callback(prewave_music.stop)

	# Fade in and play battle music
	battle_music.volume_db = -80.0
	battle_music.play()
	var battle_tween := create_tween()
	battle_tween.tween_property(battle_music, "volume_db", 0.0, 0.5)

func _stop_battle_music() -> void:
	if battle_music == null:
		return
	battle_music.stop()

	# Fade back in prewave music for break time
	if prewave_music != null:
		prewave_music.volume_db = -80.0
		prewave_music.play()
		var prewave_tween := create_tween()
		prewave_tween.tween_property(prewave_music, "volume_db", 0.0, 0.5)

func _trigger_victory() -> void:
	if is_victory:
		return
	is_victory = true
	is_game_over = true
	is_wave_active = false
	_stop_battle_music()
	if prewave_music and prewave_music.playing:
		prewave_music.stop()
	if victory_music:
		victory_music.play()
	# Show victory UI
	var victory_gui := get_node_or_null("../CanvasLayer/victory")
	if victory_gui:
		victory_gui.visible = true
	# Freeze remaining enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	print("VICTORY! Reached wave %d" % WAVE_WIN)

func _trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	_stop_battle_music()
	if prewave_music and prewave_music.playing:
		prewave_music.stop()
	if game_over_music:
		game_over_music.play()
	# Save run stats (updates high scores) — death_GUI._ready() also calls this
	global_var.save_run_stats()
	# Show death screen
	var death_gui := get_node_or_null("../CanvasLayer/death")
	if death_gui:
		death_gui.visible = true
	# Freeze remaining enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	print("GAME OVER at wave %d" % current_wave)


func _pulse_coin_label() -> void:
	if coin_label == null:
		return
	var tween := create_tween()
	tween.tween_property(coin_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(coin_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func _show_wave_start_text() -> void:
	var label := get_node_or_null("../CanvasLayer/wave_start_text")
	if label == null:
		return
	label.text = "WAVE %d" % current_wave
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(2.0, 2.0)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): label.visible = false)


func _show_wave_complete_text() -> void:
	var label := get_node_or_null("../CanvasLayer/wave_complete_text")
	if label == null:
		return
	label.text = "WAVE %d COMPLETE!" % current_wave
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): label.visible = false)


func _show_wave_event_banner() -> void:
	var banner := get_node_or_null("../CanvasLayer/wave_event_banner")
	if banner == null:
		return
	banner.text = wave_event_description
	banner.visible = true
	banner.scale = Vector2(1.8, 1.8)

	# Color based on event type (start at alpha=0 for fade-in)
	var banner_color: Color = Color.WHITE
	match current_wave_event:
		WaveEvent.DOUBLE_COINS:
			banner_color = Color(1.0, 0.85, 0.2, 0.0)  # Gold
		WaveEvent.ARMORED_WAVE:
			banner_color = Color(0.7, 0.7, 0.9, 0.0)  # Steel blue
		WaveEvent.FAST_WAVE:
			banner_color = Color(1.0, 0.4, 0.2, 0.0)  # Orange-red
		_:
			banner_color = Color(1.0, 1.0, 1.0, 0.0)

	banner.modulate = banner_color

	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(2.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): banner.visible = false)
