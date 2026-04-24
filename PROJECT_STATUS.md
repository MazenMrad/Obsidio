# OBSIDIO Project Status

Last updated: 2026-04-24

## Recent Session Updates (2026-04-24)

### Phase 2 Demo Polish — COMPLETE ✅

All Phase 2 "Should-Have" items have been implemented and verified:

| Feature | Status |
|---------|--------|
| How-to-Play / Tutorial Text | ✅ Done |
| Health Bars for Tower & Wall | ✅ Done |
| Wave Start/End Feedback | ✅ Done |
| Coin Pickup Feedback | ✅ Done |
| No-Ammo Indicator | ✅ Done |
| Death Screen Restart Verification | ✅ Done |
| Break Timer Polish | ✅ Done |
| Destruction Effect Verification | ✅ Done |

### Full Verification Complete

All items from the Recommended Verification Checklist have been verified:

**Animations & Player:**
- ✅ Player spawns in `idle` animation
- ✅ Bow normal aim transitions (draw → hold → release → idle)
- ✅ Bow upward aim transitions (up draw → up hold → up release → idle)
- ✅ Idle breathing frequency feels natural during downtime
- ✅ Throw weapons return cleanly to idle after release

**Gameplay Systems:**
- ✅ Knight spawns from wave 3+ at correct positions
- ✅ Active tower only receives enemy damage (hidden towers ignored)
- ✅ Tower wear effect visibility on each tower level (1 through 6)
- ✅ Tower red hit flash readable while dissolve wear is active
- ✅ Destruction effect plays on tower death and wall death
- ✅ Upgrade map purchase flow works (hold-to-buy, coin deduction, weapon unlock)
- ✅ Upgrade map paper card states: locked (silhouette + grey), unlockable (green paper), owned (normal icon)
- ✅ No-ammo shooting gives player feedback

**UI & UX:**
- ✅ Pause menu animation (scale-in on open, scale-out on close)
- ✅ Button hover/press animations feel responsive
- ✅ Input remapping saves and loads correctly

**Game Flow:**
- ✅ Death screen restart properly resets all global state

**Technical:**
- ✅ Clear console warnings/errors during full run
- ✅ Stable FPS with no major hitching during enemy spawn or UI open/close
- ✅ No invisible-state bugs on tower upgrade transitions

---

## Recent Session Updates (2026-04-24)

### Phase 2 Demo Polish — COMPLETED

The following Phase 2 "Should-Have" polish items have been implemented:

1. **How-to-Play / Tutorial Text** — Added controls explanation text that explains:
   - Drag-to-aim mechanics
   - Hotkeys (Q for weapon change, B for buying arrows)
   - Basic gameplay loop for first-time players

2. **Coin Pickup Feedback** — Implemented floating +1 text with pulse animation on coin collection

3. **No-Ammo Indicator** — Arrows label and weapon icon now flash red when attempting to shoot with empty ammo

4. **Break Timer Polish** — Progress bar for countdown between waves is now implemented

### Verified Items

The following animation and gameplay items have been verified in-engine:
- ✅ Player spawns in `idle` animation (not a throw frame)
- ✅ Bow transition sequences work correctly (draw → hold → release → idle)
- ✅ Throw weapons return cleanly to idle after release

---

## Recent Session Updates (2026-04-23)

### Phase 1 Demo Blockers — COMPLETED

All Phase 1 must-have features for the demo release are now complete:

1. **Victory Screen** — Created `scenes/victory.tscn` and `scripts/victory_GUI.gd` with:
   - Gold-tinted dark overlay (`Color(0.08, 0.06, 0.01, 0.72)`)
   - "VICTORY" title with glitch text shader (gold color)
   - Stats display: Waves Survived and Enemies Defeated
   - "Play Again" button with restart functionality
   - Properly wired into `main.gd` `_trigger_victory()` and `main.tscn` CanvasLayer

2. **Starting Economy Fix** — Changed `var coins: int = 999` to `var coins: int = 5` in `scripts/global_var.gd`

3. **Wall Detection for All Enemy Types** — Updated `scripts/wall.gd` and `scripts/tower.gd` to use group-based detection (`is_in_group("enemies")`) instead of name-based checks

4. **Knight Unique Stats** — Added to `scripts/knight.gd`:
   - HP: 200 (2x basic enemy)
   - Speed: 35.0 (~60% of basic enemy)
   - Damage: 35 (1.75x basic enemy)
   - Optional: 2 coin drops on death

5. **Ammo Cost Balance** — Updated `WEAPON_AMMO_COSTS` in `scripts/player.gd`:
   ```gdscript
   const WEAPON_AMMO_COSTS: Dictionary = {
       "rock": 0,
       "bow": 1,
       "knife": 1,  # Was 2
       "axe": 2,    # Was 3
       "spear": 2   # Was 4
   }
   ```

6. **Enemy Spawn Balance Tuning** — Updated `scripts/main.gd`:
   - Capped enemies per wave at 20 (`mini(5 + current_wave * 2, 20)`)
   - Fixed enemy2 spawn logic using per-wave spawn tracking
   - Knights spawn every 4th position from wave 3+

---

## Previous Session Updates (2026-04-22)

### Wave Progress Bar Fixes
- **Fixed Armored Wave Bug**: Progress bar was resetting to 0% when armored waves started due to `wave_progress_bar.value = 0.0` in `start_wave()`
- Increased progress bar size: 340×50 → **380×60 pixels** for better visibility
- Progress now correctly persists through all wave types (normal, armored, fast, double coins)

### Knight Enemy Polish
- **Fixed spawn position**: Removed `position = Vector2(0, -15)` offset from `knight.tscn` that was causing knight to spawn partially underground
- **Fixed sprite scale**: Added missing `scale = Vector2(0.555, 0.555)` to knight's AnimatedSprite2D (was causing size mismatch with other enemies)
- **Increased knight size**: Scale 0.555 → **0.7** (26% bigger) with Y-offset adjustment (-8 pixels) to keep feet on ground
- **Added debug spawn button**: "SPAWN" button in sidebar to instantly spawn knights for testing

### Health Bar Improvements
- **Fixed initial dark appearance**: Health bars were appearing dark at full HP due to low alpha (0.3), increased to **0.6** for full HP, **0.95** for damaged
- **Fixed initial value not set**: Added `_ready()` to set initial progress bar value to 100
- **Replaced with texture-based bars**: Converted `scenes/ui/health_bar.tscn` from ColorRect to TextureProgressBar using:
  - `healthbar_allied_empty.png` as `texture_under`
  - `healthbar_allied_full.png` as `texture_progress`
- Updated `scripts/ui/health_bar.gd` to work with TextureProgressBar (value-based instead of fill width)

## Previous Session Updates (2026-03-27)

- Fixed the parse error in `scripts/effects/destruction_effect.gd` by correcting the debris tween block indentation.
- **COMPLETED: Wave Progress Bar System** — Redesigned the wave progress bar to show progress toward the final boss wave (wave 15):
  - Progress bar now displays overall campaign progress, not wave countdown timer
  - Each completed wave increments progress by ~7.14% (100% / 14 waves)
  - Added `wave_progress_panel.png` as decorative container background
  - Progress bar centered inside panel with proper anchoring
  - Updated textures: `wave_progress_bar_empty.png` (under) and `wave_progress_bar_complete.png` (progress fill)
  - Moved progress bar to direct child of CanvasLayer for proper viewport centering
  - Fixed `_update_wave_progress_break()` to stop overwriting progress with countdown timer

- Added **Knight enemy** (`scenes/characters/knight.tscn`) as a third enemy type in the wave spawn roster.
- Created `scripts/knight.gd` extending `enemy_1.gd` with unique `"knight"` group assignment (removes from `"enemy1"` group on ready).
- Knight integrated into wave spawn system in `scripts/main.gd` — spawns from wave 3 onward, every 4th enemy position (indices 3, 7, 11, etc.).
- Added `KNIGHT_SCENE` preload constant and updated `spawn_wave_enemies()` with priority spawn logic: knight first (wave 3+), then enemy2 (when enemy1_count >= 3), then enemy1.
- Added debug print logging to `spawn_wave_enemies()` and `knight.gd` `_ready()` for spawn verification.
- Added **destruction shader effect** — a disintegration/dissolve visual that plays when tower or wall is destroyed.
- Created `scenes/shaders/destruction_effect.gdshader` — pixel scatter, UV displacement, vignette dissolve, and orange color shift.
- Created `scenes/effects/destruction_effect.tscn` — reusable effect scene with ShaderMaterial setup.
- Created `scripts/effects/destruction_effect.gd` — animates shader strength 0→1, scale pulse, optional debris particles, auto-cleanup.
- Updated `scripts/tower.gd` — added `_spawn_destruction_effect()` called in `destroy_tower()`, uses tower visual texture.
- Updated `scripts/wall.gd` — added `_spawn_destruction_effect()` called in `destroy_wall()`, uses wall sprite texture.

## Previous Session Updates (2026-03-27)

- Tower wear/dissolve pipeline is now wired to active tower health in `scripts/tower.gd`.
- Tower wear uses per-instance shader material on the visual child node (not the physics root).
- Tower wear sensitivity now starts at 0 and rises with damage over time.
- Added red hit flash support to dissolve shader using `hit_tint` + `hit_strength` uniforms.
- Tower hit flash now drives shader parameter tween instead of relying only on sprite modulate.
- Fixed tower active-state behavior so only the visible/active tower processes damage/collisions.
- Fixed hidden upgrade towers incorrectly taking damage while inactive.
- Added extensive tower wear debug hooks and confirmed runtime updates from live logs.
- Tower/player death coupling was reinforced so both are cleaned up consistently on fail flow.
- Upgrade map logic now supports paper-style weapon cards and nested icon targeting.
- Old highlight overlay usage was removed in favor of paper card modulation.
- Unlockable weapon cards are now represented with green paper modulation.
- Weapon icon fit/centering logic was updated for nested paper/card structures.
- On weapon unlock, icon shader is now removed (silhouette effect disabled for owned weapons).

## Working In Game

- Core loop: 2D tower-defense survival against enemy waves.
- Player combat: drag-to-aim projectile throwing and bow shooting.
- Weapons currently represented in code: rock, bow, knife, axe, spear.
- Projectile scenes and scripts exist for multiple weapon types with travel, damping, trail, and hit behavior.
- Player weapon switching exists through unlocked weapon state.
- Bow animation flow exists with separate normal and upward branches:
  draw -> hold -> release
- Throw animation flow exists with:
  draw -> hold -> release
- Player trajectory preview exists with a line preview and tip marker.
- Player breathing idle animation is integrated and can play intermittently while idle.
- Enemy wave manager logic exists in `main.gd` with wave progression, spawn counts, and breaks between waves.
- Wall system exists with health, damage intake, destruction, rebuild, repair, and upgrade progression.
- Tower system exists with health, damage intake, destruction, and upgrade levels.
- Coins and arrows are part of game state and UI flow.
- Upgrade / purchase UI exists through `buttons.gd`.
- Weapon unlock map exists through `upgrade_map.gd`.
- Death / fail flow exists through tower destruction and death UI handling described in architecture docs.
- Victory flow exists with victory screen showing stats and play again button.
- UI architecture has already been refactored so button logic lives in `buttons.gd` and gameplay nodes listen through signals instead of direct cross-node scene calls.
- Scene transition shader effect works via `PersistentScene` autoload (circular wipe).
- Pause menu now has slide-in/scale animation with smooth transitions.
- All buttons have hover/press scale animations for polished feel.
- Wave text is now properly centered at top of screen (responsive anchor).
- Options and Home buttons are now anchored to bottom-right corner (responsive).
- Input remapping screen allows players to rebind controls.

## Hotkeys Implemented

- **Q** - Change/cycle weapon (remappable in Settings → Controls)
- **B** - Buy arrows for 1 coin (remappable in Settings → Controls)

## Implemented Supporting Systems

- Global state autoload for coins, arrows, unlocked weapons, and current weapon state.
- CanvasLayer-based HUD separation from world-space gameplay.
- Button hover blocking so gameplay input does not fire while interacting with UI.
- Tower and wall upgrade hooks connected from UI.
- Enemy death signal flow into wave progression.
- Audio hooks for equip, bow draw, bow release, hits, and build interactions.
- Audio hook for buy sound when purchasing arrows via hotkey.
- Input remapping system with save/load to `user://settings.cfg`.
- Pause menu with settings (volume sliders) and controls remapping.
- Button animations with hover scale (1.05x) and press scale (0.95x).
- Victory screen with stats display and restart functionality.
- Group-based enemy detection for walls and towers (works with all enemy types).
- Knight enemy with unique stats (HP 200, speed 35, damage 35).
- Balanced ammo costs (rock: 0, bow: 1, knife: 1, axe: 2, spear: 2).
- Capped enemy spawn at 20 per wave with proper enemy type distribution.

## Known Issues & Bugs

- Destruction effect `.tscn` has a placeholder UID - Godot will regenerate it on first open, but it may still warn once.
- `SubViewportContainer` drip effect is still untested.

## Demo Release Roadmap

### Phase 1 — Must-Have (Demo Blockers) ✅ COMPLETED

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 1 | **Victory Screen** | ✅ Done | Shows stats, play again button, gold glitch effect |
| 2 | **Starting Economy** | ✅ Done | Changed from 999 to 5 coins |
| 3 | **Wall Detection** | ✅ Done | Group-based detection for all enemy types |
| 4 | **Knight Stats** | ✅ Done | HP 200, speed 35, damage 35 |
| 5 | **Ammo Cost Balance** | ✅ Done | Knife: 1, Axe: 2, Spear: 2 |
| 6 | **Enemy Spawn Balance** | ✅ Done | Capped at 20 enemies/wave, fixed enemy2 logic |

### Phase 2 — Should-Have (Demo Polish)

These make the demo feel polished and playable rather than just "functional."

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 7 | **How-to-Play / Tutorial Overlay** | ✅ Done | Controls text added explaining mechanics to first-time players |
| 8 | **Health Bars for Tower & Wall** | ✅ Done | Basic health bar system implemented and verified |
| 9 | **Wave Start/End Feedback** | ✅ Done | Animated text for wave transitions |
| 10 | **Coin Pickup Feedback** | ✅ Done | Floating +1 text, pulse coin counter |
| 11 | **No-Ammo Indicator** | ✅ Done | Flash arrows red when empty |
| 12 | **Death Screen Restart Verification** | ✅ Done | Full reset flow verified in-engine |
| 13 | **Break Timer Polish** | ✅ Done | Progress bar for countdown |
| 14 | **Destruction Effect Verification** | ✅ Done | Coordinate spaces fixed, verified in-engine |

### Phase 3 — Nice-to-Have (Demo Juice)

These elevate the demo from "playable" to "impressive."

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 15 | **Object pooling** | ❌ Missing | Project guidance recommends it. With 3 enemy types + coins + 5 projectile types spawning frequently, mid-to-late waves may stutter. Pool projectiles and coins at minimum. |
| 16 | **Wave completion fanfare** | ❌ Missing | Short jingle or stinger when a wave is cleared. Break time music crossfade exists but no explicit "wave cleared" moment. |
| 17 | **Enemy death variation** | ⚠️ Minimal | All enemies share same death flow (queue_free). Could add enemy-specific death particles or sound pitch variations per type. |
| 18 | **Screen shake tuning** | ⚠️ Untuned | Camera shake exists for hits (4.0, 0.12s) and tower/wall damage (8-10, 0.18-0.22s). Needs playtesting to confirm shake feels impactful without being annoying. |
| 19 | **Persistent high score** | ❌ Missing | No save of best wave survived or kill count. Would give replay incentive. Could store in `user://save.cfg`. |
| 20 | **Gamepad support** | ❌ Missing | Input remapping exists for keyboard but no gamepad focus navigation. Low priority for mouse-driven demo but useful for accessibility. |
| 21 | **Drip effect (SubViewportContainer)** | ❌ Untested | Exists in scene but unvalidated. Could add atmospheric polish if working. |

### Phase 4 — Post-Demo (Future)

These are beyond the scope of a first demo but worth tracking.

- Additional enemy types beyond grunt/enemy2/knight (ranged enemy, boss enemy, etc.)
- Upgrade tree expansion (weapon upgrades, not just unlocks)
- Multiple maps / map selection
- Difficulty settings (easy/normal/hard)
- Proper main menu with play/settings/quit (PersistentScene transition exists but menu is basic)
- Web export optimization and testing
- Mobile touch input support
- Localization framework

## Recommended Implementation Order for Demo

Now that Phase 1 is complete, focus on Phase 2 polish items:

1. **Add tutorial overlay** (Phase 2 #7) — 1 hr, create `tutorial_overlay.tscn` + `.gd` with controls list + first-launch detection
2. **Add wave start/end text** (Phase 2 #9) — 45 min, animated "WAVE X" / "WAVE X COMPLETE!" labels in CanvasLayer
3. **Add no-ammo feedback** (Phase 2 #11) — 30 min, flash arrows label + weapon icon red on empty-shoot attempt
4. **Add coin pickup +1 text** (Phase 2 #10) — 30 min, floating label in `coin.gd` + pulse coin counter in `main.gd`
5. **Verify destruction effect** (Phase 2 #14) — 30 min, fix `global_position` in debris particles + engine test
6. **Verify death restart** (Phase 2 #12) — 15 min, manual checklist test in Godot
7. **Health bars polish** (Phase 2 #8) — Review existing implementation, polish if needed
8. **Break timer progress bar** (Phase 2 #13) — 30 min, add ProgressBar + last-3s pulse effect

## Current Animation Notes

- The player scene now includes:
  `idle`, `idlebreathing`, `bowdraw`, `bowhold`, `bowrelease`, `bowupdraw`, `bowuphold`, `bowuprelease`, `throw`, `throwhold`, `throw_release`
- The player should load into `idle`, not a throw frame.
- Breathing idle is intended as an occasional accent, not a constant loop.

## UI Files Reference

| File | Purpose |
|------|---------|
| `scripts/buttons.gd` | HUD buttons, pause menu, settings, animations |
| `scripts/input_remapping.gd` | Controls remapping screen |
| `scenes/input_remapping.tscn` | Controls remapping UI panel |
| `scripts/death_GUI.gd` | Death screen (restart, wave/kill stats) |
| `scripts/victory_GUI.gd` | Victory screen (stats, play again) |
| `scenes/victory.tscn` | Victory UI scene |
| `scripts/upgrade_map.gd` | Weapon unlock map (hold-to-purchase, drag, zoom) |

## Shared Materials Reference

| File | Purpose |
|------|---------|
| `resources/materials/foliage_shader_material.tres` | Shared material for tree sprites (render_noise=false) |
| `resources/materials/foliage_parent_material.tres` | Shared material for tree parent nodes (render_noise=true) |
| `scenes/shaders/destruction_effect.gdshader` | Disintegration shader for tower/wall destruction |
| `scenes/shaders/dissolve.gdshader` | Wear/dissolve shader for tower health visual |
| `scenes/shaders/wall_hit_effect.gdshader` | Crack + hit flash shader for wall damage |
| `scenes/shaders/text.gdshader` | Glitch text shader used on death/victory screens |

## Input Actions

| Action | Default Key | Description |
|--------|-------------|-------------|
| `change_weapon` | Q | Cycle through unlocked weapons |
| `buy_weapon` | B | Buy arrows (1 coin → +1 arrow) |
| `MOUSE_BUTTON_LEFT` | Left Click | Drag to aim, release to shoot |
| `ui_cancel` | Escape | Pause / close menus |

## Recommended Verification Checklist

- [x] Victory screen displays at wave 15 with stats
- [x] Victory "Play Again" button restarts game properly
- [x] Starting coins are 5 (not 999)
- [x] Wall detection triggers for ALL enemy types (enemy1, enemy2, knight)
- [x] Knight has unique stats (HP 200, speed 35, damage 35)
- [x] Ammo costs balanced (rock: 0, bow: 1, knife: 1, axe: 2, spear: 2)
- [x] Enemy spawn capped at 20 per wave
- [x] Player spawns in `idle` animation
- [x] Bow normal aim transitions (draw → hold → release → idle)
- [x] Bow upward aim transitions (up draw → up hold → up release → idle)
- [x] Idle breathing frequency feels natural during downtime
- [x] Throw weapons return cleanly to idle after release
- [x] Knight spawns from wave 3+ at correct positions
- [x] Pause menu animation (scale-in on open, scale-out on close)
- [x] Button hover/press animations feel responsive
- [x] Input remapping saves and loads correctly
- [x] Active tower only receives enemy damage (hidden towers ignored)
- [x] Tower wear effect visibility on each tower level (1 through 6)
- [x] Tower red hit flash readable while dissolve wear is active
- [x] Destruction effect plays on tower death and wall death
- [x] Death screen restart properly resets all global state
- [x] Upgrade map purchase flow works (hold-to-buy, coin deduction, weapon unlock)
- [x] Upgrade map paper card states: locked (silhouette + grey), unlockable (green paper), owned (normal icon)
- [x] No-ammo shooting gives player feedback
- [x] Clear console warnings/errors during full run
- [x] Stable FPS with no major hitching during enemy spawn or UI open/close
- [x] No invisible-state bugs on tower upgrade transitions
