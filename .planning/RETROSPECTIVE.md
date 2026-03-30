# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.1 — Equipment Slots

**Shipped:** 2026-03-27
**Phases:** 4 (Phases 5–8) | **Plans:** 9 | **Timeline:** 9 days

### What Was Built

- `EquipmentData` Resource with weapon/tool slots, displaced-item return contract, and `equipment_changed` signal — pure Resource, no scene tree dependency
- Right-click context menu on bag slots with item-type-aware actions (Equip/Consume/Drop) — PopupMenu with named const IDs + `id_pressed`
- Atomic equip/unequip transaction in InventoryUI — remove-before-equip ordering prevents dual-ownership; displaced weapon returns to bag automatically
- Player `hit()` reads equipped weapon damage at call time with `int()` cast; fist fallback when no weapon
- Always-visible HUD strip (48×48 W/T slots anchored bottom-center) subscribing to `equipment_changed` with modulate dimming + gold border
- HUD strip right-click context menu (Unequip/Drop) with viewport-safe clamped positioning

### What Worked

- **TDD pattern (RED → GREEN)**: Every data-layer plan started with failing tests. Catching type errors (float vs int for damage), API contracts (empty-slot equip must still emit signal), and transaction invariants before implementation made the code correct on first pass.
- **world.gd as single wiring hub**: Centralising all `set_*()` calls in `_ready()` meant zero wiring bugs across Phases 6–8. New nodes just added one line.
- **EquipmentData as a separate Resource**: Keeping equipment data out of Inventory prevented grid corruption and kept weight accounting clean. The right call validated immediately.
- **Stub-forward planning**: Phase 5 shipped `MENU_EQUIP: pass` — Phase 6 just replaced it. No rework, clean handoff.
- **Viewport-safe popup pattern**: Extracted once in Phase 8, applied to both HudStrip and InventoryUI consistently.

### What Was Inefficient

- **Phase 8 had three plans for one feature**: HUD context menu (08-01), wiring (08-02), and verification (08-03) could have been two plans. The split added overhead without proportional clarity gain.
- **STATE.md decisions accumulate duplicates**: The decisions log in STATE.md developed duplicate entries across phases (same PopupMenu decision logged 3 times). Future: deduplicate or summarise at phase start.

### Patterns Established

- **Atomic transaction ordering**: Remove from source BEFORE placing in destination — prevents dual-ownership invariant violations. Applies to any future inventory-like system.
- **set_*() + immediate paint**: Any node accepting `set_equipment_data(ed)` should connect the signal then immediately call `_on_equipment_changed()` to paint initial state. Prevents empty-first-frame flicker.
- **PopupMenu const IDs**: Always use `id_pressed` + named integer consts (`MENU_FOO = 0`). Never `index_pressed`. Required when menu items are conditionally added.
- **Viewport-safe popup clamping**: Use `get_contents_minimum_size()` with `Vector2(120, 60)` fallback guard before any `popup()` call.
- **Sibling, not child**: Any HUD element that must survive inventory close should be a sibling of InventoryUI in the CanvasLayer, not a child.

### Key Lessons

1. **Data layer first, UI second**: Building `EquipmentData` in Phase 5 with full unit tests made Phases 6–8 mechanical. Every subsequent phase just wired to a known-good API.
2. **Return displaced items from equip methods**: `equip_weapon(item)` returning the old weapon was the key design insight — it made atomic bag-slot swaps trivial in Phase 6. Void returns would have required a separate query.
3. **Godot version mismatch is a real risk**: The Makefile / project.godot version gap hasn't caused failures yet but is latent. Address before adding CI or the first divergence will be confusing.
4. **Human verification checkpoints are worth the plan slot**: Phase 6-02 and 7-02 verification checkpoints caught no bugs but confirmed the implementation worked in Godot's scene tree — unit tests can't cover that. Keep this pattern.

### Cost Observations

- Sessions: ~6–8 (Phase 5–8 each had 1–2 sessions)
- No cost data available (no token tracking in place)
- Notable: Plans under 5 minutes each (2–10 min) with TDD kept iteration tight; Phase 8 verification was the longest at ~1 hour (human playtesting)

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 4 | 11 | Initial process setup; established GUT + TDD pattern |
| v1.1 | 4 | 9 | TDD fully embedded; world.gd wiring hub pattern emerged; fewer plans needed per phase |

### Cumulative Quality

| Milestone | Unit Tests | Zero-Dep New Files | GDScript LOC |
|-----------|------------|--------------------|--------------|
| v1.0 | ~88 | InventorySlot, Inventory, Item, HealthItem, WeaponItem, InventorySlotUI | ~2,100 |
| v1.1 | 144 | EquipmentData, WeaponIndicator, HudStrip | ~17,600 |
