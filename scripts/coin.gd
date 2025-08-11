extends StaticBody2D

func _on_mouse_entered() -> void:
	print("coin collected")
	global_var.coins+=1
	queue_free()
	pass # Replace with function body.
