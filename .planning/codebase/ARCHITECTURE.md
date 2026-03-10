# Architecture

**Analysis Date:** 2026-03-10

## Pattern Overview

**Overall:** Component-based entity composition with signal-driven communication and scene-tree hierarchy. Godot 4.2+ engine with GDScript.

**Key Characteristics:**
- Reusable sub-scene components (health, hitbox, damage effects) attached as children
- Signals for decoupled inter-system communication rather than direct references
- Explicit state machines (enum-based) for complex entities like Player
- Autoload singleton for global services (BackgroundMusic)
- Resource-based data model (Item, Inventory, InventorySlot) separate from scene logic

## Layers

**Presentation/UI Layer:**
- Purpose: Render and manage user interface elements
- Location: `scripts/inventory_ui.gd`, `scenes/inventory_ui.tscn`, `scripts/health_bar.gd`
- Contains: Control nodes, animation trees, visual feedback
- Depends on: Game state (inventory, health), input system
- Used by: Player and scene management

**Game Logic Layer:**
- Purpose: Implement core game mechanics (player, enemies, interactions, collectables)
- Location: `scripts/player.gd`, `scripts/snake.gd`, `scripts/campfire.gd`, `scripts/collectable.gd`
- Contains: Entities with behavior, state management, interaction handlers
- Depends on: Components (health, hitbox), Attack model, Inventory, Input system
- Used by: World scene, physics system

**Component Layer:**
- Purpose: Provide reusable, composable functionality attached to entities
- Location: `components/health_component.tscn`, `components/hitbox_component.tscn`, `components/player_detection_component.tscn`, `components/animation_damage.tscn`
- Contains: Generic health/damage, hit detection, area-based AI awareness, visual effects
- Depends on: Nothing (leaf layer)
- Used by: Player, enemies, interactive objects

**Data/Resource Layer:**
- Purpose: Define data structures and models (immutable or quasi-immutable)
- Location: `scripts/resources/`
- Contains: Item, Inventory, InventorySlot, HealthItem, WeaponItem, Attack
- Depends on: Nothing
- Used by: Game logic layer, UI layer

**Service Layer:**
- Purpose: Global singletons for shared functionality
- Location: `scripts/background_music.gd` (autoload as BackgroundMusic)
- Contains: Audio stream management, area-based music switching
- Depends on: Nothing
- Used by: World scene, any script needing global audio control

**Physics & Collision Layer:**
- Purpose: Handle movement, collision detection, physics queries
- Location: Built into CharacterBody2D and Area2D nodes (Godot engine)
- Contains: Velocity/position updates, overlap checks, collision layers
- Depends on: Component signals for damage application
- Used by: Player, Snake, HitboxComponent

## Data Flow

**Combat Flow:**

1. Player presses "hit" action → Player state transitions to HIT
2. Player animation plays (Fist attack animation)
3. Fist area enters enemy's HitboxComponent
4. HitboxComponent._on_area_entered() checks if attacker has "attack" property
5. HitboxComponent.take_damage() calls HealthComponent.damage(attack)
6. HealthComponent applies damage, emits damage_taken or health_depleated signal
7. Enemy/Player signal handler reacts (flash effect, state change, respawn)

**Inventory Collection Flow:**

1. Player overlaps Collectable area
2. Collectable._on_body_entered() detects Player, sets is_collectable=true
3. Player presses "interact" → Collectable.collect()
4. Collectable calls Player.collect(item)
5. Player.collect() calls Inventory.insert(item)
6. Inventory attempts to place item in slots, respecting weight/stack limits
7. Returns remaining items that couldn't fit
8. If success (remaining==0), Collectable queues_free()

**Area-based Music Flow:**

1. Player moves through DetectionArea in world
2. DetectionArea emits body_entered signal
3. World._on_detection_area_home_body_entered() calls BackgroundMusic.play_audio("home")
4. BackgroundMusic switches audio stream if not already playing

**State Management Flow:**

1. Player enum-based state machine: MOVE → HIT → DEAD transitions
2. _physics_process() matches on current_state, calls appropriate handler
3. Health signals trigger state transitions (health_depleated → DEAD)
4. Player state reset signals return to MOVE state when animations complete

**State Management:**
- Player maintains explicit state machine (PlayerStates enum)
- Health component emits signals that trigger state transitions
- Components emit signals on state changes; listeners respond without tight coupling
- No global mutable state except BackgroundMusic singleton

## Key Abstractions

**HealthComponent:**
- Purpose: Tracks HP, applies damage, signals state changes
- Examples: `scripts/health_component.gd`, child of `scenes/player.tscn`, `scenes/snake.tscn`
- Pattern: Composition—attached as child node, exported reference in hitbox
- Signals: health_depleated, damage_taken (listener pattern)

**HitboxComponent:**
- Purpose: Detect weapon/attack overlaps and apply damage
- Examples: `scripts/hitbox_component.gd`, child of player/enemy scenes
- Pattern: Area2D-based detection with cooldown timer, delegates to HealthComponent
- Coupling: References HealthComponent via @export

**Attack:**
- Purpose: Simple value object representing attack stats (damage, cooldown)
- Examples: `scripts/attack.gd`, exported on Player and Snake
- Pattern: Lightweight data holder, passed to HealthComponent.damage()

**Inventory:**
- Purpose: Manage item storage with weight and stack limits
- Examples: `scripts/resources/inventory.gd`
- Pattern: Resource class (serializable), contains array of InventorySlot
- Methods: insert(), remove(), get_item_count(), has_item(), current_weight()

**InventorySlot:**
- Purpose: Single stack of items with quantity and max_stack
- Examples: `scripts/resources/inventory_slot.gd`
- Pattern: Resource class, wrapped in Inventory
- Validation: Respects weight budget and stack limits

**Collectable:**
- Purpose: Base class for items that can be picked up
- Examples: `scripts/collectable.gd`, `scripts/axe.gd` (extends Collectable)
- Pattern: Area2D with interaction detection, calls Player.collect()
- Coupling: Requires Player to have collect() method

**PlayerDetectionArea:**
- Purpose: Enable enemy AI to detect and chase player
- Examples: `scripts/PlayerDetectionArea.gd`, child of Snake
- Pattern: Area2D wrapper around animation state machine
- Delegation: Calls get_parent().move_and_slide() on chase

## Entry Points

**Game Start:**
- Location: `scenes/world.tscn` (main scene configured in project.godot)
- Triggers: Engine loads scene tree on F5 or play button
- Responsibilities: Root node for all game entities, subscribes to area detection for music

**Player Initialization:**
- Location: `scenes/player.tscn` (placed in world.tscn)
- Triggers: Scene tree instantiation
- Responsibilities: Set up state machine, cache child components (@onready), initialize inventory

**Enemy Initialization:**
- Location: `scenes/snake.tscn` (placed in world.tscn)
- Triggers: Scene tree instantiation
- Responsibilities: Store spawn position, set up health/hitbox components, configure AI

**UI Initialization:**
- Location: `scenes/inventory_ui.tscn` (placed in world.tscn)
- Triggers: Scene tree instantiation
- Responsibilities: Hide by default, listen for inventory action, render inventory data

## Error Handling

**Strategy:** Assertion-based validation for critical dependencies, duck-typing for optional interfaces

**Patterns:**
- `assert(collector.has_method("collect"), ...)` in Collectable to verify Player interface
- `if body.has_method("increase_health")` in Medicpack to check if body is healable
- `if "attack" in body` in HitboxComponent to check if body carries attack stats
- Silent fallback (do nothing) if optional components missing (e.g., no health_bar in HealthComponent)

## Cross-Cutting Concerns

**Logging:** None detected (no dedicated logging framework)

**Validation:**
- HealthComponent: Assert max_health > 0, validate health bounds (0 to max_health)
- Inventory: Validate remaining weight >= 0, respect max_weight in insert()
- Attack: No validation (assumed configured in scene)

**Authentication:** Not applicable (single-player game)

**Input Handling:** Centralized via Godot Input singleton; each script polls for actions
- Player checks "left", "right", "up", "down", "hit" in _physics_process()
- Inventory UI checks "inventory" in _input()
- Campfire checks "interact" in _physics_process()

**Physics Layers:**
- Layer 2: player
- Layer 3: enemies
- Layer 4: weapons
- Layer 5: no_affect (non-physical objects)

---

*Architecture analysis: 2026-03-10*
