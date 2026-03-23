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

const WALL_POS: Vector2 = Vector2(367.0, 329.0)
const REBUILD_COST: int = 1
const UPGRADE_COST: int = 5

# === Exports ===
@export var repair_cost: int = 0

# === Onready ===
# Buttons are under Control/actions/ subfolder for clean layout
@onready var actions: Control = $actions
@onready var upgrade_wall_btn: TextureButton = $actions/upgrade_wall
@onready var buy_arrow_btn: TextureButton = $actions/buy_arrow
@onready var repair_btn: TextureButton = $actions/repair
@onready var upgrade_wall_label: Label = $actions/upgrade_wall/label
@onready var buy_arrow_label: Label = $actions/buy_arrow/label
@onready var repair_label: Label = $actions/repair/label
@onready var open_upgrade_map_btn: Button = $actions/open_upgrade_map
@onready var upgrade_tower_btn: Button = $actions/upgrade_tower
@onready var options_btn: TextureButton = $options_button
@onready var home_btn: TextureButton = $home_buttons

# buy_sound and equip are siblings under Node/Audio, not children of Control.
# Use explicit path in _ready() to avoid @onready issues with siblings.
var buy_sound: AudioStreamPlayer2D

# === State ===
var _wall_ref: StaticBody2D = null
var _current_wall_level: int = 0
var _repair_cost: int = 0
var _wall_spawn_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# buy_sound is a sibling under Node/Audio — resolve via parent's parent.
	var audio_node: Node = get_parent().get_parent()
	if audio_node != null:
		buy_sound = audio_node.get_node_or_null("Audio/buy_sound")
		if buy_sound == null:
			push_warning("[buttons] buy_sound not found at ../Audio/buy_sound")


	_repair_cost = repair_cost
	_cache_wall_spawn_position()
	_update_button_text()
	_connect_hover_signals()


func _connect_hover_signals() -> void:
	upgrade_wall_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	upgrade_wall_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	buy_arrow_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	buy_arrow_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	repair_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	repair_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	open_upgrade_map_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	open_upgrade_map_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	upgrade_tower_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	upgrade_tower_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	options_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	options_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	home_btn.mouse_entered.connect(_on_any_button_hover.bind(true))
	home_btn.mouse_exited.connect(_on_any_button_hover.bind(false))
	if not open_upgrade_map_btn.pressed.is_connected(_on_upgrades_pressed):
		open_upgrade_map_btn.pressed.connect(_on_upgrades_pressed)
	home_btn.pressed.connect(_on_home_pressed)


func _on_any_button_hover(is_hovering: bool) -> void:
	button_hover_changed.emit(is_hovering)


func _process(_delta: float) -> void:
	if _wall_ref == null and global_var.wall_1_standing:
		var root: Node = get_parent().get_parent()
		if root:
			_wall_ref = root.get_node_or_null("wall") as StaticBody2D
			if _wall_ref and _wall_spawn_global_position == Vector2.ZERO:
				_wall_spawn_global_position = _wall_ref.global_position
	_update_button_text()


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
	var canvas_layer: Node = get_parent()
	var upgrade_map: Node = canvas_layer.get_node_or_null("upgrade_map") if canvas_layer else null
	if upgrade_map:
		upgrade_map.visible = not upgrade_map.visible
		if upgrade_map.visible and upgrade_map.has_method("_update_coins"):
			upgrade_map._update_coins()


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


func _on_upgrade_tower_pressed() -> void:
	var root: Node = get_parent().get_parent()
	var tower: Node = root.get_node_or_null("tower") if root else null
	if tower and tower.has_method("_on_upgrade_tower_pressed"):
		tower._on_upgrade_tower_pressed()


func _on_home_pressed() -> void:
	if Engine.has_singleton("PersistentScene"):
		var persistent := Engine.get_singleton("PersistentScene")
		if persistent and persistent.has_method("go_to_main_menu"):
			persistent.go_to_main_menu()
			return
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


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
