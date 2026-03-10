# Features Research: Open World (Stardew-like 2D Survival/Adventure)

**Research Date:** 2026-03-10
**Domain:** 2D top-down survival/RPG, Stardew Valley-like, Godot 4.2+
**Milestone Context:** Subsequent — extending existing foundation (combat, inventory, campfire, music)

---

## Table Stakes

Features players expect on day one. Missing these causes immediate drop-off.

### Combat & Core Interaction

| Feature | Complexity | Notes |
|---------|-----------|-------|
| Fix HIT state exit bug | Low | **Blocker** — player.gd HIT state never exits; game is unplayable after one attack |
| Player can attack and return to MOVE state | Low | Prerequisite for all other combat work |
| Enemy drops loot on death | Medium | Players expect resources from enemies |

### Inventory System

| Feature | Complexity | Notes |
|---------|-----------|-------|
| Grid-based inventory UI with item icons + quantities | Medium | Current UI is a stub — only toggles visibility, no rendering |
| Weight/capacity feedback (current vs max shown) | Low | Players need to know when they're near limit |
| Inventory rejection message when full/overweight | Low | Silent failure is confusing |
| Consume health item from inventory | Medium | Core use case for consumables |
| Item drop from inventory back to world | Medium | Players must be able to discard items |
| Item pickup toast/notification | Low | Feedback that pickup worked |

---

## Differentiators

Features that set this game apart once table stakes are solid.

| Feature | Complexity | Prerequisite |
|---------|-----------|-------------|
| Equipment slots (weapon, tool) separate from bag | Medium | Solid grid UI |
| Hotbar quick-access row | Medium | Grid UI + equipment slots |
| Weapon equip changes attack stats | Medium | Equipment slots |
| Item tooltip on hover | Low | Grid UI |
| Knockback on hit | Low | None |
| Resource harvesting (trees, rocks with HarvestableComponent) | High | Item drop system |
| Day/night cycle | High | TimeManager singleton |
| Enemy loot drops | Medium | Item drop system |

---

## Anti-Features (Deliberately Excluded from v1)

| Feature | Reason |
|---------|--------|
| Crafting system | Requires item ID/registry system; current item matching is name-string (fragile). Build foundation first. |
| Farming / crop system | Requires time system and tile manipulation — large orthogonal dependency |
| Building / structure placement | No overlap with current systems; large new surface area |
| NPC dialogue | No NPC entities, dialogue tree, or quest system exists |
| Save / load | Game state will expand significantly before this is stable enough to serialize |
| Hunger / stamina | No food loop to refill it — pure punishment with no relief mechanic |
| Item durability | Adds friction without payoff at this stage |
| Multiplayer | Explicitly never (per PROJECT.md) |
| Real art assets | Deferred to future milestone (per PROJECT.md) |

---

## Feature Dependency Chain

```
Fix HIT state exit bug
  └─► all combat work (knockback, loot drops)

Grid inventory UI (slot rendering, icons, quantities)
  └─► item use from inventory
  └─► item drop from inventory
  └─► equipment slots
       └─► hotbar
       └─► weapon equip stats

Item ID / registry system (not in v1)
  └─► crafting system

HarvestableComponent (not in v1)
  └─► tree/rock resource nodes
  └─► tool-gated harvesting

TimeManager (not in v1)
  └─► day/night cycle
  └─► sleep mechanic
  └─► hunger drain (if ever added)
```

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Table stakes inventory | HIGH | Direct code audit confirms UI stub, solid data model |
| HIT state blocker | HIGH | Confirmed in player.gd source and CONCERNS.md |
| Anti-feature rationale | HIGH | Prerequisite analysis from codebase (name-string matching, no item registry) |
| Genre expectations | HIGH | Well-established conventions (Stardew Valley, Terraria, Valheim) |
| Differentiator ordering | MEDIUM | Complexity estimates are informed; actual effort may vary |

---

*Research complete: 2026-03-10*
