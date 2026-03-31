# Architecture

**Analysis Date:** 2025-01-24

## Pattern Overview

**Overall:** Node-based Composition with Signal-driven Communication.

**Key Characteristics:**
- **Component-based Entities:** Player and Enemies are composed of reusable logic nodes (Health, Hitbox, Detection).
- **Resource-based State:** Game state (Inventory, Equipment, Items) is stored in `Resource` objects, enabling easy serialization.
- **Signal Decoupling:** Components communicate primarily via signals, although some tight coupling exists (see CONCERNS.md).

## Layers

**Entities:**
- Purpose: Root nodes for game characters (Player, Snake).
- Location: `scenes/` (e.g., `scenes/player.tscn`) and `scripts/` (e.g., `scripts/player.gd`).
- Contains: Higher-level state management, movement, and animation logic.
- Depends on: Components, Resources.

**Components:**
- Purpose: Reusable, modular logic pieces.
- Location: `components/` and `scripts/` (e.g., `scripts/health_component.gd`).
- Contains: `HealthComponent`, `HitboxComponent`, `PlayerDetectionComponent`.
- Used by: Entities (Player, Snake).

**Resources:**
- Purpose: Data containers for game items and state.
- Location: `resources/` and `scripts/resources/`.
- Contains: `Inventory`, `Item`, `EquipmentData`, `Attack`.
- Used by: Entities and UI.

**Singletons (Autoloads):**
- Purpose: Global access points for cross-cutting concerns.
- Location: `scripts/` (e.g., `scripts/save_manager.gd`, `scripts/item_registry.gd`).
- Contains: Save/Load logic, item registration, background music.

**UI Layer:**
- Purpose: Visual representation and user interaction.
- Location: `scenes/` (e.g., `scenes/inventory_ui.tscn`) and `scripts/` (e.g., `scripts/inventory_ui.gd`).
- Depends on: Singletons and Resources.

## Data Flow

**Combat Flow:**

1. `HitboxComponent` (Area2D) detects an overlapping area/body.
2. `HitboxComponent` retrieves the `Attack` resource from the overlapping entity.
3. `HitboxComponent` calls `health_component.damage(attack)`.
4. `HealthComponent` updates its internal `health` and emits `damage_taken` or `health_depleated`.
5. The parent entity (e.g., `Snake`) listens for these signals to trigger animations (`AnimationDamage`) or death logic (`queue_free()`).

**State Management:**
- **Player State:** Managed via a simple Enum-based state machine in `scripts/player.gd` (`MOVE`, `HIT`, `DEAD`).
- **Inventory/Equipment State:** Stored in custom `Resource` objects. Serialization is handled by converting these to/from Dictionaries (`to_dict`/`from_dict`) via `SaveManager`.

## Key Abstractions

**Resource-based Items:**
- Purpose: Represent any collectable or equippable item.
- Examples: `resources/items/sword.tres`, `resources/items/medpack.tres`.
- Pattern: Strategy pattern for item effects (e.g., `medicpack.gd` has custom logic).

**Component Composition:**
- Purpose: Abstract common character behaviors (health, damage, detection).
- Examples: `scripts/health_component.gd`, `scripts/hitbox_component.gd`.
- Pattern: Entity-Component-System (ECS) lite (Composition over Inheritance).

## Entry Points

**World Scene:**
- Location: `scenes/world.tscn` (set in `project.godot`).
- Triggers: Application startup.
- Responsibilities: Loads the initial environment and instantiates the player.

## Error Handling

**Strategy:** Fail-fast using `assert()` during development, and graceful fallback in production where possible.

**Patterns:**
- `assert(collector.has_method("collect"), ...)` in `collectable.gd`.
- `if health_component:` checks in `hitbox_component.gd`.
- Return codes in `Inventory` (e.g., `0` for success).

## Cross-Cutting Concerns

**Logging:** Standard Godot `print()` and `printerr()`.
**Validation:** Resource validation and type-checking (static typing in GDScript).
**Authentication:** Not applicable (local only).

---

*Architecture analysis: 2025-01-24*
