---
phase: 02-grid-inventory-ui
plan: 03
subsystem: ui
tags: [godot, gdscript, inventory, hud, signals, tween, collectable]

# Dependency graph
requires:
  - phase: 02-grid-inventory-ui/02-01
    provides: Inventory resource with insert_rejected signal
  - phase: 02-grid-inventory-ui/02-02
    provides: InventoryUI with set_inventory() method and grid slot rendering

provides:
  - world.gd wiring player.inventory to InventoryUI and RejectionLabel via signals
  - RejectionLabel HUD node on CanvasLayer showing "Too heavy!" on insert_rejected
  - Fade animation (modulate.a via Tween) with FadeTimer (2s one_shot)
  - Correct per-type slot identity via explicit id fields on all item resources
  - axe.gd rejection guard preventing queue_free on failed inventory insert
  - Second GoldKey2 instance in world for stacking verification

affects: [phase-03-item-use, world-scene-wiring, any-new-collectable-type]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "HUD overlay via CanvasLayer child node; visibility controlled by modulate.a not visible flag"
    - "world.gd as signal coordinator wiring player.inventory to UI subsystems in _ready()"
    - "Collectable subclasses must check collect() return value before queue_free()"
    - "Item resources require a unique id: StringName for correct slot stacking"

key-files:
  created: []
  modified:
    - scripts/world.gd
    - scenes/world.tscn
    - scripts/collectable.gd
    - scripts/axe.gd
    - scenes/axe.tscn
    - scenes/gold_key.tscn

key-decisions:
  - "RejectionLabel visibility controlled by modulate.a only (not visible flag) to support smooth fade"
  - "Rejection HUD placed on CanvasLayer as sibling of InventoryUI so it appears whether inventory panel is open or closed"
  - "Item id must be set explicitly on each .tscn sub-resource — default StringName is empty, making all items share slot identity"
  - "axe.gd overrides collect() independently of base Collectable; fix applied to override, not base class"
  - "GoldKey2 added as standalone scene instance (not TileMap tile) for simplicity"

patterns-established:
  - "Signal wiring pattern: world._ready() connects player.inventory signals to UI nodes after children are ready"
  - "HUD fade pattern: set modulate.a=1.0 on show, start Timer, Tween modulate.a=0.0 on timeout"
  - "Collectable subclass override: always capture and check collector.collect() result before queue_free()"
  - "Item identity: id field drives all stacking/slot logic; name is display-only"

requirements-completed:
  - INV-02
  - INV-03

# Metrics
duration: 25min
completed: 2026-03-11
---

# Phase 2 Plan 3: Inventory UI Wiring and Rejection HUD Summary

**world.gd wires player inventory to InventoryUI and "Too heavy!" HUD, with post-checkpoint bug fixes for slot identity (missing item id) and axe queue_free on rejection**

## Performance

- **Duration:** ~25 min total (2 min initial + 20 min continuation after human-verify)
- **Started:** 2026-03-11T07:29:31Z
- **Completed:** 2026-03-11T08:30:00Z
- **Tasks:** 3 (tasks 1-2 initial; task 3 = fixes from human-verify checkpoint)
- **Files modified:** 6

## Accomplishments

- Rewrote world.gd with @onready refs and _ready() that wires player.inventory to InventoryUI and RejectionLabel
- Added RejectionLabel (Label) with FadeTimer (Timer, 2s one_shot) to world.tscn CanvasLayer, starts transparent
- Fixed critical slot identity bug: all items had empty StringName id, causing every item type to stack into the same slot
- Fixed rejection bug: axe.gd unconditionally called queue_free() — now respects collect() return value
- Added GoldKey2 instance near player start so stacking behaviour can be verified

## Task Commits

Each task was committed atomically:

1. **Task 1: Add RejectionLabel to world.tscn and rewrite world.gd** - `afad0b7` (feat)
2. **Task 2: Wire rejection feedback in collectable.gd** - `224cd90` (chore)
3. **Fix slot identity bug** - `f5e67e9` (fix)
4. **Fix axe queue_free on rejection** - `e277acf` (fix)
5. **Add GoldKey2, restore max_weight** - `875671e` (feat)

## Files Created/Modified

- `scripts/world.gd` - Rewrote with @onready refs; _ready() wires set_inventory() and insert_rejected signal; _on_insert_rejected() and _on_fade_timer_timeout() handlers added
- `scenes/world.tscn` - Added RejectionLabel (Label, modulate.a=0) and FadeTimer (Timer, wait_time=2, one_shot) as children of CanvasLayer; added GoldKey2 standalone node at Vector2(16, 33)
- `scripts/collectable.gd` - Added clarifying comment about rejection signal path (no logic change)
- `scripts/axe.gd` - Captures collect() return value; only calls queue_free() on success
- `scenes/axe.tscn` - Added `id = &"axe"` to WeaponItem sub-resource
- `scenes/gold_key.tscn` - Added `id = &"gold_key"` to Item sub-resource

## Decisions Made

- RejectionLabel visibility controlled by `modulate.a` only (not `visible` flag) to support smooth Tween fade
- Rejection HUD placed on CanvasLayer as sibling of InventoryUI so it is always visible regardless of inventory panel state
- Item `id` must be set explicitly; the default `StringName` (`&""`) is shared across all items, breaking `can_stack()`
- GoldKey2 placed as a standalone scene instance rather than a TileMap tile for simplicity

## Deviations from Plan

### Auto-fixed Issues (found at human-verify checkpoint)

**1. [Rule 1 - Bug] All items collapsed into one inventory slot**
- **Found during:** Task 3 (human-verify checkpoint)
- **Issue:** `id` field on `Item` and `WeaponItem` resources was never assigned. `can_stack()` compares `item.id == other.id`; with both being `&""`, every item type matched every other, stacking axe and key into the same slot.
- **Fix:** Added `id = &"axe"` to `axe.tscn` sub-resource and `id = &"gold_key"` to `gold_key.tscn` sub-resource.
- **Files modified:** `scenes/axe.tscn`, `scenes/gold_key.tscn`
- **Verification:** `make test` passes (test_cannot_stack_different_item and test_can_stack_same_id already cover this contract)
- **Committed in:** `f5e67e9`

**2. [Rule 1 - Bug] "Too heavy!" item still consumed from world on rejection**
- **Found during:** Task 3 (human-verify checkpoint)
- **Issue:** `axe.gd` overrides `collect()` and unconditionally calls `queue_free()` — the return value of `collector.collect(weapon_item)` was discarded. The axe disappeared from the world even when inventory rejected the insertion.
- **Fix:** Captured return value in `var success`; calls `queue_free()` only when `success` is true.
- **Files modified:** `scripts/axe.gd`
- **Verification:** `make lint`, `make format-check`, `make test` all pass
- **Committed in:** `e277acf`

**3. [Rule 2 - Missing] No same-type duplicate collectable for stacking verification**
- **Found during:** Task 3 (human-verify checkpoint)
- **Issue:** Only one GoldKey existed in the world, making it impossible to verify that picking up two of the same item type increments quantity in one slot rather than using two slots.
- **Fix:** Added `GoldKey2` node instance of `gold_key.tscn` at `Vector2(16, 33)` (near player start).
- **Files modified:** `scenes/world.tscn`
- **Committed in:** `875671e`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing verification setup)
**Impact on plan:** All fixes necessary for correctness and verifiability. No scope creep.

## Issues Encountered

- `scenes/player.tscn` was incidentally modified by the Godot editor during `make test` import step (removed `libraries` property from AnimationTree). Restored via `git checkout` to avoid committing an unrelated change.
- `scripts/resources/player_inventory.tres` had `max_weight` lowered to `2.0` during manual testing — restored to `100.0` in the GoldKey2 commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Full Phase 2 inventory loop is complete: player collects items, grid UI updates by type, rejection HUD fires on overweight, items stay in world when rejected
- Future note (not this phase): medicpack heals immediately on pickup instead of going to inventory — flagged for Phase 3
- Phase 3 (item use / consumables) can proceed

---
*Phase: 02-grid-inventory-ui*
*Completed: 2026-03-11*
