extends Node

var coins: int = 30
var wall_1_standing: bool = true
var arrows: int = 10

enum Weapon { ROCK, BOW, KNIFE, AXE, SPEAR }
var state = Weapon.ROCK

var waves: int = 0
var enemy_killed: int = 0

# Track unlocked weapons by name (strings for consistency with upgrade_map)
var unlocked_weapons: Array[String] = ["rock", "bow"]  # Start with rock and bow

func reset():
	state = Weapon.ROCK
	coins = 5
	arrows = 10
	wall_1_standing = true
	unlocked_weapons = ["rock", "bow"]
	waves = 0
	enemy_killed = 0

func set_wall_destroyed():
	wall_1_standing = false
