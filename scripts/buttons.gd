extends Control
var i=0
@onready var upgrade_wall: Button = $upgrade_wall
@onready var wall_1: StaticBody2D = $"../wall1"
var wall_pos=Vector2(-98.39,83.005)
const WALL_1 = preload("res://assets/map/props/walls/wall1.tscn")
const WALL_2 = preload("res://assets/map/props/walls/wall2.tscn")
const WALL_3 = preload("res://assets/map/props/walls/wall3.tscn")
const WALL_4 = preload("res://assets/map/props/walls/wall4.tscn")
const WALL_5 = preload("res://assets/map/props/walls/wall5.tscn")
var walls=[WALL_1,WALL_2,WALL_3,WALL_4,WALL_5]
var current_wall_level = 0

func _ready() -> void:
	$upgrade_wall.text="UPGRADE"
	update_button_text()

func _process(delta):
	# Check if wall1 is null (destroyed) and update the reference
	if wall_1 == null:
		wall_1 = get_parent().get_node_or_null("wall1")
		if wall_1 == null and not global_var.wall_1_standing:
			update_button_text()

func reset_wall_system():
	current_wall_level = 0
	update_button_text()

func update_button_text():
	if not global_var.wall_1_standing:
		$upgrade_wall.text = "REBUILD WALL (1 coin)"
	elif current_wall_level >= walls.size() - 1:
		$upgrade_wall.text = "WALL MAXED OUT"
	elif global_var.coins >= 5:
		$upgrade_wall.text = "UPGRADE WALL (5 coins)"
	else:
		$upgrade_wall.text = "UPGRADE (Need 5 coins)"

func _on_upgrade_wall_pressed() -> void:
	# Rebuild wall if it's destroyed
	if not global_var.wall_1_standing and global_var.coins >= 1:
		rebuild_wall()
		return
	
	# Upgrade wall if it's standing and player has enough coins
	if global_var.wall_1_standing and global_var.coins >= 5 and current_wall_level < walls.size() - 1:
		upgrade_wall_level()
		return

func rebuild_wall():
	global_var.coins -= 1
	global_var.wall_1_standing = true
	current_wall_level = 0
	
	var wall_instance = WALL_1.instantiate()
	wall_instance.name = "wall1"
	wall_instance.position = wall_pos
	get_parent().add_child(wall_instance)
	wall_1 = wall_instance
	
	print("Wall rebuilt!")
	update_button_text()

func upgrade_wall_level():
	global_var.coins -= 5
	current_wall_level += 1
	
	# Remove current wall
	if wall_1 != null:
		wall_1.queue_free()
	
	# Create upgraded wall
	var upgraded_wall_scene = walls[current_wall_level]
	var wall_instance = upgraded_wall_scene.instantiate()
	wall_instance.name = "wall1"
	wall_instance.position = wall_pos
	get_parent().add_child(wall_instance)
	wall_1 = wall_instance
	
	print("Wall upgraded to level ", current_wall_level + 1)
	update_button_text()
	
