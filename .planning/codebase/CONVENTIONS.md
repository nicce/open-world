# Coding Conventions

**Analysis Date:** 2026-03-10

## Naming Patterns

**Files:**
- `snake_case.gd` for all GDScript files
- Resource classes and scene-attached scripts follow same pattern: `inventory.gd`, `health_component.gd`, `player.gd`
- Example files: `scripts/player.gd`, `scripts/health_component.gd`, `scripts/resources/inventory.gd`

**Functions:**
- `snake_case` for all function names
- Signal handlers use `_on_[NodeName]_[SignalName]()` pattern: `_on_health_component_health_depleated()`, `_on_body_entered()`
- Utility functions follow standard snake_case: `current_weight()`, `can_stack()`, `take_damage()`
- Examples from codebase:
  - `func damage(attack: Attack)` in `scripts/health_component.gd`
  - `func insert(item: Item, amount: int = 1) -> int` in `scripts/resources/inventory.gd`
  - `func _physics_process(_delta)` in `scripts/player.gd`

**Variables:**
- `snake_case` for all variable names
- Private/internal variables: no underscore prefix (Godot convention uses `@onready` and `var` declarations)
- Examples: `var health_depleated: bool = false`, `var current_state = PlayerStates.MOVE`, `var inventory: int = 0`
- Member variables declared at class scope before functions
- Exported variables use `@export` annotation: `@export var speed: float = 80.0`, `@export var max_health: int`

**Types:**
- `PascalCase` for class names via `class_name` declaration at top of file
- Class names are nouns: `Player`, `Snake`, `HealthComponent`, `Inventory`, `InventorySlot`, `Attack`
- Enums in `PascalCase`: `enum PlayerStates { MOVE, HIT, DEAD }`
- Enum values in `UPPER_CASE`: `PlayerStates.MOVE`, `PlayerStates.HIT`
- Constants in `UPPER_CASE`: `const DEFAULT_MAX_STACK: int = 10` in `scripts/resources/inventory_slot.gd`

## Code Style

**Formatting:**
- Enforced by `gdformat` (gdtoolkit v4)
- Line length limit: 120 characters (configured in `.gdlintrc`)
- Indentation: automatic via gdformat
- Command to check: `make format-check`
- Command to auto-format: `make format`

**Linting:**
- Enforced by `gdlint` (gdtoolkit v4)
- Config file: `.gdlintrc` (only sets `max-line-length: 120`)
- Run with: `make lint`
- Project scripts in `scripts/`, `scenes/`, `components/` directories are linted

**Annotations:**
- `@export` for Inspector-editable variables: `@export var speed: float = 80.0`
- `@onready` for node references: `@onready var animation_tree: AnimationTree = $AnimationTree`
- `@onready` supports multiline: splits across lines when needed (see `scripts/player.gd` lines 14-16)
- Signal declarations: `signal health_changed(new_value: int)` (typed parameters supported)

## Import Organization

**Order:**
1. Class declaration: `class_name MyClass extends ParentClass` (top of file if present)
2. Signal declarations
3. Enums
4. Exported variables (`@export`)
5. Regular member variables (`var`)
6. `@onready` variables
7. Functions (lifecycle like `_ready()`, `_physics_process()` first, then public, then private/helpers)

**Path Aliases:**
- GDScript uses `res://` prefix for resource paths (Godot standard)
- Examples: `preload("res://scripts/campfire.gd")`, `load("res://scripts/campfire.gd")`
- No custom path aliases observed in codebase

**Example from `scripts/player.gd`:**
```gdscript
class_name Player extends CharacterBody2D

signal health_changed(new_value: int)

enum PlayerStates { MOVE, HIT, DEAD }

@export var speed: float = 80.0
@export var attack: Attack
@export var inventory: Inventory

var health_depleated: bool = false
var current_state = PlayerStates.MOVE

@onready var animation_tree: AnimationTree = $AnimationTree
@onready
var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var advanced_camera: AdvancedCamera = $AdvancedCamera
@onready var health_component: HealthComponent = $HealthComponent

func _physics_process(_delta):
	# ...
```

## Error Handling

**Assertions:**
- Used for preconditions and assumptions about state
- Example: `assert(collector.has_method("collect"), "Player script should have a collect method.")` in `scripts/collectable.gd:25`
- Signals error message if assertion fails; aborts in debug, warning in release

**Null checks:**
- Guard clauses for optional references
- Example: `if health_bar:` and `if health_component:` in `scripts/health_component.gd` and `scripts/hitbox_component.gd`
- No null propagation operators used

**Type hints:**
- Strong typing throughout: `func damage(attack: Attack)`, `func insert(item: Item, amount: int = 1) -> int`
- Return types declared with `->`: `func current_weight() -> float`, `func is_empty() -> bool`
- Typed signals: `signal health_changed(new_value: int)`

**Pattern - Return codes for partial success:**
- Functions return remaining/unprocessed count to indicate partial success
- Examples: `insert()` returns `int` for items that didn't fit, `remove()` returns count removed
- Avoids exceptions; allows caller to handle overflow gracefully

## Logging

**Framework:** Console logging via `print()` statements

**Patterns:**
- No explicit logging library used in source code
- Debug output via `print()` statements in development
- Error messages passed to `assert()` for validation failures
- Example: assertion messages in `scripts/collectable.gd`

## Comments

**When to Comment:**
- Explain "why", not "what" (code is self-documenting)
- Used sparingly; clear function names and types reduce need for comments
- Comments precede the code they describe or appear inline for clarity

**Examples observed:**
- Algorithm explanation: "# Try stacking into existing slots first" in `scripts/resources/inventory.gd:24`
- Data structure clarification: "# lights the fire and light animation if not already on" in `scripts/campfire.gd:50`
- Not every function has comments; comments are reserved for non-obvious logic

**Function Documentation:**
- TSDoc/JSDoc style not used
- Function signatures are self-documenting via type hints
- Complex functions have inline comments explaining logic blocks

## Function Design

**Size:**
- Functions kept concise and focused
- Examples: `is_empty() -> bool` (single line), `damage()` (4-8 lines of logic)
- Longer functions decomposed: `insert()` in `scripts/resources/inventory.gd` has two clear phases (stacking, then empty slots)

**Parameters:**
- Named parameters with type hints: `func insert(item: Item, amount: int = 1) -> int`
- Default parameters supported: `amount: int = 1`
- Parameter order: required first, optional with defaults after

**Return Values:**
- Always typed with `->`: `-> int`, `-> float`, `-> bool`
- Single return value (no multiple returns via tuples); use return codes for partial results
- Nullable returns: `var item: Item` can be null; checked with `if item == null` or `is_empty()`

## Module Design

**Exports:**
- All reusable logic placed in `scripts/resources/` for Resource-based classes
- Component-based functionality in `scripts/` root or organized by domain
- Main script attached to scene; helpers can be standalone or scene-attached

**Barrel Files:**
- No barrel files (index files exporting everything) used
- Each script is independent; imported via `preload()` or attached as node child

**Resource Classes:**
- Extend `Resource` class: `class_name Inventory extends Resource`
- Located in `scripts/resources/`
- Examples: `inventory.gd`, `inventory_slot.gd`, `item.gd`, `weapon_item.gd`, `health_item.gd`, `attack.gd`
- Contain pure data and logic; no scene dependencies

**Scene-attached Scripts:**
- Extend scene node type: `class_name Player extends CharacterBody2D`
- Located in `scripts/` root
- Can reference child nodes via `@onready`
- Examples: `player.gd`, `snake.gd`, `health_component.gd`, `hitbox_component.gd`

---

*Convention analysis: 2026-03-10*
