# Architecture Research

**Domain:** Godot 4 game Save & Load integration
**Researched:** 2026-03-30
**Confidence:** HIGH (direct codebase inspection)

## Integration with Existing Architecture

### Where SaveManager Lives: Autoload

**Decision:** `SaveManager` must be an Autoload singleton, not wired into `world.gd`.

**Why:** `world.gd` is freed on `reload_current_scene()`, which is triggered by `player.die()` in the existing death flow. Any save state stored in `world.gd` would be destroyed on player death. `BackgroundMusic` autoload is the direct precedent.

```gdscript
# scripts/save_manager.gd
extends Node

const SAVE_PATH = "user://save.json"

func save_game(player: Node, world: Node) -> void: ...
func load_game(player: Node, world: Node) -> void: ...
func has_save() -> bool: ...
```

### ItemRegistry: New Prerequisite Autoload

**Decision:** `ItemRegistry` is a new Autoload that maps `StringName id → Item Resource`.

**Why:** Items are `.tres` Resource assets. `JSON.stringify` cannot serialise Resource objects. The save file stores `item.id` (StringName). On load, `ItemRegistry.get_item(id)` returns the typed Resource. Without this, deserialisation cannot reconstruct typed items.

```gdscript
# scripts/item_registry.gd
extends Node

@export var items: Array[Item] = []  # Populated in Inspector with all .tres assets
var _registry: Dictionary = {}

func _ready() -> void:
    for item in items:
        _registry[item.id] = item

func get_item(id: StringName) -> Item:
    if not _registry.has(id):
        push_warning("ItemRegistry: unknown id '%s'" % id)
        return null
    return _registry[id]
```

### Resource Serialisation: Mutate In-Place

**Decision:** `Inventory.from_dict()` and `EquipmentData.from_dict()` mutate the existing instance. Never replace the Resource instance.

**Why:** `world.gd._ready()` stores references to `player.inventory` and `player.equipment_data` and passes them to UI nodes. Replacing the instance after wiring silently orphans the UI. Mutating in-place triggers `inventory_changed` / `equipment_changed` signals — the UI refreshes automatically.

**Why direct slot assignment instead of `insert()`:** `insert()` applies weight budget and stacking rules. On load, the save file already represents valid state — re-applying insert rules would reject items when total weight recalculates, causing data loss.

### HealthComponent: One New Method

`HealthComponent.health` is a runtime var, not `@export`. It's only set to `max_health` in `_ready()`. Save/load needs a bypass:

```gdscript
func load_health(value: int) -> void:
    health = clampi(value, 0, max_health)
    health_changed.emit(health, max_health)
```

### World State Tracking

**Collectables:** `collectable.gd` already calls `add_to_group("collectables")`. Changes needed:
1. Add `@export var collectable_id: StringName` to `collectable.gd`
2. Emit `collected(collectable_id)` signal when picked up
3. `world.gd` connects to each collectable's `collected` signal, appends to `var collected_ids: Array[StringName]`
4. On load: find matching collectable by id in group, call `queue_free()`

**Enemies:** Same pattern with `enemy_id: StringName` on `snake.gd` and `dead_enemy_ids` array in `world.gd`.

### Autosave Triggers

**Campfire:** One line in `campfire.gd`'s sleep interact handler:
```gdscript
SaveManager.save_game(player_ref, world_ref)
```

**Area transition:** Deferred to avoid mid-transition state:
```gdscript
call_deferred("_do_autosave")
```

**Guard:** All triggers check `if player.current_state == Player.State.DEAD: return`.

### Load Timing

`SaveManager.load_game()` must be called **last** in `world.gd._ready()`, after all `set_*()` wiring calls. This ensures:
1. `inventory_ui` is subscribed to `inventory_changed` before inventory is mutated
2. `hud_strip` is subscribed to `equipment_changed` before equipment is restored
3. All signals fire into live subscribers, not void

## Suggested Build Order (10 Steps → 4 Phases)

| Step | What | Why This Order |
|------|------|----------------|
| 1 | `ItemRegistry` autoload | Prerequisite for all `from_dict()` calls |
| 2 | `Inventory.to_dict()` / `from_dict()` | Pure functions, fully unit-testable |
| 3 | `EquipmentData.to_dict()` / `from_dict()` | Same pattern as Inventory |
| 4 | `HealthComponent.load_health()` | One-line addition, unit-testable |
| 5 | `SaveManager` write path only | Verify JSON output before any load logic |
| 6 | `SaveManager` load path (position + health) | Simple restore first |
| 7 | Full inventory + equipment round-trip | Highest-risk step; run full GUT suite |
| 8 | World state: collectables | Add `collectable_id` + `collected` signal + tracking |
| 9 | World state: enemies | Add `enemy_id` + dead-enemy suppression |
| 10 | Autosave triggers + polish | Campfire + area transition wiring |

**Phase mapping:**
- **Phase 9:** Steps 1–4 — ItemRegistry + Resource serialisation (pure logic, all unit-testable)
- **Phase 10:** Steps 5–6 — SaveManager + player round-trip (first file I/O)
- **Phase 11:** Steps 7–9 — Full inventory/equipment + world state (integration, highest complexity)
- **Phase 12:** Step 10 — Autosave triggers + polish

## New vs Modified Files

### New Files

| File | Type | Purpose |
|------|------|---------|
| `scripts/save_manager.gd` | Autoload | Save/load orchestration |
| `scripts/item_registry.gd` | Autoload | `StringName id → Item` mapping |
| `tests/unit/test_save_manager.gd` | Test | Unit tests for serialisation round-trips |
| `tests/unit/test_item_registry.gd` | Test | Unit tests for registry lookup |

### Modified Files

| File | Change |
|------|--------|
| `scripts/resources/inventory.gd` | Add `to_dict()` + `from_dict()` |
| `scripts/resources/equipment_data.gd` | Add `to_dict()` + `from_dict()` |
| `scripts/health_component.gd` | Add `load_health(value: int)` |
| `scripts/collectable.gd` | Add `collectable_id: StringName` + `collected` signal |
| `scripts/snake.gd` | Add `enemy_id: StringName` |
| `scripts/world.gd` | Add world state tracking arrays + load call in `_ready()` |
| `scripts/campfire.gd` | Add save trigger to sleep interaction |
| `project.godot` | Register `SaveManager` + `ItemRegistry` as Autoloads |

## Open Questions

- `gold_key` scene — does it have a stable `collectable_id` already? Audit at implementation time.
- `lake_world.gd` is listed as potentially orphaned in PROJECT.md — does it have collectables that need tracking? Audit before world-state phase.
- Save file versioning: add `"version": 1` key now. When Hunger & Stamina ships, migration logic will be needed — flag in future milestone.

---
*Architecture research for: Godot 4 Save & Load integration*
*Researched: 2026-03-30*
