# Testing Patterns

**Analysis Date:** 2025-01-24

## Test Framework

**Runner:**
- GUT (Godot Unit Test) 9.2.1+
- Config: Managed via `.godot/` but executed via Makefile/CLI.

**Assertion Library:**
- GUT's internal assertion library (`assert_eq`, `assert_true`, etc.).

**Run Commands:**
```bash
make test              # Run all unit tests
make test-unit         # Run only unit tests
./addons/gut/gut_cmdline.sh -gdir=res://tests/unit # Direct command
```

## Test File Organization

**Location:**
- Separate: All tests are located in `tests/unit/`.

**Naming:**
- `test_[filename].gd`.

**Structure:**
```
tests/
└── unit/
    ├── test_player_state.gd
    ├── test_inventory.gd
    └── ...
```

## Test Structure

**Suite Organization:**
```gdscript
extends GutTest

# Class stubs for isolated testing
class MyStub:
    extends SomeNode
    func _ready(): pass

func before_each():
    # Setup code

func test_my_feature():
    # Arrange
    var obj = MyStub.new()
    
    # Act
    obj.do_something()
    
    # Assert
    assert_eq(obj.value, 10)
    obj.free()
```

**Patterns:**
- **Arrange, Act, Assert:** Standard structure.
- **Node Mocking:** Use of local subclasses (Stubs) to override `_ready()` and avoid scene tree dependencies during unit testing.
- **Manual Memory Management:** Always call `.free()` on objects created with `.new()` in tests to avoid memory leaks.

## Mocking

**Framework:** Manual Stubs and GUT's built-in `double()`/`stub()` (though manual stubs are preferred in the current codebase).

**Patterns:**
```gdscript
class PlayerStub:
	extends Player

	func _ready() -> void:
		pass  # Skip @onready assignments that require scene tree nodes.
```

**What to Mock:**
- Scene tree dependencies (anything using `$NodePath` or `get_node()`).
- Time-dependent operations (use `await` or mock timers).

**What NOT to Mock:**
- Pure logic (e.g., `Inventory.gd`).
- Resource-based calculations.

## Fixtures and Factories

**Test Data:**
Manual instantiation of resources or using `ItemRegistry`.
```gdscript
var inventory = Inventory.new()
var item = Item.new()
item.name = "Test Item"
item.weight = 1.0
inventory.items.append(item)
```

**Location:**
- Handled inline within tests or as helper methods in the test script.

## Coverage

**Requirements:** High coverage for core mechanics (Inventory, Combat logic, Save system).

**View Coverage:**
- Currently viewed via GUT's output in the console or `test_results.xml`.

## Test Types

**Unit Tests:**
- Focus on isolated logic in `scripts/`.
- Example: `test_inventory.gd`.

**Integration Tests:**
- Focus on interactions between components/resources.
- Example: `test_player_save_load.gd`.

**E2E Tests:**
- Not strictly used; GUT can do scene-based testing, but most tests focus on script logic.

## Common Patterns

**Async Testing:**
```gdscript
func test_async_operation():
    # Trigger async action
    await get_tree().create_timer(0.1).timeout
    assert_true(...)
```

**Error Testing:**
Testing return codes or signal emissions when invalid input is provided.

---

*Testing analysis: 2025-01-24*
