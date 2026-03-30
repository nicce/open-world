# Phase 9: Foundation — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-30
**Phase:** 09-foundation-itemregistry-and-resource-serialisation
**Areas discussed:** ItemRegistry registration, Slot serialisation format, load_health() clamping, from_dict() signal noise

---

## ItemRegistry Registration

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcoded dict | `_build_registry()` lists all items as preload() calls. Simple, fully GUT-testable. | ✓ |
| Self-registration | Item Resources call `ItemRegistry.register(self)` in `_init()`. Ordering issues in tests. | |
| Folder scan | `DirAccess.get_files_at()` at startup. Automatic but unreliable in headless GUT. | |

**User's choice:** Hardcoded dict
**Notes:** User raised concern about game growing to ~100–200 items. Decision: stick with dict for Phase 9, design `get_item(id)` as the stable public interface, migrate population mechanism to folder scan in a future milestone. Deferred idea captured in CONTEXT.md.

### ItemRegistry Location

| Option | Description | Selected |
|--------|-------------|----------|
| Script-only autoload | `scripts/item_registry.gd` registered directly. No `.tscn` needed. | ✓ |
| Scene + script (like BackgroundMusic) | `scenes/item_registry.tscn` + script. Consistent but unnecessary overhead. | |

**User's choice:** Script-only autoload

---

## Slot Serialisation Format

| Option | Description | Selected |
|--------|-------------|----------|
| Sparse dict by index | Only occupied slots: `{"slots": {"2": {"id": "sword", "qty": 1}}}`. Clean JSON. | ✓ |
| Dense array (all 15 slots) | All slots with null for empty. Simpler index mapping, noisier JSON. | |

**User's choice:** Sparse dict by index
**Notes:** `from_dict()` clears all slots before filling from dict entries.

---

## load_health() Clamping

| Option | Description | Selected |
|--------|-------------|----------|
| Clamp to max_health | `clampi(value, 0, max_health)`. Safe against stale saves. | ✓ |
| Trust saved value | Direct assignment. Could produce HP > max_health. | |

**User's choice:** Clamp to max_health

### Health Bar Update

| Option | Description | Selected |
|--------|-------------|----------|
| Update bar in load_health() | `health_bar.update(health)` inside method if bar is set. Consistent with damage()/increase(). | ✓ |
| Leave to existing wiring | Caller refreshes bar. Risks stale bar. | |

**User's choice:** Update health_bar directly in load_health()

---

## from_dict() Signal Noise During Load

| Option | Description | Selected |
|--------|-------------|----------|
| Let signals fire | `equip_weapon()` / `equip_tool()` called as-is. HUD refreshes via `equipment_changed`. | ✓ |
| Direct field assignment | Assign `weapon = ...` without calling equip methods. No signals, manual HUD refresh needed. | |

**User's choice:** Let signals fire
**Notes:** `SaveManager.load_game()` will run last in `world.gd._ready()` — after HUD wiring. So `equipment_changed` fires to a connected HUD, which refreshes automatically. This is the desired behaviour.
