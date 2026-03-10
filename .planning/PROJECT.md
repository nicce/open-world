# Open World — Stardew-like 2D Survival/Adventure

## What This Is

A top-down 2D game built with Godot Engine 4.2+ and GDScript, aiming for a balanced loop of survival, farming, and combat — similar in spirit to Stardew Valley. The player moves through a tile-based world, fights enemies, collects and manages items, and interacts with objects. Mechanics-first: placeholder art for now, real assets are a future concern.

## Core Value

A satisfying item and inventory system that makes picking things up, using consumables, and managing weight feel meaningful — everything else in the game depends on items working correctly.

## Requirements

### Validated

- ✓ Player movement (4-directional, state machine: MOVE/HIT/DEAD) — existing
- ✓ Melee combat (fist attack, hitbox with cooldown, Attack resource) — existing
- ✓ Health system (HealthComponent with damage/death signals) — existing
- ✓ Snake enemy with AI chase behavior — existing
- ✓ Inventory data model (Inventory, InventorySlot, weight limits, stacking) — existing
- ✓ Inventory UI (togglable panel, renders slots) — existing
- ✓ Collectable system (Area2D-based pickup with interact key) — existing
- ✓ Campfire interactive object — existing
- ✓ Area-based background music (BackgroundMusic autoload) — existing
- ✓ Item resource types (Item, HealthItem, WeaponItem) — existing

### Active

- [ ] Grid-based inventory UI with fixed slot grid (visual overhaul of existing panel)
- [ ] Item type system: weapons/tools, resources/materials, consumables — distinct behavior per type
- [ ] Consumable use: player can use health items directly from inventory to restore HP
- [ ] Weight capacity enforced: inventory rejects items over weight limit with feedback
- [ ] Item stacking: stackable resource items stack correctly up to max_stack
- [ ] Item drop: player can drop items from inventory back into the world

### Out of Scope

- Real art assets (sprites, tilesets, character art) — deferred to future milestone
- Crafting / recipe system — future milestone
- Farming / crop system — future milestone
- Building / structure placement — future milestone
- Additional enemy types / boss fights — future milestone
- NPC interactions / quests / dialogue — future milestone
- Multiplayer — never (single-player only)

## Context

The codebase already has a solid component-based foundation: health, hitbox, detection, and animation components are reusable. The inventory refactor (weight-based limits + stacking) was completed recently. The inventory UI exists but needs a grid-based visual redesign to feel like a proper game inventory rather than a debug panel.

Key architectural patterns to preserve:
- Signal-driven communication between systems (no tight coupling)
- Resource classes for data (Item, Inventory, InventorySlot extend Resource)
- Component composition (attach to scenes, not inherit)
- Enum state machine for Player

## Constraints

- **Tech stack**: Godot 4.2+ / GDScript only — no third-party addons beyond GUT for testing
- **Art**: Placeholder sprites acceptable; do not block on real assets
- **Testing**: GUT framework; all pure logic must have unit tests (`make test` must pass)
- **Quality**: `make lint` and `make format-check` must pass before any commit

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Extend existing inventory, don't rewrite | Recent refactor already handles weight + stacking | — Pending |
| Grid-based slots UI (not weight-only bag) | More intuitive for players; matches genre conventions | — Pending |
| No crafting in v1 | Inventory system must be solid before building on it | — Pending |
| Placeholder art throughout v1 | Unblocks all mechanic work; real assets are a separate concern | — Pending |

---
*Last updated: 2026-03-10 after initialization*
