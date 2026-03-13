# Open World — Stardew-like 2D Survival/Adventure

## What This Is

A top-down 2D game built with Godot Engine 4.2+ and GDScript, aiming for a balanced loop of survival, farming, and combat. The player moves through a tile-based world, fights enemies, collects and manages items in a grid inventory, and interacts with objects. v1.0 shipped a complete item lifecycle: pickup → grid inventory → use/drop → world.

## Core Value

A satisfying item and inventory system that makes picking things up, using consumables, and managing weight feel meaningful — everything else in the game depends on items working correctly.

## Requirements

### Validated

- ✓ Player movement (4-directional, state machine: MOVE/HIT/DEAD) — existing
- ✓ Melee combat (fist attack, hitbox with cooldown, Attack resource) — existing
- ✓ Health system (HealthComponent with damage/death signals) — existing
- ✓ Snake enemy with AI chase behavior — existing
- ✓ Inventory data model (Inventory, InventorySlot, weight limits, stacking) — existing
- ✓ Collectable system (Area2D-based pickup with interact key) — existing
- ✓ Campfire interactive object — existing
- ✓ Area-based background music (BackgroundMusic autoload) — existing
- ✓ Item resource types (Item, HealthItem, WeaponItem) — existing
- ✓ Player HIT-state lockout fixed — v1.0 (CMBT-01)
- ✓ Enemy knockback on hit — v1.0 (CMBT-02)
- ✓ Stable item id: StringName for identity — v1.0 (DATA-01)
- ✓ Deep-copy inventory on scene load — v1.0 (DATA-02)
- ✓ floori() weight budget calculation — v1.0 (DATA-03)
- ✓ 15-slot grid inventory UI with icons, quantities, weight label — v1.0 (INV-01)
- ✓ Rejection message on overweight or slot-full pickup — v1.0 (INV-02)
- ✓ Stackable items share one slot up to max_stack — v1.0 (INV-03)
- ✓ Consumable use (E key) restores HP — v1.0 (ITEM-01)
- ✓ Item drop (Q key) spawns collectable in world — v1.0 (ITEM-02)
- ✓ Pickup notification label fades in/out — v1.0 (ITEM-03)

### Active

*(Define next milestone requirements via `/gsd:new-milestone`)*

### Out of Scope

- Real art assets (sprites, tilesets, character art) — deferred to future milestone
- Crafting / recipe system — future milestone
- Farming / crop system — future milestone
- Building / structure placement — future milestone
- Additional enemy types / boss fights — future milestone
- NPC interactions / quests / dialogue — future milestone
- Multiplayer — never (single-player only)

## Context

**v1.0 shipped 2026-03-13.** 4 phases, 11 plans, 88 unit tests, ~2,100 GDScript LOC.

Architecture patterns established and proven:
- Signal-driven communication (no tight coupling) — used across all inventory/UI/world wiring
- Resource classes for data (Item, Inventory, InventorySlot extend Resource)
- Component composition (HealthComponent, HitboxComponent, PlayerDetectionComponent)
- Enum state machine for Player (MOVE/HIT/DEAD)
- GUT inner-class stub pattern for testing CharacterBody2D without scene tree

Technical debt from v1.0 (non-blocking):
- CMBT-01/02 need Godot editor runtime verification (animation names, knockback feel)
- `func hit(): pass` stub in player.gd — weapon equip system not yet designed
- `drop` action missing from CLAUDE.md Input Mappings table
- Partial-insert (amount > 1) suppresses insert_rejected — latent INV-02 edge case

## Constraints

- **Tech stack**: Godot 4.2+ / GDScript only — no third-party addons beyond GUT
- **Art**: Placeholder sprites acceptable; do not block on real assets
- **Testing**: GUT framework; all pure logic must have unit tests
- **Quality**: `make lint` and `make format-check` must pass before any commit

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Extend existing inventory, don't rewrite | Recent refactor already handles weight + stacking | ✓ Good — avoided regression |
| Grid-based slots UI (not weight-only bag) | More intuitive for players; matches genre conventions | ✓ Good — clean 15-slot grid shipped |
| No crafting in v1 | Inventory system must be solid before building on it | ✓ Good — correct sequencing |
| Placeholder art throughout v1 | Unblocks all mechanic work | ✓ Good — zero art blockers |
| clone() instead of duplicate() for inventory | Godot 4.3 blocks overriding native duplicate() on Resource | ✓ Good — tests confirm isolation |
| insert_rejected on any complete failure | Slot-full was silently dropped; elif remaining > 0 covers both cases | ✓ Good — Phase 4 gap closure |

---
*Last updated: 2026-03-13 after v1.0 milestone*
