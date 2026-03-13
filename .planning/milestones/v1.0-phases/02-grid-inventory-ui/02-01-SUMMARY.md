---
phase: 02-grid-inventory-ui
plan: 01
subsystem: inventory
tags: [signals, tdd, inventory, helpers]
dependency_graph:
  requires: []
  provides: [inventory_changed signal, insert_rejected signal, InventoryUIHelpers]
  affects: [scripts/resources/inventory.gd, scripts/inventory_ui_helpers.gd]
tech_stack:
  added: []
  patterns: [TDD RED/GREEN, GUT signal assertions, GDScript static helpers]
key_files:
  created:
    - scripts/inventory_ui_helpers.gd
    - tests/unit/test_inventory_ui_helpers.gd
  modified:
    - scripts/resources/inventory.gd
    - tests/unit/test_inventory.gd
decisions:
  - InventoryUIHelpers extends RefCounted (not bare class) for GDScript 4 compatibility
  - Signal emit logic placed after both insert loops to capture full inserted count
  - insert_rejected only emitted when weight_budget <= 0 (weight-blocked), not when slots full
metrics:
  duration: 145s
  completed: 2026-03-11
  tasks_completed: 2
  files_changed: 4
---

# Phase 02 Plan 01: Inventory Signals and UI Helpers Summary

**One-liner:** TDD-driven addition of `inventory_changed`/`insert_rejected` signals to Inventory resource and static `InventoryUIHelpers` class with `abbreviate()` and `format_weight()`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write failing tests for signals and UI helpers (RED) | fa32cee | tests/unit/test_inventory.gd, tests/unit/test_inventory_ui_helpers.gd |
| 2 | Add signals to Inventory and implement InventoryUIHelpers (GREEN) | 0cc03f2 | scripts/resources/inventory.gd, scripts/inventory_ui_helpers.gd |

## What Was Built

### Inventory Signals (`scripts/resources/inventory.gd`)

Two signals added to the `Inventory` resource:
- `signal inventory_changed` — emitted from `insert()` when at least one item was actually inserted
- `signal insert_rejected` — emitted from `insert()` when weight prevents any insertion (weight_budget <= 0)

Emit logic is placed after both insert loops (stack + empty-slot). The inserted count is derived from `amount - remaining`. This ensures signals accurately reflect the outcome of the full insert operation.

### InventoryUIHelpers (`scripts/inventory_ui_helpers.gd`)

New pure-static helper class:
- `static func abbreviate(item_name: String, max_len: int = 4) -> String` — trims names longer than `max_len`; returns short names unchanged
- `static func format_weight(current: float, max_w: float) -> String` — produces `"X.X / Y kg"` format string

Extends `RefCounted` for GDScript 4 compatibility (bare class with no extends fails in some Godot versions).

### Tests

Nine new tests added across two files:
- 4 signal tests in `test_inventory.gd` (inventory_changed and insert_rejected, positive and negative cases)
- 5 helper tests in `test_inventory_ui_helpers.gd` (abbreviate short/long/exact, format_weight normal/zero)

## Verification

```
make lint     — Success: no problems found (23 files)
make format-check — 23 files would be left unchanged
make test     — 79/79 passing (up from 70)
```

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `scripts/resources/inventory.gd` — FOUND (contains signal inventory_changed, signal insert_rejected)
- `scripts/inventory_ui_helpers.gd` — FOUND (contains abbreviate and format_weight)
- `tests/unit/test_inventory_ui_helpers.gd` — FOUND
- Commit fa32cee — FOUND (RED phase)
- Commit 0cc03f2 — FOUND (GREEN phase)
- All 79 tests passing
