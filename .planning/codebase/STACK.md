# Technology Stack

**Analysis Date:** 2025-01-24

## Languages

**Primary:**
- GDScript (Godot 4.3 compatible) - Used for all game logic, components, and UI scripts.

**Secondary:**
- Python 3.x - Used for development tooling (gdtoolkit for linting).
- Shell (Bash/Makefile) - Used for automation tasks (testing, linting).

## Runtime

**Environment:**
- Godot Engine 4.3 - Primary game engine and runtime.
- Forward Plus renderer - Used for 3D/Advanced 2D rendering.

**Package Manager:**
- None for GDScript (Godot doesn't use one by default).
- pip (Python) - Used for `gdtoolkit`.
- GUT (Godot Unit Test) - Installed via Makefile as an addon.

## Frameworks

**Core:**
- Godot Engine 4.3 - Core framework for nodes, signals, and resources.

**Testing:**
- GUT (Godot Unit Test) 9.x - Used for unit and integration testing.
- gdtoolkit - Used for linting (`gdlint`) and static analysis.

**Build/Dev:**
- Makefile - Orchestrates testing, linting, and installation.

## Key Dependencies

**Critical:**
- `addons/gut/` - Essential for the testing suite.

**Infrastructure:**
- `project.godot` - Central configuration for the Godot engine.
- `.gdlintrc` - Configuration for GDScript linting.

## Configuration

**Environment:**
- `project.godot` contains application name, main scene, and input map.
- Autoloads (Singletons):
    - `BackgroundMusic`: `res://scenes/background_music.tscn`
    - `ItemRegistry`: `res://scripts/item_registry.gd`
    - `SaveManager`: `res://scripts/save_manager.gd`

**Build:**
- No traditional build script; Godot exports are handled via the editor or CLI.
- `Makefile` provides `test` and `lint` targets.

## Platform Requirements

**Development:**
- Godot Engine 4.3+
- Python 3.x (for linting)

**Production:**
- Desktop (Windows/Linux/macOS) via Godot Export.
- Web (HTML5) via Godot Export.

---

*Stack analysis: 2025-01-24*
