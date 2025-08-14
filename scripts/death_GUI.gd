extends Control

############RESTART SCENE BUTTON ##############
func _on_restart_pressed() -> void:
	print("restarting")
	global_var.reset()
	get_tree().reload_current_scene()
	pass # Replace with function body.
############MAIN MENU ##############
