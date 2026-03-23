extends SceneTree
func _init():
	var scene: Resource = ResourceLoader.load("res://scenes/main.tscn")
	var ok: bool = scene != null
	print("Result: ", "OK" if ok else "FAILED")
	quit(0 if ok else 1)
