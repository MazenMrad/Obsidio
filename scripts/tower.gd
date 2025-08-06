extends StaticBody2D

@export var max_hp: int = 100
@export var damage_per_second: int = 20
var enemy_touching=false
var current_hp: int = 100
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
	else:
		current_hp -= damage+number_enemies
		print("Wall HP: ", current_hp)

func destroy_tower():
	print("tower destroyed!")
	queue_free() 
	$"../death".show()

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
