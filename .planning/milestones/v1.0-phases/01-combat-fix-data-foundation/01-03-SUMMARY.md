---
plan: 01-03
phase: 01-combat-fix-data-foundation
status: complete
tasks_completed: 2/2
commits:
  - hash: a152a96
    message: "feat(01-03): DATA-01 — add id: StringName to Item; use id for identity comparisons"
  - hash: 193d98c
    message: "feat(01-03): DATA-02 and DATA-03 — inventory clone() and floori() fix"
---

# Plan 01-03 Summary — Inventory Data Model Hardening

## What Was Built

Hardened the inventory data model across three requirements: stable item identity (DATA-01), isolated inventory state across scene loads (DATA-02), and correct floor division for weight limits (DATA-03).

## Key Files

### Created
- None

### Modified
- `scripts/resources/item.gd` — added `@export var id: StringName`
- `scripts/resources/inventory_slot.gd` — `can_stack()` now uses `item.id == other.id`
- `scripts/resources/inventory.gd` — `remove()` and `get_item_count()` use `slot.item.id == item.id`; replaced `int()` with `floori()` at both weight budget sites; added `clone()` method for true deep-copy
- `scripts/player.gd` — `_ready()` now calls `inventory = inventory.clone()`
- `tests/unit/test_inventory_slot.gd` — `_make_item()` helper updated to auto-derive id from name
- `tests/unit/test_inventory.gd` — `_make_item()` helper updated; DATA-02 tests use `clone()`

## Decisions Made

- **`clone()` instead of `duplicate()`:** Godot 4.3 blocks overriding the native `duplicate()` method on Resource subclasses. Added an explicit `clone()` method on `Inventory` that manually deep-copies all slots. Tests updated to call `clone()`.
- **`floori()` replaces `int()`:** Both weight budget calculation sites in `inventory.gd` now use `floori()` for correct floor semantics.

## Deviations from Plan

- DATA-02 fix used `clone()` instead of `duplicate(true)` due to Godot 4.3 native method override restriction. Functionally equivalent — produces isolated copy.

## Self-Check

- [x] `make lint` — passed
- [x] `make format-check` — passed
- [x] `make test` — 70/70 passed (all DATA tests green)
- [x] No regressions in existing tests
