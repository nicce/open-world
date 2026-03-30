---
phase: 06-equip-unequip-flow
verified: 2026-03-19T10:00:00Z
status: human_needed
score: 9/9 must-haves verified
human_verification:
  - test: "Open Godot, press F5, pick up a weapon, open inventory (Tab), right-click the weapon slot, select Equip"
    expected: "Weapon disappears from the bag grid; no crash; no duplicate item visible"
    why_human: "Visual bag-grid refresh and context menu rendering cannot be verified by grep"
  - test: "With a weapon equipped from the previous test, pick up a second weapon, right-click it, select Equip"
    expected: "Second weapon occupies the equipment slot; first weapon reappears in a bag slot"
    why_human: "Swap round-trip involves UI refresh of multiple slots and visual confirmation"
  - test: "Right-click a tool-category item in the bag; verify 'Equip' appears in the context menu"
    expected: "Context menu shows 'Equip' and 'Drop' for tool items (not just weapon items)"
    why_human: "Context menu rendering depends on Godot PopupMenu at runtime"
---

# Phase 6: Equip/Unequip Flow Verification Report

**Phase Goal:** Players can move items between the bag and equipment slots atomically — equip removes from bag, unequip returns to bag, full-bag is rejected without data loss
**Verified:** 2026-03-19
**Status:** human_needed (all automated checks pass; 3 visual behaviours require in-game confirmation)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

All truths were derived from the ROADMAP.md Success Criteria for Phase 6 plus the must_haves listed in both plan frontmatters.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Equipping a weapon removes it from the bag and places it in equipment_data.weapon | VERIFIED | `test_equip_weapon_removes_from_bag` and `test_equip_weapon_stores_in_equipment_data` pass; `_do_equip_weapon` calls `inventory.remove()` before `equip_weapon()` |
| 2 | Equipping a weapon when slot is occupied returns the old weapon to the bag | VERIFIED | `test_equip_weapon_swap_returns_displaced_to_bag` and `test_equip_weapon_swap_new_weapon_in_slot` pass; displaced item returned by `equip_weapon()` is inserted back |
| 3 | Unequipping a weapon inserts it into the bag; if bag is full the weapon stays equipped | VERIFIED | `test_unequip_weapon_returns_to_bag` and `test_unequip_weapon_full_bag_stays_equipped` pass; `_do_unequip_weapon` inserts first, calls `unequip_weapon()` only if `remaining == 0` |
| 4 | Equipping a tool removes it from the bag and places it in equipment_data.tool | VERIFIED | `test_equip_tool_removes_from_bag` passes; `_do_equip_tool` follows the same remove-before-equip pattern |
| 5 | No item ever exists simultaneously in both the bag and an equipment slot | VERIFIED | `test_no_item_in_both_bag_and_weapon_slot` passes; ordering enforced by remove-before-equip in all `_do_*` methods |
| 6 | InventoryUI has a non-null _equipment_data reference at runtime | VERIFIED | `world.gd:_ready()` line 14 calls `inventory_ui.set_equipment_data(player.equipment_data)`; `player.tscn` line 403 assigns `player_equipment_data.tres` to `equipment_data` field |
| 7 | Right-clicking a weapon in the bag and selecting Equip removes it from the bag grid | HUMAN NEEDED | Logic is wired; visual confirmation requires running the game |
| 8 | The equipped weapon reappears in the bag when a second weapon is equipped | HUMAN NEEDED | Swap logic verified by tests; visual slot refresh requires runtime |
| 9 | Tool items show "Equip" in the context menu | HUMAN NEEDED | `_on_slot_right_clicked` has the `item.category == Item.Category.TOOL` branch at line 148; PopupMenu rendering requires runtime |

**Score:** 6/6 automated truths verified; 3 visual truths awaiting human confirmation

---

### Required Artifacts

#### Plan 06-01 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/resources/player_equipment_data.tres` | EquipmentData resource for Player Inspector | VERIFIED | Exists; contains `script_class="EquipmentData"` and references `equipment_data.gd` via `ExtResource("1_equip")` |
| `scripts/inventory_ui.gd` | set_equipment_data(), _do_equip_weapon(), _do_equip_tool(), _do_unequip_weapon(), tool Equip menu entry | VERIFIED | All five functions present; MENU_EQUIP stub replaced with dispatch at lines 158-165; tool branch at line 148 |
| `tests/unit/test_equip_flow.gd` | GUT unit tests for EQUIP-01 through EQUIP-04 | VERIFIED | Extends GutTest; 8 tests; all 8 pass |

#### Plan 06-02 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/world.gd` | set_equipment_data() wiring call in _ready() | VERIFIED | Line 14: `inventory_ui.set_equipment_data(player.equipment_data)` |
| `scenes/player.tscn` | equipment_data Inspector field assigned to player_equipment_data.tres | VERIFIED | Line 4: ext_resource entry for `player_equipment_data.tres`; line 403: `equipment_data = ExtResource("equip_data")` |

---

### Key Link Verification

#### Plan 06-01 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `inventory_ui.gd:_on_context_menu_id_pressed(MENU_EQUIP)` | `_do_equip_weapon()` or `_do_equip_tool()` | `item is WeaponItem` check | WIRED | Lines 162-165: `if item is WeaponItem: _do_equip_weapon(...)` / `elif item.category == Item.Category.TOOL: _do_equip_tool(...)` |
| `inventory_ui.gd:_do_equip_weapon` | `_equipment_data.equip_weapon()` | `inventory.remove()` then `equip_weapon()` then optional `insert(displaced)` | WIRED | Lines 175-181: exact transaction sequence implemented |
| `inventory_ui.gd:_do_unequip_weapon` | `_equipment_data.unequip_weapon()` | `inventory.insert()` FIRST, `unequip_weapon()` only if remaining == 0 | WIRED | Lines 193-200: insert-before-unequip ordering correctly implemented |

#### Plan 06-02 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scripts/world.gd:_ready()` | `scripts/inventory_ui.gd:set_equipment_data()` | `inventory_ui.set_equipment_data(player.equipment_data)` | WIRED | Line 14 in world.gd; `set_equipment_data` method present in inventory_ui.gd at line 61 |
| `scenes/player.tscn` | `scripts/resources/player_equipment_data.tres` | Inspector `equipment_data` field | WIRED | ext_resource entry at file line 4; assignment at node line 403 |

---

### Requirements Coverage

Both plans declare `requirements: [EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04]`. Cross-referenced against REQUIREMENTS.md:

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| EQUIP-01 | 06-01, 06-02 | Player can equip a weapon item from the bag to a dedicated weapon slot | SATISFIED | `_do_equip_weapon` removes from bag and stores in `equipment_data.weapon`; test passes |
| EQUIP-02 | 06-01, 06-02 | Equipping a weapon when the slot is already occupied swaps the old weapon back to the bag | SATISFIED | Displaced weapon returned by `equip_weapon()` is re-inserted; swap test passes |
| EQUIP-03 | 06-01, 06-02 | Player can unequip a weapon; it returns to the bag (rejected if bag is full) | SATISFIED | `_do_unequip_weapon` insert-first ordering; full-bag test passes; weapon stays equipped when `remaining > 0` |
| EQUIP-04 | 06-01, 06-02 | Player can equip a tool item to a dedicated tool slot (UI only) | SATISFIED | `_do_equip_tool` implemented; tool category branch in context menu; test passes |

**Orphaned requirements check:** REQUIREMENTS.md Traceability table maps EQUIP-01 through EQUIP-04 to Phase 6. No additional Phase 6 requirements appear that are unclaimed by either plan.

**Note on EQUIP-05** ("An item cannot exist simultaneously in the bag and an equipment slot"): REQUIREMENTS.md assigns EQUIP-05 to Phase 5. The Phase 6 PLAN-01 explicitly references it as an invariant to protect (line 302: "to avoid EQUIP-05 violation") and includes a dedicated test `test_no_item_in_both_bag_and_weapon_slot`. EQUIP-05 is correctly treated as a Phase 5 deliverable that Phase 6 must preserve — the invariant is verified to hold in Phase 6 code.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| None | — | — | — |

No TODO/FIXME/placeholder comments found in phase-modified files. No `pass` stubs remain in the MENU_EQUIP handler. No empty implementations (`return null` / `return {}` without intent). The `_do_unequip_weapon` and `_do_unequip_tool` methods are substantive — they guard correctly and perform the atomic transaction.

---

### Automated Test Results

```
133/133 tests pass
  test_equip_flow.gd: 8/8 passed (EQUIP-01 through EQUIP-04 + invariant)
make lint: no problems found
make format-check: 26 files unchanged
```

---

### Human Verification Required

#### 1. EQUIP-01: Weapon equip removes item from bag grid

**Test:** Open Godot, press F5. Pick up a weapon so it appears in the inventory bag. Open inventory (Tab or I). Right-click the weapon slot. Select "Equip".
**Expected:** The weapon tile disappears from the bag grid. No crash. No duplicate item visible anywhere in the grid.
**Why human:** The bag grid refresh (`_refresh_slots` connected to `inventory_changed` signal) and context menu render path involve Godot scene tree and PopupMenu nodes that cannot be exercised headlessly.

#### 2. EQUIP-02: Swap returns old weapon to bag

**Test:** With a weapon already equipped (from test 1), pick up a second weapon. Open inventory, right-click the second weapon, select "Equip".
**Expected:** The second weapon disappears from the bag. The first (previously equipped) weapon reappears in an empty bag slot. The equipment slot (if visible) shows the new weapon.
**Why human:** Round-trip slot refresh across two inventory mutations; requires confirming both the vacated slot and the newly filled slot update correctly.

#### 3. EQUIP-04: Tool item shows "Equip" in context menu

**Test:** If a tool-category item is available in-game, pick it up. Open inventory, right-click the tool item slot.
**Expected:** Context menu shows "Equip" and "Drop" options (not "Consume"). Selecting "Equip" moves the item out of the bag.
**Why human:** Context menu item population depends on Godot's PopupMenu at runtime; the `item.category == Item.Category.TOOL` branch in `_on_slot_right_clicked` is present in code but menu rendering requires visual confirmation.

---

### Gaps Summary

No automated gaps were found. All code-verifiable must-haves pass at all three levels (exists, substantive, wired). The three human-verification items are visual/runtime behaviours that are consistent with the plan's own design (`06-02-PLAN.md` Task 2 is explicitly a `checkpoint:human-verify` gate for EQUIP-01 and EQUIP-02). The SUMMARY for Plan 02 documents that human verification was approved for EQUIP-01 and EQUIP-02 — but this verifier cannot confirm that approval programmatically, hence the items remain flagged here for completeness.

If the human approval from the 06-02-SUMMARY.md is accepted as authoritative evidence, the phase status is **passed**.

---

_Verified: 2026-03-19_
_Verifier: Claude (gsd-verifier)_
