# Codebase Concerns

**Analysis Date:** 2026-03-10

## Tech Debt

**Weapon system hard-coded in player state machine:**
- Issue: `player.gd:58` contains a TODO comment about handling equipped weapons. The `hit()` state currently only travels to "Fist" animation, regardless of equipped weapon type.
- Files: `scripts/player.gd` (line 58)
- Impact: Player cannot use different weapons with distinct attack animations. The weapon system is designed but not integrated into player attack flow.
- Fix approach: Extract weapon logic from player; retrieve current equipped weapon from inventory and call weapon-specific attack animation. Implement weapon equip/unequip slots before attempting this refactor.

**Signal-based UI updates missing implementation:**
- Issue: `inventory_ui.gd:20` has a stubbed `_on_player_item_collected()` callback with only `pass # Replace with function body.`
- Files: `scripts/inventory_ui.gd` (line 21)
- Impact: Item collection events do not trigger UI updates (no toast notifications, inventory refresh). Player collects items but UI doesn't reflect changes.
- Fix approach: Implement signal connection from player to inventory_ui. Emit signal on item collection, listen in UI, update slot display and show toast notification.

**Health component direct reference requirement:**
- Issue: `hitbox_component.gd:4` exports `health_component` as a direct reference instead of using signals. Line 48 checks `if health_component:` before calling `damage()`.
- Files: `scripts/hitbox_component.gd` (lines 4, 48)
- Impact: Tight coupling between hitbox and health. Components cannot work independently. Fragile to refactoring—removing health_component reference breaks hitbox.
- Fix approach: Replace with signal emission. Hitbox emits `damage_received(attack)` signal; health component listens. Already partly done with `damage_taken` signal pattern in `health_component.gd`.

**Duplicate enemy spawn logic:**
- Issue: Both `abandoned_village.gd` and `lake_world.gd` contain near-identical spawn logic (lines ~25-33 in both). Same Timer setup, same spawn signal pattern, same position initialization.
- Files: `scenes/abandoned_village.gd`, `scripts/lake_world.gd`
- Impact: Code duplication. Spawn behavior changes (e.g., cooldown timing) must be made in two places. Inconsistent cooldown values across areas (both hardcoded to 60s, but no central config).
- Fix approach: Extract to `EnemySpawner` component or utility class. Use `@export var spawn_config` to allow per-area configuration without code duplication.

**Health bar display tied directly to component:**
- Issue: `health_component.gd:8` has TODO comment "replace with signals". Health bar is exported as direct reference instead of using signals.
- Files: `scripts/health_component.gd` (line 8)
- Impact: Health component must know about health bar UI. Coupling makes reusing component without UI harder. Every instance needs health_bar wired up.
- Fix approach: Emit signals from health_component; have health_bar listen separately. Decouple display from logic.

---

## Known Issues

**Inventory item matching uses string comparison:**
- Issue: `inventory.gd` lines 58 and 67 use `slot.item.name == item.name` to match items. Name collisions possible; non-unique identifier for items.
- Files: `scripts/resources/inventory.gd` (lines 58, 67)
- Impact: If two items have identical names but are different resources, inventory cannot distinguish them. Item identification is fragile.
- Workaround: Ensure all item names are globally unique. Use item resource pointers instead of name strings (would require refactoring).
- Fix approach: Store item ID (UUID or enum) instead of relying on name. Create item registry if needed.

**Inventory slot math may lose precision:**
- Issue: `inventory.gd:29` casts `remaining_weight() / item.weight` to `int`, truncating fractional quantities. `int()` conversion rounds down.
- Files: `scripts/resources/inventory.gd` (line 29)
- Impact: Items with fractional weights (e.g., 0.5) may fail to stack even when space exists. Weight budget calculation off-by-one errors possible.
- Fix approach: Use `floori()` or `ceilf()` explicitly to clarify intent, or redesign weight system to avoid fractional values during division.

**Enemy respawn blocks on Snake type check:**
- Issue: `abandoned_village.gd:17` checks `if node is Snake` in `_on_child_exiting_tree()`. Only Snake enemies trigger respawn cooldown.
- Files: `scenes/abandoned_village.gd` (line 17)
- Impact: When additional enemy types are added (Slime, Bandit from TODO list), they won't trigger respawn cooldowns. Spawning logic becomes brittle with each new enemy type.
- Fix approach: Use signal-based approach instead. Enemy emits `death` signal; spawner listens regardless of type.

**Player state machine lacks exit condition from HIT state:**
- Issue: `player.gd:58` enters `HIT` state in `hit()` function but has no logic to return to `MOVE` state. State is entered on `hit` action pressed but never exits.
- Files: `scripts/player.gd` (lines 52-53, 58-59)
- Impact: Player becomes stuck in HIT state after attacking. No attack animation completion signal or timeout to transition back. Player is completely unresponsive after first attack.
- Trigger: Press `hit` action (X or left mouse); player enters HIT state and cannot move or act.
- Fix approach: Connect to `AnimationTree` finished signal or add manual state reset on animation completion. Alternatively, add timeout after attack animation duration (2-3 frames).

---

## Security Considerations

**Direct node reference via `get_node()` avoidance (current state is good):**
- Current: Codebase uses `@onready` pattern throughout, avoiding `get_node()` in `_process()`. Good practice.
- No issues identified here.

**Input handling not validated:**
- Issue: Input actions (movement, attack, interact) are directly consumed without additional validation or rate-limiting.
- Files: `scripts/player.gd`, `scripts/campfire.gd`, `scripts/collectable.gd`
- Impact: Potential spam attacks (rapid fire input), but low risk in single-player context. No multiplayer/network code.
- Recommendation: Add cooldown state machine to prevent rapid-fire attacks once expanded combat is implemented.

---

## Performance Bottlenecks

**Enemy chase calculation divides by delta every frame:**
- Issue: `PlayerDetectionArea.gd:38` normalizes velocity with `(direction * speed).normalized() / delta`. Division by delta happens every physics frame.
- Files: `scripts/PlayerDetectionArea.gd` (line 38)
- Impact: Unnecessary per-frame division. Velocity should scale with speed independently of delta. Minor perf cost, but semantically wrong.
- Improvement path: Remove delta division; set velocity directly as `(direction.normalized() * speed)`.

**Campfire burn tick every frame:**
- Issue: `campfire.gd:28-35` runs fire/smoke state logic in `_physics_process()` every frame, even when state hasn't changed.
- Files: `scripts/campfire.gd` (lines 32-35)
- Impact: Redundant visibility toggling and animation calls. Low cost, but wasteful. Will scale poorly if many campfires exist.
- Improvement path: Set state only once; use signal from timer to trigger state changes. Only update visibility/animation when state actually changes.

**AnimationTree parameter updates every frame:**
- Issue: `player.gd:44-46` sets animation blend positions on every move frame, even if direction unchanged.
- Files: `scripts/player.gd` (lines 44-46)
- Impact: Low performance cost, but repeated redundant calls. Avoid set if direction unchanged.
- Improvement path: Cache previous direction; only call set if direction changes.

---

## Fragile Areas

**Hit animation transition has no safety timeout:**
- Issue: `player.gd:58` enters `HIT` state but never exits it. Player stuck in attack animation indefinitely.
- Files: `scripts/player.gd` (line 58)
- Impact: Player becomes uncontrollable after attacking. Must reload scene or close game to recover.
- Safe modification: Add timeout in `hit()` state or connect to AnimationTree finished signal to auto-transition back to `MOVE`.
- Test coverage: No unit tests for state machine transitions. `test_inventory.gd`, `test_campfire.gd`, `test_health_component.gd` exist but no `test_player.gd`.

**Inventory weight budget calculation assumes integer weights:**
- Issue: `inventory.gd:29` divides float by float and casts to int. Works for integer weights but fragile with fractional weights.
- Files: `scripts/resources/inventory.gd` (line 29)
- Impact: Unpredictable stacking behavior if items with fractional weights are added.
- Safe modification: Add integration tests for edge cases (items with weight 0.5, 1.5, etc.). Clarify weight system (integer or float?).
- Test coverage: `test_inventory.gd` tests stacking but not fractional weights.

**Scene file organization inconsistency:**
- Issue: `abandoned_village.gd` lives in `scenes/` instead of `scripts/`. Scene-attached logic should go in `scripts/`, not `scenes/`.
- Files: `scenes/abandoned_village.gd` (misplaced)
- Impact: Breaks naming convention. Future developers may look in wrong location. Git diffs show logic in unexpected place.
- Safe modification: Move to `scripts/abandoned_village.gd` and update scene reference. No functional change.
- Related: `lake_world.gd` is in `scripts/` (correct), but orphaned (unused).

**Lake world script unused:**
- Issue: `scripts/lake_world.gd` exists but is not referenced by any scene. Identical to `abandoned_village.gd` logic.
- Files: `scripts/lake_world.gd`
- Impact: Dead code. Contributes to confusion about which world area is active. Takes up mental space during navigation.
- Safe modification: Determine if lake area is intended. If yes, attach to scene and remove `abandoned_village.gd` redundancy. If no, delete.

**Collectable assumes Player has collect method:**
- Issue: `collectable.gd:25` uses `assert(collector.has_method("collect"), ...)` but doesn't handle missing method gracefully.
- Files: `scripts/collectable.gd` (line 25)
- Impact: Assert fails and breaks game if Player script changes and loses `collect()` method. No signal-based fallback.
- Safe modification: Replace assert with conditional check; emit signal or log error instead of crashing. Or use interface/signal pattern.

**Medicpack implementation doesn't respect inventory:**
- Issue: `medicpack.gd` calls `interacter.increase_health()` directly instead of using inventory system. Bypasses item stacking and weight limits.
- Files: `scripts/medicpack.gd` (lines 11, 16)
- Impact: Health items are directly consumed without inventory tracking. Cannot stack health items, cannot drop them. Inconsistent with collectable item pattern.
- Safe modification: Make medicpack a Collectable instead; create HealthItem resource that can be consumed from inventory. Standardize item handling.

---

## Scaling Limits

**No global item registry:**
- Issue: Items are created ad-hoc in scenes (`axe.tscn`, `medicpack.tscn`). No central registry or factory.
- Impact: Crafting system (planned) and trading system (planned) will need to enumerate all items. No way to query "all weapons" or "all tools".
- Scaling path: Create `ItemRegistry` autoload. Register all item resources on startup. Support item lookup by ID, category, or name.

**Enemy spawn tied to specific area scripts:**
- Issue: Enemy spawning is hardcoded per-area (abandoned_village, lake_world). Adding new biomes (forest, dungeon, town) requires copy-paste of spawn logic.
- Impact: No shared enemy spawning framework. Each area has its own spawn cooldown timer, position, enemy type.
- Scaling path: Create `EnemySpawner` component taking spawn config (enemy type, position, cooldown). Reuse across areas.

**No path-finding system:**
- Issue: Enemy chase uses direct path calculation (line to player). No support for obstacles or navigation meshes.
- Files: `PlayerDetectionArea.gd:37-38`
- Impact: Enemies walk through walls. Will be obvious issue as world expands with more colliders and maze-like areas.
- Scaling path: Integrate Godot's `NavigationAgent2D` or implement basic A* pathfinding before expanding to complex dungeons.

**Hard-coded spawn positions and cooldowns:**
- Issue: Enemy spawn positions (e.g., `Vector2(329, 300)` in `abandoned_village.gd:4`) and cooldown timers (60 seconds hardcoded) are spread across area scripts.
- Files: `scenes/abandoned_village.gd`, `scripts/lake_world.gd`
- Impact: No central config file for world spawning. Difficulty balance (spawn rate, enemy density) is baked into code. Requires code changes to test different spawn rates.
- Scaling path: Create SpawnConfig resource or JSON file. Load per-area on startup.

---

## Dependencies at Risk

**No external dependencies identified:**
- Codebase uses only Godot engine (4.2+) and GDScript. No npm/pip packages.
- Testing uses GUT (Godot Unit Testing) — installed locally via `make install-gut`, not in `package.json` or `requirements.txt`.
- Linting uses gdtoolkit (Python package) — installed via `pip`, configured in `.gdlintrc`.

**Risk:** If gdtoolkit falls out of maintenance, linting will break. Currently on version 4.x; Godot 4.2+ compatibility should persist.

---

## Missing Critical Features

**Weapon equip system:**
- Problem: Weapons exist as resources (axe.tscn) but player cannot select or equip them. Inventory has no equipment slots.
- Blocks: Combat expanded (TODO), tool-based harvesting (TODO)
- Related: Player TODO at line 58 about handling equipped weapons.

**Hit animation exit (HIGH PRIORITY BUG):**
- Problem: `player.gd` enters `HIT` state and never exits. No signal from attack animation completion or manual state reset.
- Blocks: All combat testing, any multiplayer input validation, game is unplayable after first attack.
- Severity: **Critical** — player becomes stuck after one attack. Game loop is broken.

**Inventory UI item collection feedback:**
- Problem: `inventory_ui.gd:21` stubbed. Item collection has no visual feedback.
- Blocks: Better UX. Item collection feels incomplete.
- Severity: Medium — game is playable, but lacking polish.

---

## Test Coverage Gaps

**Player state machine untested:**
- What's not tested: State transitions (MOVE → HIT, HIT → MOVE, MOVE → DEAD), animation playback, attack animation exit.
- Files: `scripts/player.gd`
- Risk: Regression in state transitions (like the current HIT state bug) goes undetected until manual testing.
- Priority: **High** — state machine is critical game loop code.

**Enemy AI untested:**
- What's not tested: Chase behavior, player detection distance, enemy death/respawn.
- Files: `PlayerDetectionArea.gd`, `Snake.gd`, `abandoned_village.gd`
- Risk: Changes to chase logic (e.g., delta division fix) could break enemy behavior undetected.
- Priority: Medium — enemy behavior is secondary to player mechanics but important for gameplay feel.

**Inventory UI untested:**
- What's not tested: Item collection signals, UI visibility toggle, slot updates.
- Files: `scripts/inventory_ui.gd`
- Risk: UI bugs discovered only in manual play. No regression detection.
- Priority: Medium — UI is less critical than core mechanics, but affects user experience.

**Weight-based inventory stacking edge cases:**
- What's not tested: Items with fractional weights, exact weight boundary conditions, integer division rounding.
- Files: `scripts/resources/inventory.gd`
- Risk: Weight limit bugs in edge cases (weight = 0.5, 1.5, etc.) go undetected. Current tests use integer weights only.
- Priority: Low (for now) — becomes **Medium** once fractional-weight items are added.

**Campfire interactive behavior untested:**
- What's not tested: State transitions on wood add/withdraw, burn timer behavior, exact wood consumption.
- Files: `scripts/campfire.gd`
- Current tests: `test_campfire.gd` has basic unit tests for add/withdraw logic but no state machine or animation tests.
- Risk: Interactive behavior changes (e.g., respawn timer cooldown) could break area script logic.
- Priority: Low — campfire is non-critical to core gameplay.

**Item collection and inventory integration untested:**
- What's not tested: Collectable → inventory → player flow. Item drop/pickup with weight limits.
- Files: `scripts/collectable.gd`, `scripts/medicpack.gd`, `scripts/resources/inventory.gd`
- Risk: Item systems could break when interacting (weight limit causes collect to fail silently).
- Priority: Medium — blocks feature expansion (harvesting, crafting).

---

*Concerns audit: 2026-03-10*
