# TODO

Tasks are grouped by feature. Each task is small and self-contained. Check off tasks as they are completed.

Legend: `[ ]` open · `[x]` done · `[-]` skipped/cancelled

---

## Feature: CI & Testing Infrastructure

Goal: Every pull request is automatically linted and tested; contributors can run checks locally with a single command.

- [x] Add `gdtoolkit` for GDScript linting (`gdlint`) and formatting (`gdformat`)
- [x] Add `.gdlintrc` configuration (max line length 120)
- [x] Add `Makefile` with `lint`, `format`, `format-check`, `test`, and `install-gut` targets
- [x] Add GUT (Godot Unit Testing) as the test framework — installed via `make install-gut`
- [x] Write unit tests for `Inventory.insert()` (`tests/unit/test_inventory.gd`)
- [x] Write unit tests for `campfire.add_wood()` and `campfire.withdraw_wood()` (`tests/unit/test_campfire.gd`)
- [x] Write unit tests for `HealthComponent.damage()` and `HealthComponent.increase()` (`tests/unit/test_health_component.gd`)
- [x] Fix lint issues found: unused variable in `campfire.gd`, debug `print()` in `inventory.gd`
- [x] Fix `campfire.add_wood()` overflow bug (always returned 0)
- [x] Fix `health_component.increase()` null-deref bug (`health_bar` guard missing)
- [x] Add GitHub Actions workflow (`.github/workflows/ci.yml`) — runs lint and tests on pull requests
- [ ] Add more unit tests as new pure-logic systems are introduced
- [ ] Consider integration tests for player-enemy interaction once a scene test harness is set up

---

## Feature: Resource Harvesting

Goal: Player can chop trees and mine rocks to collect raw materials.

- [ ] Create `Tree` scene with `StaticBody2D`, sprite, and collision shape
- [ ] Add a `HarvestableComponent` that tracks remaining hits before depletion
- [ ] Detect tool type on hit (axe → tree, pickaxe → rock)
- [ ] Spawn item drop (e.g. `Wood` item) when resource is fully harvested
- [ ] Play chop/mine animation on the resource node when hit
- [ ] Add tree and rock scenes to the world tilemap
- [ ] Implement resource respawn timer (resources regrow after N in-game days)

---

## Feature: Crafting System

Goal: Player can combine resources into items or structures at a crafting station.

- [ ] Define `Recipe` resource class (ingredients list → output item)
- [ ] Create a recipe registry (autoload or singleton) with initial recipes (e.g. Wood × 5 → Plank)
- [ ] Design crafting UI scene (`crafting_ui.tscn`)
- [ ] Open crafting UI when player interacts with a crafting table
- [ ] Filter available recipes by items in inventory
- [ ] Consume ingredients and add output item to inventory on craft

---

## Feature: Building Placement

Goal: Player can place structures (walls, floors, campfire, chest) in the world.

- [ ] Create a `BuildManager` autoload to track build mode state
- [ ] Show a ghost/preview sprite that follows the cursor in build mode
- [ ] Snap preview to a configurable grid
- [ ] Validate placement (no overlap with existing structures or colliders)
- [ ] Confirm placement on interact press; spawn the structure scene
- [ ] Add a demolish mode to remove placed structures and refund materials
- [ ] Expose a build menu UI listing available structures with resource costs

---

## Feature: Day/Night Cycle

Goal: Time passes in the game world, affecting lighting and enemy behaviour.

- [ ] Create a `TimeManager` autoload with in-game hour/day tracking
- [ ] Drive a `CanvasModulate` node to darken the screen at night
- [ ] Emit `day_started` and `night_started` signals from `TimeManager`
- [ ] Increase enemy spawn rate / aggression at night
- [ ] Display current time in the HUD

---

## Feature: Sleep Mechanic

Goal: Player can sleep to skip time, restore stats, and advance the day.

- [ ] Create a `Bed` interactable scene
- [ ] Show a "Sleep until morning?" confirmation dialog on interact
- [ ] On confirm: advance `TimeManager` to next morning, restore player health and stamina
- [ ] Block sleep if enemies are nearby
- [ ] Trigger autosave when the player sleeps

---

## Feature: Hunger & Stamina

Goal: Player must eat to maintain stamina; stamina gates sprinting and tool use.

- [ ] Add `hunger` and `stamina` stats to the player (similar to `health_component`)
- [ ] Drain hunger slowly over time; drain stamina on sprint/tool use/attack
- [ ] Low hunger reduces stamina regeneration
- [ ] Show hunger and stamina bars in the HUD
- [ ] Create `FoodItem` resource subclass with a `nutrition` value
- [ ] Consuming food increases hunger value
- [ ] Implement a simple sprint (hold Shift) that drains stamina

---

## Feature: Inventory Improvements

Goal: Inventory supports stacking, equipment slots, and item use.

- [ ] Implement item stacking (same item type merges up to a max stack size)
- [ ] Add equipment slots (weapon, armour, tool) separate from the bag grid
- [ ] Equip weapon/tool by dragging from bag to equipment slot
- [ ] Show equipped weapon sprite on the player
- [ ] Allow consuming food/health items directly from inventory
- [ ] Add a drop item action (removes from inventory, spawns in world)

---

## Feature: Expanded Combat

Goal: Combat supports multiple weapon types with distinct behaviour.

- [ ] Implement weapon equip logic in `player.gd` (replace hard-coded Fist state)
- [ ] Create `Sword` scene and resource with attack range and damage values
- [ ] Create `Bow` scene with projectile spawning
- [ ] Add weapon attack animations (per weapon type) to the player `AnimationTree`
- [ ] Add knockback on hit for both player and enemies
- [ ] Implement enemy loot drops (items spawned on death)

---

## Feature: More Enemies

Goal: World feels inhabited with varied enemy types.

- [ ] Create a `Slime` enemy scene with blob sprite and simple chase AI
- [ ] Create a `Bandit` enemy scene with melee attack and patrol path
- [ ] Add a `SpawnPoint` scene that periodically spawns enemies at night
- [ ] Implement enemy aggro range and de-aggro when player is far away
- [ ] Add enemy health bars visible when damaged

---

## Feature: NPC & Dialogue

Goal: The world has friendly NPCs the player can talk to.

- [ ] Create a base `NPC` scene with sprite and collision
- [ ] Implement a `DialogueManager` autoload for displaying dialogue boxes
- [ ] Write dialogue data as JSON or Resource files
- [ ] Add trader NPC that exchanges items for resources
- [ ] Add a schedule system so NPCs move between locations based on time of day

---

## Feature: Save & Load

Goal: Player progress persists between sessions.

- [ ] Decide on save format (JSON file in `user://`)
- [ ] Serialise player stats (health, hunger, stamina, position) to save data
- [ ] Serialise inventory contents
- [ ] Serialise world state (harvested resources, placed structures)
- [ ] Load save data on game start if a save file exists
- [ ] Show a load/new game menu on the main menu screen
- [ ] Autosave on sleep and on scene transition

---

## Feature: World Expansion

Goal: More areas to explore with distinct biomes.

- [ ] Design and tile a forest biome with dense trees and forageable items
- [ ] Design a cave/dungeon area with enemies and ore deposits
- [ ] Add a merchant town area with NPC shops
- [ ] Connect areas via paths the player walks through (no loading screens)
- [ ] Add a mini-map or world map screen

---

## Feature: UI & HUD Polish

Goal: Clean, readable HUD with essential information.

- [ ] Display health bar in the HUD (currently shown on player sprite)
- [ ] Display hunger and stamina bars in the HUD
- [ ] Display currently equipped tool/weapon icon
- [ ] Add a hotbar (quick-access row from inventory)
- [ ] Add a notification/toast system for item pickups ("+ 3 Wood")
- [ ] Pause menu with Resume, Settings, Save, and Quit options

---

## Bugs & Tech Debt

- [ ] `player.gd:51` — handle equipped weapon in `hit()` state (TODO in code)
- [ ] Decide and document the scene for the lake area (`scripts/lake_world.gd` exists but may be orphaned)
- [ ] Audit `abandoned_village.gd` (in `scenes/` rather than `scripts/` — likely misplaced)
- [x] `campfire.gd` — `add_wood()` overflow always returned 0 (fixed)
- [x] `health_component.gd` — `increase()` crashed when `health_bar` is null (fixed)
- [x] `inventory.gd` — debug `print()` statement removed
