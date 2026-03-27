# Domain Pitfalls: Equipment Slots (v1.1)

**Domain:** Adding weapon/tool HUD slots, right-click context menu, equip/unequip flow, and weapon-driven hit() to an existing Godot 4 inventory
**Researched:** 2026-03-13
**Milestone Context:** v1.1 — extending the existing 15-slot grid, signal-driven, Resource-based inventory (v1.0 shipped)

---

## Critical Pitfalls

Mistakes that force a rewrite or break the core feature.

---

### 1. Equipment Slot Treated as Bag Slot — Wrong Data Layer

**What goes wrong:** Equipment slots (weapon, tool) are implemented by reusing `Inventory.slots[]` and marking some slots as "special" with an index convention or a flag on `InventorySlot`. The rest of the code then has to guard against `slot_index < 2 means equipment` everywhere. The bag grid's fixed-15-slot assumption breaks. Tests fail because `inventory.slots.size()` now returns 17.

**Why it happens:** `InventorySlot` already exists, the equip/unequip flow looks like a move between slots, and it feels like the least-change path.

**Consequences:** Weight accounting counts equipped items against carry weight (or silently excludes them inconsistently). The `_refresh_slots()` loop in `inventory_ui.gd` renders equipment items in the bag grid. Stacking logic can accidentally stack into equipment slots. The data model has no concept of slot purpose — any slot can hold anything.

**Prevention:** Equipment slots are a separate data structure from the bag. Player owns `var equipped_weapon: WeaponItem = null` and `var equipped_tool: Item = null` as plain vars (or a dedicated `EquipmentSlots` Resource). The bag `Inventory` is only for carrying. Move logic transfers from `Inventory.slots` to `Player.equipped_*`; the weight budget and grid render only the bag.

**Detection:** `inventory.slots.size() != 15` at any point during gameplay. Weight label changes when you equip an item.

**Phase:** Architecture decision must be locked before any equip/unequip code is written (Phase 1).

---

### 2. PopupMenu Position Not Anchored to the Clicked Slot

**What goes wrong:** `PopupMenu.popup()` is called with no position argument. The menu appears at the mouse cursor position at menu-open time, but `popup()` in Godot 4 uses the global mouse position at the moment of the call — if the call is deferred by one frame or the slot is near the screen edge, the menu appears off-screen or clipped.

**Why it happens:** `PopupMenu.popup()` without an explicit `Rect2i` argument uses the current mouse position. In Godot 4, UI signals and `_gui_input` fire in the input phase; if there is any `await` or deferred call between the right-click event and the popup call, the mouse may have moved.

**Consequences:** Menu appears in the wrong position or is partially off-screen. On a 15-slot grid with slots near the right or bottom edge, this is common.

**Prevention:** Use `popup.popup(Rect2i(get_global_mouse_position(), Vector2i.ZERO))` called synchronously inside `_gui_input` with no intervening `await`. Alternatively use `popup_on_parent(Rect2i(...))` to let Godot clamp to the viewport. Pass the slot's `global_position` not the live mouse position so the menu is always adjacent to the slot.

**Detection:** Right-click near the right edge of the inventory panel — menu should not overflow the screen.

**Phase:** Phase 1 (context menu implementation).

---

### 3. PopupMenu Signal `id_pressed` vs `index_pressed` Confusion

**What goes wrong:** `PopupMenu` emits `id_pressed(id: int)` where `id` is the item ID you pass to `add_item()`, and separately `index_pressed(index: int)` where `index` is the position in the menu. Developers connect `id_pressed` but add items with auto-increment IDs, then get confused when Equip=0, Consume=1, Drop=2 in one context but Consume=0, Drop=1 in another (because WeaponItems have no Consume option). Using index instead of id causes the wrong action to fire.

**Why it happens:** Godot 4's `PopupMenu.add_item(label)` assigns auto-incrementing IDs from 0. When menu items are conditionally added (Equip only appears for weapons), the indices shift and `index_pressed` gives wrong results.

**Consequences:** Pressing "Drop" triggers "Equip" because the menu had 3 items for a weapon slot but only 2 for a consumable slot — the index drifts.

**Prevention:** Always use explicit IDs with `add_item(label, id)` where id is a named constant (`const MENU_EQUIP = 1`, `const MENU_CONSUME = 2`, `const MENU_DROP = 3`). Connect `id_pressed` not `index_pressed`. Never rely on menu item position.

**Detection:** Right-click a HealthItem (shows Consume + Drop). Right-click a WeaponItem (shows Equip + Drop). Verify pressing Drop always drops and not equips.

**Phase:** Phase 1 (context menu implementation).

---

### 4. Context Menu Leaves a Stale Slot Reference After Inventory Changes

**What goes wrong:** The right-click handler captures the `slot_index` (and the `Item` reference) at the time of the right-click. The context menu is shown asynchronously. If the player presses E (use) or Q (drop) via keyboard while the menu is visible, or if an item is picked up and `inventory_changed` fires before the player clicks a menu option, the slot at `_pending_slot_index` may now contain a different item or be empty.

**Why it happens:** `PopupMenu` callbacks arrive via `id_pressed` signal which fires after the menu is shown — not inline with the original input. The inventory can change between right-click and menu selection.

**Consequences:** Player right-clicks a sword, gets a menu with "Equip". A split-second later another item is collected, the inventory shifts (if items can move during pickup), and clicking Equip equips the wrong item or crashes on a null slot.

**Prevention:** Capture `item` reference by value (the `Item` object, not just the index) at right-click time. Before acting on `id_pressed`, verify the captured `item` is still in the slot: `if _inventory.slots[_pending_index].item != _pending_item: return`. Dismiss the popup in `_input` if inventory_changed fires while it is open.

**Detection:** Open context menu, simultaneously trigger an inventory change (collect an item), then click Equip.

**Phase:** Phase 1 (context menu) and Phase 2 (equip/unequip flow).

---

## Moderate Pitfalls

Mistakes that cause rework if not addressed before the feature is complete.

---

### 5. hit() Wiring: Attack Resource vs WeaponItem.damage Mismatch

**What goes wrong:** `player.gd` has `@export var attack: Attack` (an `Attack` Node with `damage: int` and `cooldown: float`). `WeaponItem` has `@export var damage: float`. The fist attack goes through `HitboxComponent` which reads `body.attack` (the Attack node). Implementing `hit()` by reading `equipped_weapon.damage` directly bypasses the Attack node entirely — the HitboxComponent never triggers, enemies take no damage.

**Why it happens:** `WeaponItem.damage` looks like the obvious value to read. The Attack node pattern is less visible. `HitboxComponent._on_body_entered` checks `if "attack" in body` — it needs a property named `attack` on the weapon scene's body, not a method or a float.

**Consequences:** Equipped weapon's damage value is read in `hit()`, applied somewhere, but the hitbox collision system that drives `HitboxComponent.take_damage()` is never called. Alternatively: the fist Attack node keeps being used regardless of what is equipped.

**Prevention:** The weapon equip system must wire through the existing `Attack` node pattern. Options: (a) swap the player's `attack` property to a new `Attack` node built from `equipped_weapon.damage` and `equipped_weapon.cooldown`, or (b) mutate the existing `Attack` node's values when equipping. Either way, `player.attack` must reflect the equipped weapon so `HitboxComponent._on_body_entered` picks it up correctly. Document the chosen approach before writing code.

**Detection:** Equip a sword. Attack an enemy. Verify damage dealt matches `WeaponItem.damage` not the fist `Attack.damage`. Then unequip — verify fist damage is restored.

**Phase:** Phase 2 (weapon wiring). Must decide the Attack→WeaponItem bridge in Phase 1 architecture.

---

### 6. Equip From Bag Does Not Remove Item From Bag Slot

**What goes wrong:** Equipping a weapon sets `player.equipped_weapon = item` but does not remove the item from `Inventory.slots`. The item now exists in both places. Weight still counts it. Player can drop it from the bag while it is equipped. The UI shows it in the bag and in the equipment slot simultaneously.

**Why it happens:** The equip action and the inventory removal are two separate operations. If the developer implements equip first as "just set the equipped var" for simplicity and defers removal, the deferred removal never gets added properly.

**Consequences:** Weight budget is wrong (counts equipped items). Drop while equipped causes the equipped reference to dangle (item no longer exists in inventory but `equipped_weapon` still points to it). Duplicate item exploit.

**Prevention:** Equip is always an atomic bag-remove + slot-set. In one function: `inventory.remove(item, 1)` then `equipped_weapon = item`. No intermediate state. Write a unit test that asserts the item is absent from the bag after equipping.

**Detection:** Equip a weapon. Open the inventory. The weapon must not appear in any bag slot. Current weight must not include the equipped weapon's weight.

**Phase:** Phase 2 (equip/unequip flow). Unit-test atomicity.

---

### 7. Unequip With Full Bag Has No Fallback

**What goes wrong:** Unequipping a weapon calls `inventory.insert(equipped_weapon)`. If the bag is full (all 15 slots occupied, or weight limit reached), `insert()` returns remaining `> 0` and the item is not returned to the bag. The code then either loses the item (sets `equipped_weapon = null` anyway) or refuses the unequip silently with no feedback.

**Why it happens:** The unequip path is implemented optimistically: "insert and assume it works." Error handling for the rejected case is an afterthought.

**Consequences:** Item disappears from the game (equipped slot cleared, bag rejected insert). Or: player cannot unequip at all with a full bag, with no indication why.

**Prevention:** Before unequipping, check `inventory.remaining_weight() >= equipped_weapon.weight` and that a slot is available. If not: show a "bag full — make room to unequip" message (reuse the existing rejection label). Do not clear `equipped_weapon` unless `insert()` returns 0.

**Detection:** Fill inventory to max. Attempt to unequip a weapon. The weapon must remain equipped and the player must see a rejection message.

**Phase:** Phase 2 (equip/unequip flow).

---

### 8. inventory_changed Signal Double-Refresh When Equipping

**What goes wrong:** Equipping triggers `inventory.remove()` which emits `inventory_changed`. The equipment HUD also refreshes on the `equipped_weapon_changed` signal (or similar). If both are connected to `_refresh_slots()` in `inventory_ui.gd`, the UI refreshes twice per equip action. With 15 slots being updated each refresh, this is harmless for performance but can cause visual glitches if the second refresh overwrites selection state or animation state.

**Why it happens:** The existing `_refresh_slots()` re-reads all 15 slot nodes unconditionally. Adding equipment changes that also emit `inventory_changed` doubles the refresh count.

**Prevention:** Accept the double refresh as correct behavior (idempotent refresh is safe), but ensure `_deselect()` is not called inside `_refresh_slots()`. The selected index must survive a refresh unless the selected slot is now empty.

**Detection:** Select a bag slot. Equip a different item via context menu. The originally-selected slot must remain selected (if it still has an item).

**Phase:** Phase 1 and 2 combined. Verify during integration.

---

### 9. Right-Click on Equipment Slot Requires Different Menu Than Bag Slot

**What goes wrong:** The context menu built for bag slots (Equip / Consume / Drop) is reused unchanged for equipment slots. An equipment slot should show "Unequip" not "Equip" — and should not show "Consume" even if the item is technically a consumable. Using the same menu logic for both contexts produces nonsensical options.

**Why it happens:** Both slot types use the same `InventorySlotUI` scene (as recommended by the architecture). The right-click handler in that scene emits the same signal regardless of context. The parent UI must differentiate — but if the differentiation is not explicit, the same menu appears everywhere.

**Prevention:** When connecting `slot_right_clicked` signals, pass a `slot_context: String` enum argument (e.g., `"bag"` or `"equipment"`) alongside the slot index. The context menu builder selects which menu items to add based on context, not just item type.

**Detection:** Right-click an equipped weapon in the HUD slot. Menu must show "Unequip", not "Equip".

**Phase:** Phase 1 (context menu architecture). Must be decided before building the menu builder.

---

### 10. Placeholder Visual on Player: Sprite2D vs CanvasGroup Layering

**What goes wrong:** Adding a child `Sprite2D` to the Player scene for the weapon visual renders above or below the player character incorrectly depending on z-index and node order. The weapon sprite may appear on top of the player's body, or may flicker between frames when the AnimationTree changes the player's animation.

**Why it happens:** Godot 4 renders children in declaration order by default. A child `Sprite2D` added after the player's main `Sprite2D` or `AnimationPlayer` renders on top. Sorting order via `CanvasItem.z_index` affects all children relative to the scene, not just siblings.

**Consequences:** The weapon sprite appears floating above the player or is hidden behind. During the Hit animation the player sprite plays but the weapon sprite is static (it has no animation track), causing visual mismatch.

**Prevention:** For a placeholder, use a small `Sprite2D` child with a bright tinted icon positioned to the player's hand position. Mark it `show_behind_parent = false` and set a comment that real weapon attachment will require animation integration. Do not invest in z-index tuning for a placeholder — the real solution is a future AnimationTree track per weapon slot.

**Detection:** Equip a weapon. Confirm a visual change appears on the player. The exact appearance is irrelevant for v1.1 (placeholder is acceptable per PROJECT.md).

**Phase:** Phase 3 (placeholder visual). Low investment required.

---

### 11. Weight Accounting for Equipped Items Is Ambiguous

**What goes wrong:** When a weapon is removed from the bag and placed in the equipment slot, its weight is removed from `Inventory.current_weight()`. The weight label now shows lower capacity usage. This is correct if equipped items do not count against carry weight — but it may feel wrong if the player expects equipped items to have weight. If no decision is made, the display is confusing.

**Why it happens:** The weight system was designed for the bag only. The equipment slot was not part of its design.

**Prevention:** Make an explicit decision: equipped items do NOT count against bag weight (they are worn, not carried). Document this in the data model and reflect it in the UI (weight label shows bag weight only). This is the simpler implementation and the most common RPG convention.

**Detection:** Equip a 3-kg weapon. The weight label must decrease by 3 kg.

**Phase:** Phase 1 architecture decision. Zero implementation cost once decided.

---

## Minor Pitfalls

---

### 12. PopupMenu Leaks When Inventory Closes

**What goes wrong:** The right-click context menu (`PopupMenu`) is shown as a child of the `InventoryUI` or as a top-level popup. If the player presses Tab (toggle inventory) while the menu is open, the inventory hides but the `PopupMenu` remains visible (it is a `Window` subclass in Godot 4 and manages its own visibility).

**Prevention:** In `inventory_ui.gd`'s `_input` handler, when toggling `visible = false`, also call `_context_menu.hide()` if the menu is open. Alternatively, make the PopupMenu a child of the slot UI so it auto-hides with the parent.

**Phase:** Phase 1. One-line fix; easy to miss.

---

### 13. GUT Tests Cannot Instantiate PopupMenu Without Scene Tree

**What goes wrong:** `PopupMenu` is a `Window` subclass and requires the scene tree to be shown. Unit tests that try to test context menu logic directly (e.g., "right-clicking a weapon slot produces an Equip option") will fail or print errors if the test calls `popup.add_item()` or `popup.popup()` without an active scene tree.

**Prevention:** Extract context menu construction into a pure function that returns an `Array[Dictionary]` of `{label, id}` entries. Test that function in isolation. The actual `PopupMenu` display is a UI concern and does not need unit tests — integration-test it manually.

**Detection:** Any unit test that calls methods on a `PopupMenu` node will print "PopupMenu: Can't popup without a scene tree" in the test output.

**Phase:** Phase 1. Decide the test boundary before writing menu logic.

---

### 14. Equipment Slot HUD Always-Visible Conflicts With Inventory UI Visibility

**What goes wrong:** The bag inventory (`InventoryUI`) is toggled hidden/visible. The equipment HUD strip is always visible. If both live in the same `CanvasLayer` as children of the same container, hiding the parent container hides the equipment HUD too.

**Prevention:** Place the equipment HUD strip in a separate `CanvasLayer` (or as a sibling outside the toggle group, not a child of `InventoryUI`). Only the bag grid panel should toggle on Tab. The HUD strip is always visible regardless of inventory open/closed state.

**Detection:** Press Tab to close the inventory. The weapon and tool HUD slots must still be visible.

**Phase:** Phase 1 (scene structure). Must be decided before any UI layout work.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Equipment slot data model | Using Inventory.slots for equipment (Pitfall 1) | Separate `equipped_weapon` var on Player |
| Context menu display | Wrong popup position at screen edges (Pitfall 2) | Use `Rect2i(slot.global_position, ...)` |
| Context menu actions | id vs index confusion causes wrong action (Pitfall 3) | Named const IDs, connect `id_pressed` |
| Async menu callbacks | Stale slot reference after inventory change (Pitfall 4) | Capture item reference, verify before acting |
| hit() wiring | WeaponItem.damage bypasses Attack node / HitboxComponent (Pitfall 5) | Bridge through existing Attack node |
| Equip transaction | Item exists in both bag and equipment slot (Pitfall 6) | Atomic remove + equip, unit-test atomicity |
| Unequip with full bag | Item lost or silent failure (Pitfall 7) | Check capacity before unequip, show rejection |
| HUD visibility | Equipment HUD hidden when inventory closes (Pitfall 14) | Separate CanvasLayer for HUD strip |
| PopupMenu + GUT tests | Tests crash on Window subclass (Pitfall 13) | Test menu data, not the PopupMenu node |
| Placeholder visual | z-index / layering issues (Pitfall 10) | Minimal Sprite2D child, no z-index tuning |

---

## Sources and Confidence

All findings are grounded in direct inspection of the v1.0 codebase:

| Pitfall | Source | Confidence |
|---------|--------|------------|
| Equipment in bag slots (1) | `inventory.gd`, `inventory_ui.gd` — fixed slot count assumption | HIGH |
| PopupMenu position (2) | Godot 4 `PopupMenu` API — `popup()` uses live mouse position | HIGH |
| id vs index (3) | Godot 4 `PopupMenu` signal contract — `id_pressed` vs `index_pressed` | HIGH |
| Stale reference (4) | `inventory_ui.gd` selection pattern — `_selected_index` captured at click time | HIGH |
| Attack node mismatch (5) | `hitbox_component.gd` — reads `body.attack`; `weapon_item.gd` — has `damage: float` | HIGH |
| Equip atomicity (6) | `inventory.gd` `remove()` and player.gd `hit()` stub — no equip logic exists yet | HIGH |
| Unequip full bag (7) | `inventory.gd` `insert()` returns remaining — caller must handle rejection | HIGH |
| Double refresh (8) | `inventory_ui.gd` `_refresh_slots()` connected to `inventory_changed` | HIGH |
| Equipment context (9) | `inventory_slot_ui.gd` — single `slot_clicked` signal, no context parameter | HIGH |
| Sprite layering (10) | Godot 4 rendering order — z-index + AnimationTree interaction | MEDIUM |
| Weight ambiguity (11) | `inventory.gd` `current_weight()` iterates all bag slots only | HIGH |
| PopupMenu leak (12) | Godot 4 `PopupMenu extends Window` — independent visibility | HIGH |
| GUT + PopupMenu (13) | GUT inner-class test pattern; `Window` requires scene tree | HIGH |
| HUD visibility (14) | `inventory_ui.gd` `visible = !visible` toggles entire UI node | HIGH |

---

*Research complete: 2026-03-13*
