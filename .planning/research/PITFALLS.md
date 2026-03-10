# Pitfalls Research: Open World (Stardew-like 2D Survival/Adventure)

**Research Date:** 2026-03-10
**Domain:** Godot 4.2+ inventory systems, item type hierarchies, 2D RPG patterns
**Milestone Context:** Subsequent — extending existing foundation

---

## Critical Pitfalls (Must Fix Before Feature Work)

### 1. Player Stuck in HIT State

**Pitfall:** The `HIT` state in `player.gd` never exits — the player is permanently locked after one attack. A `TODO` comment marks the missing transition.

**Warning signs:** Player can attack once but never again; combat is broken from the first hit.

**Prevention:** Add the state exit (transition back to `MOVE`) triggered by the attack animation completion signal before any inventory or combat work begins.

**Phase:** Must fix in Phase 1 (before any other work).

---

### 2. Item Identity by Name String

**Pitfall:** `inventory.gd` matches items using `slot.item.name == item.name`. Two different items with the same display name will silently stack or conflict.

**Warning signs:** As the item catalog grows, accidental collisions become likely.

**Prevention:** Add `@export var id: StringName` to `Item`. Use `id` for all identity checks (stack matching, removal, queries). Use `name` for display only.

**Phase:** Fix during inventory foundation work, before any new items are defined.

---

### 3. No Dispatch Contract for Consumable Use

**Pitfall:** `HealthItem` has a `consumable: bool` flag but no `use()` interface or dispatch mechanism. Implementing consumable use without defining this contract first leads to scattered `if item is HealthItem` checks across unrelated scripts.

**Prevention:** Dispatch by `item.category` (enum) in Player. Player is the authority. UI emits `item_used(item)`; Player acts on it. Define the dispatch pattern before writing any use logic.

**Phase:** Establish in Phase 1 (architecture decision), implement in consumable phase.

---

## Moderate Pitfalls (Cause Rework if Deferred)

### 4. Float Truncation in Weight Calculation

**Pitfall:** `int(remaining_weight() / item.weight)` truncates instead of floors. For item weights like `0.2`, float precision issues can cause off-by-one errors in stack size calculation.

**Warning signs:** Inventory accepts one more/fewer item than expected at weight boundary.

**Prevention:** Use `floori(remaining_weight() / item.weight)` instead of `int(...)`.

**Phase:** Fix during inventory foundation work.

---

### 5. Inventory Signal Stub Blocks All UI Responsiveness

**Pitfall:** `inventory_ui.gd` has `_on_player_item_collected: pass` — a stub that does nothing. The UI will never update after item collection until this is replaced with real slot rendering logic.

**Prevention:** Add `changed` signal to `Inventory`. Connect it to UI refresh in `inventory_ui.gd`. The slot rendering must read from `inventory.slots` on every change.

**Phase:** Phase 1 (inventory foundation).

---

### 6. GridContainer Slot Count Must Not Match Array Size

**Pitfall:** If the UI spawns one slot per `inventory.slots` element, the grid grows/shrinks as items are added/removed. This makes layout unpredictable and the "full inventory" UX impossible.

**Warning signs:** Grid has different numbers of slots after picking up vs. dropping items.

**Prevention:** Instantiate a fixed N×M grid (e.g., 20 slots) at `_ready()`. Empty slots show as blank. The slot count is a layout constant, not driven by data.

**Phase:** Phase 1 (grid UI implementation).

---

### 7. Equipment Slot Architecture Must Be Decided Before Grid UI

**Pitfall:** Building the bag grid without deciding if equipment slots (weapon, tool) share the same grid or occupy a separate row means the layout will need to be restructured when equipment is added.

**Warning signs:** Weapon slot is inside the bag grid, collides with bag items.

**Prevention:** Reserve a separate row/panel for equipment slots from the start, even if visually empty in v1. Decide: bag grid is for carrying; equipment panel is for equipping. These are separate `InventorySlot` arrays.

**Phase:** Decide in Phase 1; implement equipment slots in a later phase.

---

### 8. Item Drop Needs `collectable_scene` on Item Resource

**Pitfall:** Without a `collectable_scene: PackedScene` field on `Item`, drop logic will require hardcoded scene paths per item type — fragile and unscalable.

**Warning signs:** Drop function uses `load("res://scenes/items/health_pack.tscn")` inside game logic.

**Prevention:** Add `@export var collectable_scene: PackedScene` to `Item`. Drop logic becomes: `item.collectable_scene.instantiate()`, placed at player position. Works for any item type.

**Phase:** Add field during inventory foundation; use in item drop phase.

---

### 9. Shared `.tres` Resource Mutates Across Scene Reloads

**Pitfall:** If `Player` holds a reference to a `.tres` Inventory resource (not a duplicate), all instances of the scene share the same inventory object. Mutations in one play session persist to the next — or two players would share inventory.

**Warning signs:** Inventory is not empty on a new game; items appear that were collected in a previous run.

**Prevention:** In `Player._ready()`, call `inventory = inventory.duplicate(true)` to deep-copy the resource before use. The `true` parameter duplicates sub-resources (slots + items).

**Phase:** Fix during inventory foundation work.

---

### 10. No Feedback When Inventory Is Full

**Pitfall:** When `Inventory.insert()` returns remaining items (couldn't fit), the current code in `Collectable` and `Player.collect()` does nothing visible — the item silently fails to be collected.

**Warning signs:** Player presses interact on a collectable; nothing happens; no indication why.

**Prevention:** When `collect()` detects `remaining.size() > 0`, emit a feedback signal or display a brief "Inventory full" toast. The item should stay in the world (not queue_free).

**Phase:** Implement alongside grid UI (weight feedback is part of the same feature).

---

## Minor Pitfalls

### 11. Drop Logic Must Not Live in UI Layer

**Pitfall:** It's tempting to put `get_tree().current_scene.add_child(collectable)` inside `InventoryUI`. This makes the UI a game-logic layer — it now controls the world scene tree.

**Prevention:** UI emits `item_dropped(item, slot_index)`; Player handles world instantiation. UI never touches the world scene.

**Phase:** Enforce during item drop implementation.

---

### 12. HitboxComponent Direct Node Reference

**Pitfall:** `HitboxComponent` holds a direct `@export var health_component: HealthComponent`. If a scene is restructured and the export reference breaks, damage silently stops working.

**Warning signs:** Enemy takes no damage; no error shown.

**Prevention:** Assert the reference is not null in `_ready()`. Already partially done — maintain this pattern for all component exports.

**Phase:** Ongoing — enforce in code review.

---

### 13. Dead Code and Misplaced Scenes

**Pitfall:** `lake_world.gd` and other orphaned scripts/scenes accumulate. They add noise to search results and can be mistakenly edited.

**Prevention:** Delete confirmed-unused files rather than leaving them. One scene per `.gd` pair; no scene files without a corresponding script.

**Phase:** Cleanup pass — can be done anytime.

---

## Summary Priority Order

| Priority | Pitfall | Fix Timing |
|----------|---------|-----------|
| 🔴 Critical | HIT state never exits | Before any other work |
| 🔴 Critical | Item identity by name string | Before new items defined |
| 🔴 Critical | No consumable dispatch contract | Architecture decision first |
| 🟡 Moderate | Float truncation in weight calc | Inventory foundation phase |
| 🟡 Moderate | Inventory signal stub | Inventory foundation phase |
| 🟡 Moderate | Fixed grid slot count | Grid UI implementation |
| 🟡 Moderate | Equipment slot architecture decision | Before grid UI built |
| 🟡 Moderate | `collectable_scene` on Item | Inventory foundation phase |
| 🟡 Moderate | Shared Resource mutation | Inventory foundation phase |
| 🟡 Moderate | No full-inventory feedback | Alongside grid UI |
| 🟢 Minor | Drop logic in UI | Item drop phase |
| 🟢 Minor | HitboxComponent null reference | Ongoing |
| 🟢 Minor | Dead code cleanup | Anytime |

---

*Research complete: 2026-03-10*
