# Codebase Structure

**Analysis Date:** 2025-01-24

## Directory Layout

```
open-world/
├── addons/             # Godot addons (e.g., GUT)
├── animations/         # Pre-baked Animation Resources (.res)
├── art/                # Raw assets (PNG, WebP)
│   ├── characters/     # Player and NPC sprites
│   ├── items/          # Item icons
│   └── tilesets/       # Environment textures
├── components/         # Reusable scene components (.tscn)
├── docs/               # Project documentation (Markdown)
├── music/              # Audio files (WAV)
├── resources/          # Godot Resource instances (.tres)
│   └── items/          # Individual item data
├── scenes/             # Game scenes (.tscn) and some misplaced scripts (.gd)
├── scripts/            # Main logic files (.gd)
│   └── resources/      # Custom Resource class definitions
└── tests/              # Test suite (GUT-based)
    └── unit/           # Unit tests
```

## Directory Purposes

**`components/`:**
- Purpose: Building blocks for entities.
- Contains: Scenes with logic attached that can be instanced within other scenes.
- Key files: `health_component.tscn`, `hitbox_component.tscn`.

**`scripts/`:**
- Purpose: Game logic and behaviors.
- Contains: GDScript files for players, enemies, and world logic.
- Key files: `player.gd`, `snake.gd`, `item_registry.gd`.

**`resources/`:**
- Purpose: Data-driven design storage.
- Contains: `.tres` files which are instances of the classes in `scripts/resources/`.
- Key files: `sword.tres`, `axe.tres`.

**`tests/`:**
- Purpose: Automated quality assurance.
- Contains: GDScript files extending `GutTest`.
- Key files: `test_inventory.gd`, `test_player_state.gd`.

## Key File Locations

**Entry Points:**
- `scenes/world.tscn`: Main entry point (specified in `project.godot`).

**Configuration:**
- `project.godot`: Engine settings, input mapping, and autoloads.
- `.gdlintrc`: Coding style rules for gdtoolkit.

**Core Logic:**
- `scripts/player.gd`: Central player behavior script.
- `scripts/save_manager.gd`: Serialization and local storage logic.

**Testing:**
- `tests/unit/`: Root directory for all unit tests.

## Naming Conventions

**Files:**
- Snake Case: `player_detection_component.tscn`, `inventory_ui.gd`.

**Directories:**
- Snake Case: `tilesets/`, `unit_tests/`.

## Where to Add New Code

**New Feature:**
- Primary code: `scripts/` (for behavior) or `components/` (if modular).
- Tests: `tests/unit/test_[feature_name].gd`.

**New Component/Module:**
- Implementation: `components/[component_name].tscn` and `scripts/[component_name].gd`.

**Utilities:**
- Shared helpers: `scripts/` (as Autoloads if global, or static classes).

## Special Directories

**`.godot/`:**
- Purpose: Internal engine cache (imported assets, shader cache).
- Generated: Yes.
- Committed: No (in `.gitignore`).

**`addons/gut/`:**
- Purpose: The Godot Unit Test framework.
- Generated: No.
- Committed: Yes.

---

*Structure analysis: 2025-01-24*
