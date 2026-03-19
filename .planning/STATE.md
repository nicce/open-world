---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Equipment Slots
status: unknown
stopped_at: Completed 07-combat-wiring-hud-strip-01-PLAN.md
last_updated: "2026-03-19T09:13:27.715Z"
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 6
  completed_plans: 5
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-13)

**Core value:** A satisfying item and inventory system that makes picking things up, using consumables, and managing weight feel meaningful
**Current focus:** Phase 07 — combat-wiring-hud-strip

## Current Position

Phase: 07 (combat-wiring-hud-strip) — EXECUTING
Plan: 1 of 2

## Performance Metrics

**Velocity:**

- Total plans completed: 0 (v1.1); 11 (v1.0 historical)
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 05-data-foundation P01 | 2 | 2 tasks | 2 files |
| Phase 05-data-foundation P02 | 45 | 3 tasks | 6 files |
| Phase 06-equip-unequip-flow P01 | 3 | 2 tasks | 3 files |
| Phase 06-equip-unequip-flow P02 | 10 | 2 tasks | 2 files |
| Phase 07-combat-wiring-hud-strip P01 | 3 | 2 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap v1.1]: EquipmentData must be a separate Resource from Inventory — mixing them corrupts 15-slot grid and weight accounting
- [Roadmap v1.1]: Equip transaction must be atomic — unit test must assert item absent from all bag slots immediately after equip() returns
- [Roadmap v1.1]: PopupMenu uses named const IDs with id_pressed signal (not index_pressed) to avoid positional shift when items are conditionally added
- [Roadmap v1.1]: HUD strip placed as sibling of InventoryUI in CanvasLayer — not a child — so it remains visible when inventory panel is closed
- [Phase 04-inventory-slot-full-rejection]: Remove weight_budget guard from elif branch in insert() — any complete failure emits insert_rejected unconditionally
- [Phase 05-data-foundation]: EquipmentData: mutate field first then emit equipment_changed; return displaced item from equip methods for atomic Phase 6 swaps
- [Phase 05-data-foundation]: Use named const IDs with id_pressed (not index_pressed) in PopupMenu to avoid positional shift when items are conditionally added
- [Phase 05-data-foundation]: MENU_EQUIP handler is a pass stub in Phase 5 — Phase 6 wires the equip flow; Drop and Consume are functional immediately
- [Phase 05-data-foundation]: PopupMenu uses named const IDs with id_pressed (not index_pressed) to avoid positional shift when items are conditionally added
- [Phase 05-data-foundation]: MENU_EQUIP handler is a pass stub in Phase 5 — Phase 6 wires the equip flow; Drop and Consume are functional immediately
- [Phase 06-equip-unequip-flow]: Remove-before-equip ordering: inventory.remove() always precedes equip_weapon() to prevent item existing in both bag and slot simultaneously
- [Phase 06-equip-unequip-flow]: Unequip-with-full-bag is a safe no-op: insert() first; if remaining > 0 weapon stays equipped without mutation
- [Phase 06-equip-unequip-flow]: world.gd is the single wiring point — all scene-graph wiring lives in _ready() alongside set_inventory() and set_player()
- [Phase 07-combat-wiring-hud-strip]: Read attack.damage at hit() call time — no caching via equipment_changed subscription (locked Phase 7 decision)
- [Phase 07-combat-wiring-hud-strip]: int() cast mandatory in hit(): WeaponItem.damage is float, Attack.damage is int — truncation is specified behaviour
- [Phase 07-combat-wiring-hud-strip]: set_equipment_data() calls _on_equipment_changed() immediately after signal connect to paint initial state

### Pending Todos

None yet.

### Blockers/Concerns

- Godot version mismatch: Makefile uses 4.2.2 for headless tests; project declares 4.3. Fix before CI diverges.
- Phase 7 (hit() wiring): attack.damage mutation timing is MEDIUM confidence — needs runtime verification that HitboxComponent reads mutated value before hitbox fires. Fallback: swap entire Attack node reference on equip.

## Session Continuity

Last session: 2026-03-19T09:13:27.711Z
Stopped at: Completed 07-combat-wiring-hud-strip-01-PLAN.md
Resume file: None
