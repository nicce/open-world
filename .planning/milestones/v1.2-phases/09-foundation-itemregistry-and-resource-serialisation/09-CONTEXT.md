# Phase 9: Foundation — ItemRegistry and Resource Serialisation - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the pure data layer for save/load — no file I/O in this phase. Deliverables:
1. `ItemRegistry` autoload that maps a `StringName` id to its typed Item Resource
2. `Inventory.to_dict()` / `from_dict()` round-trip
3. `EquipmentData.to_dict()` / `from_dict()` round-trip
4. `HealthComponent.load_health(value)` bypass method

All logic must be pure and unit-tested with GUT. No SaveManager, no `user://` writes.

</domain>

<decisions>
## Implementation Decisions

### ItemRegistry — location and registration
- **D-01:** Script-only autoload: `scripts/item_registry.gd` registered in `project.godot` (no `.tscn` — pure data, no child nodes needed)
- **D-02:** Population mechanism: private `_build_registry()` function with a hardcoded dict of `StringName → preload("res://...")`. One line per item. Manual, but fully GUT-testable and auditable.
- **D-03:** Public interface: `get_item(id: StringName) -> Item` only. Population is a private implementation detail — callers never depend on how the dict is filled.
- **D-04:** Unknown id handling: log a warning with `push_warning()` and return `null` (REG-02). Does not crash.

### Inventory serialisation
- **D-05:** `to_dict()` output: sparse dict keyed by slot index (string key). Only occupied slots included. Shape: `{"slots": {"2": {"id": "sword", "qty": 1}, "7": {"id": "health_pack", "qty": 3}}}`
- **D-06:** `from_dict()` strategy: clear all slots to empty first, then iterate dict entries and assign item + quantity directly (bypasses `insert()` weight/stack rules — REG-01 lookup resolves id → Resource). Emits `inventory_changed` once after restore.

### EquipmentData serialisation
- **D-07:** `to_dict()` output: `{"weapon": "sword", "tool": null}` — id strings, null if unequipped (SER-03)
- **D-08:** `from_dict()` calls `equip_weapon()` / `equip_tool()` as-is (SER-04). Signals fire naturally. Since `SaveManager.load_game()` runs after `world.gd._ready()` wires the HUD, `equipment_changed` will reach the HUD strip and refresh it automatically — this is desirable, not a bug.

### HealthComponent
- **D-09:** `load_health(value: int)` sets `health = clampi(value, 0, max_health)` — clamped to prevent over-max HP from stale saves or Inspector edits (SER-05)
- **D-10:** `load_health()` calls `health_bar.update(health)` if `health_bar` is set — same pattern as `damage()` and `increase()`. Keeps bar in sync immediately.

### Claude's Discretion
- Exact GDScript method signatures beyond what's locked above
- Whether `_build_registry()` returns a `Dictionary` or populates an instance variable
- Unit test inner-class structure (follow existing GUT patterns)
- Whether `from_dict()` accepts `Dictionary` or `Variant` parameter type

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — REG-01, REG-02, SER-01–SER-05 acceptance criteria
- `.planning/ROADMAP.md` — Phase 9 goal and success criteria (§ Phase 9)

### Existing Resources to extend
- `scripts/resources/inventory.gd` — Inventory class shape; `slots: Array[InventorySlot]`, `insert()`, `remove()`
- `scripts/resources/inventory_slot.gd` — InventorySlot shape; `item: Item`, `quantity`, `max_stack`
- `scripts/resources/equipment_data.gd` — EquipmentData class; `equip_weapon()`, `unequip_weapon()`, `equip_tool()`, `unequip_tool()`
- `scripts/health_component.gd` — HealthComponent; `health`, `max_health`, `_ready()`, `damage()`, `increase()`
- `scripts/resources/item.gd` — Item base class; `id: StringName` is the serialisation key

### Wiring context (read before planning load ordering)
- `scripts/world.gd` — `_ready()` wiring order; SaveManager.load_game() must run last, after all `set_*()` calls

### Existing autoload pattern reference
- `scripts/background_music.gd` — Script-only autoload example (no `.tscn`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Inventory.clone()` — shows the pattern for iterating `slots` and creating copies; `from_dict()` will iterate similarly
- `EquipmentData.equip_weapon()` / `equip_tool()` — return the displaced item; `from_dict()` calls these directly, discarding the return value

### Established Patterns
- `@export var id: StringName` on all Item Resources — this is the serialisation key (DATA-01)
- `push_warning()` used elsewhere for non-fatal errors — follow for REG-02
- Signal-driven communication; `inventory_changed` emitted after bulk mutations
- `world.gd` as single wiring hub — all `set_*()` calls in `_ready()` before any load calls

### Integration Points
- `ItemRegistry` will be called by `Inventory.from_dict()` and `EquipmentData.from_dict()` to resolve ids
- `world.gd._ready()` will call `SaveManager.load_game()` as its last line (Phase 10) — this phase's APIs must be ready to be called from there
- Phase 10 will add SaveManager; Phase 11 will add full round-trip; this phase delivers only the serialisation primitives

</code_context>

<specifics>
## Specific Ideas

- The game is expected to grow to ~100–200 items. The hardcoded dict in `_build_registry()` is deliberately scoped as an interim approach. When item count becomes unwieldy, migrate to a folder scan (`DirAccess.get_files_at()`) or autoregistration — the `get_item(id)` public API stays unchanged.
- `from_dict()` on Inventory must clear all 15 slots before filling from the sparse dict — otherwise slots not in the save file retain their previous values across a load.

</specifics>

<deferred>
## Deferred Ideas

- **ItemRegistry folder scan migration** — When item count grows to ~50+, replace `_build_registry()` with a `DirAccess` scan of `res://items/`. Public interface unchanged. Tracked as future milestone improvement.

</deferred>

---

*Phase: 09-foundation-itemregistry-and-resource-serialisation*
*Context gathered: 2026-03-30*
