extends Control

const DISCLAIMER_SCENE: PackedScene = preload("res://scenes/disclaimer_popup.tscn")

@onready var start_button: Button = $VBox/StartButton
@onready var options_button: Button = $VBox/OptionsButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var master_slider: HSlider = $OptionsContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var music_slider: HSlider = $OptionsContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var sfx_slider: HSlider = $OptionsContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var back_button: Button = $OptionsContainer/BackButton

func _ready() -> void:
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Initialize volume sliders from saved settings
	_load_settings()
	
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Show main menu initially
	_show_main_menu()

func _show_main_menu() -> void:
	options_container.visible = false
	start_button.visible = true
	options_button.visible = true
	quit_button.visible = true

func _on_start_pressed() -> void:
	_save_settings()
	_show_disclaimer_popup()

func _show_disclaimer_popup() -> void:
	if DISCLAIMER_SCENE:
		var disclaimer := DISCLAIMER_SCENE.instantiate()
		add_child(disclaimer)
		# Connect to play_pressed signal to start the game
		disclaimer.play_pressed.connect(_on_disclaimer_play_pressed)

func _on_disclaimer_play_pressed() -> void:
	# Start the game after disclaimer is closed
	PersistentScene.change_scene("res://scenes/main.tscn")


func _on_restart_pressed() -> void:
	_save_settings()
	PersistentScene.go_to_main_menu()

func _on_options_pressed() -> void:
	options_container.visible = true
	start_button.visible = false
	options_button.visible = false
	quit_button.visible = false

func _on_back_pressed() -> void:
	_save_settings()
	_show_main_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _load_settings() -> void:
	var settings_file := ConfigFile.new()
	if settings_file.load("user://settings.cfg") == OK:
		var master = settings_file.get_value("audio", "master", 1.0)
		var music = settings_file.get_value("audio", "music", 0.8)
		var sfx = settings_file.get_value("audio", "sfx", 1.0)
		
		master_slider.value = master
		music_slider.value = music
		sfx_slider.value = sfx
		
		_apply_all()
	else:
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 1.0
		_apply_all()

func _save_settings() -> void:
	var settings_file := ConfigFile.new()
	settings_file.set_value("audio", "master", master_slider.value)
	settings_file.set_value("audio", "music", music_slider.value)
	settings_file.set_value("audio", "sfx", sfx_slider.value)
	settings_file.save("user://settings.cfg")

func _on_master_changed(value: float) -> void:
	_apply_bus_volume("Master", value)

func _on_music_changed(value: float) -> void:
	_apply_bus_volume("Music", value)

func _on_sfx_changed(value: float) -> void:
	_apply_bus_volume("SFX", value)

func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		# Only apply if not at min (0 = mute)
		if linear_value > 0.0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value))
		else:
			AudioServer.set_bus_volume_db(bus_idx, -80.0)  # Effectively mute

func _apply_all():
	_apply_bus_volume("Master", master_slider.value)
	_apply_bus_volume("Music", music_slider.value)
	_apply_bus_volume("SFX", sfx_slider.value)
