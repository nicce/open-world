# Requirements: Open World

**Defined:** 2026-03-10
**Core Value:** A satisfying item and inventory system that makes picking things up, using consumables, and managing weight feel meaningful — everything else depends on items working correctly.

## v1 Requirements

### Combat

- [ ] **CMBT-01**: Player can attack and return to MOVE state (HIT state exit no longer locks player)
- [ ] **CMBT-02**: Enemies are knocked back when struck by the player

### Inventory UI

- [ ] **INV-01**: Player can open inventory and see a fixed grid of item slots with icons and quantities
- [ ] **INV-02**: Inventory panel shows current weight vs max capacity; player sees a rejection message when inventory is full or overweight
- [ ] **INV-03**: Stackable resource items stack up to their max_stack limit instead of occupying multiple slots

### Item Management

- [ ] **ITEM-01**: Player can select a consumable (health item) in inventory and use it to restore HP
- [ ] **ITEM-02**: Player can drop an item from inventory and it reappears as a collectable in the world at the player's position
- [ ] **ITEM-03**: Player sees a brief notification when an item is successfully picked up

### Data Model

- [ ] **DATA-01**: Each item has a stable `id: StringName` field used for identity checks (stacking, removal, queries), distinct from display name
- [ ] **DATA-02**: Player's inventory is deep-copied on scene load (`inventory.duplicate(true)`) to prevent shared Resource mutation across sessions
- [ ] **DATA-03**: Weight capacity calculation uses `floori()` instead of `int()` to avoid float truncation off-by-one errors

## v2 Requirements

### Combat

- Enemy loot drops — enemies drop items when killed
- Additional enemy types

### Inventory

- Equipment slots — separate weapon/tool slots above bag grid
- Hotbar — quick-access row, always visible
- Weapon equip changes attack stats

### World

- Resource harvesting — trees and rocks with HarvestableComponent; tool-gated
- Day/night cycle
- NPC interactions and quests

### Systems

- Save / load — persist game state across sessions (build after inventory and world are stable)
- Crafting / recipe system (requires item registry foundation)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real art assets (sprites, tilesets) | Deferred to future milestone — placeholder art unblocks all mechanic work |
| Farming / crop system | Requires time system and tile manipulation — large orthogonal dependency |
| Building / structure placement | No overlap with current systems; large new surface area |
| NPC dialogue / quests | No NPC entities, dialogue tree, or quest system exists |
| Hunger / stamina | No food loop to refill — pure punishment without relief mechanic |
| Item durability | Adds friction without payoff at this stage |
| Multiplayer | Explicitly never — single-player only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CMBT-01 | Phase 1 | Pending |
| CMBT-02 | Phase 1 | Pending |
| DATA-01 | Phase 1 | Pending |
| DATA-02 | Phase 1 | Pending |
| DATA-03 | Phase 1 | Pending |
| INV-01 | Phase 2 | Pending |
| INV-02 | Phase 2 | Pending |
| INV-03 | Phase 2 | Pending |
| ITEM-01 | Phase 3 | Pending |
| ITEM-02 | Phase 3 | Pending |
| ITEM-03 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-10*
*Last updated: 2026-03-10 after initial definition*
