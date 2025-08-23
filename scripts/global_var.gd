extends Node
var coins = 30
var wall_1_standing = true
var arrows = 10
enum Weapon { ROCK, BOW }
var state = Weapon.ROCK  # Start with rock
var waves=0
var enemy_killed=0
# Weapon costs and unlocks
var weapon_costs = {
	Weapon.ROCK: 0,    # Starting weapon
	Weapon.BOW: 0
}

var unlocked_weapons = [Weapon.ROCK, Weapon.BOW]  # Start with rock and bow

func reset():
	state = Weapon.ROCK
	coins = 5
	arrows = 10
	wall_1_standing = true
	unlocked_weapons = [Weapon.ROCK, Weapon.BOW]
	waves = 0  # Reset total waves survived
	enemy_killed = 0  # Reset total enemies killed

########################THIS WAS AN ATTEMPT TO MAKE UNLOCKABLE WEAPONS BUT I OVERSCOPED THE GAMES PURPOSE THIS IS DEPRECIATED FOR NOW#################
func can_purchase_weapon(weapon_type: Weapon) -> bool:
	if weapon_type in unlocked_weapons:
		return false
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
