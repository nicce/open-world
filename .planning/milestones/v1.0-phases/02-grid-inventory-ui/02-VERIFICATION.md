---
phase: 02-grid-inventory-ui
verified: 2026-03-11T00:00:00Z
status: human_needed
score: 14/14 automated must-haves verified
re_verification: false
human_verification:
  - test: "Open Godot, press F5, then press Tab to open inventory"
    expected: "A 5x3 grid of 15 slots appears. Empty slots are visibly dimmed (semi-transparent ~40% opacity). Weight label at the bottom shows '0.0 / 100 kg'."
    why_human: "Godot scene rendering and UI layout cannot be verified headlessly."
  - test: "Walk to a collectable (GoldKey or Axe), press E to pick it up, then open inventory"
    expected: "One slot fills with an abbreviation label (e.g. 'Gold') and quantity '1'. Weight label updates to reflect the item's weight."
    why_human: "Real-time signal-driven slot refresh requires running game."
  - test: "Pick up a second GoldKey2 (placed near player start)"
    expected: "INV-03: quantity in the existing GoldKey slot increments to '2'. No new slot is consumed."
    why_human: "Stacking UI behavior requires running game and visual inspection."
  - test: "Fill inventory to weight limit, then walk into another collectable and press E"
    expected: "'Too heavy!' appears on screen as a HUD overlay (not inside the inventory panel). It fades out over approximately 2 seconds."
    why_human: "HUD fade animation via Tween requires running game to observe timing and visual result."
  - test: "Close the inventory panel (Tab/I), then attempt the overweight pickup again"
    expected: "'Too heavy!' HUD label still appears even though the inventory panel is closed."
    why_human: "Requires running game to confirm CanvasLayer overlay is independent of inventory panel visibility."
---

# Phase 2: Grid Inventory UI — Verification Report

**Phase Goal:** Deliver a functional grid-based inventory UI that displays items in a 5x3 slot grid, updates in real time when items are collected, and shows a "Too heavy!" HUD message when the weight limit is exceeded.
**Verified:** 2026-03-11
**Status:** human_needed — all automated checks pass; 5 items require human in-game verification
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

The Phase 2 success criteria from ROADMAP.md define four truths:

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Opening the inventory shows a fixed grid of slots with item icons and quantity labels | ? HUMAN | inventory_ui.gd instantiates 15 slots at runtime via SLOT_SCENE.instantiate(); inventory_slot_ui.gd exposes update(slot) that sets icon or abbrev + quantity; scenes confirmed structurally correct |
| 2 | The inventory panel displays current weight and max capacity (e.g., "12.5 / 20 kg") | ✓ VERIFIED | WeightLabel node in inventory_ui.tscn; _refresh_weight_label() calls InventoryUIHelpers.format_weight(); signal-driven via inventory_changed.connect; format_weight("%.1f / %.0f kg") matches expected format; 5 unit tests green |
| 3 | Attempting to pick up an item when over weight limit shows a visible rejection message | ✓ VERIFIED | insert_rejected signal in inventory.gd; world.gd connects insert_rejected to _on_insert_rejected(); RejectionLabel in world.tscn (modulate.a=0 start, text="Too heavy!"); FadeTimer wait_time=2.0 one_shot=true; Tween fade on timeout — full chain wired; ? HUMAN for visual confirmation |
| 4 | Stackable items share a single slot and increment quantity rather than filling a new slot | ✓ VERIFIED (logic) | InventorySlot.can_stack() uses item.id; item id fields set (&"axe", &"gold_key"); GoldKey2 scene instance added for stacking test; ? HUMAN for visual confirmation in-game |

**Automated Score:** 14/14 must-have checks pass (truths 2 and 3 fully automated; truths 1 and 4 have structural verification complete, visual/runtime confirmation pending human)

---

## Required Artifacts

### Plan 02-01 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/resources/inventory.gd` | inventory_changed and insert_rejected signals; emit rules on insert() | ✓ VERIFIED | signal inventory_changed (line 3); signal insert_rejected (line 4); emit logic after both insert loops (lines 52-58); inventory_changed.emit() when inserted > 0; insert_rejected.emit() when weight_budget <= 0 |
| `tests/unit/test_inventory_ui_helpers.gd` | Unit tests for abbreviate() and format_weight() | ✓ VERIFIED | 5 tests: abbreviate short/long/exact, format_weight normal/zero; all 5 passing in 79/79 suite |
| `tests/unit/test_inventory.gd` | Signal emission tests for insert_rejected and inventory_changed | ✓ VERIFIED | 4 signal tests added at lines 286-322: emitted/not emitted for both signals; uses watch_signals + assert_signal_emitted/not_emitted; all passing |

### Plan 02-02 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scenes/inventory_slot_ui.tscn` | Slot scene with TextureRect + AbbrevLabel + QuantityLabel nodes | ✓ VERIFIED | IconRect (TextureRect, line 19), AbbrevLabel (Label, line 29), QuantityLabel (Label, line 39) — all present in tscn |
| `scripts/inventory_slot_ui.gd` | update(slot) display logic per slot | ✓ VERIFIED | update(slot: InventorySlot) exists; modulate.a = 0.4 for empty, 1.0 for occupied; icon vs abbreviation branch; calls InventoryUIHelpers.abbreviate() |
| `scenes/inventory_ui.tscn` | Panel with GridContainer and WeightLabel; no hardcoded slot children | ✓ VERIFIED | WeightLabel present (line 39); GridContainer columns=5; 0 hardcoded InventorySlotUI instances; clean 47-line tscn |
| `scripts/inventory_ui.gd` | SLOT_COUNT constant, runtime instantiation, signal wiring, weight display | ✓ VERIFIED | SLOT_COUNT = 15 (line 3); SLOT_SCENE.instantiate() loop in _ready() (line 17); set_inventory() connects inventory_changed to both refreshers (lines 28-29); _refresh_weight_label() uses format_weight (lines 49-51) |

### Plan 02-03 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/world.gd` | Inventory wiring and rejection signal connection | ✓ VERIFIED | set_inventory(player.inventory) called in _ready() (line 10); insert_rejected.connect(_on_insert_rejected) (line 11); _on_insert_rejected() sets modulate.a=1.0 and starts timer (lines 15-17); existing _on_detection_area_home_body_entered preserved |
| `scenes/world.tscn` | RejectionLabel node on CanvasLayer with Timer child | ✓ VERIFIED | RejectionLabel (Label, modulate=Color(1,1,1,0), text="Too heavy!") under CanvasLayer (line 1966); FadeTimer (Timer, wait_time=2.0, one_shot=true) as child (lines 1978-1980) |
| `scripts/collectable.gd` | Rejection callback when collect() returns false | ✓ VERIFIED (deviation noted) | collect() captures success and calls queue_free() only on success (lines 26-28); comment documents signal path. Plan must_have artifact spec said `contains: "show_rejection"` — actual implementation uses the insert_rejected signal directly (inventory.gd → world.gd) rather than a collectable-side HUD call. The goal truth (rejection shown when collect fails) is achieved by the superior signal path. No functional gap. |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scripts/resources/inventory.gd` | `signal inventory_changed` | emitted inside insert() when inserted > 0 | ✓ WIRED | `inventory_changed.emit()` at line 54 |
| `scripts/resources/inventory.gd` | `signal insert_rejected` | emitted inside insert() when weight_budget <= 0 | ✓ WIRED | `insert_rejected.emit()` at line 58 |
| `scripts/inventory_ui.gd` | `scripts/inventory_slot_ui.gd` | SLOT_SCENE.instantiate() then slot_node.update(slot) | ✓ WIRED | `SLOT_SCENE.instantiate()` (line 17); `slot_nodes[i].update(...)` (lines 40, 43) |
| `scripts/inventory_ui.gd` | `inventory.inventory_changed` | connected in set_inventory() to _refresh_slots and _refresh_weight_label | ✓ WIRED | `inv.inventory_changed.connect(_refresh_slots)` (line 28); `inv.inventory_changed.connect(_refresh_weight_label)` (line 29) |
| `scripts/world.gd` | `scripts/inventory_ui.gd` | inventory_ui.set_inventory(player.inventory) in _ready() | ✓ WIRED | `inventory_ui.set_inventory(player.inventory)` (line 10) |
| `scripts/world.gd` | `RejectionLabel._on_insert_rejected()` | player.inventory.insert_rejected.connect(...) | ✓ WIRED | `player.inventory.insert_rejected.connect(_on_insert_rejected)` (line 11) |
| `scenes/world.tscn` | `RejectionLabel` | CanvasLayer child, sibling of InventoryUI | ✓ WIRED | RejectionLabel at `parent="CanvasLayer"` (line 1966); sibling of InventoryUI |

---

## Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| INV-01 | 02-01, 02-02 | Player can open inventory and see a fixed grid of item slots with icons and quantities | ✓ SATISFIED | inventory_ui.gd instantiates 15-slot grid; inventory_slot_ui.gd renders icon/abbrev + quantity per slot; GridContainer columns=5 (5x3 grid) |
| INV-02 | 02-01, 02-02, 02-03 | Inventory panel shows current weight vs max capacity; rejection message shown when overweight | ✓ SATISFIED | WeightLabel with format_weight() via signal; RejectionLabel "Too heavy!" wired to insert_rejected signal via world.gd; FadeTimer + Tween fade |
| INV-03 | 02-02, 02-03 | Stackable resource items stack up to max_stack limit instead of occupying multiple slots | ✓ SATISFIED (logic) | can_stack() uses item.id; id fields set on axe (&"axe") and gold_key (&"gold_key"); GoldKey2 instance added for runtime stacking verification; unit tests confirm stacking logic |

No orphaned requirements — all three requirements (INV-01, INV-02, INV-03) are mapped to plans and covered by implementation.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scripts/collectable.gd` | 9 | `_process` used for input polling (`is_collectable and Input.is_action_just_pressed`) | ℹ️ Info | Pre-existing pattern, not introduced in Phase 2; no impact on phase goals |

No TODO/FIXME/placeholder comments found in Phase 2 files. No stub implementations (`return null`, `return {}`, `return []`). No `console.log`-only handlers. No empty `_process` loops introduced by this phase.

---

## Human Verification Required

All automated structural and logical checks pass. The following behaviors require running the game in Godot to confirm:

### 1. Inventory Grid Renders Correctly

**Test:** Open Godot, press F5, then press Tab (or I).
**Expected:** A 5x3 grid of 15 slots appears inside the inventory panel. Empty slots are visibly dimmed at ~40% opacity. The weight label at the bottom shows "0.0 / 100 kg".
**Why human:** Godot scene rendering and UI node layout cannot be verified headlessly.

### 2. Item Pickup Fills a Slot in Real Time

**Test:** Walk to a collectable (GoldKey or Axe), press E to pick it up, then open inventory.
**Expected:** One slot transitions from dimmed to full opacity, showing an abbreviation label (e.g. "Gold") and quantity "1". The weight label updates to reflect the new weight.
**Why human:** Real-time signal-driven slot refresh requires running game.

### 3. Stacking Increments Quantity (INV-03)

**Test:** Pick up a second GoldKey2 (placed near player start at Vector2(16, 33)).
**Expected:** The existing GoldKey slot increments its quantity counter to "2". No second slot is consumed.
**Why human:** Visual confirmation of single-slot stacking requires running game.

### 4. "Too heavy!" HUD Appears and Fades

**Test:** Fill inventory to the weight limit by picking up items, then walk into another collectable and press E.
**Expected:** "Too heavy!" appears on screen as an overlay (not inside the inventory panel). It fades out over approximately 2 seconds.
**Why human:** HUD fade animation via Tween requires running game to observe timing and visual result.

### 5. Rejection HUD Works Regardless of Inventory Panel State

**Test:** Close the inventory panel (Tab/I), then attempt the overweight pickup again.
**Expected:** "Too heavy!" HUD label still appears even though the inventory panel is closed.
**Why human:** Requires running game to confirm CanvasLayer overlay is independent of inventory panel visibility state.

---

## Summary

Phase 2 goal is fully implemented at the code level. All 14 automated must-have checks pass across Plans 01, 02, and 03:

- `inventory.gd` emits the correct signals under the correct conditions, covered by 4 passing unit tests.
- `InventoryUIHelpers.abbreviate()` and `format_weight()` are correct, covered by 5 passing unit tests.
- `inventory_slot_ui.tscn` has the three display nodes (IconRect, AbbrevLabel, QuantityLabel); `inventory_slot_ui.gd` implements `update(slot)` with correct opacity logic.
- `inventory_ui.gd` uses `SLOT_COUNT=15`, runtime instantiation, and signal-driven refreshes with no `_process` polling.
- `inventory_ui.tscn` has WeightLabel and no hardcoded slot children.
- `world.gd` wires `set_inventory()` and `insert_rejected` in `_ready()`; `world.tscn` has `RejectionLabel` (modulate.a=0, text="Too heavy!") with `FadeTimer` (2s, one_shot).
- All 9 committed commits from the three plans exist and are confirmed in git history.
- `make lint`, `make format-check`, `make test` all pass (79/79 tests).

One artifact deviation noted: Plan 02-03 specified `collectable.gd` would contain `show_rejection()`. Instead, the rejection path is handled entirely via the `insert_rejected` signal connecting `inventory.gd` to `world.gd._on_insert_rejected()`. This is functionally superior (no HUD coupling in Collectable) and achieves the same observable outcome. `axe.gd` independently guards `queue_free()` to prevent item disappearance on rejection. No functional gap.

Five in-game behaviors require human verification in Godot before the phase can be marked fully complete.

---

_Verified: 2026-03-11_
_Verifier: Claude (gsd-verifier)_
