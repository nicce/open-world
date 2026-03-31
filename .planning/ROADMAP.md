# Roadmap: Open World

## Milestones

- ✅ **v1.0 Inventory & Combat** — Phases 1–4 (shipped 2026-03-13)
- ✅ **v1.1 Equipment Slots** — Phases 5–8 (shipped 2026-03-27)
- 🚧 **v1.2 Save & Load** — Phases 9–12 (in progress)

## Phases

<details>
<summary>✅ v1.0 Inventory & Combat (Phases 1–4) — SHIPPED 2026-03-13</summary>

- [x] Phase 1: Combat Fix + Data Foundation (3/3 plans) — completed 2026-03-10
- [x] Phase 2: Grid Inventory UI (3/3 plans) — completed 2026-03-11
- [x] Phase 3: Item Management (4/4 plans) — completed 2026-03-12
- [x] Phase 4: Inventory Slot-Full Rejection (1/1 plan) — completed 2026-03-13

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Equipment Slots (Phases 5–8) — SHIPPED 2026-03-27</summary>

- [x] Phase 5: Data Foundation (2/2 plans) — completed 2026-03-18
- [x] Phase 6: Equip/Unequip Flow (2/2 plans) — completed 2026-03-19
- [x] Phase 7: Combat Wiring + HUD Strip (2/2 plans) — completed 2026-03-20
- [x] Phase 8: Integration Polish (3/3 plans) — completed 2026-03-27

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### 🚧 v1.2 Save & Load (In Progress)

**Milestone Goal:** Persist player progress (stats, inventory, equipment) to disk and restore it on game start, with autosave on key events.

## Phase Details

### Phase 9: Foundation — ItemRegistry and Resource Serialisation
**Goal**: All save/load data contracts exist as pure, unit-tested logic — no file I/O yet
**Depends on**: Phase 8
**Requirements**: REG-01, REG-02, SER-01, SER-02, SER-03, SER-04, SER-05
**Success Criteria** (what must be TRUE):
  1. ItemRegistry autoload resolves any registered item id to its typed Resource instance
  2. ItemRegistry returns null and logs a warning for any unknown id (does not crash)
  3. Inventory.to_dict() / from_dict() round-trip preserves all slot item ids and quantities
  4. EquipmentData.to_dict() / from_dict() round-trip preserves weapon and tool slot contents
  5. HealthComponent.load_health(value) sets HP to the given value without triggering _ready() re-init
**Plans**: 3 plans
- [x] 09-01-PLAN.md — Create Item Resources and ItemRegistry Autoload
- [x] 09-02-PLAN.md — Implement Inventory Sparse Dict Serialisation
- [x] 09-03-PLAN.md — Implement Equipment and Health Serialisation

### Phase 10: SaveManager — Write Path and Player Round-Trip
**Goal**: Player can save and load position and HP via a file that survives game restart
**Depends on**: Phase 9
**Requirements**: SAVE-01, SAVE-02, SAVE-04
**Success Criteria** (what must be TRUE):
  1. Saving writes a valid JSON file to user://save.json using atomic write (no corrupt file on partial write)
  2. After a save, restarting the game restores the player to the saved position
  3. After a save, restarting the game restores the player's HP to the saved value
  4. If no save file exists on start, the game launches normally with no error
**Plans**: 2 plans
- [ ] 10-01-PLAN.md — SaveManager and File I/O
- [ ] 10-02-PLAN.md — Integration and Player Round-Trip

### Phase 11: Full Round-Trip — Inventory and Equipment
**Goal**: All player-owned items survive a save/load cycle exactly as they were
**Depends on**: Phase 10
**Requirements**: SAVE-03
**Success Criteria** (what must be TRUE):
  1. After a save and restart, the player's bag contains the same items in the same quantities
  2. After a save and restart, the player's equipped weapon and tool slots are restored
  3. Inventory UI and HUD strip reflect the loaded state immediately on game start without additional interaction
  4. Items do not appear in both the bag and equipment slots after load (EQUIP-05 invariant holds)
**Plans**: [To be planned]

### Phase 12: Autosave Triggers and Polish
**Goal**: The game saves automatically at key moments and the save file is version-stamped
**Depends on**: Phase 11
**Requirements**: TRIG-01, TRIG-02, TRIG-03
**Success Criteria** (what must be TRUE):
  1. Sleeping at the campfire triggers a save (progress is preserved without manual action)
  2. The game autosaves on a configurable interval without player intervention
  3. The save file contains a version key that can be inspected for future migration support
  4. Autosave does not fire while the player is dead (no corrupt/inconsistent save state)
**Plans**: 2 plans
- [x] 12-01-PLAN.md — Version key in save format and campfire sleep save trigger
- [x] 12-02-PLAN.md — Autosave timer with configurable interval and dead-player guard

### Phase 13: Campfire Menu Polish — Keyboard Navigation and Fire Control
**Goal**: The campfire menu is fully keyboard-driven and exposes fire control so the player can light or extinguish the fire from the menu
**Depends on**: Phase 10
**Requirements**: UI-01, UI-02, FIRE-01
**Success Criteria** (what must be TRUE):
  1. Arrow keys (up/down) move focus between menu buttons; Enter/Space activates the focused button
  2. The menu can be closed with the interact key (E) or a close button without touching the mouse
  3. The campfire menu contains a "Light Fire" / "Extinguish Fire" option that toggles fire state
  4. The fire option label reflects current fire state (shows "Light Fire" when out, "Extinguish Fire" when burning)
  5. Adding wood via the menu (or lighting via menu) starts the burn timer correctly
**Plans**: [To be planned]

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Combat Fix + Data Foundation | v1.0 | 3/3 | Complete | 2026-03-10 |
| 2. Grid Inventory UI | v1.0 | 3/3 | Complete | 2026-03-11 |
| 3. Item Management | v1.0 | 4/4 | Complete | 2026-03-12 |
| 4. Inventory Slot-Full Rejection | v1.0 | 1/1 | Complete | 2026-03-13 |
| 5. Data Foundation | v1.1 | 2/2 | Complete | 2026-03-18 |
| 6. Equip/Unequip Flow | v1.1 | 2/2 | Complete | 2026-03-19 |
| 7. Combat Wiring + HUD Strip | v1.1 | 2/2 | Complete | 2026-03-20 |
| 8. Integration Polish | v1.1 | 3/3 | Complete | 2026-03-27 |
| 9. Foundation — ItemRegistry and Resource Serialisation | v1.2 | 3/3 | Complete | 2026-03-30 |
| 10. SaveManager — Write Path and Player Round-Trip | v1.2 | 0/2 | Not started | - |
| 11. Full Round-Trip — Inventory and Equipment | v1.2 | 1/1 | Complete   | 2026-03-31 |
| 12. Autosave Triggers and Polish | v1.2 | 2/2 | Complete    | 2026-03-31 |
| 13. Campfire Menu Polish — Keyboard Navigation and Fire Control | v1.2 | 0/1 | Not started | - |
