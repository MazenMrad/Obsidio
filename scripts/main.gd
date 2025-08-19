extends Node2D

@export var enemy = preload("res://scenes/characters/enemy.tscn")
@export var enemy2 = preload("res://scenes/characters/enemy2.tscn")  # Use preload
@onready var spawn_text: Label = $"../spawn_text"
@onready var coin_label: Label = $"../coin_label"
@onready var arrows_label: Label = $"../arrows"
@onready var wave_timer: Timer = $Timer

# Wave system variables
var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var is_wave_active: bool = false
var break_time_remaining: float = 10.0
var is_break_time: bool = false


func _ready():
	# Set up wave timer
	wave_timer.wait_time = 10.0  # 10 second break between waves
	wave_timer.one_shot = true
	start_break_time()

func _process(delta):
	coin_label.text =str(global_var.coins)
	arrows_label.text =str(global_var.arrows)
	
	# Resupply arrows for 1 coin when pressing 'R'
	if Input.is_action_just_pressed("ui_accept"): # Change to 'R' if you have a custom input, or use Input.is_key_pressed(KEY_R)
		if global_var.coins > 0:
			global_var.coins -= 1
			global_var.arrows += 1
	
	# Update break time countdown
	if is_break_time:
		break_time_remaining -= delta
		if break_time_remaining <= 0:
			start_wave()
		else:
			spawn_text.text = "Wave " + str(current_wave) + " in " + str(int(break_time_remaining)) + "s"
	
	# Check if wave is complete
	if is_wave_active:
		var current_enemies = get_tree().get_nodes_in_group("enemies").size()
		if current_enemies == 0 and enemies_spawned_this_wave > 0:
			complete_wave()
	
		
#(break time ends)
func start_break_time():
	is_break_time = true
	is_wave_active = false
	break_time_remaining = 10.0
	spawn_text.text = "Wave " + str(current_wave) + " in 10s"
	print("Break time started - Wave ", current_wave, " in 10 seconds")

func start_wave():
	is_break_time = false
	is_wave_active = true
	enemies_spawned_this_wave = 0
	enemies_killed_this_wave = 0
	
	spawn_text.text = "Wave " + str(current_wave) + " - Enemies: " + str(enemies_per_wave)
	print("Wave ", current_wave, " started with ", enemies_per_wave, " enemies")
	
	# Spawn all enemies for this wave
	spawn_wave_enemies()

func spawn_wave_enemies():
	$enemy_spawn_audio.play()
	for i in range(enemies_per_wave):
		print("spawned enemy")
		var ene = enemy.instantiate()
		if get_tree().get_nodes_in_group("enemy1").size()>=3:
			var ene2 = enemy2.instantiate()
			get_parent().add_child(ene2)
			ene2.position = Vector2(randf_range(-10,-60), 83.005)
			enemies_spawned_this_wave += 1
			ene2.connect("died", Callable(self, "_on_enemy_died"))
		get_parent().add_child(ene)
		ene.position = Vector2(randf_range(-10,-60), 83.005)
		
		enemies_spawned_this_wave += 1
		
		# Connect to enemy death signal
		ene.connect("died", Callable(self, "_on_enemy_died"))
		
	
	update_enemy_count()

func complete_wave():
	is_wave_active = false
	enemies_killed_this_wave = enemies_spawned_this_wave
	
	print("Wave ", current_wave, " completed! Killed: ", enemies_killed_this_wave, "/", enemies_spawned_this_wave)
	
	# Prepare for next wave
	current_wave += 1
	enemies_per_wave += 2  # Add 2 enemies per wave
	
	# Start break time for next wave
	start_break_time()

func _on_enemy_died():
	enemies_killed_this_wave += 1
	update_enemy_count()
	
	# Update wave progress
	if is_wave_active:
		var remaining = enemies_spawned_this_wave - enemies_killed_this_wave
		spawn_text.text = "Wave " + str(current_wave) + " - Remaining: " + str(remaining)

func update_enemy_count():
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	print("Enemies alive: ", enemy_count)
	
	# Update wave progress display
	if is_wave_active:
		var remaining = enemies_spawned_this_wave - enemies_killed_this_wave
		spawn_text.text = "Wave " + str(current_wave) + " - Remaining: " + str(remaining)
		

	
