# Architecture Patterns: v1.1 Equipment Slots

**Research Date:** 2026-03-13
**Domain:** Godot 4.2+ equipment slot integration, right-click context menus, HUD composition
**Milestone Context:** Subsequent — extending proven v1.0 component-based, signal-driven foundation
**Confidence:** HIGH (derived from direct codebase inspection; Godot 4 API patterns from training data)

---

## Existing Architecture (What to Preserve)

Three-layer architecture already in place and proven across 88 unit tests:

```
UI Layer         inventory_ui.gd, inventory_slot_ui.gd
Game Logic       player.gd, snake.gd, collectable.gd, campfire.gd
Data/Resource    Item, InventorySlot, Inventory, HealthItem, WeaponItem, Attack
```

**Invariants to maintain for v1.1:**
- Signals for all cross-layer communication — no direct references from UI into game logic
- Resource classes for all equipment/item data — never use plain dictionaries
- Player is the single authority on stat changes (health, equipped weapon)
- Components are leaf nodes with no cross-component dependencies
- `world.gd` is the wiring point: it calls `set_inventory()`, `set_player()` on UI nodes

---

## Where Equipment State Lives

**Decision: New `EquipmentData` Resource, not Inventory extension.**

Rationale:
- `Inventory` already has a clear contract: ordered slots, weight limits, stacking. Equipment breaks that model (only one weapon can be equipped, no stacking, no weight subtraction needed).
- Extending `Inventory` with nullable `equipped_weapon` and `equipped_tool` fields couples unrelated responsibilities and pollutes `clone()`, `insert()`, `remove()` logic.
- A separate `EquipmentData extends Resource` mirrors the existing pattern: `Inventory` for the bag, `EquipmentData` for equipped slots. They are parallel, not nested.
- Player owns both: `@export var inventory: Inventory` already exists; add `@export var equipment: EquipmentData`.

**`EquipmentData` structure:**

```gdscript
class_name EquipmentData extends Resource

signal equipment_changed

@export var weapon_slot: WeaponItem = null
@export var tool_slot: Item = null  # Item base; tool subtype deferred

func equip_weapon(item: WeaponItem) -> void:
    weapon_slot = item
    equipment_changed.emit()

func unequip_weapon() -> WeaponItem:
    var prev := weapon_slot
    weapon_slot = null
    equipment_changed.emit()
    return prev

func equip_tool(item: Item) -> void:
    tool_slot = item
    equipment_changed.emit()

func unequip_tool() -> Item:
    var prev := tool_slot
    tool_slot = null
    equipment_changed.emit()
    return prev
```

**Why not a Dictionary or plain vars on Player:** Resources are inspectable in the Godot editor, support `@export`, and can emit signals. Inline vars on Player would require Player to be the emitter for equipment UI refreshes, tangling UI concerns into the game logic layer.

---

## Component Boundaries (v1.1 additions)

| Component | Owns | Communicates Via |
|-----------|------|-----------------|
| `EquipmentData` (Resource) | `weapon_slot`, `tool_slot` nullable items | `equipment_changed` signal |
| `EquipmentHUD` (Control) | Two slot nodes, always visible HUD strip | Observes `EquipmentData.equipment_changed`; emits `unequip_requested(slot_type)` |
| `EquipmentSlotUI` (Panel) | One slot display (icon or empty) | Extends or reuses `inventory_slot_ui.tscn` |
| `ContextMenu` (PopupMenu) | Dynamic action list built per item type | Emits action signals: `equip_pressed`, `use_pressed`, `drop_pressed` |
| `InventoryUI` (Control) | Bag grid (unchanged) + context menu trigger | Right-click on slot opens ContextMenu with relevant actions |
| `Player` | `equipment: EquipmentData`, equip/unequip logic, weapon dispatch in `hit()` | Consumes UI signals; calls `EquipmentData` methods; drives combat |

---

## Scene Tree Changes

### HUD Strip (always visible, outside inventory toggle)

The existing `world.tscn` has a `CanvasLayer` that contains `InventoryUI` (toggle-visible). The HUD strip must live in the same `CanvasLayer` but be always visible and independent of the inventory toggle.

```
CanvasLayer
├── InventoryUI          (toggle with Tab/I — existing)
├── EquipmentHUD         (always visible — NEW)
│   ├── HBoxContainer
│   │   ├── Label ("W:")
│   │   ├── EquipmentSlotUI (weapon)  ← instance of slot scene
│   │   ├── Label ("T:")
│   │   └── EquipmentSlotUI (tool)    ← instance of slot scene
│   └── (optional: equipped item name label)
├── RejectionLabel       (existing)
└── PickupLabel          (existing)
```

**Scene file:** `scenes/equipment_hud.tscn`
**Script:** `scripts/equipment_hud.gd`

### Context Menu

`PopupMenu` is a built-in Godot Control node. It is instantiated as a child of the `InventoryUI` (or `CanvasLayer`) and shown/hidden programmatically. It must not be a persistent visible node — it appears on right-click and disappears on selection or click-away.

```
InventoryUI
└── ContextMenu (PopupMenu)   ← added as child, hidden by default
```

**Script:** handled directly in `inventory_ui.gd` — no separate script needed.

---

## Right-Click Context Menu: Implementation Pattern

**Node:** `PopupMenu` (Godot built-in Control).

**Trigger:** In `inventory_slot_ui.gd`, `_gui_input` currently handles left-click only. Extend it to emit a second signal for right-click:

```gdscript
# inventory_slot_ui.gd — extend existing _gui_input
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            slot_clicked.emit(self)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            slot_right_clicked.emit(self)
            get_viewport().set_input_as_handled()
```

**Context menu construction** in `inventory_ui.gd`:

```gdscript
# inventory_ui.gd — context menu handling
@onready var _context_menu: PopupMenu = $ContextMenu

func _on_slot_right_clicked(slot_node: Panel) -> void:
    var index := grid.get_children().find(slot_node)
    if index < 0 or _inventory.slots[index].is_empty():
        return
    var item := _inventory.slots[index].item
    _context_menu.clear()
    if item is WeaponItem:
        _context_menu.add_item("Equip", 0)
    if item.consumable:
        _context_menu.add_item("Use", 1)
    _context_menu.add_item("Drop", 2)
    _context_menu_slot_index = index
    _context_menu.popup(Rect2(get_viewport().get_mouse_position(), Vector2.ZERO))
```

**Action dispatch:**

```gdscript
func _on_context_menu_id_pressed(id: int) -> void:
    match id:
        0: _equip_selected()
        1: _use_selected()
        2: _drop_selected()
```

**Confidence:** HIGH — `PopupMenu.add_item(label, id)`, `popup(Rect2)`, and `id_pressed` signal are stable Godot 4.2+ API. The `_gui_input` extension is an established pattern (the existing left-click code already uses it).

---

## Equip/Unequip Data Flow

### Equip weapon from bag

```
Player right-clicks bag slot containing WeaponItem
  → InventorySlotUI emits slot_right_clicked(self)
  → InventoryUI._on_slot_right_clicked() builds ContextMenu with "Equip" action
  → Player selects "Equip"
  → InventoryUI._equip_selected():
      var item := _inventory.slots[index].item as WeaponItem
      _inventory.remove(item, 1)          # remove from bag
      # if weapon already equipped, return it to bag first
      if _equipment.weapon_slot != null:
          _inventory.insert(_equipment.weapon_slot)
      _equipment.equip_weapon(item)       # put in equipment slot
  → Inventory.inventory_changed emitted → bag UI refreshes
  → EquipmentData.equipment_changed emitted → EquipmentHUD refreshes
```

### Unequip weapon back to bag

```
Player right-clicks weapon slot in EquipmentHUD
  → EquipmentHUD emits unequip_requested("weapon")
  → InventoryUI (or world.gd) handles:
      var item := _equipment.unequip_weapon()
      _inventory.insert(item)
  → Both signals fire → both UIs refresh
```

### Hit() dispatch (equipped weapon vs fist fallback)

```
Player presses "hit" action
  → player.gd move() detects action, sets state HIT, triggers Fist animation
  → hit() is called at animation event point (or by animation_finished)
  → hit():
      if equipment.weapon_slot != null:
          # use weapon stats: equipment.weapon_slot.damage
          # HitboxComponent already reads attack from body.attack
          # Player needs an Attack child node whose damage is updated from weapon
          attack.damage = equipment.weapon_slot.damage
      else:
          attack.damage = BASE_FIST_DAMAGE  # fallback constant
```

**Key insight:** `HitboxComponent._on_area_entered()` reads `area.get_parent().attack` where `attack` is the exported `Attack` node on Player. The simplest integration is: Player has one `Attack` child node (already exists as `@export var attack: Attack`). `hit()` writes `attack.damage` from the equipped weapon before the hitbox fires, then resets to fist fallback after. No new scene architecture needed.

**Confidence:** MEDIUM — the `Attack` node approach avoids a scene restructure but requires verifying that `attack.damage` mutation mid-frame is read correctly by `HitboxComponent`. The existing `@export var attack: Attack` on Player makes this the lowest-risk path.

---

## Player Visual Indicator

A `Sprite2D` child on `player.tscn`, named `EquippedWeaponSprite`, set `visible = false` by default. When a weapon is equipped, `player.gd` sets `visible = true` and assigns `texture` from `equipment.weapon_slot.texture`. When unequipped, hide again.

No new component needed. This is a direct player.gd concern since it reflects player state.

---

## Wiring in world.gd

`world.gd` is the scene bootstrap that already calls `inventory_ui.set_inventory()` and `inventory_ui.set_player()`. Add parallel calls for equipment:

```gdscript
# world.gd _ready() additions
inventory_ui.set_equipment(player.equipment)
equipment_hud.set_equipment(player.equipment)
equipment_hud.unequip_requested.connect(_on_unequip_requested)

func _on_unequip_requested(slot_type: String) -> void:
    if slot_type == "weapon" and player.equipment.weapon_slot != null:
        var item := player.equipment.unequip_weapon()
        player.inventory.insert(item)
```

---

## New vs Modified Scripts

| Script | Status | Change |
|--------|--------|--------|
| `scripts/resources/equipment_data.gd` | NEW | `EquipmentData` Resource with weapon/tool slots and `equipment_changed` signal |
| `scripts/equipment_hud.gd` | NEW | Control script for always-visible HUD strip; observes `equipment_changed`; emits `unequip_requested` |
| `scenes/equipment_hud.tscn` | NEW | HBoxContainer with two `EquipmentSlotUI` instances, Label nodes |
| `scripts/inventory_slot_ui.gd` | MODIFY | Add `signal slot_right_clicked(slot_node)` and right-click branch in `_gui_input` |
| `scripts/inventory_ui.gd` | MODIFY | Add `_equipment: EquipmentData` ref, `set_equipment()`, `_context_menu: PopupMenu` child, `_equip_selected()`, context menu signal handlers |
| `scripts/player.gd` | MODIFY | Add `@export var equipment: EquipmentData`; implement `hit()` to dispatch from equipped weapon vs fist fallback; add visual indicator logic |
| `scenes/world.tscn` | MODIFY | Add `EquipmentHUD` node to `CanvasLayer`; add `ContextMenu` (PopupMenu) to `InventoryUI` |
| `scripts/world.gd` | MODIFY | Wire `equipment_hud.set_equipment(player.equipment)`; connect `unequip_requested` |

**No new components required.** `EquipmentSlotUI` reuses or extends the existing `inventory_slot_ui.tscn` — it needs the same icon/label display. Whether it is a scene instance or a subclass is a build-time decision; reusing the scene directly is the simpler path.

---

## Data Flow Summary

```
EquipmentData (Resource)
  ├── observed by: EquipmentHUD (always visible)
  ├── observed by: Player (for hit() dispatch + visual indicator)
  └── modified by: InventoryUI._equip_selected() / world.gd._on_unequip_requested()

Inventory (Resource)
  ├── observed by: InventoryUI (bag grid)
  └── modified by: equip flow (remove from bag) / unequip flow (insert back)

Player
  ├── owns: Inventory + EquipmentData
  ├── calls: equipment.equip_weapon() / unequip_weapon()
  └── reads: equipment.weapon_slot in hit()
```

---

## Build Order (Dependency Rationale)

1. **`EquipmentData` Resource** — No dependencies. Defines the data contract everything else reads. Unit-testable immediately with pure GUT tests.

2. **`InventorySlotUI` right-click signal** — No new dependencies; trivial extension. Unblocks context menu work. Test: emit right-click and assert signal fires.

3. **Context menu in `InventoryUI`** — Depends on slot right-click signal and `EquipmentData` reference. Build after step 1 and 2. Can be tested by calling `_on_slot_right_clicked()` directly.

4. **Equip/Unequip flow (data wiring)** — Depends on `EquipmentData` (step 1) and context menu (step 3). Moves items between `Inventory` and `EquipmentData`. Most complex logic; highest test priority.

5. **`EquipmentHUD` scene + script** — Depends on `EquipmentData` (step 1). Observes `equipment_changed` and renders slots. Unblocks the always-visible HUD requirement. Mostly display logic.

6. **`hit()` weapon dispatch in `Player`** — Depends on `EquipmentData` (step 1). Reads `equipment.weapon_slot` and adjusts `attack.damage`. Testable via `PlayerStub` inner-class pattern already established.

7. **Player visual indicator** — Depends on step 6. Simplest step; add `EquippedWeaponSprite` visibility toggle.

8. **`world.gd` wiring** — Depends on all above. Connects all scenes together. Integration-level; verify in Godot editor.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why | Prevention |
|-------------|-----|-----------|
| Adding `equipped_weapon` to `Inventory` | Mixes bag and slot semantics; breaks `insert/remove/clone` contracts | Separate `EquipmentData` Resource |
| InventoryUI directly mutating `EquipmentData` without going through Player | Bypasses Player as authority on stats | UI calls inventory/equipment methods; Player listens and reacts via signals |
| Showing context menu as a separate full scene | Adds complexity and scene tree overhead | Use built-in `PopupMenu` node as child of InventoryUI |
| Rebuilding slot nodes on every `equipment_changed` | Performance and state loss | Same pattern as inventory slots: instantiate once, update in-place |
| Hardcoding weapon damage in Attack node inspector | Makes equipped weapon stat irrelevant | `hit()` writes `attack.damage` from `equipment.weapon_slot.damage` before hitbox fires |
| Tool slot logic in v1.1 | Out of scope; harvesting logic deferred | Tool slot UI only; `tool_slot` in EquipmentData is nullable and not read by any game logic in v1.1 |

---

## Scalability Notes (Future Phases)

- **Expanded Combat (future):** When sword/bow scenes are added, `hit()` can dispatch on `equipment.weapon_slot.category` or a new `weapon_type` enum on `WeaponItem`. The `attack.damage` write pattern scales without changing `HitboxComponent`.
- **Hotbar (future):** Separate `hotbar_slots: Array[InventorySlot]` on `Inventory`, rendered in its own always-visible row. Shares `InventorySlotUI` scene. Does not conflict with `EquipmentHUD`.
- **Armour slot (future):** Add `armour_slot: Item` to `EquipmentData`; add corresponding slot in `EquipmentHUD`. No structural changes needed.
- **ToolItem subtype (future):** When harvesting logic is built, add `class_name ToolItem extends Item` with `harvest_power` export. The `tool_slot: Item` field on `EquipmentData` will accept it without change.

---

## Confidence Assessment

| Area | Confidence | Source |
|------|------------|--------|
| EquipmentData design (separate Resource) | HIGH | Codebase inspection + established v1.0 pattern |
| PopupMenu right-click API | HIGH | Godot 4.2 training data; stable API since 4.0 |
| `_gui_input` MOUSE_BUTTON_RIGHT pattern | HIGH | Existing left-click code in `inventory_slot_ui.gd` is identical pattern |
| `attack.damage` mutation in `hit()` | MEDIUM | Inferred from `HitboxComponent` reading `body.attack`; needs runtime verification |
| HUD always-visible in CanvasLayer | HIGH | `world.tscn` already has CanvasLayer; `visible = true` by default |
| Build order (step sequencing) | HIGH | Dependencies are explicit from codebase inspection |

---

*Research complete: 2026-03-13 — v1.1 equipment slot architecture*
