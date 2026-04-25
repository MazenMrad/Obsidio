extends Control

# === Signals ===
signal upgrade_wall_pressed
signal buy_arrow_pressed
signal button_hover_changed(is_hovering: bool)
signal upgrades_pressed

# === Constants ===
const WALL_1: PackedScene = preload("res://assets/map/props/walls/wall1.tscn")
const WALL_2: PackedScene = preload("res://assets/map/props/walls/wall2.tscn")
const WALL_3: PackedScene = preload("res://assets/map/props/walls/wall3.tscn")
const WALL_4: PackedScene = preload("res://assets/map/props/walls/wall4.tscn")
const WALL_5: PackedScene = preload("res://assets/map/props/walls/wall5.tscn")
const WALLS: Array[PackedScene] = [WALL_1, WALL_2, WALL_3, WALL_4, WALL_5]

const DISCLAIMER_SCENE: PackedScene = preload("res://scenes/disclaimer_popup.tscn")

const WALL_POS: Vector2 = Vector2(367.0, 329.0)
const REBUILD_COST: int = 1
const UPGRADE_COST: int = 5
const SETTINGS_PATH: String = "user://settings.cfg"

# === Exports ===
@export var repair_cost: int = 0

# === Onready ===
@onready var sidebar: Control = $sidebar
@onready var actions: Control = $sidebar/actions
@onready var upgrade_wall_btn: TextureButton = $sidebar/actions/upgrade_wall
@onready var buy_arrow_btn: TextureButton = $sidebar/actions/buy_arrow
@onready var repair_btn: TextureButton = $sidebar/actions/repair
@onready var upgrade_wall_label: Label = $sidebar/actions/upgrade_wall/label
@onready var buy_arrow_label: Label = $sidebar/actions/buy_arrow/label
@onready var repair_label: Label = $sidebar/actions/repair/label
@onready var open_upgrade_map_btn: TextureButton = $open_upgrade_map
@onready var upgrade_tower_btn: TextureButton = $sidebar/actions/upgrade_tower
@onready var debug_spawn_knight_btn: TextureButton = $sidebar/actions/debug_spawn_knight
@onready var options_btn: TextureButton = $options_button
@onready var home_btn: TextureButton = $home_buttons
@onready var pause_overlay: ColorRect = $"../PauseOverlay"
@onready var pause_menu: CenterContainer = $"../PauseMenu"
@onready var pause_title: Label = $"../PauseMenu/PausePanel/MarginContainer/VBox/PauseTitle"
@onready var pause_buttons: VBoxContainer = $"../PauseMenu/PausePanel/MarginContainer/VBox/PauseButtons"
@onready var resume_button: Button = $"../PauseMenu/PausePanel/MarginContainer/VBox/PauseButtons/ResumeButton"
@onready var settings_button: Button = $"../PauseMenu/PausePanel/MarginContainer/VBox/PauseButtons/SettingsButton"
@onready var tutorial_button: Button = $"../PauseMenu/PausePanel/MarginContainer/VBox/PauseButtons/TutorialButton"
@onready var pause_home_button: Button = $"../PauseMenu/PausePanel/MarginContainer/VBox/PauseButtons/HomeButton"
@onready var options_container: VBoxContainer = $"../PauseMenu/PausePanel/MarginContainer/VBox/OptionsContainer"
@onready var master_slider: HSlider = $"../PauseMenu/PausePanel/MarginContainer/VBox/OptionsContainer/MasterVolumeContainer/MasterVolumeSlider"
@onready var music_slider: HSlider = $"../PauseMenu/PausePanel/MarginContainer/VBox/OptionsContainer/MusicVolumeContainer/MusicVolumeSlider"
@onready var sfx_slider: HSlider = $"../PauseMenu/PausePanel/MarginContainer/VBox/OptionsContainer/SFXVolumeContainer/SFXVolumeSlider"
@onready var back_button: Button = $"../PauseMenu/PausePanel/MarginContainer/VBox/OptionsContainer/BackButton"
@onready var controls_button: Button = $"../PauseMenu/PausePanel/MarginContainer/VBox/OptionsContainer/ControlsButton"
@onready var death_gui: Control = $"../death"
@onready var upgrade_map: Control = $"../upgrade_map"
@onready var input_remapping: Control = $"../input_remapping"

# buy_sound and equip are siblings under Node/Audio, not children of Control.
var buy_sound: AudioStreamPlayer2D
var tower_upgrade_sound: AudioStreamPlayer
var ui_click_sound: AudioStreamPlayer

# === State ===
var _wall_ref: StaticBody2D = null
var _current_wall_level: int = 0
var _repair_cost: int = 0
var _wall_spawn_global_position: Vector2 = Vector2.ZERO
var _pause_tween: Tween = null
var _is_animating_pause: bool = false

# === Animation State ===
const HOVER_SCALE: float = 1.05
const PRESS_SCALE: float = 0.95
const ANIM_DURATION: float = 0.1
var _button_tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_pause_ui()
	_connect_hover_signals()
	_connect_pause_signals()
	_load_settings()

	var audio_node: Node = get_parent().get_parent()
	if audio_node != null:
		buy_sound = audio_node.get_node_or_null("Audio/buy_sound")
		tower_upgrade_sound = audio_node.get_node_or_null("Audio/tower_upgrade")
		ui_click_sound = audio_node.get_node_or_null("Audio/ui_click")
		if buy_sound == null:
			push_warning("[buttons] buy_sound not found at ../Audio/buy_sound")
		if tower_upgrade_sound == null:
			push_warning("[buttons] tower_upgrade_sound not found at ../Audio/tower_upgrade")
		if ui_click_sound == null:
			push_warning("[buttons] ui_click_sound not found at ../Audio/ui_click")

	_repair_cost = repair_cost
	_cache_wall_spawn_position()
	_update_button_text()


func _process(_delta: float) -> void:
	if _wall_ref == null and global_var.wall_1_standing:
		var root: Node = get_parent().get_parent()
		if root:
			_wall_ref = root.get_node_or_null("wall") as StaticBody2D
		if _wall_ref and _wall_spawn_global_position == Vector2.ZERO:
			_wall_spawn_global_position = _wall_ref.global_position
		_update_button_text()


func _unhandled_input(event: InputEvent) -> void:
	# Handle TAB to open/close upgrade map
	if event.is_action_pressed("open_upgrades"):
		if event is InputEventKey and event.echo:
			return
		if death_gui != null and death_gui.visible:
			return
		if _is_pause_visible():
			return
		on_upgrades_pressed()
		get_viewport().set_input_as_handled()
		return

	# Handle ESC for pause menu
	if not event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.echo:
		return
	if death_gui != null and death_gui.visible:
		return
	if upgrade_map != null and upgrade_map.visible and not _is_pause_visible():
		if upgrade_map.has_method("_close_with_animation"):
			upgrade_map._close_with_animation()
		else:
			upgrade_map.visible = false
		get_viewport().set_input_as_handled()
		return
	if options_container.visible:
		_show_pause_menu()
	elif _is_pause_visible():
		_resume_game()
	else:
		_pause_game(false)
	get_viewport().set_input_as_handled()


func _connect_hover_signals() -> void:
	# Connect hover/exit for gameplay buttons with animations
	_connect_button_animation(upgrade_wall_btn)
	_connect_button_animation(buy_arrow_btn)
	_connect_button_animation(repair_btn)
	_connect_button_animation(open_upgrade_map_btn)
	_connect_button_animation(upgrade_tower_btn)
	_connect_button_animation(options_btn)
	_connect_button_animation(home_btn)

	# Also emit the hover signal for gameplay blocking
	if upgrade_wall_btn:
		upgrade_wall_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		upgrade_wall_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if buy_arrow_btn:
		buy_arrow_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		buy_arrow_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if repair_btn:
		repair_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		repair_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if open_upgrade_map_btn:
		open_upgrade_map_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		open_upgrade_map_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if upgrade_tower_btn:
		upgrade_tower_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		upgrade_tower_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if options_btn:
		options_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		options_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if home_btn:
		home_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
		home_btn.mouse_exited.connect(_on_any_button_hover.bind(false))

	# Connect pressed signals for sidebar buttons
	if upgrade_wall_btn and not upgrade_wall_btn.pressed.is_connected(_on_upgrade_wall_pressed):
		upgrade_wall_btn.pressed.connect(_on_upgrade_wall_pressed)
	if buy_arrow_btn and not buy_arrow_btn.pressed.is_connected(_on_buy_arrow_pressed):
		buy_arrow_btn.pressed.connect(_on_buy_arrow_pressed)
	if repair_btn and not repair_btn.pressed.is_connected(_on_repair_pressed):
		repair_btn.pressed.connect(_on_repair_pressed)
	if upgrade_tower_btn and not upgrade_tower_btn.pressed.is_connected(_on_upgrade_tower_pressed):
		upgrade_tower_btn.pressed.connect(_on_upgrade_tower_pressed)
	if debug_spawn_knight_btn and not debug_spawn_knight_btn.pressed.is_connected(_on_debug_spawn_knight_pressed):
		debug_spawn_knight_btn.pressed.connect(_on_debug_spawn_knight_pressed)
	if open_upgrade_map_btn and not open_upgrade_map_btn.pressed.is_connected(_on_upgrades_pressed):
		open_upgrade_map_btn.pressed.connect(_on_upgrades_pressed)
	if options_btn and not options_btn.pressed.is_connected(_on_options_pressed):
		options_btn.pressed.connect(_on_options_pressed)
	if home_btn and not home_btn.pressed.is_connected(_on_home_pressed):
		home_btn.pressed.connect(_on_home_pressed)


func _connect_button_animation(btn: Control) -> void:
	if btn == null:
		return
	if not btn.mouse_entered.is_connected(_on_button_hover_in.bind(btn)):
		btn.mouse_entered.connect(_on_button_hover_in.bind(btn))
	if not btn.mouse_exited.is_connected(_on_button_hover_out.bind(btn)):
		btn.mouse_exited.connect(_on_button_hover_out.bind(btn))
	# Connect button_down/up for press animation
	if btn is Button:
		if not btn.button_down.is_connected(_on_button_press.bind(btn)):
			btn.button_down.connect(_on_button_press.bind(btn))
		if not btn.button_up.is_connected(_on_button_release.bind(btn)):
			btn.button_up.connect(_on_button_release.bind(btn))
	elif btn is TextureButton:
		if not btn.button_down.is_connected(_on_button_press.bind(btn)):
			btn.button_down.connect(_on_button_press.bind(btn))
		if not btn.button_up.is_connected(_on_button_release.bind(btn)):
			btn.button_up.connect(_on_button_release.bind(btn))


func _on_button_hover_in(btn: Control) -> void:
	_animate_button_scale(btn, HOVER_SCALE)


func _on_button_hover_out(btn: Control) -> void:
	_animate_button_scale(btn, 1.0)


func _play_ui_click() -> void:
	if ui_click_sound == null:
		return
	# Randomize pitch between 0.85 and 1.15 for variety
	ui_click_sound.pitch_scale = randf_range(0.85, 1.15)
	ui_click_sound.play()


func _on_button_press(btn: Control) -> void:
	_animate_button_scale(btn, PRESS_SCALE)
	_play_ui_click()


func _on_button_release(btn: Control) -> void:
	if btn.is_hovered():
		_animate_button_scale(btn, HOVER_SCALE)
	else:
		_animate_button_scale(btn, 1.0)


func _animate_button_scale(btn: Control, scale_mult: float) -> void:
	if btn == null:
		return
	var tween_key: String = btn.get_path()
	if _button_tweens.has(tween_key) and _button_tweens[tween_key]:
		_button_tweens[tween_key].kill()

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE * scale_mult, ANIM_DURATION)
	_button_tweens[tween_key] = tween


func _connect_pause_signals() -> void:
	# Connect button animations for pause menu buttons
	_connect_button_animation(resume_button)
	_connect_button_animation(settings_button)
	_connect_button_animation(tutorial_button)
	_connect_button_animation(pause_home_button)
	_connect_button_animation(back_button)
	_connect_button_animation(controls_button)

	# Connect click sound for pause menu buttons
	if resume_button and not resume_button.button_down.is_connected(_play_ui_click):
		resume_button.button_down.connect(_play_ui_click)
	if settings_button and not settings_button.button_down.is_connected(_play_ui_click):
		settings_button.button_down.connect(_play_ui_click)
	if tutorial_button and not tutorial_button.button_down.is_connected(_play_ui_click):
		tutorial_button.button_down.connect(_play_ui_click)
	if pause_home_button and not pause_home_button.button_down.is_connected(_play_ui_click):
		pause_home_button.button_down.connect(_play_ui_click)
	if back_button and not back_button.button_down.is_connected(_play_ui_click):
		back_button.button_down.connect(_play_ui_click)
	if controls_button and not controls_button.button_down.is_connected(_play_ui_click):
		controls_button.button_down.connect(_play_ui_click)

	if not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if not settings_button.pressed.is_connected(_on_options_pressed):
		settings_button.pressed.connect(_on_options_pressed)
	if tutorial_button and not tutorial_button.pressed.is_connected(_on_tutorial_pressed):
		tutorial_button.pressed.connect(_on_tutorial_pressed)
	if not pause_home_button.pressed.is_connected(_on_home_pressed):
		pause_home_button.pressed.connect(_on_home_pressed)
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if not controls_button.pressed.is_connected(_on_controls_pressed):
		controls_button.pressed.connect(_on_controls_pressed)
	if not master_slider.value_changed.is_connected(_on_master_changed):
		master_slider.value_changed.connect(_on_master_changed)
	if not music_slider.value_changed.is_connected(_on_music_changed):
		music_slider.value_changed.connect(_on_music_changed)
	if not sfx_slider.value_changed.is_connected(_on_sfx_changed):
		sfx_slider.value_changed.connect(_on_sfx_changed)

	# Connect input remapping signal
	if input_remapping and input_remapping.has_signal("remapping_closed"):
		if not input_remapping.remapping_closed.is_connected(_on_remapping_closed):
			input_remapping.remapping_closed.connect(_on_remapping_closed)


func _configure_pause_ui() -> void:
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	# Set initial state for animation
	pause_overlay.modulate.a = 0.0
	pause_menu.modulate.a = 0.0
	pause_menu.scale = Vector2(0.9, 0.9)
	_hide_pause_ui()


func _on_any_button_hover(is_hovering: bool) -> void:
	button_hover_changed.emit(is_hovering)


# === Public Methods ===

func on_upgrade_wall_pressed() -> void:
	if not global_var.wall_1_standing:
		_rebuild_wall()
		return
	if global_var.coins >= UPGRADE_COST and _current_wall_level < WALLS.size() - 1:
		_upgrade_wall()


func on_buy_arrow_pressed() -> void:
	if global_var.coins >= 1 and buy_sound != null:
		buy_sound.play()
		global_var.arrows += 1
		global_var.coins -= 1
	elif global_var.coins >= 1:
		global_var.arrows += 1
		global_var.coins -= 1


func on_upgrades_pressed() -> void:
	if _is_pause_visible():
		return
	var canvas_layer: Node = get_parent()
	var map: Control = canvas_layer.get_node_or_null("upgrade_map") if canvas_layer else null
	if map:
		if map.visible:
			# If already visible, trigger close animation
			if map.has_method("_close_with_animation"):
				map._close_with_animation()
			else:
				map.visible = false
		else:
			# If not visible, trigger open animation
			if map.has_method("_open_with_animation"):
				map._open_with_animation()
			else:
				map.visible = true


func on_repair_pressed() -> void:
	if _wall_ref == null or not is_instance_valid(_wall_ref):
		return
	if _wall_ref.current_hp <= 0:
		return
	if _wall_ref.current_hp >= _wall_ref.max_hp:
		return
	if global_var.coins < _repair_cost:
		return

	global_var.coins -= _repair_cost
	_wall_ref.current_hp += 60
	if _wall_ref.current_hp > _wall_ref.max_hp:
		_wall_ref.current_hp = _wall_ref.max_hp

	var build_sound: AudioStreamPlayer2D = _wall_ref.get_node_or_null("build_sound")
	if build_sound:
		build_sound.play()

	if _wall_ref.hit_material:
		var crack_level: float = 1.0 - (float(_wall_ref.current_hp) / float(_wall_ref.max_hp))
		_wall_ref.hit_material.set_shader_parameter("crack_intensity", crack_level * 0.5)


func reset_wall_system() -> void:
	_current_wall_level = 0
	_update_button_text()


# === Scene-connected handlers ===

func _on_upgrades_pressed() -> void:
	on_upgrades_pressed()


func _on_upgrade_wall_pressed() -> void:
	on_upgrade_wall_pressed()


func _on_buy_arrow_pressed() -> void:
	on_buy_arrow_pressed()


func _on_repair_pressed() -> void:
	on_repair_pressed()


func _on_debug_spawn_knight_pressed() -> void:
	# Debug: spawn a knight enemy for testing
	var knight_scene: PackedScene = preload("res://scenes/characters/knight.tscn")
	var root: Node = get_parent().get_parent()
	if root == null:
		return
	var spawner: Node = root.get_node_or_null("Enemy spawner")
	if spawner:
		var knight: CharacterBody2D = knight_scene.instantiate()
		root.add_child(knight)
		knight.position = spawner.position + Vector2(randf_range(-10.0, -60.0), 0.0)
		# Connect death signal
		if knight.has_signal("died"):
			knight.died.connect(spawner._on_enemy_died.bind() if spawner.has_method("_on_enemy_died") else Callable())
		print("Debug: Spawned knight at position", knight.position)

func _on_upgrade_tower_pressed() -> void:
	var root: Node = get_parent().get_parent()
	if root == null:
		return
	# Find the currently visible tower (tower -> tower2 -> tower3 -> etc.)
	for tower_name: String in ["tower", "tower2", "tower3", "tower4", "tower5", "tower6"]:
		var tower: Node = root.get_node_or_null(tower_name)
		if tower and is_instance_valid(tower) and tower.visible:
			if tower.has_method("_on_upgrade_tower_pressed"):
				tower._on_upgrade_tower_pressed()
				return


func _on_options_pressed() -> void:
	_pause_game(true)


func _on_resume_pressed() -> void:
	_resume_game()


func _on_back_pressed() -> void:
	_save_settings()
	_show_pause_menu()


func _on_controls_pressed() -> void:
	if input_remapping != null:
		input_remapping.visible = true
		input_remapping.show_remapping()


func _on_remapping_closed() -> void:
	input_remapping.visible = false
	_show_options_menu()


func _on_home_pressed() -> void:
	_save_settings()
	if get_tree() != null:
		get_tree().paused = false
	# Use the PersistentScene autoload directly - it handles the transition shader
	PersistentScene.go_to_main_menu()


func _on_tutorial_pressed() -> void:
	# Show disclaimer popup instead of tutorial overlay
	if DISCLAIMER_SCENE:
		var disclaimer := DISCLAIMER_SCENE.instantiate()
		# Add to CanvasLayer for proper viewport centering
		var canvas_layer: Node = get_parent()
		if canvas_layer:
			canvas_layer.add_child(disclaimer)
		else:
			add_child(disclaimer)
		# Hide the pause menu while disclaimer is shown
		_hide_pause_ui()
		# Connect to play_pressed signal to resume game
		disclaimer.play_pressed.connect(_on_disclaimer_closed_resume_game)


func _on_disclaimer_closed_resume_game() -> void:
	# Resume the game after disclaimer is closed
	if get_tree() != null:
		get_tree().paused = false



func _on_master_changed(value: float) -> void:
	_apply_bus_volume("Master", value)


func _on_music_changed(value: float) -> void:
	_apply_bus_volume("Music", value)


func _on_sfx_changed(value: float) -> void:
	_apply_bus_volume("SFX", value)


# === Pause / Settings ===

func _pause_game(show_options: bool) -> void:
	if death_gui != null and death_gui.visible:
		return
	if _is_animating_pause:
		return
	if upgrade_map != null:
		upgrade_map.visible = false
	if get_tree() != null:
		get_tree().paused = true

	# Kill any existing tween
	if _pause_tween:
		_pause_tween.kill()

	# Set initial state for animation
	pause_overlay.modulate.a = 0.0
	pause_menu.modulate.a = 0.0
	pause_menu.scale = Vector2(0.9, 0.9)
	pause_overlay.visible = true
	pause_menu.visible = true

	if show_options:
		_show_options_menu_no_animate()
	else:
		_show_pause_menu_no_animate()

	# Play UI click sound
	_play_ui_click()

	# Animate in
	_is_animating_pause = true
	_pause_tween = create_tween()
	_pause_tween.set_parallel(true)
	_pause_tween.set_ease(Tween.EASE_OUT)
	_pause_tween.set_trans(Tween.TRANS_BACK)
	_pause_tween.tween_property(pause_overlay, "modulate:a", 0.6, 0.25)
	_pause_tween.tween_property(pause_menu, "modulate:a", 1.0, 0.25)
	_pause_tween.tween_property(pause_menu, "scale", Vector2.ONE, 0.25)
	_pause_tween.set_parallel(false)
	_pause_tween.tween_callback(func(): _is_animating_pause = false)
	_pause_tween.tween_callback(resume_button.grab_focus)


func _resume_game() -> void:
	_save_settings()
	if _is_animating_pause:
		return

	# Kill any existing tween
	if _pause_tween:
		_pause_tween.kill()

	# Animate out
	_is_animating_pause = true
	_pause_tween = create_tween()
	_pause_tween.set_parallel(true)
	_pause_tween.set_ease(Tween.EASE_IN)
	_pause_tween.set_trans(Tween.TRANS_QUAD)
	_pause_tween.tween_property(pause_overlay, "modulate:a", 0.0, 0.15)
	_pause_tween.tween_property(pause_menu, "modulate:a", 0.0, 0.15)
	_pause_tween.tween_property(pause_menu, "scale", Vector2(0.9, 0.9), 0.15)
	_pause_tween.set_parallel(false)
	_pause_tween.tween_callback(func():
		_is_animating_pause = false
		if get_tree() != null:
			get_tree().paused = false
		_hide_pause_ui()
	)


func _show_pause_menu_no_animate() -> void:
	pause_title.text = "PAUSED"
	pause_buttons.visible = true
	options_container.visible = false


func _show_pause_menu() -> void:
	pause_overlay.visible = true
	pause_menu.visible = true
	pause_title.text = "PAUSED"
	pause_buttons.visible = true
	options_container.visible = false
	resume_button.grab_focus()


func _show_options_menu_no_animate() -> void:
	pause_title.text = "OPTIONS"
	pause_buttons.visible = false
	options_container.visible = true


func _show_options_menu() -> void:
	pause_overlay.visible = true
	pause_menu.visible = true
	pause_title.text = "OPTIONS"
	pause_buttons.visible = false
	options_container.visible = true
	back_button.grab_focus()


func _hide_pause_ui() -> void:
	pause_title.text = "PAUSED"
	pause_buttons.visible = true
	options_container.visible = false
	pause_overlay.visible = false
	pause_menu.visible = false
	# Reset animation state
	pause_overlay.modulate.a = 0.0
	pause_menu.modulate.a = 0.0
	pause_menu.scale = Vector2(0.9, 0.9)


func _is_pause_visible() -> bool:
	return pause_overlay.visible or pause_menu.visible


func _load_settings() -> void:
	var settings_file := ConfigFile.new()
	if settings_file.load(SETTINGS_PATH) == OK:
		master_slider.value = float(settings_file.get_value("audio", "master", 1.0))
		music_slider.value = float(settings_file.get_value("audio", "music", 0.8))
		sfx_slider.value = float(settings_file.get_value("audio", "sfx", 1.0))
	else:
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 1.0
	_apply_all_audio()


func _save_settings() -> void:
	var settings_file := ConfigFile.new()
	settings_file.set_value("audio", "master", master_slider.value)
	settings_file.set_value("audio", "music", music_slider.value)
	settings_file.set_value("audio", "sfx", sfx_slider.value)
	settings_file.save(SETTINGS_PATH)


func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	if linear_value > 0.0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value))
	else:
		AudioServer.set_bus_volume_db(bus_idx, -80.0)


func _apply_all_audio() -> void:
	_apply_bus_volume("Master", master_slider.value)
	_apply_bus_volume("Music", music_slider.value)
	_apply_bus_volume("SFX", sfx_slider.value)


# === Private Methods ===

func _rebuild_wall() -> void:
	if global_var.coins < REBUILD_COST:
		return

	global_var.coins -= REBUILD_COST
	global_var.wall_1_standing = true
	_current_wall_level = 0

	var wall_instance: StaticBody2D = WALL_1.instantiate()
	wall_instance.name = "wall"
	var root: Node = get_parent().get_parent()
	if root:
		root.add_child(wall_instance)
		wall_instance.global_position = _get_wall_spawn_global_position(root)
	_wall_ref = wall_instance

	_wall_ref.tree_exited.connect(_on_wall_destroyed.bind(_wall_ref))
	_play_build_sound()
	_update_button_text()


func _upgrade_wall() -> void:
	global_var.coins -= UPGRADE_COST
	_current_wall_level += 1

	if _wall_ref != null:
		_wall_ref.queue_free()

	var upgraded_wall: PackedScene = WALLS[_current_wall_level]
	var wall_instance: StaticBody2D = upgraded_wall.instantiate()
	wall_instance.name = "wall"
	var root: Node = get_parent().get_parent()
	if root:
		root.add_child(wall_instance)
		wall_instance.global_position = _get_wall_spawn_global_position(root)
	_wall_ref = wall_instance

	_wall_ref.tree_exited.connect(_on_wall_destroyed.bind(_wall_ref))
	_play_build_sound()
	_update_button_text()


func _play_build_sound() -> void:
	if _wall_ref == null:
		return
	var build_sound: AudioStreamPlayer2D = _wall_ref.get_node_or_null("build_sound")
	if build_sound:
		build_sound.play()


func _on_wall_destroyed(destroyed_wall: Node) -> void:
	if destroyed_wall != _wall_ref:
		return
	_wall_ref = null
	global_var.wall_1_standing = false
	_update_button_text()


func _cache_wall_spawn_position() -> void:
	var root: Node = get_parent().get_parent()
	if root == null:
		return
	var wall: StaticBody2D = root.get_node_or_null("wall") as StaticBody2D
	if wall:
		_wall_spawn_global_position = wall.global_position
		_wall_ref = wall
		var wall_destroyed_callback: Callable = _on_wall_destroyed.bind(wall)
		if not wall.tree_exited.is_connected(wall_destroyed_callback):
			wall.tree_exited.connect(wall_destroyed_callback)


func _get_wall_spawn_global_position(root: Node) -> Vector2:
	if _wall_spawn_global_position != Vector2.ZERO:
		return _wall_spawn_global_position
	var root_2d := root as Node2D
	if root_2d:
		return root_2d.to_global(WALL_POS)
	return WALL_POS


func _update_button_text() -> void:
	if not global_var.wall_1_standing:
		if global_var.coins >= REBUILD_COST:
			upgrade_wall_label.text = "REBUILD %d coin" % REBUILD_COST
		else:
			upgrade_wall_label.text = "REBUILD WALL"
	elif _current_wall_level >= WALLS.size() - 1:
		upgrade_wall_label.text = "WALL MAXED OUT"
	elif global_var.coins >= UPGRADE_COST:
		upgrade_wall_label.text = "UPGRADE %d coins" % UPGRADE_COST
	else:
		upgrade_wall_label.text = "UPGRADE Need %d" % UPGRADE_COST
