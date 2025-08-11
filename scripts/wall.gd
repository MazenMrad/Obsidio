# wall.gd
extends StaticBody2D

@export var max_hp: int = 100
@export var damage_per_second: int = 20
var enemy_touching=false
var current_hp: int = 100
var enemy_nearby: bool = false
var damage_timer: float = 0

func _ready():
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
		destroy_wall()
	else:
		current_hp -= damage
		print("Wall HP: ", current_hp)

func destroy_wall():
	queue_free() 

func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("enemies"):
		enemy_touching = true
		damage_timer = 0
		take_damage(damage_per_second)
	pass # Replace with function body.


func _on_wallarea_area_entered(area: Area2D) -> void:
	if area.name=="enemy1":
		enemy_nearby=true
		take_damage(damage_per_second)
	pass # Replace with function body.


func _on_wallarea_area_exited(area: Area2D) -> void:
	if area.name=="enemy1":
		enemy_nearby=false
	pass # Replace with function body.
