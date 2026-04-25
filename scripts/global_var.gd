extends Node

var coins: int = 8
var wall_1_standing: bool = true
var arrows: int = 15

enum Weapon { ROCK, BOW, KNIFE, AXE, SPEAR }
var state = Weapon.ROCK

var waves: int = 0
var enemy_killed: int = 0
var coins_earned: int = 0

# Track unlocked weapons by name (strings for consistency with upgrade_map)
var unlocked_weapons: Array[String] = ["rock", "bow"] # Start with rock and bow

## ——— Persistent data (survives between runs) ———

## Bonus arrows granted at the start of each run (purchased between runs)
var persistent_bonus_arrows: int = 0
## Best wave survived (persistent high score)
var best_wave: int = 0
## Best enemies killed (persistent high score)
var best_kills: int = 0
## Best coins earned in a single run (persistent high score)
var best_coins: int = 0

const SAVE_PATH: String = "user://obsidio_save.cfg"

func _ready() -> void:
	_load_persistent_data()

func reset() -> void:
	state = Weapon.ROCK
	coins = 8
	arrows = 15 + persistent_bonus_arrows
	wall_1_standing = true
	unlocked_weapons = ["rock", "bow"]
	waves = 0
	enemy_killed = 0
	coins_earned = 0

func set_wall_destroyed():
	wall_1_standing = false

## Call at end of run (death or victory) to update high scores and save
func save_run_stats() -> void:
	if waves > best_wave:
		best_wave = waves
	if enemy_killed > best_kills:
		best_kills = enemy_killed
	if coins_earned > best_coins:
		best_coins = coins_earned
	_save_persistent_data()

## Purchase persistent bonus arrows (costs coins at the end-of-run screen)
func purchase_bonus_arrows(cost: int) -> bool:
	if coins < cost:
		return false
	coins -= cost
	persistent_bonus_arrows += 3
	_save_persistent_data()
	return true

func _save_persistent_data() -> void:
	var config := ConfigFile.new()
	config.set_value("persistent", "bonus_arrows", persistent_bonus_arrows)
	config.set_value("highscores", "best_wave", best_wave)
	config.set_value("highscores", "best_kills", best_kills)
	config.set_value("highscores", "best_coins", best_coins)
	var err: int = config.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save persistent data: error %d" % err)

func _load_persistent_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return # No save file yet — use defaults
	persistent_bonus_arrows = config.get_value("persistent", "bonus_arrows", 0)
	best_wave = config.get_value("highscores", "best_wave", 0)
	best_kills = config.get_value("highscores", "best_kills", 0)
	best_coins = config.get_value("highscores", "best_coins", 0)
