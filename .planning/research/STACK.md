# Technology Stack

**Project:** Open World — Stardew-like 2D Survival/Adventure
**Researched:** 2026-03-13 (updated for v1.1 Equipment Slots milestone)
**Confidence Note:** All findings grounded in direct codebase inspection + Godot 4.3 API knowledge through August 2025. Web lookup tools unavailable; external Godot docs unverified for this session. Confidence levels reflect this constraint.

---

## Core Engine (unchanged from v1.0)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Godot Engine | 4.3 (stable) | Game engine and runtime | `project.godot` declares `"4.3"` feature flag. Do not downgrade to 4.2. |
| GDScript | 4.x | All game logic, UI, resource systems | Engine-native; typed, `class_name` Resources work correctly. |

**Confidence:** HIGH — read directly from `project.godot`.

---

## New: Equipment Data Model

### EquipmentSlots Resource

**Add:** `scripts/resources/equipment_slots.gd` — a new `Resource` subclass that owns the two logical slots (weapon, tool).

| Pattern | Purpose | Why |
|---------|---------|-----|
| `Resource` subclass `EquipmentSlots` | Holds `var weapon_slot: Item` and `var tool_slot: Item` (nullable) | Consistent with existing data model. Serializable. Testable with `.new()` in GUT. Do NOT reuse `InventorySlot` — equipment is quantity-1, no stacking, no weight budget constraint at equip time (weight is only a bag concern). |
| Signals `equipped(item: Item, slot_name: StringName)` and `unequipped(item: Item, slot_name: StringName)` on `EquipmentSlots` | UI and Player observe changes | Keeps Player.gd and HUD decoupled from each other, matching the existing signal-driven pattern (see `Inventory.inventory_changed`). |
| `@export var weapon_slot: Item = null` | Nullable item reference, not an InventorySlot | No stacking needed. Equipment slots hold a single item or are empty (null). |

**Why NOT reuse `Inventory`:** `Inventory` enforces weight budgets and max_stack. Equipment has neither. Mixing them adds complexity and breaks the weight invariant. A dedicated resource is the correct boundary.

**Confidence:** HIGH — pattern is identical to how `Inventory` was introduced alongside `InventorySlot`.

---

### Item.Category (existing, no change needed)

`Item.Category` already declares `WEAPON` and `TOOL`. The context menu will filter actions by this enum. No additions required.

**Confidence:** HIGH — read directly from `scripts/resources/item.gd`.

---

### WeaponItem.damage (existing, no change needed)

`WeaponItem extends Item` with `@export var damage: float`. When a weapon is equipped, `Player.hit()` reads `equipped_weapon.damage` and applies it via the existing `Attack` node. No new fields needed on `WeaponItem`.

**Confidence:** HIGH — read directly from `scripts/resources/weapon_item.gd`.

---

## New: Right-Click Context Menu

### Godot Node: PopupMenu

**Use `PopupMenu` as a child of the inventory slot UI scene.**

| Aspect | Decision | Why |
|--------|----------|-----|
| Node type | `PopupMenu` (built-in Godot node) | Native Godot right-click menu. No addon required. Renders above all other UI by design. |
| Trigger | `MOUSE_BUTTON_RIGHT` in `inventory_slot_ui.gd`'s `_gui_input()` | The slot already handles `_gui_input` for left-click (`slot_clicked`). Extend the same handler for right-click. |
| Positioning | `popup.popup_on_parent(Rect2(get_global_mouse_position(), Vector2.ZERO))` or `popup.position = get_global_mouse_position(); popup.popup()` | Appears at cursor. Both approaches are valid in Godot 4.3. |
| Menu items | Added dynamically at popup time based on `item.category` and `item.consumable` | Prevents showing "Equip" for a food item. Build the menu in the signal handler, not at `_ready()`. |
| Signal | `id_pressed(id: int)` on `PopupMenu` | Clean integer dispatch. Assign a constant int to each action (EQUIP=0, CONSUME=1, DROP=2). |
| Ownership | One `PopupMenu` per `InventorySlotUI`, added in `_ready()` as `add_child()` | Simplest scope. The slot that was right-clicked owns its menu. Alternatively, one shared popup on `InventoryUI` — see Alternatives. |

**Key API (Godot 4.3, HIGH confidence from training data):**
```gdscript
# In inventory_slot_ui.gd
@onready var context_menu: PopupMenu = $ContextMenu

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            slot_clicked.emit(self)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            slot_right_clicked.emit(self)
            get_viewport().set_input_as_handled()
```

**Signal to emit vs. handle locally:** Emit a `slot_right_clicked(slot_node)` signal up to `InventoryUI`, and let `InventoryUI` build and show the menu. This matches the existing `slot_clicked` pattern and keeps slot nodes thin.

**Confidence:** HIGH for `PopupMenu` existence and `id_pressed` signal. MEDIUM for exact `popup()` overload syntax — verify against Godot 4.3 docs during implementation.

---

## New: HUD Equipment Strip

### Godot Nodes: CanvasLayer + HBoxContainer + Panel

| Node | Role | Why |
|------|------|-----|
| `CanvasLayer` (existing, reuse) | Parent for all persistent HUD elements | `$CanvasLayer` already contains `InventoryUI`, `RejectionLabel`, `PickupLabel`. Add the equipment strip here. Do not create a second CanvasLayer. |
| `HBoxContainer` | Layout for weapon slot + tool slot side-by-side | Standard horizontal layout container. `separation` property controls gap. |
| `Panel` (x2) | Individual equipment slot visuals | Reuse the same `StyleBoxFlat` pattern as `InventorySlotUI`. Each panel shows: icon (TextureRect) + label (e.g. "W" / "T"). |
| `Label` for slot letter | Indicates slot purpose (W = weapon, T = tool) | Small corner label. Placeholder until icons are added. |

**Always-visible requirement:** Place the `HBoxContainer` directly in the `CanvasLayer`, NOT inside `InventoryUI`. `InventoryUI` toggles `visible` on Tab press. The HUD strip must not toggle with it.

**Scene path:** `scenes/equipment_hud.tscn` — a standalone scene instantiated in `world.tscn` under `$CanvasLayer`.

**Script:** `scripts/equipment_hud.gd` — observes `EquipmentSlots` signals and refreshes visuals. Wired in `world.gd` (same pattern as `inventory_ui.set_inventory()`).

**Confidence:** HIGH — CanvasLayer + HBoxContainer is the established Godot 4 pattern for always-on HUD.

---

## New: Equip/Unequip Flow

### Data flow

```
InventoryUI (slot right-click)
    → context_menu "Equip" selected
    → inventory_ui calls equipment_slots.equip(item, slot_name)
    → EquipmentSlots removes item from Inventory bag (calls inventory.remove())
    → EquipmentSlots stores item reference in weapon_slot / tool_slot
    → EquipmentSlots emits equipped(item, slot_name)
    → EquipmentHUD refreshes via equipped signal
    → Player refreshes via equipped signal
```

**Who owns equip logic:** `EquipmentSlots` resource. It is the single authority on what is equipped, matching how `Inventory` owns insert/remove logic. `InventoryUI` does not call `Inventory.remove()` directly for equip — it delegates to `EquipmentSlots.equip()`.

**Unequip:** Right-click on an equipment slot in the HUD shows "Unequip". `EquipmentSlots.unequip(slot_name)` calls `inventory.insert(item)` to return it to the bag, then clears the slot. If the bag is full (insert returns > 0 remaining), unequip is rejected and the item stays equipped.

**Weight during equip:** When equipping, remove the item from the bag (which lowers bag weight). Equipped items do not count toward bag weight — they are held separately. This matches genre convention (equipped gear is "on your body").

**Confidence:** HIGH — logic follows existing `Inventory` insert/remove contract exactly.

---

## New: Player hit() Integration

### Attack dispatch

`player.gd` already has `func hit(): pass` as a stub. The equip signal provides the bridge:

| Mechanism | Decision | Why |
|-----------|----------|-----|
| `var equipped_weapon: WeaponItem = null` on `Player` | Player holds a direct reference | Avoids a lookup on every attack frame. Updated by observing `EquipmentSlots.equipped` / `EquipmentSlots.unequipped`. |
| `Attack` node (existing) | Carries `damage` and `cooldown` to hitbox | `HitboxComponent` reads `body.attack` or `area.get_parent().attack`. Existing pattern. |
| Fist fallback | If `equipped_weapon == null`, use the existing fist `Attack` node | Preserves current behavior when nothing is equipped. |
| `hit()` reads `equipped_weapon.damage` | Sets `attack.damage` before animation plays | `Attack` node is already `@export` on `Player`. Mutate its `damage` at equip time rather than creating new nodes. |

**Wiring:** In `world.gd._ready()`:
```gdscript
equipment_slots.equipped.connect(player._on_weapon_equipped)
equipment_slots.unequipped.connect(player._on_weapon_unequipped)
```

**Confidence:** HIGH — `Attack` node and `hit()` stub are confirmed by reading `scripts/player.gd` and `scripts/attack.gd`.

---

## New: Placeholder Visual Indicator on Player

### Godot node: Sprite2D (or Label)

| Option | Decision | Why |
|--------|----------|-----|
| `Sprite2D` child on player | Preferred if a placeholder texture exists | Engine-standard. Toggle `visible` on equip/unequip. Set `offset` to place it above/beside player sprite. |
| `Label` with item name | Fallback if no texture | Zero art dependency. Shows equipped weapon name as floating text. |

**No new Godot node type is needed.** Either is a plain child of `player.tscn`. Set `z_index = 1` to render above the player sprite. Toggle visibility via the `equipped` / `unequipped` signals.

**Confidence:** HIGH — Sprite2D with toggled visibility is trivially standard in Godot 4.

---

## Testing Additions

### What can be unit-tested with GUT

| Test file | What to test |
|-----------|--------------|
| `tests/unit/test_equipment_slots.gd` | `equip()` moves item out of inventory, populates slot. `unequip()` returns item to inventory. Equipping when already equipped swaps. Unequip when bag full fails gracefully. |
| `tests/unit/test_equipment_slots.gd` | `equipped` and `unequipped` signals fire on correct operations. |
| Extend `test_inventory.gd` if needed | Verify `remove()` correctly reduces weight when called during equip. |

### What cannot be unit-tested with GUT

- `PopupMenu` behavior (requires scene tree and input system)
- `EquipmentHUD` rendering (scene tree required)
- `Player` state after weapon swap (CharacterBody2D requires scene tree)

Use the existing GUT inner-class stub pattern (`class StubPlayer` that duck-types `Player`) for testing Player-adjacent logic where possible.

**Confidence:** HIGH — consistent with existing `test_inventory.gd` and `test_player_state.gd` patterns.

---

## Supporting Libraries (no changes)

| Library | Version | Purpose |
|---------|---------|---------|
| GUT | 9.3.0 | Unit testing — `make test` |
| gdtoolkit | 4.* | Lint and format — `make lint`, `make format-check` |

No new addons. `PROJECT.md` explicitly forbids third-party addons beyond GUT.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Context menu | `PopupMenu` child of `InventoryUI` | One `PopupMenu` per slot | Per-slot menus inflate node count (15 slots = 15 menus). One shared menu on `InventoryUI` is cleaner. |
| Context menu | `PopupMenu` child of `InventoryUI` | Custom `Control`-based overlay | Requires manual positioning, hit-testing, outside-click handling. `PopupMenu` handles all of this natively. |
| Equipment data | Dedicated `EquipmentSlots` resource | Add weapon/tool slots to `Inventory` | `Inventory` has weight + stacking invariants. Adding nullable equipment slots breaks its contract. Separate resource is cleaner. |
| Equipment data | Dedicated `EquipmentSlots` resource | Store equipment on `Player` directly | Player.gd becomes a data store. Hard to test without scene tree. Resource approach allows GUT tests. |
| HUD strip | `HBoxContainer` in `CanvasLayer` | Anchor it inside `InventoryUI` | `InventoryUI` toggles visibility. HUD must be always visible. Must be a sibling, not a child. |
| Player indicator | `Sprite2D` child toggle | New `AnimationPlayer` state | Animation state adds overhead for a placeholder. Simple visibility toggle is sufficient until real weapon scenes are built. |
| Equip removes from bag | Yes, remove from bag on equip | Keep item in bag, just mark it "equipped" | Marking in-bag creates a split truth (is the item in the bag or not?). Removal is the clean model. Matches RPG convention. |

---

## What NOT to Use

| Avoid | Why |
|-------|-----|
| Third-party addons (beyond GUT) | Explicitly constrained in PROJECT.md |
| Reusing `InventorySlot` for equipment | Equipment has no stacking, no max_stack, no weight logic — a slot Resource adds dead fields |
| `ConfigFile` for save data | Cannot encode object graphs |
| `get_node()` in `_process()` | Forbidden in CLAUDE.md — cache with `@onready` |
| Dictionary for item data | Loses type safety, editor integration, serialization |
| Second `CanvasLayer` for HUD | Adds render layer complexity without benefit — reuse existing `$CanvasLayer` |
| Storing equipped item in `InventoryUI` | UI is a View, not a store. Equipment state belongs in `EquipmentSlots` resource |
| `PopupMenu.clear()` omitted before each show | Forgetting to clear produces duplicate menu items on repeated right-clicks |

---

## Integration Points with Existing Code

| Existing file | Change required |
|---------------|----------------|
| `scripts/player.gd` | Add `var equipped_weapon: WeaponItem = null`. Implement `hit()` with weapon dispatch + fist fallback. Connect to `EquipmentSlots` signals in `world.gd`. Add placeholder indicator child. |
| `scripts/world.gd` | Instantiate `EquipmentSlots`, wire to `player`, `inventory_ui`, `equipment_hud`. Same pattern as existing `set_inventory()` + `set_player()`. |
| `scripts/inventory_ui.gd` | Add right-click handler: emit `slot_right_clicked(slot_node)`. Build and show `PopupMenu`. Call `equipment_slots.equip()` on "Equip" selection. |
| `scripts/inventory_slot_ui.gd` | Add `MOUSE_BUTTON_RIGHT` branch to `_gui_input()`. Emit `slot_right_clicked(self)`. |
| **New files** | `scripts/resources/equipment_slots.gd`, `scripts/equipment_hud.gd`, `scenes/equipment_hud.tscn`, `tests/unit/test_equipment_slots.gd` |

---

## Godot Version Note (carried forward)

`project.godot` declares `"4.3"` as its feature version, but the Makefile sets `GODOT_VERSION ?= 4.2.2` for the binary download. Update the Makefile's `GODOT_VERSION` to `4.3.x` to avoid version mismatch warnings during headless test runs.

**Confidence:** HIGH — read directly from `project.godot` and `Makefile`.

---

*Research complete: 2026-03-13 (v1.1 Equipment Slots milestone)*
