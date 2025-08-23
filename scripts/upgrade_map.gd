extends Control

# Onready variables for weapon nodes
@onready var axe: TextureRect = get_node_or_null("axe")
@onready var rock: TextureRect = get_node_or_null("rock")
@onready var bow: TextureRect = get_node_or_null("bow")
@onready var knife: TextureRect = get_node_or_null("knife")
@onready var spear: TextureRect = get_node_or_null("spear")
@onready var coin_label: Label = get_node_or_null("coin_label")

var dragging_node: TextureRect = null
var drag_offset: Vector2 = Vector2.ZERO
var hold_time = 0.0
const HOLD_DURATION = 1.0  # Time needed to hold to purchase

var purchase_tween: Tween
var weapon_nodes_map: Dictionary = {}

# Upgrade tree structure
var upgrade_paths = {
	"rock": {
		"next_upgrades": ["bow"],
		"cost": 0,  # Starting weapon
	},
	"knife": {
		"next_upgrades": [],
		"cost": 15,
	},
	"spear": {
		"next_upgrades": [],
		"cost": 20,
	},
	"axe": {
		"next_upgrades": [],
		"cost": 10,
	},
	"bow": {
		"next_upgrades": ["spear","knife","axe"],
		"cost": 0,
	}
}

# Track unlocked weapons
var unlocked_weapons = ["rock", "bow"]  # Start with rock and bow

func _ready():
	# Create a map for easy node access and validate
	var potential_nodes = {
		"axe": axe,
		"rock": rock,
		"bow": bow,
		"knife": knife,
		"spear": spear
	}

	for key in potential_nodes:
		var node = potential_nodes[key]
		if is_instance_valid(node):
			weapon_nodes_map[key] = node
		else:
			printerr("Weapon node not found in upgrade_map scene: %s" % key)

	# Connect signals for all valid weapon nodes
	for node in weapon_nodes_map.values():
		node.gui_input.connect(_on_weapon_input.bind(node))
		update_weapon_appearance(node)
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if weapon_nodes_map.size() != 5:
		printerr("One or more weapon nodes are missing. UI will be incomplete.")

func _draw():
	# Draw lines as a series of circles
	for weapon_name in upgrade_paths:
		if not weapon_nodes_map.has(weapon_name):
			continue

		var from_node = weapon_nodes_map[weapon_name]
		var from_pos = from_node.position + from_node.size / 2

		for next_upgrade in upgrade_paths[weapon_name]["next_upgrades"]:
			if not weapon_nodes_map.has(next_upgrade):
				continue
				
			var to_node = weapon_nodes_map[next_upgrade]
			var to_pos = to_node.position + to_node.size / 2
			
			var is_path_available = weapon_name in unlocked_weapons
			var line_color = Color.GRAY 
			draw_dotted_line(from_pos, to_pos, line_color)


func draw_dotted_line(from: Vector2, to: Vector2, color: Color):
	var distance = from.distance_to(to)
	var direction = (to - from).normalized()
	var segment_length = 10
	var gap_length = 5
	var current_pos = from
	
	while from.distance_to(current_pos) < distance:
		var end_pos = current_pos + direction * segment_length
		if from.distance_to(end_pos) > distance:
			end_pos = to
		
		draw_circle(current_pos, 3.0, color)
		current_pos = end_pos + direction * gap_length


func _on_weapon_input(event: InputEvent, weapon: TextureRect):
	var weapon_name = weapon.name.to_lower()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_node = weapon
			drag_offset = weapon.get_global_mouse_position() - weapon.global_position
			
			if not weapon_name in unlocked_weapons and can_purchase(weapon_name):
				hold_time = 0.0
				if purchase_tween:
					purchase_tween.kill()
				purchase_tween = create_tween()
				purchase_tween.tween_property(weapon, "modulate", Color.GHOST_WHITE, HOLD_DURATION).from(Color.GRAY)
		else:
			if purchase_tween:
				purchase_tween.kill()
				purchase_tween = null
				update_weapon_appearance(weapon)
			
			dragging_node = null
			hold_time = 0.0
				
	elif event is InputEventMouseMotion and dragging_node == weapon:
		weapon.global_position = get_global_mouse_position() - drag_offset
		queue_redraw()

func can_purchase(weapon_name: String) -> bool:
	if weapon_name in unlocked_weapons:
		return false
		
	var weapon_data = upgrade_paths[weapon_name]
	
	return global_var.coins >= weapon_data["cost"]

func attempt_upgrade(weapon_name: String):
	if not can_purchase(weapon_name):
		return
		
	var weapon_data = upgrade_paths[weapon_name]
	
	global_var.coins -= weapon_data["cost"]
	unlocked_weapons.append(weapon_name)
	update_all_weapons()
	queue_redraw()
	$purchase_sound.play()

func update_all_weapons():
	for weapon in weapon_nodes_map.values():
		update_weapon_appearance(weapon)
		
func update_weapon_appearance(weapon: TextureRect):
	var weapon_name = weapon.name.to_lower()
	var grey_layer = weapon.get_node("grey_layer")
	var price_label = weapon.get_node("price_label")
	var highlight = weapon.get_node("highlight")
	
	if weapon_name in unlocked_weapons:
		weapon.modulate = Color.WHITE
		grey_layer.visible = false
		price_label.visible = false
		highlight.visible = false
	else:
		var can_upgrade = true
		for req in upgrade_paths[weapon_name]:
			if not req in unlocked_weapons:
				can_upgrade = false
				break
		
		var weapon_data = upgrade_paths[weapon_name]
		if weapon_data["cost"] == 0:
			price_label.text = "Free"
		else:
			price_label.text = "Price: %d" % weapon_data["cost"]
		price_label.visible = true
		
		if can_purchase(weapon_name):
			weapon.modulate = Color.WHITE
			grey_layer.visible = false
			highlight.visible = true
		else:
			weapon.modulate = Color.WHITE
			grey_layer.visible = true
			highlight.visible = false

func _process(delta):
	# Update weapon colors based on purchase status
	for weapon_name in weapon_nodes_map:
		var weapon_node = weapon_nodes_map[weapon_name]
		update_weapon_appearance(weapon_node)
	if is_instance_valid(coin_label):
		coin_label.text = "Coins: %d" % global_var.coins
	if dragging_node != null and not dragging_node.name.to_lower() in unlocked_weapons and can_purchase(dragging_node.name.to_lower()):
		hold_time += delta
		
		if hold_time >= HOLD_DURATION:
			attempt_upgrade(dragging_node.name.to_lower())
			if purchase_tween:
				purchase_tween.kill()
				purchase_tween = null
			dragging_node = null
			hold_time = 0.0
