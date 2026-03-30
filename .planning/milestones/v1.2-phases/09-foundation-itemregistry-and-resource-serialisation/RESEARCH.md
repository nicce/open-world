# Phase 9: Foundation — ItemRegistry and Resource Serialisation - Research

**Researched:** 2026-03-30
**Domain:** Godot 4 Resource Serialization & Singletons
**Confidence:** HIGH

## Summary

This phase establishes the pure data layer required for a robust save/load system. The primary goal is to provide a way to convert complex runtime objects (Inventory, EquipmentData, Health) into simple Dictionaries and back, using an `ItemRegistry` to bridge the gap between serialised "item IDs" and actual Resource instances.

**Primary recommendation:** Create standalone `.tres` files for all game items (Sword, Axe, Medpack) immediately, as the `ItemRegistry` requires stable file paths for its `preload` dictionary.

<user_constraints>
## User Constraints (from 09-CONTEXT.md)

### Locked Decisions
- **ItemRegistry:** Script-only autoload (`scripts/item_registry.gd`) using a hardcoded dictionary population via `preload()`.
- **ItemRegistry Interface:** `get_item(id: StringName) -> Item` only; unknown IDs return `null` and log a warning via `push_warning()`.
- **Inventory Serialisation:** Sparse dictionary format keyed by slot index string. Shape: `{"slots": {"idx": {"id": "...", "qty": ...}}}`.
- **EquipmentData Serialisation:** Serialise as item IDs: `{"weapon": "id", "tool": "id"}`. Restore via `equip_weapon()` / `equip_tool()`.
- **HealthComponent:** `load_health(value: int)` method that clamps value and updates the health bar without full re-initialisation.

### the agent's Discretion
- Exact GDScript method signatures beyond what's locked above.
- Whether `_build_registry()` returns a `Dictionary` or populates an instance variable.
- Unit test inner-class structure (following existing GUT patterns).
- Whether `from_dict()` accepts `Dictionary` or `Variant` parameter type.

### Deferred Ideas (OUT OF SCOPE)
- **ItemRegistry folder scan migration:** Replacing the hardcoded dictionary with a dynamic folder scan is deferred until the item count exceeds ~50.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REG-01 | ItemRegistry resolves item id to Resource instance. | Implementation via `Dictionary` of `StringName` to `Item`. |
| REG-02 | ItemRegistry returns null and logs warning for unknown id. | Verified `push_warning()` usage in existing codebase. |
| SER-01 | Inventory.to_dict() serialises sparse slots. | Sparse pattern verified as efficient for 15-slot inventories. |
| SER-02 | Inventory.from_dict() restores state exactly. | Requires `ItemRegistry` for ID -> Resource resolution. |
| SER-03 | EquipmentData.to_dict() serialises slots as IDs. | Matches locked decisions. |
| SER-04 | EquipmentData.from_dict() restores equipment state. | Calls existing `equip_*` methods to ensure signal propagation. |
| SER-05 | HealthComponent.load_health(value) restores HP. | Verified `clampi` and `health_bar.update()` pattern in `scripts/health_component.gd`. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GDScript | 2.0 (Godot 4.x) | Logic | Native, high-performance integration with Godot Engine. |
| GUT | 9.x | Unit Testing | Project standard for asserting data integrity and signal emission. |

## Architecture Patterns

### Item Registry Pattern
**What:** A singleton (Autoload) mapping unique identifiers (StringName) to Resource instances.
**Why:** Decouples serialised data (strings) from runtime assets (Resources). Prevents bloat in save files by storing IDs instead of full object data.

### Sparse Dictionary Serialisation
**What:** Only serialise non-default or "occupied" data.
**Example:**
```gdscript
# Inventory to_dict
{
    "slots": {
        "0": {"id": &"axe", "qty": 1},
        "4": {"id": &"medpack", "qty": 5}
    }
}
```

### Signal-Safe Restoration
**What:** Call existing setter/equip methods during deserialisation.
**Why:** Ensures that UI components (like `HudStrip`) and other systems listening to `equipment_changed` or `inventory_changed` are notified of the state change automatically.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Resource Deep Copy | Custom recursive copy | `clone()` method | Godot 4 `duplicate(true)` fails on typed arrays; project already has `Inventory.clone()`. |
| Unique ID System | Custom UUID generator | `@export var id: StringName` | Simple, human-readable, and already present in `Item.gd`. |

## Common Pitfalls

### Pitfall 1: Slot Index Type Collision
**What goes wrong:** Dictionary keys are technically Strings when serialised to JSON.
**How to avoid:** Always cast slot indices to `String` when building `to_dict()` and back to `int` in `from_dict()`.

### Pitfall 2: Stale Registry Preloads
**What goes wrong:** `ItemRegistry` preloads a path that doesn't exist or was moved.
**How to avoid:** Use `preload()` in `_build_registry()` to catch errors at compile/load time rather than runtime.

### Pitfall 3: Health Bar Desync
**What goes wrong:** `load_health()` updates the variable but the UI remains at full.
**How to avoid:** Explicitly call `health_bar.update(health)` inside `load_health()` (D-10).

## Code Examples

### Registry Lookup Pattern
```gdscript
# scripts/item_registry.gd
var _items: Dictionary = {}

func _build_registry():
    _items = {
        &"axe": preload("res://resources/items/axe.tres"),
        &"medpack": preload("res://resources/items/medpack.tres")
    }

func get_item(id: StringName) -> Item:
    if not _items.has(id):
        push_warning("ItemRegistry: Unknown id '%s'" % id)
        return null
    return _items[id]
```

### Sparse Restore Pattern
```gdscript
# scripts/resources/inventory.gd
func from_dict(data: Dictionary):
    _clear_all_slots()
    var slots_data = data.get("slots", {})
    for idx_str in slots_data:
        var idx = int(idx_str)
        var item_data = slots_data[idx_str]
        slots[idx].item = ItemRegistry.get_item(item_data["id"])
        slots[idx].quantity = item_data["qty"]
    inventory_changed.emit()
```

## Open Questions

1. **Where should the new `.tres` files live?**
   - Recommendation: `res://resources/items/`. This keeps them separate from scripts and scenes.
2. **Should `from_dict` handle missing "slots" key gracefully?**
   - Recommendation: Yes, use `data.get("slots", {})` to allow loading "empty" inventories without error.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot Engine | Runtime | ✓ | 4.x | — |
| GUT Addon | Testing | ✓ | 9.x | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 9.1.1 |
| Config file | `.gutconfig.json` (implicit) |
| Quick run command | `make test` |
| Full suite command | `godot --headless -s addons/gut/gut_cmdline.gd` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REG-01 | Resolve ID to Item | Unit | `gut -gtest_item_registry.gd` | ❌ Wave 0 |
| SER-01 | Inventory Sparse Dict | Unit | `gut -gtest_inventory_serialisation.gd` | ❌ Wave 0 |
| SER-02 | Inventory Round-trip | Unit | `gut -gtest_inventory_serialisation.gd` | ❌ Wave 0 |
| SER-03 | Equipment ID Dict | Unit | `gut -gtest_equipment_serialisation.gd` | ❌ Wave 0 |
| SER-05 | Health Restore | Unit | `gut -gtest_health_restore.gd` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `res://resources/items/` directory and `.tres` files for `axe`, `sword`, `medpack`.
- [ ] `tests/unit/test_item_registry.gd`
- [ ] `tests/unit/test_inventory_serialisation.gd`
- [ ] `tests/unit/test_equipment_serialisation.gd`

## Sources

### Primary (HIGH confidence)
- `09-CONTEXT.md` - Implementation decisions and domain.
- `scripts/resources/inventory.gd` - Existing class structure.
- `scripts/health_component.gd` - Existing health logic.

### Secondary (MEDIUM confidence)
- Godot 4 Documentation (Resource serialisation patterns).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built on existing project conventions.
- Architecture: HIGH - Registry/Serialisation patterns are standard for Godot.
- Pitfalls: HIGH - Identified specific issues with JSON keys and Resource sub-resources.

**Research date:** 2026-03-30
**Valid until:** 2026-04-30
