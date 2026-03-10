---
phase: 01-combat-fix-data-foundation
plan: "01"
subsystem: testing
tags: [tdd, combat, inventory, failing-tests, red-phase]
dependency_graph:
  requires: []
  provides:
    - tests/unit/test_player_state.gd
    - tests/unit/test_snake.gd
    - tests/unit/test_inventory_slot.gd (extended)
    - tests/unit/test_inventory.gd (extended)
  affects:
    - plans/01-02 (implements against these contracts)
    - plans/01-03 (implements against these contracts)
tech_stack:
  added: []
  patterns:
    - GUT inner-class stub (override _ready() as no-op to test CharacterBody2D logic in isolation)
    - Forward-compatible test helpers (accept optional id param, guard with empty check)
key_files:
  created:
    - tests/unit/test_player_state.gd
    - tests/unit/test_snake.gd
  modified:
    - tests/unit/test_inventory_slot.gd
    - tests/unit/test_inventory.gd
decisions:
  - "Used GUT inner-class stub pattern (override _ready()) to test CharacterBody2D subclasses without a scene tree — avoids headless mode failures from AnimationTree @onready lookups"
  - "DATA-03 weight-boundary test passes on current code due to float luck with 1.0/1.0 division; test retained as regression guard documenting the floori() contract"
  - "test_cannot_stack_same_name_different_id is Risky (script error before assertion) rather than Failed because the item.id property doesn't exist yet — accepted as valid RED state"
metrics:
  duration_seconds: 181
  completed_date: "2026-03-10"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 2
---

# Phase 1 Plan 01: Failing Test Scaffolds Summary

**One-liner:** TDD RED scaffolds for five requirements — combat HIT-state lockout, snake knockback, id-based stacking, deep-copy isolation, and weight boundary — using GUT inner-class stubs for scene-free CharacterBody2D testing.

## What Was Built

Four test files covering all five Phase 1 requirements. No production code was changed. All new tests are in RED state; all 63 previously-passing tests remain green.

### Test coverage by requirement

| Requirement | Test file | Test function | RED mechanism |
|---|---|---|---|
| CMBT-01 | test_player_state.gd | test_hit_state_resets_to_move_via_animation_signal | Method not found: on_attack_animation_finished |
| CMBT-02 | test_snake.gd | test_apply_knockback_sets_nonzero_velocity | Method not found: apply_knockback |
| CMBT-02 | test_snake.gd | test_apply_knockback_direction_is_away_from_attacker | Method not found: apply_knockback |
| CMBT-02 | test_snake.gd | test_apply_knockback_zero_direction_does_not_crash | Method not found: apply_knockback |
| DATA-01 | test_inventory_slot.gd | test_cannot_stack_same_name_different_id | Invalid property 'id' on Item |
| DATA-01 | test_inventory_slot.gd | test_can_stack_same_id | Invalid property 'id' on Item |
| DATA-02 | test_inventory.gd | test_duplicate_true_isolates_slots | FAILS: slot quantity changes in original after mutating copy |
| DATA-02 | test_inventory.gd | test_duplicate_slots_are_different_references | FAILS: slots[0] reference is identical in original and copy |
| DATA-03 | test_inventory.gd | test_insert_at_exact_weight_limit_accepts_item | PASSES (float luck with 1.0/1.0); retained as regression guard |

### Test suite totals

| Metric | Before | After |
|---|---|---|
| Scripts | 4 | 6 |
| Tests | 59 | 70 |
| Passing | 59 | 63 |
| Failing | 0 | 3 |
| Risky | 0 | 4 |
| Regressions | — | 0 |

## Decisions Made

### GUT inner-class stub pattern for CharacterBody2D

Player and Snake both extend CharacterBody2D and use `@onready` to look up scene-tree nodes (AnimationTree, AnimationDamage) in `_ready()`. Instantiating them outside a scene tree in headless mode would crash on those lookups.

Solution: define a local inner class inside each test file that extends the target class and overrides `_ready()` as a no-op. This lets tests call pure-logic methods (on_player_state_reset, apply_knockback) without triggering node lookups.

### DATA-03 passes on current code

The exact-weight boundary test (`insert at remaining_weight == item.weight`) passes with the current `int()` implementation because `1.0 / 1.0` in Godot 4.3 evaluates to exactly `1.0`, not `0.9999…`. The test is retained as a regression guard and documents the contract that Plan 02 must uphold by switching to `floori()`.

### Forward-compatible _make_item() helpers

Both `test_inventory_slot.gd` and `test_inventory.gd` updated `_make_item()` to accept an optional `item_id: StringName` parameter. When the id is non-empty, the helper assigns `item.id = item_id` — which currently raises a script error since `Item` has no such field. This keeps the DATA-01 tests RED and makes them trivially go GREEN once Plan 03 adds the field.

## Deviations from Plan

### Auto-fixed Issues

None.

### Scope notes

- CMBT-01: The plan's primary test (`on_player_state_reset` sets state to MOVE) was written. An additional test was added to directly test the missing signal handler (`on_attack_animation_finished`) — this is the actual RED test that drives Plan 02's implementation. The two passing tests (reset method works, initial state is MOVE) validate positive existing behavior.
- DATA-03 passes immediately as noted in the plan's own caveat ("may currently pass or fail depending on float luck").

## Self-Check: PASSED

| Check | Result |
|---|---|
| tests/unit/test_player_state.gd | FOUND |
| tests/unit/test_snake.gd | FOUND |
| tests/unit/test_inventory_slot.gd | FOUND |
| tests/unit/test_inventory.gd | FOUND |
| .planning/phases/01-combat-fix-data-foundation/01-01-SUMMARY.md | FOUND |
| Commit 9848c2c (CMBT-01, CMBT-02 tests) | FOUND |
| Commit a99b557 (DATA-01, DATA-02, DATA-03 tests) | FOUND |
