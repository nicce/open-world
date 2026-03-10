# Testing Patterns

**Analysis Date:** 2026-03-10

## Test Framework

**Runner:**
- GUT (Godot Unit Test) 9.3.0
- Config: `addons/gut/gut_cmdln.gd` for headless execution
- Installation: `make install-gut` downloads from GitHub releases
- Installed to: `addons/gut/` (git-ignored)

**Assertion Library:**
- Built into GUT; uses GUT assertion methods: `assert_eq()`, `assert_true()`, `assert_false()`, `assert_signal_emitted()`, etc.

**Run Commands:**
```bash
make test                  # Run all tests headlessly with GUT, output JUnit XML to test_results.xml
make test                  # Auto-installs GUT and Godot binary if missing
```

**Test Configuration:**
- Headless mode: `--headless --import` and `--headless -s addons/gut/gut_cmdln.gd`
- Test discovery: `-gdir=res://tests -ginclude_subdirs` (recursive in `tests/` directory)
- Exit behavior: `-gexit` (terminates after tests complete)
- Logging: `-glog=1` (verbose output)
- Output format: JUnit XML to `test_results.xml` via `-gjunit_xml_file=test_results.xml`

## Test File Organization

**Location:**
- Co-located with source code in `tests/unit/` subdirectory
- Test files parallel source structure: `tests/unit/test_[component_name].gd`

**Naming:**
- `test_[system_name].gd` format
- Examples: `test_inventory.gd`, `test_inventory_slot.gd`, `test_campfire.gd`, `test_health_component.gd`
- Located in: `tests/unit/` directory

**Structure:**
```
tests/
└── unit/
    ├── test_inventory.gd
    ├── test_inventory_slot.gd
    ├── test_campfire.gd
    └── test_health_component.gd
```

## Test Structure

**Suite Organization:**
```gdscript
extends GutTest

var _inventory: Inventory

func before_each() -> void:
	_inventory = _make_inventory()

func test_insert_single_item_returns_zero_remaining() -> void:
	var wood = _make_item("Wood")
	assert_eq(_inventory.insert(wood), 0)

func test_insert_stacks_same_item() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 3)
	_inventory.insert(wood, 4)
	assert_eq(_inventory.slots[0].quantity, 7)
	assert_true(_inventory.slots[1].is_empty())
```

**Patterns:**

**Setup (before_each):**
- Called before each test function
- Creates fresh test instances: `_inventory = _make_inventory()`
- Initializes helper factories: `_make_item()`, `_make_inventory()`
- Example from `tests/unit/test_inventory.gd`:
```gdscript
func before_each() -> void:
	_inventory = _make_inventory()
```

**Teardown (after_each):**
- Called after each test function
- Cleans up resources: `_campfire.free()`
- Example from `tests/unit/test_campfire.gd`:
```gdscript
func after_each() -> void:
	_campfire.free()
```

**Assertion patterns:**
- Value equality: `assert_eq(actual, expected)` - `assert_eq(_inventory.slots[0].item, wood)`
- Boolean: `assert_true()`, `assert_false()` - `assert_true(_inventory.slots[1].is_empty())`
- Float approximation: `assert_almost_eq(actual, expected, tolerance)` - `assert_almost_eq(_inventory.current_weight(), 10.0, 0.001)`
- Signal checking: `watch_signals()`, `assert_signal_emitted()`, `assert_signal_not_emitted()`
- Example from `tests/unit/test_health_component.gd`:
```gdscript
func test_damage_emits_damage_taken_when_health_remains() -> void:
	var attack: Attack = autofree(Attack.new())
	attack.damage = 10
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_emitted(_health_component, "damage_taken")
```

## Mocking

**Framework:** GUT built-in stubbing and autofree utilities

**Patterns:**

**Object creation for testing:**
```gdscript
var _health_component: HealthComponent

func before_each() -> void:
	_health_component = HealthComponent.new()
	_health_component.max_health = 100
	add_child_autoqfree(_health_component)
```

**Dependency injection via constructor:**
```gdscript
func _make_inventory(slot_count: int = 5, weight: float = 100.0) -> Inventory:
	var inv = Inventory.new()
	inv.max_weight = weight
	for i in range(slot_count):
		inv.slots.append(InventorySlot.new())
	return inv
```

**Factory methods for test data:**
```gdscript
func _make_item(item_name: String, item_weight: float = 1.0) -> Item:
	var item = Item.new()
	item.name = item_name
	item.weight = item_weight
	return item
```

**Resource cleanup:**
- `autofree()` - Automatically free object after test
- `add_child_autoqfree()` - Add child and automatically free
- Example from `tests/unit/test_health_component.gd`:
```gdscript
var attack: Attack = autofree(Attack.new())
attack.damage = 30
```

**What to Mock:**
- External dependencies (Attack, Item resources)
- Heavy objects (scenes with many children)
- State that needs specific values

**What NOT to Mock:**
- Classes under test (test the real implementation)
- Godot built-in types (Vector2, Transform2D)
- Pure data Resource classes (Item, Attack) unless needed for specific test

## Fixtures and Factories

**Test Data:**
```gdscript
func _make_item(item_name: String, item_weight: float = 1.0) -> Item:
	var item = Item.new()
	item.name = item_name
	item.weight = item_weight
	return item

func _make_inventory(slot_count: int = 5, weight: float = 100.0) -> Inventory:
	var inv = Inventory.new()
	inv.max_weight = weight
	for i in range(slot_count):
		inv.slots.append(InventorySlot.new())
	return inv
```

**Location:**
- Inside test files at top of class after member variable declarations
- Private scope (prefix with `_` by convention): `func _make_item()`, `func _make_inventory()`
- Called from `before_each()` or within individual test functions

**Pattern - Parameterized fixtures:**
```gdscript
func _make_inventory(slot_count: int = 5, weight: float = 100.0) -> Inventory:
	var inv = Inventory.new()
	inv.max_weight = weight
	for i in range(slot_count):
		inv.slots.append(InventorySlot.new())
	return inv
```

## Coverage

**Requirements:** Not enforced (no coverage threshold in Makefile or gdlint config)

**Current Coverage:**
- Pure-logic Resource classes fully tested: `Inventory`, `InventorySlot`, `HealthComponent`, `Campfire` (inventory logic only)
- Tests exist for: `tests/unit/test_inventory.gd` (186 lines), `tests/unit/test_inventory_slot.gd` (118 lines), `tests/unit/test_campfire.gd` (88 lines), `tests/unit/test_health_component.gd` (89 lines)
- Scene-attached scripts with Godot lifecycle hooks largely untested (e.g., `Player._physics_process()`, `Snake`)

**View Coverage:**
```bash
# GUT outputs coverage info to console when running tests
make test 2>&1 | grep -A 10 "coverage"
```

## Test Types

**Unit Tests:**
- Scope: Single class or pure function, no scene dependencies
- Approach: Isolate component via factories and mocking
- Examples: `test_inventory.gd` (Inventory.insert/remove logic), `test_inventory_slot.gd` (stacking logic), `test_health_component.gd` (damage/healing)
- Pattern: Direct instantiation and method calls
```gdscript
func test_insert_single_item_returns_zero_remaining() -> void:
	var wood = _make_item("Wood")
	assert_eq(_inventory.insert(wood), 0)
```

**Integration Tests:**
- Not present in current codebase
- Would test interactions between components (e.g., Player + HealthComponent + Hitbox)
- Could be added to `tests/integration/` if needed

**E2E Tests:**
- Not used in codebase
- Godot projects typically rely on GUI editor testing for scene-level E2E

## Common Patterns

**Async Testing:**
Not used in current tests. GUT supports `await` for async operations:
```gdscript
# Example pattern (not in codebase yet):
func test_die_reloads_scene_after_delay() -> void:
	player.die()
	await get_tree().create_timer(2.1).timeout
	# Assert scene was reloaded
```

**Signal Testing:**
```gdscript
func test_damage_emits_health_depleated_when_health_reaches_zero() -> void:
	var attack: Attack = autofree(Attack.new())
	attack.damage = 100
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_emitted(_health_component, "health_depleated")

func test_damage_does_not_emit_damage_taken_on_lethal_hit() -> void:
	var attack: Attack = autofree(Attack.new())
	attack.damage = 100
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_not_emitted(_health_component, "damage_taken")
```

**Error Testing:**
```gdscript
# Tests that functions handle edge cases gracefully (no exceptions)
func test_insert_into_full_inventory_returns_remaining() -> void:
	var inv = _make_inventory(2)
	var wood = _make_item("Wood")
	inv.insert(wood, 10)
	inv.insert(wood, 10)
	var remaining = inv.insert(wood, 5)
	assert_eq(remaining, 5)  # 5 items not inserted due to capacity

func test_insert_into_empty_slots_array_returns_amount() -> void:
	var inv = Inventory.new()
	assert_eq(inv.insert(_make_item("Wood"), 3), 3)  # All items rejected, no slots
```

**Boundary Testing:**
```gdscript
func test_withdraw_wood_clamps_to_zero() -> void:
	_campfire.inventory = 2
	_campfire.withdraw_wood(5)
	assert_eq(_campfire.inventory, 0)  # Doesn't go negative

func test_increase_does_not_exceed_max_health() -> void:
	_health_component.increase(50)
	assert_eq(_health_component.health, 100)  # Clamped at max
```

## Definition of Done for Tests

Per CLAUDE.md, a task is not complete until:
1. `make lint` passes with no errors
2. `make test` passes with no failures
3. **New pure-logic functions have corresponding unit tests added under `tests/unit/`**

This means: any new public function added to Resource classes or pure-logic components must have unit tests. Scene-attached scripts with Godot lifecycle hooks (_ready, _process, etc.) do not require tests.

---

*Testing analysis: 2026-03-10*
