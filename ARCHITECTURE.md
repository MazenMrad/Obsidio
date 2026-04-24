# OBSIDIO — Architecture Summary

> Generated: 2026-03-20 | Godot 4.6 / GDScript

---

## What Changed & Why

### 1. Signal Architecture — Eliminated Cross-Node Coupling

**Problem:** UI buttons in `Control` connected **directly** to `player` and `wall1` node methods across scene boundaries. If any node was deleted, the game would crash.

```
BEFORE (9 broken connections):
  Control/upgrade_wall → player._on_upgrade_wall_mouse_entered()   ❌
  Control/repair        → wall1._on_repair_pressed()               ❌
  Control/buy_arrow    → player._on_buy_arrow_mouse_entered()     ❌
  ... (6 more)
```

**Solution:** `buttons.gd` owns all button logic and emits typed signals. `main.gd` listens. `player.gd` listens to one hover signal from `buttons.gd`.

```
AFTER (6 clean connections):
  Control/upgrade_wall → buttons._on_upgrade_wall_pressed()     ✅
  Control/repair        → buttons._on_repair_pressed()           ✅
  Control/buy_arrow    → buttons._on_buy_arrow_pressed()         ✅
  Control/upgrade_tower → buttons._on_upgrade_tower_pressed()    ✅
  ... (2 more)
```

**Files changed:**
- `scripts/buttons.gd` — Added 4 typed signals, all gameplay logic
- `scripts/main.gd` — Connects to buttons signals
- `scripts/player.gd` — Listens to `button_hover_changed` instead of each button
- `scenes/main.tscn` — Updated connection table

---

### 2. UI State — Moved Under Control Node

**Problem:** `coin_label`, `arrows`, `spawn_text`, `Coin`, `Arrow` were on the root `Node2D` alongside game entities. Mixing game-state UI with visual sprites violates the **Presentation Layer** rule.

**Solution:** Moved all UI elements under `Control`. Added `layout_mode` to children that were missing it.

```
BEFORE:
  Node2D (root)
  ├── coin_label      ← misplaced
  ├── arrows          ← misplaced
  ├── spawn_text      ← misplaced
  ├── Coin sprite     ← misplaced
  ├── Arrow sprite    ← misplaced
  └── Control         ← buttons only

AFTER:
  Node2D (root)
  ├── Control
  │   ├── coin_label
  │   ├── arrows
  │   ├── spawn_text
  │   ├── Coin sprite
  │   ├── Arrow sprite
  │   ├── upgrade_wall (Button)
  │   ├── repair (Button)
  │   ├── buy_arrow (Button)
  │   ├── upgrade_tower (Button)
  │   └── ...
  └── (game entities)
```

---

### 3. Node Path Resolution — Fixed Sibling Access

**Problem:** `@onready` on `Enemy spawner` used `$Control` which looks for a **child** named `Control`. But `Control` is a **sibling** (both children of root `Node2D`). `$"../Control"` from `@onready` was unreliable.

**Solution:** Replaced all `@onready` sibling paths with explicit `get_parent().get_node()` in `_ready()`, with `null` guards on every node access.

```gdscript
# BEFORE (broken — Control is a sibling, not a child)
@onready var buttons: Control = $Control

# AFTER (safe — resolved via parent root)
var buttons: Control
func _ready() -> void:
    var root: Node2D = get_parent() as Node2D
    buttons = root.get_node_or_null("Control")
    if buttons == null:
        push_error("[Main] buttons not found!")
        return
```

---

### 4. buttons.gd — Complete Rewrite

| Issue | Fix |
|--------|-----|
| Missing type hints | All variables typed: `Button`, `AudioStreamPlayer2D`, `StaticBody2D` |
| Magic numbers | Constants: `REBUILD_COST`, `UPGRADE_COST`, `WALL_POS`, `WALLS[]` |
| Cross-node calls | All gameplay in `buttons.gd`; `player.gd` no longer calls it |
| Button hover | 8 individual connections → 1 signal: `button_hover_changed(bool)` |
| Wall state coupling | `_wall_ref` tracks wall instance; `tree_exited` signal auto-nulls it |
| Duplicate build sound logic | `_play_build_sound()` helper |

---

### 5. Scene Fixes (main.tscn)

| Fix | Change |
|-----|--------|
| `light_mask = 7` on `Enemy spawner` | Removed — this node is not a light |
| `Restart` button text | `"Restart\n"` → `"Restart"` (trailing newline) |
| `target_path` on `SubViewportContainer` | `"../player"` → `"../%Player"` (unique name) |
| `player` node name | `"player"` → `"%Player"` (unique name) |
| `wall1` node name | `"wall1"` → `"%wall1"` (unique name) |
| Duplicate connections | Removed 6 cross-node connections, replaced with `Control`-local |
| Missing `layout_mode` | Added to `buy_sound`, `equip`, `weapon_ui`, `upgrade_tower` |

---

### 6. player.gd — Hover Signal Architecture

**Problem:** `player.gd` connected to each button's `mouse_entered/exited` signals across scenes.

**Solution:** `buttons.gd` emits one `button_hover_changed(bool)` signal. `player.gd` listens once.

```gdscript
# player.gd — now clean
func _connect_to_buttons_signal() -> void:
    var buttons: Control = get_parent().get_node_or_null("Control")
    if buttons and buttons.has_signal("button_hover_changed"):
        buttons.button_hover_changed.connect(_on_button_hover_changed)

func _on_button_hover_changed(is_hovering: bool) -> void:
    _mouse_in_button = is_hovering
```

---

### 7. Embedded GDScript in player.tscn — Escaped Quotes

**Problem:** GDScript embedded as `script/source = "..."` inside a `.tscn` file. All inner `"` must be `\"`. Paths like `$"../Control/weapon_ui"` had raw quotes → parser error.

**Solution:** Escaped all inner quotes: `$"../Control/weapon_ui"` → `\$"../Control/weapon_ui"`.

---

### 8. persistent_foreground_scene.tscn — Format & Parent Fix

**Problem:** Godot 4.4 packed scene parser rejected `TransitionEffect` child — it had no explicit `parent` attribute in `format=3`.

**Fix:** Updated to `format=4`, added explicit `parent="."`:
```
[node name="TransitionEffect" type="ColorRect" parent="."]
```

---

### 9. persistent_scene.gd — Defensive Error Handling

Added `ResourceLoader.exists()` check and null guards so the game doesn't crash if the transition scene fails:
```gdscript
var scene: Node = null
if ResourceLoader.exists("res://scenes/persistent_foreground_scene.tscn"):
    scene = PERSISTENT_SCENE.instantiate()
if scene == null:
    push_error("[PersistentScene] Failed to instantiate — transitions disabled")
    return
```

---

## Architecture Overview (Current)

```
┌─────────────────────────────────────────────────────────┐
│  Layer: Infrastructure (Autoloads)                       │
│  global_var        — game state (coins, arrows, weapons) │
│  PersistentScene   — scene transitions                   │
└───────────────────────┬─────────────────────────────────┘
                        │ (signals)
┌───────────────────────▼─────────────────────────────────┐
│  Layer: Presentation (UI)                               │
│  Control (buttons.gd)                                    │
│  ├── Emits: upgrade_wall_pressed, buy_arrow_pressed,    │
│  │         button_hover_changed, upgrades_pressed       │
│  ├── Owns: coin_label, arrows, spawn_text, Coin, Arrow │
│  └── children: upgrade_wall, repair, buy_arrow, etc.    │
└───────────────────────┬─────────────────────────────────┘
                        │ (signals + direct calls)
┌───────────────────────▼─────────────────────────────────┐
│  Layer: Logic (Controllers)                              │
│  main.gd (Enemy spawner)                                │
│  ├── Wave system: spawn, break, complete                 │
│  ├── Connects to: buttons signals, enemy.died            │
│  └── Owns: wave state, enemy counts                     │
│                                                          │
│  player.gd                                               │
│  ├── Weapon: bow, rock                                  │
│  ├── Drag-to-aim: trajectory, shooting                   │
│  └── Listens: buttons.button_hover_changed               │
└───────────────────────┬─────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────┐
│  Layer: Data (Resources / Scenes)                        │
│  enemy.tscn / enemy2.tscn  — enemies                     │
│  wall1.tscn…wall5.tscn  — wall levels                   │
│  tower.tscn             — tower defense                  │
│  upgrade_map.tscn       — upgrade UI                    │
│  death.tscn             — game over screen               │
└─────────────────────────────────────────────────────────┘
```

---

## Signal Flow Diagram

```
UI Button pressed
       │
       ▼
buttons.gd  ──────────────────────────►  player.gd
  │                                   (button_hover_changed)
  │  on_upgrade_wall_pressed()            │
  │  on_buy_arrow_pressed()                │
  │  on_repair_pressed()                   │
  │  on_upgrades_pressed()                 │
  │  on_upgrade_tower_pressed() ───────────► tower.gd
  │                                              │
  ▼                                              ▼
main.gd                                   wall.gd
  ├── spawn_wave_enemies()                (wall upgrade/rebuild)
  ├── complete_wave()                          │
  ├── update_enemy_count()                     │
  └── _on_enemy_died() ◄───────────────────────
                     (enemy.died signal)
```

---

## Recent System Changes

### Wave Progress Bar Architecture
- **Type**: Changed from `TextureRect` to `TextureProgressBar` for proper fill behavior
- **Progress tracking**: Boss wave progress (0-100%) vs. per-wave enemy kill count
- **Update pattern**: Only increments on wave completion via `_update_wave_boss_progress()`
- **Bug fix**: Removed erroneous reset in `start_wave()` that was breaking progress during armored waves

### Health Bar System
- **Scene**: `scenes/ui/health_bar.tscn` now uses `TextureProgressBar` instead of ColorRect fills
- **Textures**: Uses `healthbar_allied_empty.png` and `healthbar_allied_full.png` for allied units (tower/wall)
- **Script**: `scripts/ui/health_bar.gd` updated to set `progress_bar.value` (0-100) instead of manual fill sizing
- **Fade behavior**: 60% opacity at full HP, 95% when damaged (was 30%/90%)

### Knight Enemy System
- **Scene**: `scenes/characters/knight.tscn` - removed position offset, added proper sprite scale
- **Scale**: 0.7 (vs 0.555 for basic enemies) - visually larger
- **Positioning**: Y-offset of -8 on sprite to keep feet aligned with collision shape
- **Debug**: Spawn button in sidebar connects to `_on_debug_spawn_knight_pressed()` in `buttons.gd`

## Remaining Known Issues

| Priority | Issue | Status |
|----------|-------|--------|
| 🟡 | Duplicate shader materials (15 foliage trees share identical `ShaderMaterial`) | Not fixed — needs shader refactor |
| 🟡 | `SubViewportContainer` drip effect not fully integrated | Needs testing |
| 🟡 | `CanvasLayer/Control` button positions — may need visual adjustment in editor to match original layout | Needs user verification |
| 🟢 | Enemy spawn position hardcoded: `Vector2(randf_range(-10, -60), 83.005)` | Low priority |
| 🟢 | Wave balance (`enemies_per_wave += 2`) | Needs playtesting |

---

## Scene Hierarchy (Current — After CanvasLayer Restructure)

```
root (".")
├── Node2D                              ← WORLD LAYER (scrolls with camera)
│   ├── Enemy spawner (main.gd)
│   ├── %Player
│   ├── %wall1
│   ├── tower
│   ├── Camera2D
│   ├── trees / trees2 (decoration)
│   ├── Ground / GroundCollision
│   ├── Flag
│   └── AudioStreamPlayer (ambience)
│
├── Audio (Node)                        ← AUDIO SIBLING
│   ├── buy_sound                       ← moved from Control
│   └── equip                           ← moved from Control
│
└── CanvasLayer                         ← SCREEN LAYER (fixed to screen)
    ├── Control (buttons.gd)            ← HUD: buttons, labels, sprites
    │   ├── upgrade_wall / repair / buy_arrow / upgrade_tower
    │   ├── weapon_ui / spawn_text / arrows
    │   ├── Coin / Arrow / coin_label
    │   └── (coin_label — properly named, under Control)
    ├── death (instanced)
    ├── upgrade_map (instanced)
    ├── vignette / vignette2
    └── SubViewportContainer (instanced)
```

### Key Node Path Changes

| Before | After | Reason |
|--------|-------|--------|
| `../Control/spawn_text` | `../../CanvasLayer/Control/spawn_text` | Control is now under CanvasLayer |
| `../death/wave` | `../../CanvasLayer/death/wave` | Same |
| `get_parent().get_node("wall1")` | `get_parent().get_node("%wall1")` | Unique name |
| `get_parent().add_child(wall)` | `get_parent().get_parent().add_child(wall)` | CanvasLayer between Control and world root |
| `$buy_sound` | `../Audio/buy_sound` | Audio nodes moved out of Control |
| `get_parent().get_node("tower")` | `get_parent().get_parent().get_node("Node2D/tower")` | CanvasLayer depth |

### Audio Nodes Moved to `Audio` Sibling

`buy_sound` and `equip` (both `AudioStreamPlayer2D`) were children of `Control`. Audio nodes are not UI elements and should not be under a `Control` node. They are now under `Node/Audio` at the root level, alongside `Node2D` and `CanvasLayer`.

`buttons.gd` resolves `buy_sound` via `get_parent().get_parent().get_node("Audio/buy_sound")`.

`player.gd` uses `%weapon_ui` and `%equip` unique names — these still work because unique names search the entire scene tree (not just the script's owner tree).

