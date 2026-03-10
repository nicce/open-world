---
phase: 01-combat-fix-data-foundation
plan: "02"
subsystem: combat
tags: [gdscript, godot, animation, signals, state-machine, knockback]

# Dependency graph
requires:
  - phase: 01-combat-fix-data-foundation
    provides: "Failing unit tests for CMBT-01 and CMBT-02 (test_player_state.gd, test_snake.gd)"
provides:
  - "Player state resets to MOVE after Fist animation via animation_finished signal"
  - "HitboxComponent emits knocked_back signal with attacker position on area hit"
  - "Snake receives velocity impulse away from attacker with move_toward decay"
affects: [02-inventory-ui, combat-ai]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "animation_finished signal drives state-machine exit (not polling)"
    - "Signal chain: animation_finished -> _on_animation_finished -> on_attack_animation_finished -> on_player_state_reset"
    - "Knockback via velocity impulse + move_toward decay in _physics_process"

key-files:
  created: []
  modified:
    - scripts/player.gd
    - scripts/hitbox_component.gd
    - scripts/snake.gd

key-decisions:
  - "Used on_attack_animation_finished() as named handler (matches test contract from Plan 01)"
  - "hit() body emptied — state exit driven entirely by animation_finished signal, no polling"
  - "travel('Fist') moved from hit() to move() on state entry to avoid re-triggering blend space every frame"
  - "knockback decay threshold set at 1.0 px/s to avoid floating-point never-zero"

patterns-established:
  - "Animation-driven state exit: connect animation_finished in _ready, filter by anim_name in handler"
  - "Knockback pattern: apply_knockback(from_position) sets impulse; _physics_process decays with move_toward"

requirements-completed: [CMBT-01, CMBT-02]

# Metrics
duration: 8min
completed: 2026-03-10
---

# Phase 01 Plan 02: Combat Fixes (CMBT-01 + CMBT-02) Summary

**Player HIT state lockout fixed via animation_finished signal; snake gains velocity knockback impulse away from attacker**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-10T18:30:00Z
- **Completed:** 2026-03-10T18:38:00Z
- **Tasks:** 2 of 3 auto tasks complete (Task 3 is checkpoint:human-verify)
- **Files modified:** 3

## Accomplishments

- Player no longer locks in HIT state — animation_finished signal exits state when Fist anim completes
- Fist travel() called once on state entry (in move()) instead of every physics frame
- HitboxComponent emits knocked_back(from_position) signal on every area hit
- Snake applies velocity impulse away from attacker with exponential decay via move_toward

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix CMBT-01 — Wire animation_finished signal to reset player state** - `1756739` (feat)
2. **Task 2: Fix CMBT-02 — Add knocked_back signal and snake velocity impulse** - `c080bf6` (feat)

_Task 3 is a checkpoint:human-verify (visual verification in Godot engine required)._

## Files Created/Modified

- `scripts/player.gd` - Added _ready() connecting animation_finished; added _on_animation_finished() and on_attack_animation_finished(); fixed hit() to no-op; moved travel("Fist") to move() on state entry
- `scripts/hitbox_component.gd` - Added knocked_back signal; emit in _on_area_entered after take_damage
- `scripts/snake.gd` - Added knockback_force export, knockback_velocity var, apply_knockback(), _on_knocked_back(), _physics_process() with decay; connected signal in _ready()

## Decisions Made

- `on_attack_animation_finished()` used as the public method name — matches the test contract established in Plan 01 (test calls this name directly)
- `_on_animation_finished()` filters for FistNorth/FistSouth/FistEast/FistWest names — if runtime shows different names, update the array (low-confidence from research)
- `hit()` left as no-op rather than removed — cleaner state machine structure with all states represented
- Knockback decay threshold 1.0 chosen to avoid floating-point never reaching zero

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The test contract used `on_attack_animation_finished()` (not `_on_animation_finished()` directly), so the handler chain was structured to expose that public method name that the tests call.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CMBT-01 and CMBT-02 unit tests pass (6/6 new tests green)
- All pre-existing passing tests still pass
- Task 3 (human-verify) requires visual confirmation in Godot: player returns to MOVE after Fist animation, snake visibly recoils on hit
- If animation_finished signal fires with different anim names at runtime, update the array in _on_animation_finished()

---
*Phase: 01-combat-fix-data-foundation*
*Completed: 2026-03-10*
