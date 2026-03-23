# AGENTS.md — OBSIDIO (Godot 4.6 2D Tower Defense)

## Project Overview

**OBSIDIO** is a 2D tower defense game built with Godot 4.6 and GDScript. Players defend against waves of enemies using projectile weapons (bow, rock) with drag-to-aim mechanics, upgrading walls and a defensive tower.

## Build & Run Commands

### Running the Game

- **Editor:** Open the project in Godot 4.6 (`project.godot`), press F5 to run.
- **CLI headless (server):** `godot --headless --path . --script run_server.gd` (create `run_server.gd` if needed).
- **Export (Web):** `godot --headless --export-release "Web" D:/Obsidio_game/index.html`
  - Requires `Godot_v4.6-stable_export_templates.tpz` installed in Godot templates directory.

### Godot MCP (for AI agents)

This project includes a Godot MCP server in `godot-mcp/`. See `godot-mcp/README.md` for setup. MCP enables agents to:
- Read scene files, execute code, list nodes, get project info
- **Important:** MCP cannot modify `.tscn` or `.gd` files directly — agents must use tools to edit files on disk.

### No Formal Test Suite

There are no GDScript unit tests or integration tests. Verify changes by:
1. Opening the project in Godot Editor
2. Running the scene (`F5`)
3. Checking the Output panel for `push_error` / `push_warning` messages

---

## Code Style Guidelines

### General

- **Engine:** Godot 4.6, GDScript (`.gd`), Godot scene format (`.tscn`)
- **Encoding:** UTF-8 (per `.editorconfig`)
- **Formatting:** Use Godot's built-in formatter (`Shift+Alt+F` in editor) or match surrounding code indentation.
- **Tabs vs Spaces:** Match existing files — the codebase mixes both; be consistent within a file.

### Imports & Preloads

```gdscript
# Scene preloads at class level (cached at load time)
@export var enemy_scene: PackedScene  # Preferred for exported scenes
const WALL_1 = preload("res://assets/map/props/walls/wall1.tscn")  # For hardcoded scenes

# In functions, instantiate with .instantiate()
var e = enemy_scene.instantiate()
```

### Typing

- **Always use static typing** for function parameters, return types, and variables where possible.
- Use Godot 4 `@export` for Inspector-exposed fields.
- Use `@onready` for node references when the node path is stable.

```gdscript
@export var speed: float = 200.0
@export var damage: int = 20
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

func take_damage(amount: int) -> void:
    var actual := mini(amount, current_hp)
```

### Naming Conventions

| Element          | Convention           | Example                        |
|------------------|----------------------|--------------------------------|
| Scripts/files    | snake_case.gd       | `enemy_1.gd`, `global_var.gd`  |
| Class names      | PascalCase           | `class_name Player`             |
| Variables        | snake_case           | `current_hp`, `enemy_nearby`   |
| Constants        | UPPER_SNAKE_CASE     | `MAX_SPEED`, `COST_UPGRADE`     |
| Enums            | PascalCase values    | `enum Weapon { ROCK, BOW }`    |
| Signals          | snake_case           | `signal died`, `signal health_changed` |
| Node groups      | lowercase plural     | `"enemies"`, `"enemy1"`        |
| Export vars      | snake_case           | `@export var move_speed: float` |
| Private vars     | `_leading_underscore`| `var _health: int`             |

### Signals & Communication

- Use signals for decoupled communication between nodes.
- Connect signals in `_ready()` or at instantiation time.
- Prefer `emit_signal()` shorthand (`died.emit()`) over `emit_signal("died")`.

```gdscript
# In enemy_1.gd
signal died

func die():
    died.emit()
    queue_free()

# In main.gd — connect at spawn time
ene.connect("died", Callable(self, "_on_enemy_died"))
```

### Node Access

- Use `@onready` for stable node paths.
- Use `get_node_or_null()` for optional nodes to avoid crashes.
- Check `has_node()` before `get_node()` for optional dependencies.
- Avoid `get_node()` inside `_process()` or `_physics_process()` loops.

```gdscript
# Good
@onready var tower: StaticBody2D = $tower

# Good — optional node
@onready var upgrade_btn: Button = $Control/upgrade_tower
if upgrade_btn and not upgrade_btn.pressed.is_connected(_on_upgrade_tower_pressed):
    upgrade_btn.pressed.connect(_on_upgrade_tower_pressed)

# Avoid in hot paths
# var x = get_node("Foo")  # Cache with @onready instead
```

### Physics & Movement

- Use `move_and_slide()` for CharacterBody2D entities.
- Use `move_and_collide()` for RigidBody2D when you need collision info.
- Call `move_and_slide()` once per `_physics_process()`.
- Use `_physics_process(delta)` for physics, `_process(delta)` for non-physics logic.

### Resource Management

- Use `PackedScene.instantiate()` for spawning scenes.
- Call `queue_free()` to safely remove nodes (deferred deletion).
- Preload textures/scenes at class level for frequently used assets.

### Error Handling

- Use `push_error("message")` for critical failures.
- Use `push_warning("message")` for recoverable issues.
- Use `printerr()` for simple debug output.
- Use `@warning_ignore` sparingly and only for intentional suppressions.

```gdscript
if not states.has(state_name):
    push_error("State '%s' not found" % state_name)
    return

@warning_ignore("unused_parameter")
func _physics_process(delta):
    pass
```

### Scene Organization

- **Scenes:** `res://scenes/` — game scenes (`.tscn` files)
- **Scripts:** `res://scripts/` — loose scripts (one per associated scene)
- **Assets:** `res://assets/` — art, audio, fonts
- **Shaders:** `res://scenes/shaders/` — GLSL shaders

### Common Patterns in This Project

```gdscript
# Wave system pattern (main.gd)
var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var is_wave_active: bool = false
var break_time_remaining: float = 10.0
var is_break_time: bool = false

# Drag-to-aim pattern (player.gd)
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var max_drag_distance: float = 120.0

# Tower upgrade pattern (tower.gd)
@export var upgrade_level: int = 1
@export var max_upgrade_level: int = 4
var upgrade_costs: Array[int] = [0, 50, 120, 200]
var tower_stats: Array[Dictionary] = [...]

# Autoload usage
global_var.coins += 1
global_var.arrows -= 1
global_var.state = global_var.Weapon.BOW
```

### Adding New Enemy Types

1. Create a new scene in `scenes/characters/` (e.g., `enemy2.tscn`)
2. Create the script inheriting from `CharacterBody2D`
3. Add `signal died` and `add_to_group("enemies")` in `_ready()`
4. Connect `died` signal in `main.gd`'s `spawn_wave_enemies()`
5. Add to `enemy_spawn_audio` spawn logic and group checks

### Adding New Weapons

1. Create projectile scene in `scenes/` (e.g., `knife.tscn`)
2. Script must have `shoot(dir, speed_multiplier)` method
3. Add weapon enum to `global_var.Weapon` if needed
4. Add to upgrade tree in `upgrade_map.gd` (`upgrade_paths` dictionary)
5. Add projectile instantiation in `player.gd` `shoot_*` methods

### Project Conventions

- **Groups:** Enemies add themselves to `"enemies"` group. Enemy type-specific logic uses `"enemy1"`, `"enemy2"` groups.
- **Death flow:** Tower destroyed → player freed → death GUI shown. Wall destroyed → `global_var.wall_1_standing = false`.
- **Coins:** Spawned at enemy death, auto-collected on mouse hover. Waves tracked via `global_var.waves`.
- **Sound nodes:** Placed as children of the entities (e.g., `$wall_hit.play()`).

### Performance Notes

- Cache `@onready` node references — never call `get_node()` in `_process()`.
- Use object pooling for frequently spawned projectiles/coins (not yet implemented — see godot-gdscript-patterns skill).
- Disable processing on nodes that are off-screen or pooled.

---

Last reviewed: 2026-03-19
