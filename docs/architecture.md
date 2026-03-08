# Architecture — Open World Game

## Tech Stack

- **Engine:** Godot 4.2+
- **Language:** GDScript
- **Rendering:** 2D (top-down orthographic)

## Directory Layout

```
open-world/
├── scenes/          # .tscn scene files — world, player, enemies, UI, items
├── scripts/         # .gd scripts attached to scenes or used as resources
│   └── resources/   # Custom Resource classes (Inventory, Item, WeaponItem, HealthItem)
├── components/      # Reusable sub-scenes (health, hitbox, detection, animation)
├── art/             # Sprites, tilesets, animation sheets
│   ├── characters/  # Player & enemy sprites (+ normal maps)
│   ├── items/       # Weapon and key sprites
│   ├── tilesets/    # Grass, field, water, nature, house, village, floor
│   └── animations/  # Animation frame sheets
├── animations/      # Animation resource files (.res/.tres)
├── music/           # Audio tracks (.wav)
└── docs/            # Project documentation
```

## Core Patterns

### 1. Component-Based Composition

Reusable behaviours are implemented as standalone sub-scenes under `components/` and attached as children to any scene that needs them. This avoids deep inheritance chains.

| Component | Script | Purpose |
|---|---|---|
| `health_component.tscn` | `scripts/health_component.gd` | HP tracking, damage, healing, death signal |
| `hitbox_component.tscn` | `scripts/hitbox_component.gd` | Area-based damage with cooldown |
| `player_detection_component.tscn` | `scripts/PlayerDetectionArea.gd` | Enemy awareness area |
| `animation_damage.tscn` | — | Flash effect on hit |

### 2. Signal-Driven Communication

Systems communicate through signals rather than direct node references. This keeps coupling low.

```
HealthComponent emits:
  health_depleated  →  Player/Enemy listens, transitions to DEAD state
  damage_taken      →  AnimationDamage listens, plays flash

BackgroundMusic receives:
  play_audio(track) called from area scripts (world.gd, lake_world.gd)
```

### 3. State Machine (Player & Enemies)

The player uses an explicit enum state machine evaluated in `_physics_process`:

```gdscript
enum player_states { MOVE, HIT, DEAD }
```

Future entities (NPC, boss) should follow the same pattern.

### 4. Autoload Singleton

`BackgroundMusic` is registered as an autoload. Access globally via `BackgroundMusic.play_audio("track_name")`. Only use autoloads for truly global services (music, save data, game settings).

### 5. Resource Classes

Game data that is not a node (items, inventory, stats) lives as `Resource` subclasses under `scripts/resources/`. These can be serialized to `.tres` files and assigned in the Inspector.

| Resource | File | Purpose |
|---|---|---|
| `Item` | `resources/item.gd` | Base item data |
| `WeaponItem` | `resources/weapon_item.gd` | Weapon stats extending Item |
| `HealthItem` | `resources/health_item.gd` | Consumable heal item |
| `Inventory` | `resources/inventory.gd` | Collection of Items with insert/remove |

## Key Scenes

| Scene | Script | Role |
|---|---|---|
| `scenes/world.tscn` | `scripts/world.gd` | Root scene; holds tilemap, player, enemies, background |
| `scenes/player.tscn` | `scripts/player.gd` | Player character; state machine, movement, attack, inventory |
| `scenes/snake.tscn` | `scripts/snake.gd` | Snake enemy; AI, pathfinding, health |
| `scenes/campfire.tscn` | `scripts/campfire.gd` | Interactable campfire |
| `scenes/inventory_ui.tscn` | `scripts/inventory_ui.gd` | Inventory overlay UI |
| `scenes/background_music.tscn` | `scripts/background_music.gd` | Global music player (autoload) |

## Physics Layers

| Layer | Name | Used by |
|---|---|---|
| 2 | player | Player collision shape |
| 3 | enemies | Enemy collision shapes |
| 4 | weapons | Weapon hitboxes |
| 5 | no_affect | Areas that don't cause physics response |

## Input Mappings

Defined in `project.godot`. Do not hard-code key codes in scripts — always use action strings.

| Action | Default Keys | Purpose |
|---|---|---|
| `left/right/up/down` | WASD / Arrows | Movement |
| `hit` | X / LMB | Attack |
| `interact` | E | Interact with objects |
| `inventory` | Tab / I | Toggle inventory |
| `jump` | Space | Jump (reserved) |

## Adding New Features — Checklist

1. **New entity (enemy, NPC):** Create a `.tscn` scene, attach `health_component` and `hitbox_component` as children. Add an enum state machine in the script.
2. **New item type:** Extend `Item` resource class, add to `scripts/resources/`. Create a collectable scene using `collectable.tscn` as a base.
3. **New interactable:** Add an `Area2D` with an `interact` signal. Listen for `interact` input in the script.
4. **New building/structure:** Create a scene with static collision. Future: add a placement preview mode and a build system manager.
5. **New biome/area:** Add to the tilemap or as a sub-scene. Attach an `Area2D` and call `BackgroundMusic.play_audio()` on entry.

## Planned Systems (not yet implemented)

- **Resource harvesting system** — tree/rock nodes that drop items on tool use
- **Crafting system** — recipe registry and crafting UI
- **Building placement** — ghost preview + grid snapping + collision validation
- **Day/night cycle** — time manager driving a DirectionalLight2D or CanvasModulate
- **Hunger / stamina** — additional stat components similar to `health_component`
- **Save / load** — serialise world state and player inventory to disk
- **NPC system** — schedules, dialogue, and trading
