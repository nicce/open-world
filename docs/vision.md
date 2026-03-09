# Vision — Open World Game

## End Goal

A 2D top-down open-world survival and life-simulation game inspired by **Stardew Valley**. The world is freely explorable from the start with no hard gates. The player survives, builds, and thrives by interacting with the environment, gathering resources, and crafting their way forward.

## Core Pillars

| Pillar | Description |
|---|---|
| **Exploration** | A large, open world the player can roam freely. Different biomes (forest, village, lake, ruins) each with unique resources and secrets. |
| **Harvesting** | Chop trees for wood, forage for food, mine rocks for stone. Resources respawn over time. |
| **Building** | Place structures (walls, floors, beds, chests, campfires) in the world to create a base or homestead. |
| **Survival** | Manage hunger, energy, and health. Sleep to restore energy and advance time. |
| **Combat** | Fight enemies defending resources or guarding areas. Equip different weapons and armour. |
| **Progression** | Improve tools, unlock recipes, and expand the homestead over time. |

## Gameplay Loop

```
Explore world
  → Gather resources (wood, food, stone, loot)
    → Craft / Build
      → Survive the night / hostile enemies
        → Sleep to restore energy & advance time
          → Repeat with improved tools and expanded base
```

## World Design

- Seamless open world — no loading screens between areas.
- Distinct biomes: starting village, forest, lakeside, ruins/dungeon.
- Day/night cycle affecting enemy behaviour and NPC schedules.
- Points of interest: abandoned villages, caves, shrines, merchants.

## Player Mechanics (planned)

- Movement in all four directions (already implemented).
- Melee combat with equippable weapons (axe partially implemented).
- Tool use: axe for trees, pickaxe for rocks, fishing rod for fish.
- Inventory with item stacking and equipment slots.
- Hunger and stamina bars (planned).
- Sleep mechanic to pass time and restore stats.

## Scope Notes

This project is developed incrementally. The current codebase provides a foundation:
- Player movement and state machine
- Basic enemy (snake) with AI
- Health/hitbox component system
- Campfire interaction
- Inventory UI
- Area-based background music

Everything beyond this is greenfield and should be added feature by feature.
