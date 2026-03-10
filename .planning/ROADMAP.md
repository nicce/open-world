# Roadmap: Open World — Inventory & Combat v1

## Overview

Three phases deliver a playable, inventory-complete game loop. Phase 1 fixes the combat blocker and hardens the data model so nothing downstream is corrupted. Phase 2 builds the visible grid inventory on that foundation. Phase 3 adds item use, item drop, and pickup feedback — closing the full item lifecycle from world to inventory and back.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Combat Fix + Data Foundation** - Fix HIT state lockout, add item identity, harden inventory data model (completed 2026-03-10)
- [ ] **Phase 2: Grid Inventory UI** - Replace debug panel with fixed-slot grid showing icons, quantities, and weight
- [ ] **Phase 3: Item Management** - Consumable use, item drop to world, pickup notification

## Phase Details

### Phase 1: Combat Fix + Data Foundation
**Goal**: Player can fight without locking up and the inventory data model is correct for all downstream work
**Depends on**: Nothing (first phase)
**Requirements**: CMBT-01, CMBT-02, DATA-01, DATA-02, DATA-03
**Success Criteria** (what must be TRUE):
  1. Player can attack and immediately move again — no state lockout after the HIT animation
  2. Enemies visibly recoil when the player lands a hit
  3. Each item has a stable `id` field distinct from its display name; stacking and removal use `id` for comparison
  4. Loading a scene does not bleed inventory state from a previous session — inventory is deep-copied on load
  5. Adding items at the exact weight limit accepts the item without off-by-one rejection
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md — Write failing test scaffolds for all 5 requirements (Wave 0 RED tests)
- [ ] 01-02-PLAN.md — Fix CMBT-01 (player state lockout) and CMBT-02 (enemy knockback)
- [ ] 01-03-PLAN.md — Fix DATA-01 (item id field), DATA-02 (deep copy), DATA-03 (floori weight)

### Phase 2: Grid Inventory UI
**Goal**: Player can open the inventory and see a proper fixed-slot grid with item icons, quantities, and weight feedback
**Depends on**: Phase 1
**Requirements**: INV-01, INV-02, INV-03
**Success Criteria** (what must be TRUE):
  1. Opening the inventory shows a fixed grid of slots with item icons and quantity labels
  2. The inventory panel displays current weight and max capacity (e.g., "12.5 / 20 kg")
  3. Attempting to pick up an item when over weight limit shows a visible rejection message
  4. Stackable items share a single slot and increment their quantity counter rather than filling a new slot
**Plans**: TBD

### Phase 3: Item Management
**Goal**: Player can consume health items from inventory, drop items back into the world, and see feedback on pickups
**Depends on**: Phase 2
**Requirements**: ITEM-01, ITEM-02, ITEM-03
**Success Criteria** (what must be TRUE):
  1. Selecting a health item in inventory and pressing use restores the player's HP and removes one unit of the item
  2. Dropping an item from inventory spawns a collectable at the player's position that can be picked up again
  3. A brief on-screen notification appears when the player successfully picks up an item
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Combat Fix + Data Foundation | 2/3 | Complete    | 2026-03-10 |
| 2. Grid Inventory UI | 0/TBD | Not started | - |
| 3. Item Management | 0/TBD | Not started | - |
