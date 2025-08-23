extends Control
@onready var player: CharacterBody2D = $"../player"
@onready var tower: StaticBody2D = $"../tower"
@onready var flag: Sprite2D = $"../Flag"

func _ready() -> void:
	$wave.text="waves survived "+ str(global_var.waves) 
	$enemy.text="enemies killed "+ str(global_var.enemy_killed)
	
############RESTART SCENE BUTTON ##############
func _on_restart_pressed() -> void:
	print("restarting")
	global_var.reset()
	get_tree().reload_current_scene()
	pass # Replace with function body.
	

############MAIN MENU ##############
