# Stack Research

**Domain:** Godot 4 game Save & Load
**Researched:** 2026-03-30
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.3 | Game engine and runtime | `project.godot` declares `"4.3"`. Do not downgrade. |
| GDScript | 4.x | All save/load logic | Engine-native; Resource classes serialise cleanly. |
| `FileAccess` | built-in | File I/O to `user://save.json` | Godot 4 standard; `WRITE` truncates, `READ` reads. |
| `JSON` | built-in | Serialise/deserialise save data | `JSON.stringify(dict)` for write, `JSON.parse_string(text)` for read. Returns `null` on invalid JSON — always guard. |

### New Autoloads Required

| Autoload | Script | Purpose |
|----------|--------|---------|
| `SaveManager` | `scripts/save_manager.gd` | Owns save/load orchestration. Must be Autoload (not wired in world.gd) because `world.gd` is freed on `reload_current_scene()`. Precedent: `BackgroundMusic` autoload. |
| `ItemRegistry` | `scripts/item_registry.gd` | Maps `StringName id → Item Resource`. Required for deserialising item ids back to typed Resource instances. Does not exist yet — must be built first. |

### Supporting Libraries (unchanged)

| Library | Version | Purpose |
|---------|---------|---------|
| GUT | 9.3.0 | Unit testing — wrap `FileAccess` in injectable `SaveFileIO` for testability |
| gdtoolkit | 4.* | Lint and format — `make lint` + `make format-check` |

## Serialisation Pattern

**Serialise by id, not by value.** Items are `.tres` assets with stable `StringName id`. Save file stores `{"id": "sword_01", "qty": 1}`. `ItemRegistry` resolves ids to Resource instances on load.

**Mutate in-place on load — never replace Resource instances.** `world.gd._ready()` connects `player.inventory` and `player.equipment_data` to the UI. Replacing those instances after wiring silently breaks signal subscriptions. `Inventory.from_dict()` and `EquipmentData.from_dict()` mutate the existing instance and emit signals — UI refreshes automatically.

**Atomic write pattern (prevent corruption):**
```gdscript
# Write to .tmp, verify, then rename
var tmp_path = "user://save.tmp"
var save_path = "user://save.json"
var file = FileAccess.open(tmp_path, FileAccess.WRITE)
file.store_string(JSON.stringify(data))
file.close()
var verify = FileAccess.open(tmp_path, FileAccess.READ)
var parsed = JSON.parse_string(verify.get_as_text())
verify.close()
if parsed != null:
    DirAccess.rename_absolute(tmp_path, save_path)
```

## Integration Points with Existing Code

| Existing file | Change required |
|---------------|-----------------|
| `scripts/resources/inventory.gd` | Add `to_dict()` and `from_dict(data, registry)` — mutates in place |
| `scripts/resources/equipment_data.gd` | Add `to_dict()` and `from_dict(data, registry)` — mutates in place |
| `scripts/health_component.gd` | Add `load_health(value: int)` — bypasses `_ready()` init |
| `scripts/collectable.gd` | Add `@export var collectable_id: StringName` and `collected(id)` signal |
| `scripts/snake.gd` | Add `@export var enemy_id: StringName` |
| `scripts/world.gd` | Track collected ids + dead enemy ids; call load last in `_ready()` |
| `scripts/player.gd` | `global_position` serialised as `{"x": float, "y": float}` |
| **New** | `scripts/save_manager.gd` (Autoload), `scripts/item_registry.gd` (Autoload) |

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `FileAccess` + `JSON` | `ResourceSaver` / `.tres` | Cannot encode non-Resource data (world state arrays); binary format hard to debug |
| `FileAccess` + `JSON` | `ConfigFile` | Cannot encode nested object graphs; designed for flat key-value settings |
| `FileAccess` + `JSON` | Third-party save library | Explicitly constrained in PROJECT.md — no addons beyond GUT |
| Autoload `SaveManager` | Wiring save in `world.gd` | `world.gd` freed on `reload_current_scene()` (triggered by `player.die()`). Autoload survives scene reloads. |
| Mutate in-place | Replace Resource instances | Replacing breaks signal subscriptions wired in `world.gd._ready()` |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `ResourceSaver` | Cannot encode world state; binary by default | `FileAccess` + `JSON.stringify` |
| `ConfigFile` | Flat key-value only | `FileAccess` + `JSON` |
| Third-party addons | PROJECT.md constraint | Built-in Godot APIs only |
| Store Item Resource objects in JSON | `JSON.stringify` won't serialise them | Store `item.id` StringName, resolve via `ItemRegistry` |
| `FileAccess.WRITE` directly to final path | Truncates on open — partial write = corrupt file | Write to `.tmp`, verify, rename |

---
*Stack research for: Godot 4 Save & Load*
*Researched: 2026-03-30*
