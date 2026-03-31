# Coding Conventions

**Analysis Date:** 2025-01-24

## Naming Patterns

**Files:**
- Snake Case: `player_detection_component.gd`, `inventory_ui.tscn`.

**Functions:**
- Snake Case: `_ready()`, `_physics_process()`, `move()`, `on_player_state_reset()`.

**Variables:**
- Snake Case: `current_state`, `speed`, `health_component`.

**Types:**
- Pascal Case (class_name): `Player`, `Snake`, `HealthComponent`, `Inventory`.

## Code Style

**Formatting:**
- Indentation: Tabs (standard GDScript).
- Style: Follows Godot's official GDScript style guide.

**Linting:**
- Tool: `gdtoolkit` (specifically `gdlint`).
- Config: `.gdlintrc`.

## Import Organization

**Order:**
1. Engine built-ins (`extends`, `class_name`).
2. Signals.
3. Enums.
4. Constants.
5. `@export` variables.
6. Local variables.
7. `@onready` variables.
8. Life-cycle methods (`_init`, `_ready`, `_process`).
9. Custom methods.
10. Signal handlers.

**Path Aliases:**
- `res://`: Standard Godot root path alias. Used for all internal scene and resource loading.

## Error Handling

**Patterns:**
- `assert()`: Used for developer-only checks (e.g., `assert(collector.has_method("collect"))`).
- Return values: Methods returning an integer error code (0 for success).
- Null checks: Used for optional component references (e.g., `if health_bar:`).

## Logging

**Framework:** Godot's built-in `print()` and `printerr()`.

**Patterns:**
- Debug prints for game state changes.
- `printerr()` for unexpected failure conditions.

## Comments

**When to Comment:**
- Complexity: Explaining intricate logic.
- TODOs: Marking missing features or debt (e.g., `TODO: replace with signals`).
- Tests: Describing test scenarios and bug IDs (e.g., `CMBT-01`).

**JSDoc/TSDoc:**
- Not strictly used; GDScript 2.0's built-in documentation comments (`##`) are preferred for libraries.

## Function Design

**Size:** Functions are generally small and focused (single responsibility).

**Parameters:** Type-hinted (e.g., `delta: float`, `item: Item`).

**Return Values:** Type-hinted (e.g., `-> void`, `-> bool`).

## Module Design

**Exports:** Extensive use of `@export` for inspector configuration and dependency injection.

**Barrel Files:** Not applicable in GDScript (scenes/resources act as entry points).

---

*Convention analysis: 2025-01-24*
