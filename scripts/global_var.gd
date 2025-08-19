extends Node
var coins=5
var wall_1_standing=true
var arrows=10
enum Weapon { ROCK, BOW, SPEAR}
var state=Weapon.BOW

func reset():
	state=Weapon.BOW
	coins=5
	arrows=10
	wall_1_standing=true

func set_wall_destroyed():
	wall_1_standing = false

	
