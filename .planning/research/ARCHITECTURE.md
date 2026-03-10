# Architecture Research: Open World (Stardew-like 2D Survival/Adventure)

**Research Date:** 2026-03-10
**Domain:** Godot 4.2+ inventory systems, item type hierarchies, grid-based UI
**Milestone Context:** Subsequent — extending existing component-based, signal-driven foundation

---

## Existing Architecture (What to Preserve)

Three-layer architecture already in place:

```
UI Layer         inventory_ui.gd, health_bar.gd
Game Logic       player.gd, snake.gd, collectable.gd, campfire.gd
Data/Resource    Item, InventorySlot, Inventory, HealthItem, WeaponItem, Attack
```

**Invariants to maintain:**
- Signals for all cross-layer communication (no direct references from UI into game logic)
- Resource classes for all item/inventory data (never move to dictionaries)
- Player is the authority on stat changes (health, equipment)
- Components are leaf nodes with no cross-component dependencies

---

## Component Boundaries

| Component | Owns | Communicates Via |
|-----------|------|-----------------|
| `Inventory` (Resource) | Array of InventorySlot, weight tracking | `changed` signal (to add) |
| `InventorySlot` (Resource) | One item + quantity | Read-only by UI |
| `Item` (Resource) | id, name, weight, category, texture | Inspected by Player for dispatch |
| `InventoryUI` (Control) | Slot nodes, layout | Observes `Inventory.changed`; emits `item_used`, `item_dropped` |
| `Player` | State machine, health, inventory reference | Handles `item_used`, `item_dropped`; calls Inventory methods |
| `Collectable` | Scene, item reference | Calls `Player.collect()` on interact |

---

## Item Type Hierarchy

```
Item (base Resource)
├── @export var id: StringName
├── @export var name: String
├── @export var weight: float
├── @export var category: ItemCategory (enum: WEAPON, TOOL, RESOURCE, CONSUMABLE)
├── @export var texture: Texture2D
├── @export var stackable: bool
└── @export var max_stack: int

HealthItem extends Item
└── @export var heal_amount: int

WeaponItem extends Item
└── @export var attack: Attack
```

**Extension points for future phases (do not build yet):**
- `ToolItem extends Item` — harvest_power, compatible_nodes
- `RecipeItem extends Item` — ingredients array

---

## Grid Inventory UI — Scene Tree

```
InventoryUI (CanvasLayer)
└── Panel (background)
    ├── VBoxContainer
    │   ├── Label ("Inventory — X / Y kg")
    │   └── GridContainer (columns = 5)
    │       ├── InventorySlotUI [0]  ← preloaded slot scene
    │       ├── InventorySlotUI [1]
    │       └── ... (N slots total)
    └── Label (empty state hint, hidden when slots occupied)

InventorySlotUI (Panel)
├── TextureRect (item icon)
├── Label (quantity, hidden if not stackable)
└── Label (weight hint, optional)
```

**Key rule:** Slot nodes are instantiated once at `_ready()`. They are updated in-place when inventory changes — never destroyed and re-added.

---

## Data Flows

### Item Collection
```
Player overlaps Collectable
  → Collectable._on_body_entered() sets is_collectable = true
  → Player presses "interact" → Collectable.collect()
  → Player.collect(item) calls Inventory.insert(item)
  → Inventory.insert() places in slots, respects weight + stack limits
  → Inventory.changed signal emitted
  → InventoryUI._on_inventory_changed() refreshes all slot nodes
  → Remaining items returned; if 0, Collectable queues_free()
```

### Item Use (Consumable)
```
Player selects slot in InventoryUI and presses use key
  → InventoryUI emits item_used(item, slot_index)
  → Player._on_item_used(item, slot_index):
      match item.category:
        CONSUMABLE:
          if item is HealthItem:
            health_component.increase(item.heal_amount)
          inventory.remove(item, 1)
  → Inventory.changed emitted → UI refreshes
```

### Item Drop
```
Player selects slot in InventoryUI and presses drop key
  → InventoryUI emits item_dropped(item, slot_index)
  → Player._on_item_dropped(item, slot_index):
      inventory.remove(item, 1)
      collectable = item.collectable_scene.instantiate()
      collectable.position = player.position + drop_offset
      get_tree().current_scene.add_child(collectable)
  → Inventory.changed emitted → UI refreshes
```

### Weight Feedback
```
Player attempts to collect overweight item
  → Inventory.insert() returns remaining = [item] (couldn't fit)
  → Player.collect() detects remaining, emits feedback signal
  → UI displays "Inventory full" toast / label
```

---

## Build Order (Dependency Rationale)

1. **Fix HIT state exit bug** — Combat loop is broken; unblock before any other work
2. **Add `Inventory.changed` signal + item `id` field** — Foundation for everything else; no UI work is correct without this signal
3. **Grid inventory UI** — Depends on signal; delivers visible slot rendering, weight display
4. **Item use (consumables)** — Depends on grid UI for interaction surface + HealthComponent
5. **Item drop** — Depends on grid UI + item's `collectable_scene` reference

---

## Patterns to Follow

### Slot UI receives data, does not own it
`InventorySlotUI` is a dumb display node. It accepts an `InventorySlot` (or null) and renders it. It never modifies inventory data directly.

### Behavior dispatch lives in Player
Player matches on `item.category` to determine what happens when an item is used. UI emits an event; Player acts. This keeps effect logic centralized.

### Inventory is the single source of truth
All slot state is read from `Inventory.slots`. The UI never maintains its own item list. On `changed` signal, the UI re-reads all slots.

### Reuse Collectable for item drop
The `item.collectable_scene: PackedScene` field (to add) points to an existing collectable scene for that item. Drop logic instantiates it — no new scene architecture needed.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why | Prevention |
|-------------|-----|-----------|
| UI modifying Inventory directly | Bypasses signal chain; UI becomes a logic layer | UI emits signals; Player calls Inventory methods |
| `use()` method on Item Resource | Resources are data, not behavior | Dispatch on `item.category` in Player |
| Rebuilding slot nodes on every inventory change | Performance and focus loss | Instantiate once; update in-place |
| Dynamic slot count (grid grows with items) | Breaks fixed-weight UX, harder to lay out | Fixed N×M grid; empty slots show as blank |

---

## Scalability Notes (Future Phases)

- **Equipment slots:** Add a separate `HBoxContainer` row for weapon/tool slots above the bag grid. `Player` maintains `equipped_weapon: WeaponItem` and `equipped_tool: ToolItem`. Equipment slots share the same `InventorySlotUI` scene.
- **Crafting:** Requires an `ItemRegistry` (autoload with `Dictionary[StringName, Item]`) before recipes can reference items by id. Do not build crafting without this.
- **Hotbar:** A fixed 5-slot row, separate from the bag, always visible. Shares slot scene. Adds `hotbar_slots: Array[InventorySlot]` to `Inventory`.

---

*Research complete: 2026-03-10*
