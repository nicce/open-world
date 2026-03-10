# Codebase Structure

**Analysis Date:** 2026-03-10

## Directory Layout

```
project-root/
├── scenes/              # .tscn scene files (game entities and UI)
├── scripts/             # .gd source code (game logic and systems)
│   └── resources/       # Resource classes (Item, Inventory, etc.)
├── components/          # Reusable sub-scene components
├── art/                 # Sprites, tilesets, UI images
│   ├── characters/      # Player and enemy sprites
│   ├── items/           # Weapon and collectible sprites
│   ├── animations/      # Animation frame sheets
│   ├── tilesets/        # Grass, water, house, village tilesets
│   └── potions/         # Health item sprites
├── music/               # Audio tracks (area-based background music)
├── animations/          # Animation resource (.res/.tres) files
├── tests/               # GUT unit tests
│   └── unit/            # Pure logic tests
├── docs/                # Documentation (vision, architecture, TODO)
├── bin/                 # Build artifacts and virtual environment
├── project.godot        # Engine configuration and input mappings
└── Makefile             # Build and test commands
```

## Directory Purposes

**scenes/**
- Purpose: Godot scene files (.tscn) containing game entities and UI
- Contains: Player, enemies, world, inventory UI, interactive objects, camera, music player
- Key files:
  - `world.tscn` — Main game scene, contains all game entities and systems
  - `player.tscn` — Player character with animation tree and components
  - `snake.tscn` — Enemy template with AI detection and health
  - `inventory_ui.tscn` — UI panel for viewing/managing inventory
  - `campfire.tscn` — Interactive object for wood management
  - `collectable.tscn` — Base template for pickable items
  - `background_music.tscn` — Autoload singleton for audio playback
  - `abandoned_village.tscn` — Alternative world/map
  - Component sub-scenes: `advanced_camera.tscn`, `health_bar.tscn`, `axe.tscn`, `medicpack.tscn`, `gold_key.tscn`

**scripts/**
- Purpose: GDScript source code for game behavior
- Contains: Entity logic, components, UI controllers, singletons
- Organized by responsibility (not by entity type)
- Key files:
  - `player.gd` — Player movement, combat state machine, item collection
  - `snake.gd` — Enemy behavior initialization and respawn signals
  - `health_component.gd` — Shared HP/damage logic (attached as child)
  - `hitbox_component.gd` — Attack detection and damage application
  - `inventory_ui.gd` — Inventory panel toggle and display
  - `campfire.gd` — Interactive fire management with burn timer
  - `collectable.gd` — Base class for pickable items
  - `background_music.gd` — Global audio singleton (autoload)
  - `advanced_camera.gd` — Camera shake effects using Perlin noise
  - `attack.gd` — Value object for attack stats
  - `health_bar.gd` — Visual HP bar display
  - `axe.gd` — Extends Collectable for weapon items
  - `medicpack.gd` — Interactive healing object
  - `PlayerDetectionArea.gd` — Enemy AI detection and chase behavior
  - `world.gd` — World scene logic (area-based music)
  - `lake_world.gd` — Alternative world logic (currently unused)

**scripts/resources/**
- Purpose: Data models and Resource classes (immutable/quasi-immutable)
- Contains: Item definitions, inventory system, health modifiers
- Key files:
  - `item.gd` — Base item class with name, texture, weight, category
  - `inventory.gd` — Inventory container managing weight/stack limits
  - `inventory_slot.gd` — Single slot holding one item stack (max 10 units)
  - `weapon_item.gd` — Extends Item for attack-based items
  - `health_item.gd` — Extends Item for consumable healing items

**components/**
- Purpose: Reusable sub-scene templates for composition
- Contains: Generic, scene-agnostic functionality
- Key files:
  - `health_component.tscn` + `scripts/health_component.gd` — HP/damage system
  - `hitbox_component.tscn` + `scripts/hitbox_component.gd` — Collision/damage detection
  - `player_detection_component.tscn` + `scripts/PlayerDetectionArea.gd` — Enemy awareness
  - `animation_damage.tscn` — Flash effect on hit (visual feedback)

**art/**
- Purpose: All visual assets (sprites, tilesets, UI graphics)
- Contains: PNG/WebP images for characters, items, tiles, animations
- Subdirectories:
  - `characters/` — Player and enemy sprite sheets (includes normal maps)
  - `items/` — Weapon and key sprites
  - `tilesets/` — Grass, field, water, nature, house, village, floor tilesets
  - `animations/` — Animation frame sheets (separate from Godot animation resources)
  - `potions/` — Health item sprites
  - Root level: `InventoryRect.png`, `inventorySlot.png`, `natural_light.webp` (UI assets)

**music/**
- Purpose: Background audio tracks
- Contains: WAV audio files for area-based ambiance
- Key files:
  - `home.wav` — Peaceful area music
  - `dark_woodslands.wav` — Danger/exploration area music

**animations/**
- Purpose: Godot animation resource files (.tres/.res)
- Contains: Pre-configured AnimationResource objects referenced by scenes

**tests/unit/**
- Purpose: Pure logic unit tests using GUT framework
- Contains: Tests for resource classes and components
- Key files:
  - `test_inventory.gd` — 186 test cases covering insert/remove/weight/stacking logic
  - `test_inventory_slot.gd` — Stack and weight limit tests
  - `test_health_component.gd` — Health/damage/healing tests
  - `test_campfire.gd` — Fire/smoke/burn timer tests

**docs/**
- Purpose: Project documentation
- Contains: Vision, architecture decisions, TODO list, design docs

## Key File Locations

**Entry Points:**
- `scenes/world.tscn` — Main game scene (configured in project.godot)
- `project.godot` — Engine configuration and input action mappings

**Configuration:**
- `project.godot` — Godot engine settings, input bindings, autoload registration
- `Makefile` — Development commands (lint, format, test)

**Core Game Logic:**
- `scripts/player.gd` — Player character state machine and mechanics
- `scripts/snake.gd` — Enemy behavior
- `scripts/world.gd` — World/area management
- `scripts/campfire.gd` — Interactive object pattern example
- `scripts/collectable.gd` — Item collection pattern

**Component System:**
- `scripts/health_component.gd` — Reusable HP system
- `scripts/hitbox_component.gd` — Reusable damage detection
- `scripts/PlayerDetectionArea.gd` — Reusable enemy awareness

**Data Models:**
- `scripts/resources/inventory.gd` — Weight-based inventory with stacking
- `scripts/resources/inventory_slot.gd` — Individual item stack
- `scripts/resources/item.gd` — Base item definition
- `scripts/resources/attack.gd` — Combat stats

**UI/Presentation:**
- `scripts/inventory_ui.gd` — Inventory panel controller
- `scripts/health_bar.gd` — HP bar display
- `scripts/advanced_camera.gd` — Camera shake effects

**Services:**
- `scripts/background_music.gd` — Autoload singleton for audio management

**Tests:**
- `tests/unit/test_inventory.gd` — Comprehensive inventory logic tests (186 cases)
- `tests/unit/test_inventory_slot.gd` — Slot-level tests
- `tests/unit/test_health_component.gd` — Health/damage tests
- `tests/unit/test_campfire.gd` — Campfire interaction tests

## Naming Conventions

**Files:**
- Scene files: `snake_case.tscn` (e.g., `player.tscn`, `health_component.tscn`)
- Script files: `snake_case.gd` (e.g., `player.gd`, `health_component.gd`)
- Resource files: `snake_case.tres` or `.res` (e.g., animations in `animations/` directory)
- Test files: `test_<system>.gd` (e.g., `test_inventory.gd`, `test_health_component.gd`)

**Directories:**
- Scene collections: lowercase plural or singular (e.g., `scenes/`, `components/`)
- Feature domains: lowercase (e.g., `scripts/`, `music/`, `art/`)
- Subdirectories: descriptive lowercase (e.g., `art/characters/`, `art/tilesets/`)

**GDScript Classes:**
- Class names (via `class_name`): `PascalCase` for reusable/exportable classes
  - Examples: `Player`, `Snake`, `HealthComponent`, `HitboxComponent`, `Inventory`, `Item`, `Attack`, `Collectable`
- Local/attached scripts: May omit `class_name` for scene-specific logic
  - Examples: `world.gd` (extends Node2D, no class_name), `inventory_ui.gd` (extends Control, no class_name)

**Variables/Methods:**
- Variables: `snake_case` (e.g., `health`, `max_health`, `current_weight`, `inventory`)
- Functions/Methods: `snake_case` (e.g., `damage()`, `insert()`, `collect()`, `increase_health()`)
- Signals: `snake_case` (e.g., `health_depleated`, `damage_taken`, `dead`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `NOISE_SPEED`, `DEFAULT_MAX_STACK`)
- Enums: `PascalCase` (e.g., `PlayerStates`, `Category`)
- Enum values: `UPPER_SNAKE_CASE` (e.g., `MOVE`, `HIT`, `DEAD`)

**Exported Variables:**
- Prefix: `@export` annotation (configurable in Inspector)
- Pattern: `var <name>: <Type>` with clear purpose
- Examples: `@export var speed: float`, `@export var max_health: int`, `@export var attack: Attack`

**Node References:**
- Pattern: `@onready var <name> = $<NodePath>` (cached on _ready)
- Examples:
  - `@onready var animation_tree: AnimationTree = $AnimationTree`
  - `@onready var health_component: HealthComponent = $HealthComponent`

## Where to Add New Code

**New Feature (e.g., weapon system, new mechanic):**
- Primary code: `scripts/<feature_name>.gd` (e.g., `scripts/sword.gd` for weapon)
- If reusable component: `components/<feature_name>.tscn` + `scripts/<feature_name>.gd`
- Data model: `scripts/resources/<feature_name>.gd` if needed
- Scene: `scenes/<feature_name>.tscn`
- Tests: `tests/unit/test_<feature_name>.gd`

**New Component/Module:**
- Implementation: `scripts/<component_name>.gd` with `class_name ComponentName`
- Scene wrapper: `components/<component_name>.tscn`
- Attach as child to entities that need it
- Export interface via @export for parent to configure
- Pattern: Health, Hitbox, Animation Damage examples

**Utilities/Helpers:**
- Shared helpers: `scripts/utils/` or `scripts/helpers/` (not yet used—create as needed)
- Example: If multiple systems need a common algorithm, extract to `scripts/utils/algorithm_name.gd`

**Interactive Objects:**
- Pattern: Base class or mixin approach
- Example: `scripts/campfire.gd`, `scripts/medicpack.gd` (both StaticBody2D with interaction logic)
- Add to world via scene instantiation, hook into `_on_interact_area_body_entered()`

**State Changes/Transitions:**
- Location: Entity's main script (e.g., Player state machine in `scripts/player.gd`)
- Pattern: Enum-based state machine with match statement in _physics_process()
- Signals: Emit from components; entities listen and respond

**Resource/Data Definitions:**
- Location: `scripts/resources/<name>.gd` extending Resource
- Pattern: Use `@export` for inspector configuration
- Example: New item type → `scripts/resources/new_item_type.gd extends Item`

## Special Directories

**tests/unit/**
- Purpose: Unit tests for pure logic
- Generated: No (manually written)
- Committed: Yes (part of codebase)
- Dependencies: GUT framework (installed via `make install-gut`)

**animations/**
- Purpose: Godot animation resource files
- Generated: Partially (by Godot editor when saving animations)
- Committed: Yes (if manually created .tres files)

**.godot/**
- Purpose: Engine cache and editor state
- Generated: Yes (automatically by Godot editor)
- Committed: No (in .gitignore)

**addons/gut/**
- Purpose: GUT testing framework
- Generated: No (external dependency)
- Committed: No (in .gitignore, installed via `make install-gut`)

**bin/venv/**
- Purpose: Python virtual environment for gdtoolkit (linting)
- Generated: Yes (by pip)
- Committed: No (in .gitignore)

---

*Structure analysis: 2026-03-10*
