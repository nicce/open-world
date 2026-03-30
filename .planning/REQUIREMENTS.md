# Requirements: Open World

**Defined:** 2026-03-30
**Core Value:** A satisfying item and inventory system that makes picking things up, equipping weapons, using consumables, and managing weight feel meaningful

## v1.2 Requirements

Requirements for milestone v1.2 Save & Load. Each maps to roadmap phases.

### Registry

- [ ] **REG-01**: ItemRegistry autoload maps StringName id to typed Item Resource
- [ ] **REG-02**: ItemRegistry logs a warning for unknown ids and returns null gracefully

### Serialisation

- [ ] **SER-01**: Inventory.to_dict() serialises all slots by item id and quantity
- [ ] **SER-02**: Inventory.from_dict() restores slots by direct assignment (bypasses insert rules)
- [ ] **SER-03**: EquipmentData.to_dict() serialises weapon/tool slots as id strings
- [ ] **SER-04**: EquipmentData.from_dict() restores weapon/tool via existing equip methods
- [ ] **SER-05**: HealthComponent exposes load_health(value) to bypass _ready() init

### SaveManager

- [ ] **SAVE-01**: Player can save game to user://save.json via atomic write (write .tmp, verify, rename)
- [ ] **SAVE-02**: SaveManager persists player position and current HP
- [ ] **SAVE-03**: SaveManager persists inventory contents and equipped items
- [ ] **SAVE-04**: Game loads existing save automatically on start

### Save Triggers

- [ ] **TRIG-01**: Game saves when player sleeps at campfire
- [ ] **TRIG-02**: Game autosaves on a configurable interval (property on SaveManager)
- [ ] **TRIG-03**: Save file includes a version key for future migration support

## Future Requirements

### World State

- **WORLD-01**: Picked-up collectables do not respawn after load
- **WORLD-02**: Dead enemies do not respawn after load

### Save UX

- **UX-01**: Player can configure autosave interval via in-game UI settings

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multiple save slots | High UI complexity; single slot sufficient until game has meaningful branching choices |
| Binary/encrypted saves | Overkill for single-player local game; JSON is readable and debuggable |
| Cloud save sync | Requires external service and conflict resolution; out of scope for v1.x |
| World state (collectables/enemies) | Deferred to future milestone — no TimeManager yet; scope is player data only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REG-01 | Phase 9 | Pending |
| REG-02 | Phase 9 | Pending |
| SER-01 | Phase 9 | Pending |
| SER-02 | Phase 9 | Pending |
| SER-03 | Phase 9 | Pending |
| SER-04 | Phase 9 | Pending |
| SER-05 | Phase 9 | Pending |
| SAVE-01 | Phase 10 | Pending |
| SAVE-02 | Phase 10 | Pending |
| SAVE-03 | Phase 11 | Pending |
| SAVE-04 | Phase 10 | Pending |
| TRIG-01 | Phase 12 | Pending |
| TRIG-02 | Phase 12 | Pending |
| TRIG-03 | Phase 12 | Pending |

**Coverage:**
- v1.2 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-30*
*Last updated: 2026-03-30 after roadmap creation*
