---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
inputDocuments:
  - PROJECT_STATUS.md
  - ARCHITECTURE.md
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 0
  projectDocs: 2
workflowType: gdd
lastStep: 13
project_name: obsidioo
user_name: Mr123
date: 2026-04-24
game_type: 'tower-defense'
game_name: 'OBSIDIO'
---

# OBSIDIO - Game Design Document

**Author:** Mr123
**Game Type:** Tower Defense
**Target Platform(s):** PC (Primary), Web, Mobile

---

## Executive Summary

### Game Name

**OBSIDIO**

### Core Concept

OBSIDIO is a 2D tower defense survival game where players defend their tower and wall against escalating waves of enemies using projectile-based combat. The core gameplay loop combines drag-to-aim shooting mechanics with strategic resource management and upgrade progression. Players start with basic weapons (rock and bow) and unlock additional projectiles (knife, axe, spear) through an upgrade map system, creating meaningful progression decisions.

The game currently features 15 waves culminating in a victory condition, with three enemy types offering varied threats: basic grunts, armored enemies, and heavy knights. The experience blends immediate-action shooting with longer-term strategic choices about when to upgrade defenses, buy ammo, or repair damage.

### Game Type

**Type:** Tower Defense

**Framework:** This GDD uses the tower-defense template with type-specific sections covering tower types and upgrades, enemy wave design, path and placement strategy, economy and resources, abilities and powers, and difficulty and replayability systems.

**Current State:** Phase 2 Demo Complete - All must-have and should-have features implemented. Ready for Phase 3 (Nice-to-Have) and Phase 4 (Post-Demo) feature planning.

---

## Target Platform(s)

### Primary Platform

**PC (Windows/Mac/Linux)**
- Initial release on itch.io
- Steam release planned for later
- Full mouse + keyboard support with input remapping

### Secondary Platforms

**Web Browser**
- Instant access for demos and playtests
- Godot web export support

**Mobile (iOS/Android)**
- Touch-optimized drag-to-aim controls
- UI scaling for small screens
- Battery and thermal considerations for longer sessions

### Platform Considerations

- PC/Web: Mouse-driven combat works natively; keyboard shortcuts for weapon switching and buying
- Mobile: Touch controls translate drag-to-aim naturally; on-screen buttons needed for weapon/buy actions
- Performance: 60fps target across all platforms; object pooling recommended for mobile optimization

### Control Scheme

- **Aim/Shoot:** Drag to aim (mouse or touch), release to fire
- **Weapon Switch:** Q key (PC) / On-screen button (Mobile)
- **Buy Arrows:** B key (PC) / On-screen button (Mobile)
- **Pause:** Escape (PC) / System back button (Mobile)

---

## Target Audience

### Demographics

**Age Range:** 5+ (E for Everyone)
- No mature content
- Accessible mechanics with depth for all skill levels

### Gaming Experience

**Multi-Tier Appeal**
- **Casual:** Pick-up-and-play, intuitive drag controls, visible progression
- **Core:** Strategic weapon choices, upgrade planning, wave management
- **Hardcore:** Optimization runs, perfect clears, economy efficiency, high-score chasing

### Genre Familiarity

**Genre-Innovative**
- Hybrid experience blending active projectile combat with tower defense structure
- May attract players from: action games, tower defense, survival games, and arcade shooters
- Tutorial/onboarding important for players new to either genre

### Session Length

**Flexible by Design**
- **Quick Sessions:** 5-15 minutes (complete 1-3 waves)
- **Extended Sessions:** 30-60+ minutes (full campaign completion, 15 waves to victory)
- Save/continue functionality supports both play patterns

### Player Motivations

- **Progression Enthusiasts:** Weapon unlocks, tower upgrades, wall improvements create tangible growth
- **Completionists:** "Finish the map" - clear all 15 waves, max all upgrades
- **Strategic Optimizers:** Economy management, upgrade timing, wave planning
- **Skill Expression:** Drag-to-aim mastery, perfect waves, minimal damage runs

---

## Goals and Context

### Project Goals

{{goals}}

### Background and Rationale

{{context}}

---

## Core Gameplay

### Game Pillars

**1. Meaningful Progression**
Every upgrade and unlock creates tangible growth. Weapon unlocks, tower levels, and wall improvements all provide visible, impactful progression that rewards player investment.

**2. Strategic Depth**
Resource management under pressure. When to defend vs. spend, which upgrades to prioritize, and how to balance ammo economy create meaningful decisions.

**3. Skill Expression**
Drag-to-aim mastery rewards precision. Player skill directly impacts success - every shot matters when ammo costs coins.

**Pillar Prioritization:** When pillars conflict, prioritize: Skill Expression > Strategic Depth > Meaningful Progression

### Core Gameplay Loop

**Break/Prepare Phase**
- Buy ammo (B key)
- Switch weapons (Q key)
- Assess tower/wall health
- Plan upgrade purchases

**Wave Defense Phase**
- Wave starts with enemy spawn announcement
- Enemies advance toward tower
- Three enemy types: Basic (fast), Armored (tough), Knight (heavy)
- Wave modifiers: Normal, Armored, Fast, Double Coins

**Combat Phase**
- Drag to aim trajectory
- Release to shoot projectile
- Switch weapons based on enemy type
- Manage ammo economy
- Avoid shooting when enemies are near wall

**Rewards/Upgrade Phase**
- Collect coins from defeated enemies
- Access upgrade map (weapons, tower, wall)
- Repair wall if needed
- Prepare for next wave

**Loop Timing:** ~3 minutes per wave

**Loop Variation:**
- Enemy composition changes each wave
- Special waves (armored, fast, double coins)
- Increasing enemy count (capped at 20 per wave)
- Boss wave at wave 15

### Win/Loss Conditions

#### Victory Conditions
**Demo:** Survive all 15 waves in the single level. Upon victory, stats screen displays waves survived and enemies defeated.

**Future:** Multiple levels, each with 15 waves and unique challenges.

#### Failure Conditions
**Tower Destroyed:** If tower health reaches 0, game over. The tower is the player's position - losing it means losing the game.

**Wall Status:** Wall can be destroyed but does NOT end the game. Wall provides defensive buffer but is not a fail condition.

#### Failure Recovery
On failure, players restart from the beginning (wave 1). No checkpoint system currently implemented.

#### Learning Through Failure
- **Ammo Economy:** Every shot costs coins - spray-and-pray leads to bankruptcy
- **Defense Priority:** Wall fortification early prevents tower damage
- **Strategic Timing:** Knowing when to spend vs. save is critical
- **Weapon Mastery:** Different enemies require different approaches

---

## Game Mechanics

### Primary Mechanics

**1. Shoot (Aim & Fire)**
- **Input:** Drag mouse to aim, release to shoot
- **Feedback:** Trajectory line preview, projectile travel, hit effects
- **Skill Tested:** Precision, timing, lead targeting
- **Supports Pillars:** Skill Expression
- **Progression:** Unlock 5 weapons (Rock, Bow, Knife, Axe, Spear) each with unique trajectory and damage

**2. Collect (Coins)**
- **Input:** Mouse hover over coins (auto-collect)
- **Feedback:** Coin pickup animation, floating +1 text, coin counter pulse
- **Skill Tested:** Position awareness, prioritization
- **Supports Pillars:** Strategic Depth, Meaningful Progression
- **Interaction:** Shoot → Kill → Collect → Upgrade cycle

**3. Upgrade (Weapons & Defenses)**
- **Input:** Button clicks in upgrade menu
- **Feedback:** Visual upgrades, new weapon icons, health bar changes
- **Skill Tested:** Economic decision-making, timing
- **Supports Pillars:** Meaningful Progression, Strategic Depth
- **Options:** Weapon unlocks, Tower upgrades (6 levels), Wall repair/upgrades

### Mechanic Interactions

**Core Cycle:** Shoot enemies → Collect coins from kills → Spend on upgrades → Shoot more effectively

**Weapon-Economy Loop:**
- Different weapons cost different ammo (Rock: 0, Bow: 1, Knife: 1, Axe: 2, Spear: 2)
- Choose between cheap spam (Rock) or expensive power (Spear)
- Balance ammo buying vs. saving for upgrades

**Defense-Offense Balance:**
- Spend coins on wall repair (defense) or weapon unlocks (offense)
- Strategic timing: repair during break vs. upgrade for next wave

### Mechanic Progression

**Weapon Unlock Tree:**
```
Rock (Free)
└── Bow (Starting)
    ├── Knife
    ├── Axe
    └── Spear
```

**Tower Upgrade Path:**
- 6 upgrade levels
- Each level increases max health
- Visual changes per level (wear/dissolve effects)

**Wall System:**
- 5 wall levels
- Repair during breaks
- Upgrade for more health

---

## Controls and Input

### Control Scheme (PC)

**Mouse-Only Play:**

| Action | Control |
|--------|---------|
| Aim | Drag |
| Shoot | Release |
| Weapon Switch | Click weapon UI |
| Buy Arrows | Click buy button |
| Upgrade Menu | Click upgrade button |
| Repair Wall | Click repair button |

**Mouse + Keyboard (Enhanced):**

| Action | Mouse | Keyboard |
|--------|-------|----------|
| Aim | Drag | - |
| Shoot | Release | - |
| Weapon Switch | - | Q |
| Buy Arrows | - | B |
| Pause | Button | Escape |

### Input Feel

- **Responsive:** Drag-to-aim has immediate visual feedback
- **Precise:** Trajectory line shows exact path
- **Snappy:** Weapon switches have no delay
- **Tactile:** Buttons have hover scale (1.05x) and press scale (0.95x) animations

### Accessibility Controls

- **Input Remapping:** Fully remappable controls (Settings → Controls)
- **Visual Feedback:** All actions have clear visual/audio feedback
- **Multiple Input Methods:** Mouse-only or mouse+keyboard both fully supported
- **Configurable:** Sensitivity and other options planned for post-demo

---

## Tower Defense Specific Design

### Tower Types and Upgrades

**Tower System:**
- 6 upgrade levels
- Each upgrade increases: Tower health and damage
- Cost varies by level
- Visual wear/dissolve effects show damage state

**Wall System:**
- 6 upgrade levels
- Repair system available during breaks
- Upgrade cost varies with current level
- Provides defensive buffer (not a fail condition)

### Enemy Wave Design

**Enemy Types:**

| Enemy | HP | Speed | Damage | Spawn Logic |
|-------|-----|-------|--------|-------------|
| Basic | ~100 | ~60 | ~20 | Standard spawn |
| Armored | 150 | Slower | Higher | When 3+ basics in wave |
| Knight | 200 | 35 | 35 | Wave 3+, every 4th position |

**Wave Scaling:**
- Enemy count: 5 + (wave × 2), capped at 20 per wave
- Wave modifiers: Normal, Armored, Fast, Double Coins
- Final wave: Wave 15 (victory condition)

### Path and Placement Strategy

**Current (Demo):**
- Fixed linear path: Left spawn to right-side tower
- Player IS the tower (no placement mechanic)
- Wall provides single choke point defense

**Future (Post-Demo):**
- Multiple levels with varied layouts
- Potential: Multiple lanes, elevated positions, winding paths

### Economy and Resources

**Income:**
- Starting: 5 coins
- Generation: Per enemy kill (1 coin basic, 2 coins knight)

**Costs:**

| Item | Cost |
|------|------|
| Rock ammo | Free |
| Bow/Knife ammo | 1 coin |
| Axe/Spear ammo | 2 coins |
| Upgrades | Level-based |

### Abilities and Powers

**Current:** None. Pure projectile combat focused.

**Future Considerations:** Emergency repairs, area attacks, temporary buffs (not planned for demo)

### Difficulty and Replayability

**Current:** Single difficulty, 15-wave survival

**Replayability:**
- Weapon strategy variety
- Upgrade timing optimization
- Economy efficiency challenges
- Perfect run attempts

---

## Progression and Balance

### Player Progression

**Progression Types:**
- **Power Progression:** Unlock weapons (Rock → Bow → Knife → Axe → Spear), upgrade tower (6 levels), upgrade/repair wall (6 levels)
- **Skill Progression:** Player improves at drag-to-aim accuracy, economy management, and strategic timing
- **No Meta Progression:** Each run starts fresh with no persistent unlocks between sessions

**Progression Pacing:**
- **Waves 1-3:** Learning phase with starting weapons
- **Waves 4-5:** First meaningful upgrades become achievable
- **Waves 6-14:** Steady power growth through unlocks and upgrades
- **Wave 15:** Final test of accumulated power and skill

### Difficulty Curve

**Pattern:** Linear increase with variation through wave modifiers

**Challenge Scaling:**

| Wave Range | Enemy Count | Key Challenge |
|------------|-------------|---------------|
| 1-2 | 5-7 | Learn basics |
| 3 | 5-7 + Knight | First heavy enemy |
| 4-14 | 9-20 + Modifiers | Increasing density + special waves |
| 15 | 20 + Boss | Final victory test |

**Wave Modifiers:**
- **Normal:** Standard enemies
- **Armored:** Higher HP enemies
- **Fast:** Increased movement speed
- **Double Coins:** More rewards, same challenge

**Difficulty Spikes:**
- Wave 3: First knight spawn (2x HP of basic)
- Armored waves: Tankier enemies require strategy adjustment
- Wave 15: Final wave completion challenge

**No Difficulty Settings:** Single difficulty (potential for Easy/Normal/Hard in future)

### Economy and Resources

**Resources:**
- **Coins:** Single currency for all purchases
- **Ammo:** Weapon-specific (unlimited rock, limited others)

**Economy Flow:**

- **Earn:** Defeat enemies (1 coin basic, 2 coins knight)
- **Spend:**

| Purchase | Cost |
|----------|------|
| Rock ammo | Free |
| Bow/Knife ammo | 1 coin |
| Axe/Spear ammo | 2 coins |
| Tower upgrade | Level-based |
| Wall repair | Damage-based |
| Weapon unlock | Varies |

**Economic Tension:**
- Limited starting coins (5) force early decisions
- Kill-to-earn only (no passive income)
- Every shot has opportunity cost
- Balance ammo buying vs. saving for upgrades

---

## Level Design Framework

### Structure Type

**Current (Demo):** Arena-style single level
- Single contained map
- 15 waves of escalating challenge
- One environment
- Immediate restart on failure

**Future (Post-Demo):** Linear Campaign with World Map
- Overworld map connecting multiple levels
- Linear progression (Level 1 → Level 2 → Level 3 → ...)
- Biome-based variety (forest, desert, snow, etc.)
- Complete all levels to finish the campaign

### Level Types

**Current:**
- Single Tutorial/Intro Level: Teaches drag-to-aim, weapon switching, upgrades
- Standard waves with progressive difficulty

**Future:**

| Level Type | Description |
|------------|-------------|
| Tutorial Level | Teaches core mechanics |
| Biome Levels | Unique environment with themed enemies |
| Boss Levels | Culmination of biome challenges |
| Final Level | Ultimate challenge |

**Biome Concepts (Future):**
- Forest: Standard enemies, natural obstacles
- Desert: Fast enemies, limited cover
- Snow: Slow but tanky enemies
- etc.

### Level Progression

**Current:**
- No unlock system
- Single level available
- Replay for optimization/high scores

**Future:**
- **Unlock System:** Complete Level 1 to unlock Level 2
- **Linear Sequence:** Must progress in order
- **World Map:** Visual representation of journey
- **Biome Gate:** Complete all levels in biome to unlock boss level

#### Replayability

- **Current:** Restart for better performance, optimization
- **Future:** Replay any completed level for practice, high scores, or different strategies

### Level Design Principles

_Level design principles will be established during full development._

**Guiding Intent:**
- Each new map introduces new enemy types
- Biome-specific visual themes and hazards
- Progressive complexity across levels

---

## Art and Audio Direction

### Art Style

**Style:** Pixel Art (Kingdom Two Crowns inspired)

Clean, detailed pixel art with atmospheric lighting and rich color palette. Stylized 2D side-scrolling perspective.

#### Visual References

- **Primary Reference:** Kingdom Two Crowns
- Clean pixel art with readable silhouettes
- Atmospheric environments
- Rich but not overwhelming color palette
- Stylized character designs

#### Color Palette

- Rich, atmospheric colors
- Good contrast for readability
- Warm tones for player/tower
- Enemy silhouettes clearly distinguishable

#### Camera and Perspective

- **Type:** 2D side-scrolling
- **Position:** Fixed camera
- **View:** Player on right, enemies approach from left
- **Depth:** Parallax backgrounds for depth

### Audio and Music

#### Music Style

- **Genre:** Simple medieval/fantasy
- **Mood:** Atmospheric, not overwhelming
- **Implementation:** Background ambient tracks
- **Wave Variation:** Break time music crossfade exists

#### Sound Design

- **Approach:** Realistic medieval sound effects
- **Weapons:** Bow draw/release, projectile impacts, weapon equips
- **Feedback:** Hit sounds, coin pickup, upgrade confirmations
- **Environment:** Subtle ambient battle sounds
- **UI:** Button hover/click, purchase sounds

#### Voice/Dialogue

**None**
- No voice acting
- Sound effects communicate game state

### Aesthetic Goals

**Art supports gameplay by:**
- Clear visual feedback (hit flashes, particle effects)
- Readable enemy types at a glance
- Upgrade visual changes show progression
- Shader effects enhance impact (destruction, dissolve)

**Audio supports gameplay by:**
- Weapon sounds give firing feedback
- Hit sounds confirm successful shots
- Coin pickup audio reinforces reward
- Music sets medieval atmosphere without distraction

---

## Technical Specifications

### Performance Requirements

**Frame Rate Target:** 60fps across all platforms

**Resolution Support:**
- PC: 1920x1080 (scalable)
- Web: Responsive/adaptive
- Mobile: Various screen sizes with UI scaling

**Load Times:** Under 5 seconds initial load

### Platform-Specific Details

**Engine:** Godot 4.6 with GDScript

**PC Requirements:**
- OS: Windows 10+, macOS 10.14+, Linux
- Input: Mouse + Keyboard (remappable)
- Distribution: itch.io (initial), Steam (future)

**Web Requirements:**
- WebGL 2.0 compatible browser
- Maximum build size: 50MB
- Keyboard and mouse support

**Mobile Requirements (Future):**
- iOS 13+, Android API 26+
- Touch controls with on-screen buttons
- Portrait/landscape support
- Battery optimization needed

### Asset Requirements

**Art Assets:**
- Pixel art sprites (player, enemies, tower, wall)
- Animated sprites with frame-based animation
- Particle effects (coins, destruction)
- UI elements (buttons, icons, health bars)
- Background elements (trees, ground)

**Audio Assets:**
- Music tracks (ambient medieval)
- SFX: Weapon sounds, impacts, UI feedback
- No voice/dialogue

**External Assets:**
- Shader materials (dissolve, destruction effects)
- Shared foliage materials for trees

---

## Development Epics

### Epic Overview

| # | Epic Name | Status | Focus |
|---|-----------|--------|-------|
| 1 | Core Combat & Movement | ✅ Complete | Drag-to-aim, weapons, shooting |
| 2 | Enemy System & Waves | ✅ Complete | 3 enemy types, wave spawning, AI |
| 3 | Upgrade & Economy | ✅ Complete | Coins, upgrades, weapon unlocks |
| 4 | UI & Game Flow | ✅ Complete | Menus, settings, victory/death screens |
| 5 | Phase 3 Polish | 📋 Planned | Object pooling, audio polish, juice |
| 6 | Level Framework | 📋 Future | Multiple levels, world map |
| 7 | Content Expansion | 📋 Future | New enemies, weapons, bosses |
| 8 | Feature Complete | 📋 Future | Difficulty, gamepad, save system |

### Vertical Slice

**Completed:** Core gameplay loop functional with all essential systems. Demo ready with single level, 15 waves, upgrade system, and polished UI.

---

## Success Metrics

### Technical Metrics

| Metric | Target | Measurement Method |
| ------ | ------ | ------------------ |
| Frame Rate | 60fps stable | In-engine monitoring |
| Console Errors | 0 errors | Godot output panel |
| Memory Usage | <500MB | Godot profiler |
| Load Time | <5 seconds | Stopwatch test |

### Gameplay Metrics

| Metric | Target | Measurement Method |
| ------ | ------ | ------------------ |
| Wave 5 Completion | 70% of players | Analytics |
| Full Game Completion | 30% of players | Analytics |
| Avg Session Length | 20 minutes | Analytics |
| Weapon Variety Used | 3+ weapons | Analytics |

### Qualitative Success Criteria

- Players describe game as "fun" and "engaging"
- Positive feedback on progression system
- Players want to replay after death
- Interest in additional content/levels
- Reviews mention satisfying skill-based combat

### Metric Review Cadence

- **Development:** Per build testing
- **Demo Release:** Post-launch analytics review
- **Future Updates:** Monthly metric review

---

## Out of Scope

{{out_of_scope}}

---

## Assumptions and Dependencies

{{assumptions_and_dependencies}}
