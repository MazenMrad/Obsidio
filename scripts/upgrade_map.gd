extends Control

# Onready variables for weapon nodes
@onready var axe: TextureRect = $axe
@onready var rock: TextureRect = $rock
@onready var bow: TextureRect = $bow
@onready var knife: TextureRect = $knife
@onready var spear: TextureRect = $spear
@onready var line_2d: Line2D = $Line2D
@onready var hold_progress = $hold_progress

var dragging_node: TextureRect = null
var drag_offset: Vector2 = Vector2.ZERO
var hold_time = 0.0
const HOLD_DURATION = 1.0  # Time needed to hold to purchase

# Upgrade tree structure
var upgrade_paths = {
	"rock": {
		"next_upgrades": ["knife", "spear"],
		"cost": 0,  # Starting weapon
		"requirements": []
	},
	"knife": {
		"next_upgrades": ["axe"],
		"cost": 100,
		"requirements": ["rock"]
	},
	"spear": {
		"next_upgrades": ["axe"],
		"cost": 150,
		"requirements": ["rock"]
	},
	"axe": {
		"next_upgrades": ["bow"],
		"cost": 300,
		"requirements": ["knife", "spear"]
	},
	"bow": {
		"next_upgrades": [],
		"cost": 500,
		"requirements": ["axe"]
	}
}

# Track unlocked weapons
var unlocked_weapons = ["rock"]  # Start with rock

func _ready():
	# Connect signals for all weapon nodes
	var weapon_nodes = [axe, rock, bow, knife, spear]
	for node in weapon_nodes:
		node.gui_input.connect(_on_weapon_input.bind(node))
		update_weapon_appearance(node)
		node.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_weapon_input(event: InputEvent, weapon: TextureRect):
	var weapon_name = weapon.name.to_lower()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if weapon_name in unlocked_weapons:
					# Start dragging if weapon is already unlocked
					dragging_node = weapon
					drag_offset = weapon.global_position - get_global_mouse_position()
				else:
					# Start holding to purchase
					if can_purchase(weapon_name):
						hold_time = 0.0
						dragging_node = weapon
						hold_progress.show()
						hold_progress.position = weapon.global_position + Vector2(0, -20)
			else:
				# Released mouse button
				dragging_node = null
				hold_time = 0.0
				hold_progress.hide()
				
	elif event is InputEventMouseMotion and dragging_node == weapon and weapon_name in unlocked_weapons:
		# Only allow dragging if weapon is unlocked
		weapon.global_position = get_global_mouse_position() + drag_offset

func can_purchase(weapon_name: String) -> bool:
	if weapon_name in unlocked_weapons:
		return false
		
	var weapon_data = upgrade_paths[weapon_name]
	
	# Check if requirements are met
	for req in weapon_data["requirements"]:
		if not req in unlocked_weapons:
			return false
			
	# Check if player has enough coins
	return global_var.coins >= weapon_data["cost"]

func attempt_upgrade(weapon_name: String) -> void:
	if not can_purchase(weapon_name):
		return
		
	var weapon_data = upgrade_paths[weapon_name]
	
	# Deduct coins and unlock
	global_var.coins -= weapon_data["cost"]
	unlocked_weapons.append(weapon_name)
	update_all_weapons()
	$purchase_sound.play()  # Add a purchase sound if you have one
func update_all_weapons() -> void:
	for weapon in [axe, rock, bow, knife, spear]:
		update_weapon_appearance(weapon)
		
func update_weapon_appearance(weapon: TextureRect) -> void:
	var weapon_name = weapon.name.to_lower()
	if weapon_name in unlocked_weapons:
		weapon.modulate = Color.WHITE
	else:
		# Check if this weapon can be upgraded to (all requirements met)
		var can_upgrade = true
		for req in upgrade_paths[weapon_name]["requirements"]:
			if not req in unlocked_weapons:
				can_upgrade = false
				break
		weapon.modulate = Color(1, 1, 1, 1 if can_upgrade else 0.5)

func _process(delta):
	# Handle hold-to-purchase
	if dragging_node != null and not dragging_node.name.to_lower() in unlocked_weapons:
		hold_time += delta
		hold_progress.value = (hold_time / HOLD_DURATION) * 100
		
		if hold_time >= HOLD_DURATION:
			attempt_upgrade(dragging_node.name.to_lower())
			dragging_node = null
			hold_time = 0.0
			hold_progress.hide()
	
	# Update lines to show upgrade paths
	var points = PackedVector2Array()
	
	# Draw lines based on upgrade paths
	for weapon_name in upgrade_paths:
		var from_node = get_node(weapon_name.capitalize())
		var from_pos = from_node.global_position + from_node.size / 2
		
		# Draw lines to each possible upgrade
		for next_upgrade in upgrade_paths[weapon_name]["next_upgrades"]:
			var to_node = get_node(next_upgrade.capitalize())
			var to_pos = to_node.global_position + to_node.size / 2
			
			# Change line color based on unlock status
			var is_path_available = weapon_name in unlocked_weapons
			line_2d.default_color = Color(1, 1, 0, 1) if is_path_available else Color(0.5, 0.5, 0.5, 0.5)
			
			# Add points for this connection
			points.append(from_pos)
			points.append(to_pos)
			points.append(Vector2.ZERO)  # Gap between lines
	
	line_2d.points = points
