# Feature Research

**Domain:** Godot 4 game Save & Load
**Researched:** 2026-03-30
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Player position saved | Progress means nothing if you respawn at start | LOW | `global_position` as `{x, y}` dict |
| Player HP saved | Returning to full-HP after load is wrong; 0-HP loop is game-breaking | LOW | `HealthComponent.health` + `max_health` |
| Inventory saved | Collected items must persist | MEDIUM | Serialise by `item.id` + `quantity` per slot index; restore via direct slot assignment (not `insert()`) |
| Equipment saved | Equipped weapon must persist | MEDIUM | `EquipmentData.weapon`/`.tool` saved as id strings; restored via existing equip methods |
| World state: collectables | Picked-up items must not respawn | MEDIUM | Track `collected_ids` array; `queue_free()` on load for matching nodes |
| Manual save trigger | Player must be able to save intentionally | LOW | Campfire sleep interaction (already exists in `campfire.gd`) |
| Load on game start | Progress restored automatically | MEDIUM | `SaveManager.load_game()` called last in `world.gd._ready()` |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Autosave on sleep/transition | Never lose progress; matches Stardew-like genre convention | LOW | One `call_deferred("_autosave")` in campfire + area transition |
| World state: dead enemies | Dead enemies stay dead between sessions; world feels persistent | MEDIUM | Track `dead_enemy_ids` array; suppress/free on load |
| Save file versioning | Enables future migration when new stats added | LOW | Add `"version": 1` key to save dict; check on load |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Multiple save slots | "What if I want to try something different" | High UI complexity; no TimeManager yet; out of scope | Single slot is sufficient; add when game has meaningful diverging choices |
| Binary/encrypted saves | "Security" | Impossible to debug; no cheating risk in single-player local game | Plain JSON in `user://` — readable, debuggable |
| Enemy respawn timers | "Realism" | Requires TimeManager (future milestone); complicates world state | Permanent death is correct for v1.2 scope |
| Cloud save sync | "Play anywhere" | Requires external service, auth, conflict resolution | Out of scope; file-based save is the correct foundation first |

## Feature Dependencies

```
ItemRegistry (id → Resource mapping)
    └──required by──> Inventory.from_dict()
    └──required by──> EquipmentData.from_dict()

Inventory.to_dict() / from_dict()
    └──required by──> SaveManager (player data round-trip)

EquipmentData.to_dict() / from_dict()
    └──required by──> SaveManager (player data round-trip)

HealthComponent.load_health()
    └──required by──> SaveManager (HP restore)

SaveManager write path
    └──required by──> SaveManager load path (verify output first)
    └──required by──> Autosave triggers

World state tracking (world.gd)
    └──required by──> SaveManager.save() world section
```

### Dependency Notes

- **ItemRegistry is the critical prerequisite** — nothing can be deserialised without it; build first
- **Save path before load path** — verify JSON output is correct before implementing load
- **Inventory round-trip is highest risk** — direct slot assignment bypasses `insert()` rules; needs careful testing

## MVP Definition

### Launch With (v1.2)

- [ ] ItemRegistry autoload — prerequisite for all deserialisation
- [ ] Inventory serialise/deserialise — core player data
- [ ] EquipmentData serialise/deserialise — core player data
- [ ] Player position + HP saved — basic progress persistence
- [ ] World state: collectables — items don't respawn
- [ ] Manual save via campfire — intentional save trigger
- [ ] Load on game start — progress restored

### Add After Validation (v1.2 polish)

- [ ] Autosave on area transition — convenience, matches genre expectation
- [ ] Dead enemy persistence — world feels persistent
- [ ] Save file versioning — future-proofing for hunger/stamina milestone

### Future Consideration (v2+)

- [ ] Multiple save slots — defer to when game has meaningful branching choices
- [ ] Save screenshot thumbnail — UI complexity not worth it yet

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| ItemRegistry | HIGH | LOW | P1 |
| Inventory round-trip | HIGH | MEDIUM | P1 |
| Equipment round-trip | HIGH | MEDIUM | P1 |
| Player position + HP | HIGH | LOW | P1 |
| Collectable world state | HIGH | MEDIUM | P1 |
| Manual save (campfire) | HIGH | LOW | P1 |
| Autosave on sleep | MEDIUM | LOW | P2 |
| Dead enemy persistence | MEDIUM | MEDIUM | P2 |
| Save versioning | LOW | LOW | P2 |
| Multiple save slots | LOW | HIGH | P3 |

---
*Feature research for: Godot 4 Save & Load*
*Researched: 2026-03-30*
