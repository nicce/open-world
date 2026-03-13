---
phase: 03-item-management
verified: 2026-03-12T00:00:00Z
status: human_needed
score: 9/9 must-haves verified
re_verification: false
human_verification:
  - test: "Open Godot, run game (F5), open inventory (Tab/I), click an occupied slot to select it, click again to deselect, click an empty slot and verify no highlight"
    expected: "Yellow-gold border appears on selected slot; clicking again removes it; empty slots produce no effect"
    why_human: "StyleBoxFlat border rendering depends on Godot scene tree and Panel theme overrides — cannot be asserted without running the editor"
  - test: "Take damage from an enemy, open inventory, select a Medpack slot, press E, verify HP increases and Medpack quantity decrements by 1"
    expected: "Health bar visually increases; slot quantity decrements (or slot clears if last unit); non-consumables (key) produce no HP change when E is pressed"
    why_human: "HealthComponent.increase() effect on health bar requires running game; _use_selected() chain through scene tree cannot be verified headlessly"
  - test: "Open inventory, select a Gold Key slot, press Q, close inventory, and verify a Gold Key collectable appears near the player in the world"
    expected: "A collectable with a Gold Key sprite spawns near player position; walking over it and pressing E re-collects it"
    why_human: "Collectable spawning via get_tree().current_scene.add_child() requires scene tree; world-space position and sprite visibility need visual confirmation"
  - test: "Pick up any item by pressing E near a collectable; verify a '+ [Item Name]' label appears at bottom-center of screen, then fades out after ~2 seconds; pick up two items quickly and verify the label updates to the latest item name"
    expected: "Label appears with correct text, fades to invisible, and resets on rapid pickups"
    why_human: "Label modulate tween and timer reset behavior require running game; replace-on-pickup timing cannot be asserted in unit tests"
---

# Phase 3: Item Management Verification Report

**Phase Goal:** Player can consume health items from inventory, drop items back into the world, and see feedback on pickups
**Verified:** 2026-03-12
**Status:** human_needed (all automated checks pass; 4 items require in-game confirmation)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

All truths are derived from the phase goal and plan must_haves across plans 01 through 04.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All 8 ITEM-01/02/03 unit tests exist and pass | VERIFIED | `make test` 87/87 passed; test_item_management.gd confirmed with 8 named test functions |
| 2 | `_use_selected()` removes 1 unit of a consumable and calls `increase_health` | VERIFIED | inventory_ui.gd lines 75-88; guard chain: consumable check + HealthItem check + inventory.remove() + _player.increase_health(heal) |
| 3 | `_use_selected()` is a no-op for non-consumables and no selection | VERIFIED | inventory_ui.gd early returns on `not slot.item.consumable` and `_selected_index < 0` |
| 4 | `_drop_selected()` removes 1 unit and spawns a Collectable node near player | VERIFIED | inventory_ui.gd lines 103-120; capture-before-remove, COLLECTABLE_SCENE.instantiate(), add_child before global_position set |
| 5 | Dropping the last unit from a slot deselects that slot | VERIFIED | inventory_ui.gd line 119: `if slot.is_empty(): _deselect()` |
| 6 | `player.item_collected` signal emitted with item.name on successful collect() | VERIFIED | player.gd lines 93-97; `item_collected.emit(item.name)` inside success guard |
| 7 | `item_collected` connected in world._ready() to `_on_item_collected()` | VERIFIED | world.gd line 15: `player.item_collected.connect(_on_item_collected)` |
| 8 | `_on_item_collected()` sets pickup_label text and restarts PickupTimer | VERIFIED | world.gd lines 30-33; sets text, sets modulate.a=1.0, calls pickup_timer.start() |
| 9 | `make lint`, `make format-check`, `make test` all pass | VERIFIED | lint: "no problems found"; format-check: "24 files would be left unchanged"; test: 87/87 passed |

**Score: 9/9 truths verified**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/unit/test_item_management.gd` | 8 test cases for ITEM-01/02/03 | VERIFIED | 8 test functions present; FakePlayer inner class; _make_health_item() helper; all 8 pass |
| `scripts/inventory_slot_ui.gd` | slot_clicked signal, _gui_input, set_selected(bool), StyleBoxFlat border | VERIFIED | All 4 elements present at lines 3, 29-32, 35-39, 19-26 |
| `scripts/inventory_ui.gd` | _player, set_player(), _selected_index, _on_slot_clicked(), _deselect(), _use_selected(), _drop_selected(), COLLECTABLE_SCENE | VERIFIED | All elements present; file is 129 lines with substantive implementation |
| `scripts/player.gd` | item_collected signal declared and emitted in collect() | VERIFIED | Line 4: signal declaration; lines 93-97: emitted on success |
| `scripts/world.gd` | pickup_label + pickup_timer @onready, set_player() call, item_collected connected, _on_item_collected(), _on_pickup_timer_timeout() | VERIFIED | All 5 elements present; file is 43 lines with complete wiring |
| `scenes/world.tscn` | PickupLabel (Label, modulate.a=0, bottom-center) + PickupTimer (Timer, one_shot, wait_time=2.0) under CanvasLayer | VERIFIED | Lines 1982-2001 confirmed: modulate=Color(1,1,1,0), anchor_top=1.0, bottom-center positioning, PickupTimer wait_time=2.0 one_shot=true |
| `project.godot` | drop action mapped to Q key (physical_keycode=81) | VERIFIED | Lines 75-82: drop action with physical_keycode=81, unicode=113 |
| `scenes/collectable.tscn` | Collectable scene referenced by COLLECTABLE_SCENE preload | VERIFIED | File exists at scenes/collectable.tscn (697 bytes); collectable.gd has add_to_group("collectables") + closest-wins logic |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `inventory_slot_ui.gd` | `inventory_ui.gd` | slot_clicked.connect(_on_slot_clicked) in _ready() | WIRED | inventory_ui.gd line 22: `slot.slot_clicked.connect(_on_slot_clicked)`; _on_slot_clicked resolves index via grid.get_children().find(slot_node) — fixes the closure-capture bug from smoke test |
| `inventory_ui.gd` | `scripts/player.gd` | _player.increase_health() in _use_selected() | WIRED | inventory_ui.gd line 86: `_player.increase_health(heal)` guarded by `if _player != null` |
| `inventory_ui.gd` | `scenes/collectable.tscn` | COLLECTABLE_SCENE.instantiate() in _drop_selected() | WIRED | inventory_ui.gd line 113: `var node: Collectable = COLLECTABLE_SCENE.instantiate()`; scene file confirmed to exist |
| `scripts/player.gd` | `scripts/world.gd` | item_collected.connect in world._ready() | WIRED | world.gd line 15: `player.item_collected.connect(_on_item_collected)` |
| `scripts/world.gd` | `scenes/world.tscn` | @onready pickup_label + pickup_timer | WIRED | world.gd lines 7-8: `@onready var pickup_label: Label = $CanvasLayer/PickupLabel` and `@onready var pickup_timer: Timer = $CanvasLayer/PickupLabel/PickupTimer`; nodes confirmed in world.tscn |
| `world.gd._ready()` | `inventory_ui.set_player(player)` | set_player() call passes player reference for drop spawning | WIRED | world.gd line 13: `inventory_ui.set_player(player)` |
| `inventory.remove()` | `inventory_changed.emit()` | UI refresh triggered after use/drop | WIRED | inventory.gd line 74: `inventory_changed.emit()` inside remove(); connected to _refresh_slots in set_inventory() |

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| ITEM-01 | 03-01, 03-02, 03-04 | Player can select a consumable (health item) in inventory and use it to restore HP | SATISFIED | _use_selected() in inventory_ui.gd; increase_health() wired; 3 unit tests pass |
| ITEM-02 | 03-01, 03-03, 03-04 | Player can drop an item from inventory and it reappears as a collectable in the world at the player's position | SATISFIED | _drop_selected() in inventory_ui.gd; COLLECTABLE_SCENE.instantiate() with global_position; 3 unit tests pass |
| ITEM-03 | 03-01, 03-02, 03-03, 03-04 | Player sees a brief notification when an item is successfully picked up | SATISFIED | item_collected signal on Player; _on_item_collected() in world.gd; PickupLabel + PickupTimer nodes in world.tscn; 2 unit tests pass |

No orphaned requirements: REQUIREMENTS.md marks ITEM-01, ITEM-02, ITEM-03 as Phase 3 / Complete. All three appear in plan frontmatter requirements fields and have implementation evidence.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scripts/player.gd` | 74 | `func hit(): pass` with TODO comment | Info | Unrelated to Phase 3; pre-existing stub for weapon system |

No anti-patterns found in Phase 3 code paths. All Phase 3 implementations contain substantive logic with no placeholder returns, empty handlers, or TODO comments in the new feature code.

---

### Human Verification Required

The following 4 items cannot be verified programmatically — they require running the game in Godot.

#### 1. Slot Selection Visual

**Test:** Open Godot, run the game (F5). Press Tab/I to open the inventory. Click an occupied slot — a yellow-gold border should appear. Click the same slot again — the border should disappear. Click an empty slot — nothing should happen. Close the inventory with a slot selected, reopen it — no slot should be highlighted.

**Expected:** Yellow-gold (Color(1.0, 0.85, 0.0)) 2px border appears on the selected slot; toggle and close behaviors clear the highlight.

**Why human:** StyleBoxFlat rendering depends on Godot's theme system and Panel node rendering pipeline. The StyleBoxEmpty default + StyleBoxFlat selected pattern was added specifically to fix a smoke-test regression (self_modulate=0 hiding the border). Visual outcome cannot be asserted without running the editor.

#### 2. E Key Uses Medpack (ITEM-01)

**Test:** Take some damage from an enemy. Open inventory, select the Medpack slot, press E. Verify HP visually increases on the health bar and the Medpack quantity decrements by 1 (or the slot clears if last unit). Then select a Gold Key slot, press E — HP should not change.

**Expected:** HP increases; slot quantity decrements; non-consumable key is a silent no-op.

**Why human:** HealthComponent.increase() visual effect on the health bar requires the full scene tree. Unit tests cover the pure data layer (inventory.remove returns correct count) but not the rendered HP bar update.

#### 3. Q Key Drops Item Into World (ITEM-02)

**Test:** Open inventory, select any item (e.g., Gold Key), press Q. Close inventory. Verify a collectable node with the item's sprite appears near the player. Walk to it, press E — it should be collectible again and trigger a pickup notification.

**Expected:** Collectable spawns in world-space near player with correct sprite; re-collection works.

**Why human:** The smoke test (Plan 04) fixed three bugs in this path — closure capture, add_child vs global_position ordering, and collectable texture. These fixes are confirmed in the code, but the world-space spawning and sprite visibility require visual confirmation in-game.

#### 4. Pickup Notification Label (ITEM-03)

**Test:** Walk over a collectable and press E. Verify a "+ [Item Name]" label appears at the bottom-center of the screen and fades out after approximately 2 seconds. Pick up a second item before the first label fades — verify the label text updates to the latest item name.

**Expected:** Label appears at bottom-center, fades after 2s, replaces on rapid pickups.

**Why human:** The fade tween (create_tween + tween_property modulate:a to 0.0) and timer restart behavior require a running Godot instance. The replace-on-pickup behavior (pickup_timer.start() restarts mid-countdown) depends on frame timing.

---

### Summary

All automated checks pass completely:

- 87/87 unit tests GREEN (8 new item management tests + 79 pre-existing tests, zero regressions)
- `make lint` clean (no problems found)
- `make format-check` clean (24 files unchanged)
- All 7 key links wired and verified in source
- All 8 required artifacts exist with substantive, non-stub implementations
- All 3 requirement IDs (ITEM-01, ITEM-02, ITEM-03) have direct implementation evidence

The 4 human verification items cover interactive/visual behaviors that the smoke test (Plan 04) already confirmed working in the running game. The SUMMARY for Plan 04 documents specific bugs found and fixed during that smoke test (closure capture bug, StyleBoxEmpty fix, inventory_changed emit fix, collectable texture fix, add_child ordering fix). Those fixes are reflected in the current codebase state. Human re-verification is recommended to confirm the final state.

---

_Verified: 2026-03-12_
_Verifier: Claude (gsd-verifier)_
