---
phase: 05-data-foundation
verified: 2026-03-18T14:00:00Z
status: human_needed
score: 4/5 must-haves verified
re_verification: null
gaps: null
human_verification:
  - test: "Right-clicking a weapon slot shows Equip + Drop"
    expected: "PopupMenu appears with exactly two items: 'Equip' and 'Drop'"
    why_human: "PopupMenu.popup() is a runtime visual event; cannot assert popup contents without running the game"
  - test: "Right-clicking a health-item slot shows Consume + Drop"
    expected: "PopupMenu appears with exactly two items: 'Consume' and 'Drop'"
    why_human: "Same — runtime visual assertion required"
  - test: "Right-clicking an empty slot shows no menu"
    expected: "No popup appears; no visual artifact"
    why_human: "Absence of a popup cannot be confirmed by static analysis"
  - test: "Closing inventory panel dismisses any open context menu"
    expected: "Popup disappears when Tab/I is pressed to hide the inventory"
    why_human: "Requires live Godot session to observe dismissal behaviour"
  - test: "Player Inspector shows Equipment Data export field"
    expected: "'Equipment Data' field is visible in the Inspector on the Player node (currently null)"
    why_human: "Godot Inspector fields are not stored in .tscn for null-default typed Resource exports"
---

# Phase 5: Data Foundation Verification Report

**Phase Goal:** EquipmentData Resource is established as the single source of truth for equipment state, and the slot UI emits a right-click signal with context-aware menu logic
**Verified:** 2026-03-18T14:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Success Criteria from ROADMAP.md are used as the primary truths. Plan 05-01 adds one additional truth that is internal to the data layer.

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | An item equipped to a weapon or tool slot is absent from every bag slot (no simultaneous presence) | ? UNCERTAIN | `EquipmentData` provides the displaced-item return-value contract. The plan explicitly defers atomicity enforcement to Phase 6. Phase 5 satisfies its portion: `equip_weapon()` returns the displaced item so Phase 6 can remove it from the bag atomically. No evidence of a design gap — this is an intentional staged delivery. |
| 2   | Right-clicking a bag slot with a weapon item shows a menu with "Equip" and "Drop" | ? NEEDS HUMAN | Code path is fully wired: `right_clicked` → `_on_slot_right_clicked` → `_popup_menu.add_item("Equip")` + `add_item("Drop")`. Visual confirmation requires running the game. |
| 3   | Right-clicking a bag slot with a consumable shows a menu with "Consume" and "Drop" | ? NEEDS HUMAN | Code path wired: `item is HealthItem` branch → `add_item("Consume")` + `add_item("Drop")`. Visual confirmation requires running the game. |
| 4   | Closing the inventory panel dismisses any open context menu | ? NEEDS HUMAN | `_popup_menu.hide()` is called inside the `if not visible:` branch of `_input()`. Correctness is code-verifiable; dismissal behaviour requires live game confirmation. |
| 5   | `equip_weapon()` / `unequip_weapon()` / `equip_tool()` / `unequip_tool()` store the item, return the displaced item, and emit `equipment_changed` exactly once | VERIFIED | 22 GUT tests in `tests/unit/test_equipment_data.gd` cover all 8 behaviour cases. Implementation in `scripts/resources/equipment_data.gd` matches spec: mutate-then-emit pattern confirmed. |

**Score:** 1 programmatically VERIFIED, 3 require human confirmation, 1 UNCERTAIN (intentional staged delivery — not a gap)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `scripts/resources/equipment_data.gd` | EquipmentData Resource with equip/unequip methods and `equipment_changed` signal | VERIFIED | `class_name EquipmentData extends Resource`, signal declared, 4 methods implemented, mutate-before-emit confirmed |
| `tests/unit/test_equipment_data.gd` | GUT unit tests for all EquipmentData method contracts | VERIFIED | 22 tests covering all 8 behaviour cases; uses `watch_signals` / `assert_signal_emitted` pattern |
| `scripts/inventory_slot_ui.gd` | `right_clicked(slot_node: Panel)` signal emitted on `MOUSE_BUTTON_RIGHT` | VERIFIED | Signal declared on line 4; `_gui_input` correctly dispatches `MOUSE_BUTTON_LEFT` → `slot_clicked` and `MOUSE_BUTTON_RIGHT` → `right_clicked`; `set_input_as_handled()` called for both |
| `scripts/inventory_ui.gd` | PopupMenu child, `_on_slot_right_clicked` handler, dismissal on hide, const IDs | VERIFIED | `MENU_EQUIP=0`, `MENU_CONSUME=1`, `MENU_DROP=2` present; `@onready _popup_menu` present; `right_clicked.connect` in `_ready()` loop; `_popup_menu.hide()` in inventory-close path; `_on_slot_right_clicked` and `_on_context_menu_id_pressed` implemented |
| `scenes/inventory_ui.tscn` | PopupMenu child node named "PopupMenu" | VERIFIED | Line 48 of tscn: `[node name="PopupMenu" type="PopupMenu" parent="."]` |
| `scripts/player.gd` | `@export var equipment_data: EquipmentData` field | VERIFIED | Line 11: `@export var equipment_data: EquipmentData` — added after `inventory` as specified |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `equipment_data.gd` | `weapon_item.gd` | `@export var weapon: WeaponItem` typed field | WIRED | Line 5 of equipment_data.gd confirms typed field |
| `equipment_data.gd` | `signal equipment_changed` | emitted after every mutate | WIRED | All 4 methods call `equipment_changed.emit()` after field assignment |
| `inventory_slot_ui.gd` | `inventory_ui.gd` | `slot.right_clicked.connect(_on_slot_right_clicked)` in `_ready()` loop | WIRED | Line 29 of inventory_ui.gd: `slot.right_clicked.connect(_on_slot_right_clicked)` |
| `inventory_ui.gd` | PopupMenu node | `@onready _popup_menu: PopupMenu = $PopupMenu`; `id_pressed.connect` in `_ready()` | WIRED | Line 18 declares `@onready`; line 30: `_popup_menu.id_pressed.connect(_on_context_menu_id_pressed)` |
| `inventory_ui.gd _input` | `_popup_menu.hide()` | called when visible becomes false | WIRED | Line 39: `_popup_menu.hide()` inside `if not visible:` branch |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| EQUIP-05 | 05-01-PLAN.md | An item cannot exist simultaneously in the bag and an equipment slot | PARTIAL — STAGED | `EquipmentData` establishes the displaced-item return contract. Full enforcement (bag removal + equip atomically) is deferred to Phase 6 by design. REQUIREMENTS.md marks this Complete, which reflects the data-layer portion being done. |
| CTXMENU-01 | 05-02-PLAN.md | Right-clicking a bag slot shows a context menu | NEEDS HUMAN | Code wiring confirmed; visual requires game run |
| CTXMENU-02 | 05-02-PLAN.md | Context menu shows "Equip"+"Drop" for weapon/tool; "Consume"+"Drop" for consumables | NEEDS HUMAN | Item-type branching logic confirmed in code; visual requires game run |
| CTXMENU-04 | 05-02-PLAN.md | Context menu dismisses when inventory panel is closed | NEEDS HUMAN | `_popup_menu.hide()` call confirmed in close path; dismissal requires game run |

No orphaned requirements: all four phase-5 IDs (EQUIP-05, CTXMENU-01, CTXMENU-02, CTXMENU-04) are declared in a plan and traced in REQUIREMENTS.md traceability table. No additional phase-5 IDs appear in REQUIREMENTS.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `scripts/player.gd` | 75 | `# TODO how do we handle different equipped weapons?` | Info | Pre-existing comment; unrelated to Phase 5 scope |
| `scripts/inventory_ui.gd` | 152 | `pass  # Phase 6 wires equip flow` | Info | Intentional stub per plan. `MENU_EQUIP` handler is a deliberate placeholder; Phase 6 fills it. Not a blocker. |

No blocker anti-patterns. Both flagged items are either pre-existing or intentional per the plan specification.

### Human Verification Required

#### 1. Right-click weapon slot shows Equip + Drop

**Test:** Open the game (F5). Collect a sword/weapon into the bag. Press Tab/I to open inventory. Right-click the slot containing the weapon.
**Expected:** A popup menu appears with exactly two entries: "Equip" and "Drop".
**Why human:** `PopupMenu.popup()` is a runtime display event. The code path is fully wired but the visual result can only be confirmed in-engine.

#### 2. Right-click health item slot shows Consume + Drop

**Test:** Collect a health item into the bag. Right-click its slot.
**Expected:** A popup menu appears with exactly two entries: "Consume" and "Drop".
**Why human:** Same as above — runtime assertion required.

#### 3. Right-click empty slot shows nothing

**Test:** Right-click a slot with no item.
**Expected:** No menu appears.
**Why human:** Absence of popup cannot be confirmed by static grep.

#### 4. Inventory close dismisses open popup

**Test:** Right-click a weapon slot to open the context menu. While the menu is visible, press Tab or I to close the inventory panel.
**Expected:** Both the inventory panel and the popup disappear simultaneously.
**Why human:** Dismissal behaviour is a live-session event.

#### 5. Player Inspector shows Equipment Data field

**Test:** Open Godot editor. Select the Player node in the world scene. Check the Inspector.
**Expected:** An "Equipment Data" export field is visible (value: null or assigned Resource).
**Why human:** Godot does not write `null`-default typed Resource exports to .tscn, so absence from player.tscn is expected. The field declaration in player.gd is confirmed but the Inspector rendering must be verified in-editor.

### Gaps Summary

No code gaps found. All artifacts exist and are substantive (not stubs). All key links are wired. The only remaining items are runtime/visual behaviours that require human confirmation in Godot. The MENU_EQUIP `pass` stub is an intentional Phase 5 boundary — Phase 6 completes it.

The EQUIP-05 "simultaneous presence" contract is correctly staged: Phase 5 delivers the return-value API that makes atomic swaps possible; Phase 6 enforces the invariant by doing the swap. The REQUIREMENTS.md traceability table already marks EQUIP-05 as Complete for Phase 5, consistent with this interpretation.

---

_Verified: 2026-03-18T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
