# Technology Stack

**Analysis Date:** 2026-03-10

## Languages

**Primary:**
- GDScript 4.3 - All game logic, UI, and resource systems

**Secondary:**
- Not applicable

## Runtime

**Environment:**
- Godot Engine 4.2.2+ (configured in `project.godot` and `Makefile`)

**Package Manager:**
- Not applicable (Godot uses scene and script files directly)
- Lockfile: Not applicable

## Frameworks

**Core:**
- Godot Engine 4.2.2 - Game engine and runtime
  - Features enabled: Forward Plus renderer
  - Viewport stretch mode: integer scaling

**Testing:**
- GUT (Godot Unit Test) 9.3.0 - Unit testing framework
  - Location: `addons/gut/`
  - Configuration: Headless test runner with XML output
  - Config file: `addons/gut/gut_cmdln.gd`

**Build/Dev:**
- gdtoolkit 4.* - GDScript linting and formatting
  - Lint tool: gdlint
  - Format tool: gdformat
  - Config: `.gdlintrc` (max-line-length: 120)

## Key Dependencies

**Critical:**
- GUT 9.3.0 - Unit testing framework for GDScript
  - Installed locally via `make install-gut`
  - git-ignored in `.gitignore`

**Infrastructure:**
- Godot built-in Audio system - Background music via `AudioStreamPlayer`
- Godot built-in Physics2D - Character movement and collision
- Godot built-in AnimationTree - Character animation state machine
- Godot built-in Signal system - Event-driven communication

## Configuration

**Environment:**
- Configured via `project.godot` (Godot project configuration file)
- Input mappings defined in `[input]` section: left, right, up, down, hit, interact, inventory, jump
- Physics layers defined in `[layer_names]` for 2D physics (layers 2-5)

**Build:**
- `Makefile` - Build automation for linting, formatting, and testing
- `project.godot` - Main Godot engine configuration
- `.gdlintrc` - gdtoolkit linting configuration

## Platform Requirements

**Development:**
- Godot Engine 4.2.2+ binary
- Python 3.x (for gdtoolkit virtual environment)
- Make (for build commands)
- macOS (symlinks to /Applications/Godot.app/Contents/MacOS/Godot) or Linux x86_64
- Optional: Godot GUI editor for scene editing

**Production:**
- Godot Engine 4.2.2+ runtime for game execution
- Target platforms: Desktop (macOS, Linux, Windows via Godot export)

---

*Stack analysis: 2026-03-10*
