extends StaticBody2D

@export var max_hp: int = 200 #this is the max hp of the tower
@export var damage_per_second: int = 15
var enemy_touching=false
var current_hp: int = 100 #this is just a temp var to swap between max_hp and current_hp
var enemy_nearby: bool = false
var damage_timer: float = 0
var number_enemies: int =0
func _ready():
	var death_gui=$"../death"
	death_gui.hide()
	current_hp = max_hp

func _process(delta):
	if enemy_nearby:
		damage_timer += delta
		# Deal damage every second
		if damage_timer >= 1.0:
			take_damage(damage_per_second)
			damage_timer = 0
	

func take_damage(damage: int):
	if current_hp<=0:
		destroy_tower()
		$"../death/lost".play()
	else:
		current_hp -= damage+number_enemies
		print("Wall HP: ", current_hp)

func destroy_tower():
	print("tower destroyed!")
	queue_free() 
	$"../player".queue_free()
	$"../death".show()
	$"../Flag".queue_free()
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name=="enemy1":
		number_enemies+=1
		enemy_nearby=true
		take_damage(damage_per_second)
		print("lmmao")
	pass # Replace with function body.

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name=="enemy1":
		enemy_nearby=false
	pass # Replace with function body.

################DISSOLVE###############
var rng = RandomNumberGenerator.new()
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		burnCard(rng.randf_range(0.0, 360.0))

func burnCard(direction):
	if material and material is ShaderMaterial:
		var tween = create_tween()
		# set burning direction in degrees
		material.set_shader_parameter("direction", 180.0)
		# use tweens to animate the progress value
		tween.tween_method(update_progress, -1.5, 1.5, 1.0)
	 
func update_progress(value: float):
	if material:
		material.set_shader_parameter("progress", value)
