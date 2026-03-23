extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/characters/enemy.tscn")
const ENEMY2_SCENE: PackedScene = preload("res://scenes/characters/enemy2.tscn")
@onready var wave_timer: Timer = $Timer
var spawner_pos: Vector2

var spawn_text: Label
var coin_label: Label
var arrows_label: Label

const BREAK_TIME: float = 10.0

var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var is_wave_active: bool = false
var break_time_remaining: float = BREAK_TIME
var is_break_time: bool = false




func _ready() -> void:
	spawn_text = $"../CanvasLayer/Control/indicators/spawn_text"
	coin_label = $"../CanvasLayer/Control/indicators/coin_label"
	arrows_label = $"../CanvasLayer/Control/indicators/arrows"
	
	spawner_pos = position
	wave_timer.wait_time = BREAK_TIME
	wave_timer.one_shot = true
	start_break_time()

func _on_timer_timeout() -> void:
	pass

func _process(delta: float) -> void:
	if coin_label:
		coin_label.text = str(global_var.coins)
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
		elif spawn_text:
			spawn_text.text = "Wave %d in %ds" % [current_wave, int(break_time_remaining)]
	
	if is_wave_active:
		var current_enemies := get_tree().get_nodes_in_group("enemies").size()
		if current_enemies == 0 and enemies_spawned_this_wave > 0:
			complete_wave()

func start_break_time() -> void:
	is_break_time = true
	is_wave_active = false
	break_time_remaining = BREAK_TIME
	if spawn_text:
		spawn_text.text = "Wave %d in 10s" % current_wave
	print("Break time started - Wave %d in 10 seconds" % current_wave)

func start_wave() -> void:
	is_break_time = false
	is_wave_active = true
	enemies_spawned_this_wave = 0
	enemies_killed_this_wave = 0
	if spawn_text:
		spawn_text.text = "Wave %d - Enemies: %d" % [current_wave, enemies_per_wave]
	print("Wave %d started with %d enemies" % [current_wave, enemies_per_wave])
	spawn_wave_enemies()

func spawn_wave_enemies() -> void:
	$enemy_spawn_audio.play()
	var enemy1_count := get_tree().get_nodes_in_group("enemy1").size()
	for i in range(enemies_per_wave):
		if enemy1_count >= 3:
			var ene2 := ENEMY2_SCENE.instantiate()
			get_parent().add_child(ene2)
			ene2.position = spawner_pos + Vector2(randf_range(-10.0, -60.0), 0.0)
			ene2.died.connect(_on_enemy_died)
			enemies_spawned_this_wave += 1
			continue

		var ene := ENEMY_SCENE.instantiate()
		get_parent().add_child(ene)
		ene.position = spawner_pos + Vector2(randf_range(-10.0, -60.0), 0.0)
		ene.died.connect(_on_enemy_died)
		enemies_spawned_this_wave += 1
		enemy1_count += 1
	
	update_enemy_count()

func complete_wave() -> void:
	is_wave_active = false
	enemies_killed_this_wave = enemies_spawned_this_wave
	print("Wave %d completed! Killed: %d/%d" % [current_wave, enemies_killed_this_wave, enemies_spawned_this_wave])
	
	global_var.waves += 1
	
	current_wave += 1
	enemies_per_wave += 2
	
	start_break_time()

func _on_enemy_died() -> void:
	enemies_killed_this_wave += 1
	global_var.enemy_killed += 1
	print("Total enemies killed: %d" % global_var.enemy_killed)
	
	update_enemy_count()
	if is_wave_active:
		var wave_label := get_node_or_null("../CanvasLayer/death/wave")
		var kill_label := get_node_or_null("../CanvasLayer/death/enemy")
		if wave_label:
			wave_label.text = "Waves Survived %d" % global_var.waves
		if kill_label:
			kill_label.text = "Total Kills %d" % global_var.enemy_killed

func update_enemy_count() -> void:
	var enemy_count := get_tree().get_nodes_in_group("enemies").size()
	print("Enemies alive: %d" % enemy_count)
	if is_wave_active and spawn_text:
		var remaining := enemies_spawned_this_wave - enemies_killed_this_wave
		spawn_text.text = "Wave %d - Remaining: %d" % [current_wave, remaining]
