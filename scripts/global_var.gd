extends Node
var coins = 5
var wall_1_standing = true
var arrows = 10
enum Weapon { ROCK, BOW, SPEAR, KNIFE, AXE }
var state = Weapon.ROCK  # Start with rock

# Weapon costs and unlocks
var weapon_costs = {
	Weapon.ROCK: 0,    # Starting weapon
	Weapon.KNIFE: 10,
	Weapon.SPEAR: 30,
	Weapon.AXE: 20,
	Weapon.BOW: 7
}

var unlocked_weapons = [Weapon.ROCK]  # Start with just the rock

func reset():
	state = Weapon.ROCK
	coins = 5
	arrows = 10
	wall_1_standing = true
	unlocked_weapons = [Weapon.ROCK]

func can_purchase_weapon(weapon_type: Weapon) -> bool:
	# Already unlocked
	if weapon_type in unlocked_weapons:
		return false
	# Can afford it
	return coins >= weapon_costs[weapon_type]

func purchase_weapon(weapon_type: Weapon) -> bool:
	if can_purchase_weapon(weapon_type):
		coins -= weapon_costs[weapon_type]
		unlocked_weapons.append(weapon_type)
		return true
	return false

func is_weapon_unlocked(weapon_type: Weapon) -> bool:
	return weapon_type in unlocked_weapons

func set_wall_destroyed():
	wall_1_standing = false

	
