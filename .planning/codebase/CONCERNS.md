# Codebase Concerns

**Analysis Date:** 2025-01-24

## Tech Debt

**UI Keyboard Navigation missing (Phase 13 Prep):**
- Issue: `inventory_ui.gd` and `campfire_menu.gd` rely heavily on mouse interactions (clicks, mouse position for popups). There is no focus management for gamepads or keyboards.
- Files: `scripts/inventory_ui.gd`, `scripts/campfire_menu.gd`.
- Impact: Game is currently unplayable with just a keyboard or controller. Accessibility is low.
- Fix approach: Implement Godot's built-in focus system. Set `focus_mode` to `FocusMode.ALL` for interactive elements. Map `ui_up/down/left/right` to navigate slots.

**Signal-based UI updates missing implementation:**
- Issue: `inventory_ui.gd` has some signal connections but others are missing or stubbed. For example, `_on_player_item_collected()` was noted as missing in previous audits.
- Files: `scripts/inventory_ui.gd`.
- Impact: UI feedback for item collection is non-existent.
- Fix approach: Implement the collection signal handler to show a toast or highlight the new item.

**Health component direct reference requirement:**
- Issue: `hitbox_component.gd` and `health_component.gd` still use direct `@export` references for cross-component communication (Hitbox -> Health, Health -> HealthBar).
- Files: `scripts/hitbox_component.gd`, `scripts/health_component.gd`.
- Impact: Tight coupling makes components less reusable and more fragile.
- Fix approach: Finalize the transition to a purely signal-based architecture.

**Duplicate spawning logic:**
- Issue: Spawning logic is duplicated across multiple world scripts.
- Files: `scenes/abandoned_village.gd`, `scripts/lake_world.gd`.
- Impact: Harder to maintain and balance enemy density.
- Fix approach: Create a dedicated `SpawnerComponent` that takes a `SpawnConfig` resource.

## Known Bugs

**Player HIT state exit condition:**
- Issue: Player can get stuck in the `HIT` state if the animation signal doesn't fire correctly or isn't connected.
- Files: `scripts/player.gd`.
- Impact: Critical gameplay blocker.
- Fix approach: Ensure `animation_finished` is connected correctly and add a safety timer fallback.

**Inventory item matching uses name strings:**
- Issue: Items are matched by `name` rather than a unique ID or resource pointer.
- Files: `scripts/resources/inventory.gd`.
- Impact: Risk of bugs if multiple items share the same name but have different properties.
- Fix approach: Use resource-based comparison (`item == other_item`) or a unique `item_id`.

## Security Considerations

**Input handling not validated:**
- Issue: Rapid-fire input (spamming 'hit' or 'interact') is not rate-limited at the engine level.
- Impact: Low (single-player), but can lead to animation glitches.
- Recommendation: Implement a global or per-action cooldown.

## Performance Bottlenecks

**Redundant Visibility/Animation Toggles:**
- Issue: Some nodes update visibility or animation states every frame in `_process` even if the state hasn't changed.
- Files: `scripts/campfire.gd`.
- Impact: Negligible for one instance, but scales poorly.
- Improvement path: Only update visuals when a state change signal is received.

## Fragile Areas

**Collectable assumes Player has `collect` method:**
- Issue: Uses a hard `assert` on a method check.
- Files: `scripts/collectable.gd`.
- Impact: Hard crash if the player script is refactored without updating the collectable script.
- Safe modification: Use `if collector.has_method("collect"):` instead of `assert`.

**Health Item implementation bypasses inventory:**
- Issue: `medicpack.gd` applies healing directly instead of being an item that can be carried and used later.
- Files: `scripts/medicpack.gd`.
- Impact: Inconsistent item system behavior.
- Fix approach: Convert `Medicpack` to a standard `Collectable` that provides a `HealthItem` resource.

## Scaling Limits

**No Global Item Registry:**
- Issue: Items are referenced by their `.tres` paths or names.
- Impact: Difficult to implement features like "Total items collected" or "Item Encyclopedia".
- Scaling path: Fully utilize the `ItemRegistry` autoload to track all game items.

**Hardcoded Spawn Positions:**
- Issue: Enemy spawn positions are hardcoded in GDScript instead of being placed as nodes in the editor or defined in a config.
- Impact: Difficult for level designers to adjust enemy placement.
- Scaling path: Use `Marker2D` nodes in the scene to define spawn points.

## Test Coverage Gaps

**State Machine transitions:**
- What's not tested: Complex transitions (e.g., getting hit while attacking).
- Priority: High.

**UI Interactions:**
- What's not tested: Inventory slot selection, context menu logic.
- Priority: Medium.

---

*Concerns audit: 2025-01-24*
