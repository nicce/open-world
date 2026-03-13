# Plan 03-04 Summary — Human Smoke Test

## Status: Complete

## What Was Verified

Human smoke test confirmed all four Phase 3 scenarios work end-to-end in the running game.

## Tasks Completed

| Task | Status | Notes |
|------|--------|-------|
| Task 1: Automated gate (lint + format + test) | ✓ Complete | 87/87 tests pass |
| Task 2: Human smoke test (ITEM-01, ITEM-02, ITEM-03) | ✓ Approved | All 4 scenarios verified |

## Bugs Fixed During Verification

Three bugs were found and fixed during the smoke test:

1. **GDScript closure capture in loop** — `func(_n): _on_slot_clicked(i)` captured `i` by reference; all 15 slots resolved to index 14. Fixed by connecting directly to `_on_slot_clicked` and finding the index from the node reference.

2. **Panel self_modulate=0 hid selection border** — The slot Panel had `self_modulate.a=0` to hide its default background (visual from Sprite2D child). This also made the StyleBox border invisible. Fixed by restoring `self_modulate.a=1.0` in `_ready()` and using `StyleBoxEmpty` as default override.

3. **`inventory.remove()` missing `inventory_changed.emit()`** — UI never refreshed after using or dropping items, making operations appear to do nothing. Fixed by emitting `inventory_changed` when items are removed.

## Additional Fixes

- **Collectable texture on drop** — Dropped items were invisible (no texture). Fixed by setting `$Sprite2D.texture = item.texture` in `collectable._ready()`.
- **Drop position order** — `add_child` now called before setting `global_position` so world-space coords resolve correctly.
- **Multiple simultaneous pickups** — Added "collectables" group with closest-wins logic in `_process`.
- **Starting inventory** — Added 3 Medpacks to `player_inventory.tres` so ITEM-01 can be tested immediately.

## Smoke Test Results

| Scenario | Result |
|----------|--------|
| Slot selection (click to highlight, click again to deselect) | ✓ Pass |
| E key uses Medpack (HP restores, quantity decrements) | ✓ Pass |
| Q key drops item (collectable spawns near player with sprite) | ✓ Pass |
| Pickup notification (+ label appears, fades after ~2s) | ✓ Pass |
