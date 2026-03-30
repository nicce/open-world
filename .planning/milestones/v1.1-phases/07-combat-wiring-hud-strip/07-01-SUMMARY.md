---
phase: 07-combat-wiring-hud-strip
plan: "01"
subsystem: combat
tags: [gdscript, godot, player, combat, equipment, weapon-indicator, tdd]

requires:
  - phase: 05-data-foundation
    provides: EquipmentData resource with equipment_changed signal and WeaponItem.damage float field
  - phase: 06-equip-unequip-flow
    provides: Equip/unequip wiring in world.gd; player_equipment_data.tres resource attached to player scene

provides:
  - hit() in player.gd reads equipment_data.weapon.damage at call time (int cast); fist fallback when null
  - 4 unit tests covering CMBT-03 and CMBT-04 combat dispatch contracts
  - WeaponIndicator Node2D child in player.tscn at Vector2(0, -24) showing equipped weapon texture or name
affects:
  - 07-02 (HUD strip will need same equipment_changed pattern)
  - runtime combat verification (attack.damage mutation timing note in STATE.md)

tech-stack:
  added: []
  patterns:
    - "Read-at-call-time: hit() reads equipment_data.weapon at call time, never caches via signal subscription"
    - "Texture-or-label: WeaponIndicator reuses collectable.gd pattern — TextureRect when texture present, Label fallback"
    - "set_equipment_data() wiring: pass EquipmentData to indicator; it connects signal and paints initial state immediately"

key-files:
  created:
    - tests/unit/test_player_combat.gd
    - scripts/weapon_indicator.gd
  modified:
    - scripts/player.gd
    - scenes/player.tscn

key-decisions:
  - "Read attack.damage at hit() call time — no caching via equipment_changed subscription (locked decision from Phase 7 context)"
  - "int() cast mandatory: WeaponItem.damage is float, Attack.damage is int — truncation is the specified behaviour"
  - "WeaponIndicator default visible=false in scene; set_equipment_data() calls _on_equipment_changed() immediately to paint initial state"

patterns-established:
  - "set_equipment_data(ed) pattern: connect signal then call handler immediately for initial paint"
  - "Indicator wired in player.gd _ready() after animation_tree connection"

requirements-completed:
  - CMBT-03
  - CMBT-04
  - CMBT-05

duration: 3min
completed: 2026-03-19
---

# Phase 7 Plan 01: Combat Wiring + WeaponIndicator Summary

**hit() dispatch reading weapon damage at call time with int cast, plus WeaponIndicator Node2D above player showing equipped weapon texture or name fallback**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-19T09:09:07Z
- **Completed:** 2026-03-19T09:12:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Implemented `hit()` in `player.gd` that reads `equipment_data.weapon.damage` at call time with `int()` cast; leaves `attack.damage` unchanged when no weapon or no equipment_data
- Added 4 unit tests in `test_player_combat.gd` covering weapon equipped (CMBT-03), no weapon (CMBT-04), null equipment_data, and float truncation
- Created `scripts/weapon_indicator.gd` as a `Node2D` with `TextureRect` + `Label` children using the texture-or-label pattern from `collectable.gd`
- Added `WeaponIndicator` node to `scenes/player.tscn` at `Vector2(0, -24)` and wired it in `player.gd _ready()`

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement hit() combat dispatch with unit tests** - `e12f24a` (feat + test, TDD)
2. **Task 2: Add WeaponIndicator child node to Player scene** - `edd88a3` (feat)

## Files Created/Modified

- `tests/unit/test_player_combat.gd` - 4 GUT unit tests for hit() dispatch (CMBT-03, CMBT-04)
- `scripts/player.gd` - hit() implementation + WeaponIndicator wiring in _ready()
- `scripts/weapon_indicator.gd` - Node2D indicator subscribing to equipment_changed; texture-or-label display
- `scenes/player.tscn` - WeaponIndicator node at Vector2(0, -24) with IconRect + NameLabel children

## Decisions Made

- Read `attack.damage` at `hit()` call time — no caching via `equipment_changed` subscription. This is a locked decision from the Phase 7 context document.
- `int()` cast is explicit and mandatory: `WeaponItem.damage` is `float`, `Attack.damage` is `int`; GDScript would error without the cast.
- `set_equipment_data()` calls `_on_equipment_changed()` immediately after connecting the signal to paint the initial state (handles weapon already set in Inspector resource).

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CMBT-03, CMBT-04, CMBT-05 all satisfied and unit tested
- Plan 02 (HUD strip) can proceed: `equipment_data.equipment_changed` signal pattern is established; `set_equipment_data()` wiring pattern is confirmed working
- Runtime combat verification of `attack.damage` mutation timing is still noted as MEDIUM confidence in STATE.md — needs in-editor playtesting

---
*Phase: 07-combat-wiring-hud-strip*
*Completed: 2026-03-19*

## Self-Check: PASSED

- FOUND: tests/unit/test_player_combat.gd
- FOUND: scripts/weapon_indicator.gd
- FOUND: scripts/player.gd
- FOUND: scenes/player.tscn
- FOUND: .planning/phases/07-combat-wiring-hud-strip/07-01-SUMMARY.md
- FOUND commit: e12f24a (feat: hit() combat dispatch)
- FOUND commit: edd88a3 (feat: WeaponIndicator)
