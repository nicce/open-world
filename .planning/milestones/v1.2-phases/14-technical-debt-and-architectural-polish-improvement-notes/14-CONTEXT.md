---
phase: 14-technical-debt-and-architectural-polish-improvement-notes
created: 2026-03-31
mode: auto
---

# Phase 14 Context — Technical Debt and Architectural Polish

## Phase Goal

Address all technical debt and architectural improvements identified during v1.2 audit:
refactoring, UI/UX polish, performance/safety fixes, and test coverage expansion.

---

## Decisions (auto-selected)

### 1. Signal-based HitboxComponent

**Decision:** Remove `@export var health_component: HealthComponent` from `HitboxComponent`.
Instead, `HitboxComponent` emits a new `hit_taken(attack: Attack)` signal when damage occurs.
`HealthComponent` (or any subscriber) connects to this signal — wired in the scene, not via @export.

- `take_damage()` becomes `hit_taken.emit(attack)` — the component no longer calls `health_component.damage()` directly
- All scenes that currently wire the @export must be updated to wire the signal connection instead
- `knocked_back` signal is unchanged
- Keep backward compat: if a scene is found not yet updated, the planner should update it

**Why:** Tight @export coupling means HitboxComponent cannot be reused without a HealthComponent. Signal-based wiring allows any subscriber to react to hits.

---

### 2. Signal-based HealthComponent health_bar

**Decision:** Remove `@export var health_bar: HealthBar` from `HealthComponent`.
HealthComponent emits a `health_changed(current: int, maximum: int)` signal whenever health updates
(on damage, heal, and load). HealthBar connects to `health_changed` in the scene.

- `damage()`, `increase()`, and `load_health()` emit `health_changed(health, max_health)` instead of calling `health_bar.update()` / `health_bar.max_value` directly
- All scenes that wire `health_bar` @export must be migrated to signal connections
- `health_depleated` and `damage_taken` signals unchanged

**Why:** HealthComponent should not need to know about UI nodes. Signal decoupling lets any node observe health (e.g., future AI, buffs, achievement system).

---

### 3. SpawnerComponent

**Decision:** Create `components/spawner_component.tscn` + `scripts/spawner_component.gd` with:
- `@export var enemy_scene: PackedScene`
- `@export var spawn_position: Vector2`
- `@export var respawn_delay: float = 60.0`
- Handles: initial spawn in `_ready()`, `child_exiting_tree` detection, respawn timer

Both `abandoned_village.gd` and `lake_world.gd` are refactored to use `SpawnerComponent` as a
child node (one instance per enemy type). Their own spawn logic is removed.

**Scope:** Only consolidates existing behavior — no new features (no spawn limits, no multi-spawn).

---

### 4. Item Identity Safety

**Current state:** `inventory.gd` already uses `slot.item.id == item.id` (lines 67, 79). IDs are in use.

**Decision:** Audit remaining scripts for any name-string item matching. If found, migrate to `.id`
comparison. If no name-based matching is found, this item is complete after audit confirmation.

---

### 5. Global Focus Management — InventoryUI

**Decision:** Apply Phase 13's pattern to `InventoryUI`:
- When inventory opens, call `grab_focus()` on the first non-empty slot (or first slot if all empty)
- Arrow keys navigate between slots via Godot's native focus traversal (requires `FOCUS_ALL` on slot buttons)
- Tab / I key closes inventory via `_unhandled_input` + `set_input_as_handled()`

**Scope:** InventoryUI only. HUD strip right-click context menu is mouse-only (small target, not a full menu). Equipment slots in InventoryUI can also receive keyboard focus.

---

### 6. Item Collection Feedback

**Decision:** When an item is added to inventory, briefly flash the receiving slot gold
(modulate animation, ~0.4s, same gold color used by HUD strip `#D4AF37`).

- Connect to an existing signal from `Inventory` or `InventoryUI` that fires after a successful insert
- The flash runs on the specific `InventorySlotUI` node that received the item
- If no slot-specific signal exists, add one or use `item_inserted(slot_index)` emitted from `Inventory`

---

### 7. Hover Tooltips

**Decision:** Use Godot's built-in `tooltip_text` property on `InventorySlotUI` and equipment slot
`Button` nodes. Set tooltip_text whenever slot content changes:
- Format: `"{item.name}\n{item description or type}"` — use item.name + item type (weapon/health/key)
- Clear to `""` when slot is empty
- No custom tooltip UI needed — Godot's default tooltip is sufficient for this phase

---

### 8. Process Optimization — _process polling

**Decision:** Convert `_process` + `Input.is_action_just_pressed("interact")` to
`_unhandled_input(event)` + `event.is_action_pressed("interact")` in:
- `scripts/collectable.gd`
- `scripts/medicpack.gd`

Same pattern established in Phase 13 for campfire. Removes per-frame polling.

Note: `campfire.gd` already converted in Phase 13. The `_physics_process` in campfire drives
fire/smoke state — this is intentional state enforcement, not redundant polling; leave it.

---

### 9. Safe Collections — collectable.gd

**Decision:** Replace `assert(collector.has_method("collect"), ...)` in `collectable.gd` with:
```gdscript
if not collector.has_method("collect"):
    push_warning("Collectable: collector %s has no collect() method" % collector.name)
    return
```

Hard assert crashes the game in release builds. A warning + early return degrades gracefully.

---

### 10. Medicpack Standardization

**Decision:** Convert `Medicpack` from a `StaticBody2D` with direct healing to a standard
`Collectable` that adds a `HealthItem` resource to the player's inventory.

- `medicpack.gd` extends `Collectable` (or is replaced by a configured `Collectable` scene)
- On collect, a `HealthItem` resource is inserted into the player's inventory
- Direct `interacter.increase_health(value)` call is removed
- Player uses the item from inventory (existing consume flow from Phase 3/6)
- `player.increase_health()` method remains — it's still used by campfire sleep

**Implication:** Medicpack no longer heals instantly on interact; it goes to inventory first.
This is an intentional gameplay change per the roadmap.

---

### 11. State Machine Fuzzing Tests

**Decision:** Add unit tests for player state transitions in `tests/unit/`:
- MOVE → HIT (damage taken during movement)
- HIT → HIT (damage taken while already in HIT state — should not reset watchdog)
- HIT → DEAD (health depleted during HIT)
- DEAD state invariant (no state transition out of DEAD from damage)

Test only the state machine logic; use the existing `test_player.gd` pattern (or create it).

---

### 12. UI Integration Tests

**Decision:** Add GUT tests for:
- `InventorySlotUI` context menu: right-click on a slot with a weapon triggers "Equip" option
- `InventorySlotUI` context menu: right-click on empty slot triggers no menu
- `InventoryUI` keyboard navigation: first slot receives focus on open (if testable headlessly)

Focus on the conditional logic paths (which menu items appear), not visual rendering.

---

## Deferred Ideas

None captured during auto-mode.

---

## Implementation Notes for Planner

- **Wave structure suggestion:** Split into waves by risk — Architecture (signal rewiring, SpawnerComponent) first since it touches many scenes; UI polish (focus, tooltips, feedback) second; safety/testing third.
- **Highest risk:** Signal-based HitboxComponent/HealthComponent requires scene file edits in `.tscn` files across player, snake, and any other entity that uses these components. Planner must enumerate all affected scenes.
- **Medicpack change is breaking gameplay** — note in plan tasks for manual verification.
- **Item identity audit** may be a no-op — planner should verify and skip if already clean.
