# Roadmap: Open World

## Milestones

- ✅ **v1.0 Inventory & Combat** — Phases 1–4 (shipped 2026-03-13)
- 🚧 **v1.1 Equipment Slots** — Phases 5–8 (in progress)

## Phases

<details>
<summary>✅ v1.0 Inventory & Combat (Phases 1–4) — SHIPPED 2026-03-13</summary>

- [x] Phase 1: Combat Fix + Data Foundation (3/3 plans) — completed 2026-03-10
- [x] Phase 2: Grid Inventory UI (3/3 plans) — completed 2026-03-11
- [x] Phase 3: Item Management (4/4 plans) — completed 2026-03-12
- [x] Phase 4: Inventory Slot-Full Rejection (1/1 plan) — completed 2026-03-13

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### 🚧 v1.1 Equipment Slots (In Progress)

**Milestone Goal:** Add weapon and tool equipment slots with right-click context menu, gameplay wiring for the equipped weapon, and a placeholder visual indicator on the player.

- [x] **Phase 5: Data Foundation** — EquipmentData Resource, right-click signal on slot UI, context menu architecture (completed 2026-03-18)
- [x] **Phase 6: Equip/Unequip Flow** — Atomic equip/unequip logic, swap on re-equip, full-bag rejection (completed 2026-03-19)
- [ ] **Phase 7: Combat Wiring + HUD Strip** — hit() weapon dispatch, always-visible HUD strip, player visual indicator
- [ ] **Phase 8: Integration Polish** — Popup positioning, popup lifecycle, context menu for HUD slots

## Phase Details

### Phase 5: Data Foundation
**Goal**: EquipmentData Resource is established as the single source of truth for equipment state, and the slot UI emits a right-click signal with context-aware menu logic
**Depends on**: Phase 4 (v1.0 complete)
**Requirements**: EQUIP-05, CTXMENU-01, CTXMENU-02, CTXMENU-04
**Success Criteria** (what must be TRUE):
  1. An item equipped to a weapon or tool slot is absent from every bag slot — no item exists in both places simultaneously
  2. Right-clicking a bag slot that contains a weapon item shows a menu with "Equip" and "Drop" options
  3. Right-clicking a bag slot that contains a consumable item shows a menu with "Consume" and "Drop" options
  4. Closing the inventory panel dismisses any open context menu
**Plans**: 2 plans

Plans:
- [ ] 05-01-PLAN.md — EquipmentData Resource (TDD: equip/unequip methods, equipment_changed signal)
- [ ] 05-02-PLAN.md — Right-click signal + PopupMenu wiring in InventoryUI; equipment_data export on Player

### Phase 6: Equip/Unequip Flow
**Goal**: Players can move items between the bag and equipment slots atomically — equip removes from bag, unequip returns to bag, full-bag is rejected without data loss
**Depends on**: Phase 5
**Requirements**: EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04
**Success Criteria** (what must be TRUE):
  1. Player can equip a weapon from the bag to the weapon slot; the item disappears from the bag grid
  2. Equipping a second weapon when the slot is occupied returns the old weapon to the bag and places the new one in the slot
  3. Player can unequip a weapon back to the bag; if the bag is full, the unequip is rejected and the weapon stays equipped
  4. Player can equip a tool item to the tool slot (item moves from bag; no gameplay effect wired yet)
**Plans**: 2 plans

Plans:
- [ ] 06-01-PLAN.md — player_equipment_data.tres + test scaffold + atomic equip/unequip in InventoryUI (TDD)
- [ ] 06-02-PLAN.md — Wire set_equipment_data() in world.gd, assign Player Inspector field, human-verify equip flow

### Phase 7: Combat Wiring + HUD Strip
**Goal**: The equipped weapon drives the player's hit() attack with a fist fallback, a HUD strip showing both equipment slots is always visible, and a placeholder indicator appears on the player when a weapon is equipped
**Depends on**: Phase 6
**Requirements**: CMBT-03, CMBT-04, CMBT-05, HUD-01, HUD-02
**Success Criteria** (what must be TRUE):
  1. Attacking with a weapon equipped deals the weapon's damage value (not fist damage)
  2. Attacking with no weapon equipped deals fist damage — the player can always attack
  3. Weapon and tool equipment slots are visible on screen at all times, even when the inventory panel is closed
  4. Equipment slots display the icon of the equipped item when occupied
  5. A visible indicator appears on the player character when a weapon is equipped
**Plans**: 2 plans

Plans:
- [ ] 07-01-PLAN.md — Combat dispatch (TDD hit() with weapon damage + fist fallback) + WeaponIndicator on player
- [ ] 07-02-PLAN.md — HUD strip scene (always-visible equipment slots) + world wiring + human verification

### Phase 8: Integration Polish
**Goal**: Context menu and HUD interactions are coherent across all input paths — popup is viewport-safe, cleans up correctly, and right-clicking an equipment slot shows the correct unequip menu
**Depends on**: Phase 7
**Requirements**: CTXMENU-03
**Success Criteria** (what must be TRUE):
  1. Right-clicking an occupied equipment slot shows an "Unequip" and "Drop" context menu (not an "Equip" menu)
  2. The context menu never appears partially off-screen regardless of where the slot sits in the viewport
  3. Closing the inventory panel while a context menu is open dismisses the menu without error
**Plans**: 2 plans

Plans:
- [ ] 08-01: TBD

## Progress

**Execution Order:** Phases execute in numeric order: 5 → 6 → 7 → 8

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Combat Fix + Data Foundation | v1.0 | 3/3 | Complete | 2026-03-10 |
| 2. Grid Inventory UI | v1.0 | 3/3 | Complete | 2026-03-11 |
| 3. Item Management | v1.0 | 4/4 | Complete | 2026-03-12 |
| 4. Inventory Slot-Full Rejection | v1.0 | 1/1 | Complete | 2026-03-13 |
| 5. Data Foundation | 2/2 | Complete   | 2026-03-18 | - |
| 6. Equip/Unequip Flow | v1.1 | Complete    | 2026-03-19 | - |
| 7. Combat Wiring + HUD Strip | 1/2 | In Progress|  | - |
| 8. Integration Polish | v1.1 | 0/? | Not started | - |
