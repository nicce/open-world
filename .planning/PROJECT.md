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

<!-- v1.1 Equipment Slots -->
- [ ] Right-click context menu on inventory items (Equip / Consume / Drop by type)
- [ ] Equipping moves item from bag to equipment slot; unequipping returns it to bag
- [ ] Tool slot exists in UI (gameplay wired in future milestone)

### Validated

- ✓ Always-visible HUD strip with weapon and tool equipment slots — v1.1 (HUD-01, HUD-02)
- ✓ Equipped weapon drives player hit() attack; fist as fallback — v1.1 (CMBT-03, CMBT-04)
- ✓ Placeholder visual indicator on player when weapon is equipped — v1.1 (CMBT-05)

### Out of Scope

- Multiplayer — never (single-player only)
- Real art assets — do not block on; placeholder sprites are acceptable throughout all milestones

## Future Features

Feature groups available for upcoming milestones, roughly in suggested build order. Each group becomes a milestone or part of one — scope at planning time via `/gsd:new-milestone`.

**Near-term (foundational mechanics):**
- **Expanded Combat** — weapon equip logic in player.gd, Sword/Bow scenes, weapon animations, enemy loot drops
- **Equipment Slots** — weapon/armour/tool slots separate from bag grid, equip by slot-click, show equipped weapon on player
- **More Enemies** — Slime, Bandit, SpawnPoint with night spawning, aggro/de-aggro range, enemy health bars, Inspector-tunable stats
- **UI & HUD Polish** — HUD health bar, hotbar (quick-access row), equipped weapon icon, pause menu (Resume/Save/Quit)
- **Save & Load** — JSON save in `user://`, serialise player stats + inventory + world state, load on start, autosave on sleep/transition

**Mid-term (survival loop):**
- **Hunger & Stamina** — hunger/stamina stats, drain over time, bars in HUD, FoodItem resource, sprint (hold Shift) drains stamina
- **Day/Night Cycle** — TimeManager autoload, CanvasModulate darkness, day_started/night_started signals, increased enemy aggression at night
- **Sleep Mechanic** — Bed interactable, skip-to-morning dialog, restore stats, block if enemies nearby, autosave on sleep
- **Resource Harvesting** — Tree/Rock scenes, HarvestableComponent, tool-type detection (axe/pickaxe), item drops on depletion, respawn timer

**Long-term (world depth):**
- **Crafting System** — Recipe resource, recipe registry autoload, crafting UI, filter by inventory, consume ingredients
- **Building Placement** — BuildManager autoload, ghost preview, grid snap, validate placement, demolish mode, build menu
- **NPC & Dialogue** — base NPC scene, DialogueManager autoload, dialogue data files, trader NPC, time-based schedules
- **Farming / Crop System** — plant, grow, harvest loop (scope TBD)
- **World Expansion** — forest biome, cave/dungeon, merchant town, connected areas, mini-map

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
- `scripts/lake_world.gd` exists but may be orphaned — audit before building world expansion
- `scenes/abandoned_village.gd` is misplaced (should be under `scripts/`) — audit and relocate

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
## Current Milestone: v1.1 Equipment Slots

**Goal:** Add weapon and tool equipment slots with right-click context menu, gameplay wiring for the equipped weapon, and a placeholder visual indicator on the player.

**Target features:**
- Always-visible HUD strip with weapon (W) and tool (T) slots
- Right-click context menu on bag items and equipment slots
- Equip/unequip flow moves items between bag and slot
- Equipped weapon drives hit() attack (fist fallback)
- Tool slot UI only — harvesting logic deferred
- Placeholder indicator on player when weapon equipped

---
*Last updated: 2026-03-20 — Phase 7 complete: combat wiring + HUD strip; 3 requirements validated*
