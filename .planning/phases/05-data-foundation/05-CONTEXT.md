# Phase 5: Data Foundation - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish `EquipmentData` Resource as the single source of truth for equipped weapon and tool items, and wire right-click signals on bag slot UI nodes with context-aware PopupMenu construction logic. Phase 6 will handle the actual equip/unequip flow; this phase lays the data and signal foundation.

</domain>

<decisions>
## Implementation Decisions

### EquipmentData Resource shape
- Two explicitly typed fields: `@export var weapon: WeaponItem` and `@export var tool: Item`
- Lives in `scripts/resources/equipment_data.gd` extending `Resource` — same pattern as `Inventory`
- Attached to Player as `@export var equipment_data: EquipmentData` — configured in Inspector, same as `inventory` and `attack`
- Methods live on the Resource: `equip_weapon(item: WeaponItem)`, `unequip_weapon() -> WeaponItem`, `equip_tool(item: Item)`, `unequip_tool() -> Item`
- Emits `signal equipment_changed()` from equip/unequip methods — HUD and player indicator (Phase 7) connect to it

### Right-click signal payload
- Each bag slot node emits `signal slot_right_clicked(slot_index: int, item: Item)` on right-click via `gui_input`
- `InventoryUI` connects to each slot's signal in `_ready()`
- `InventoryUI` is the decision-maker: receives `(slot_index, item)`, checks `item is WeaponItem` vs `item is HealthItem`, builds `PopupMenu` with correct options
- `WeaponItem` → menu shows `Equip` + `Drop`; `HealthItem` → menu shows `Consume` + `Drop`
- Right-clicking an empty slot shows no menu

### Context menu architecture
- `PopupMenu` is a child node of `InventoryUI` — no separate scene needed for Phase 5
- Named const IDs for menu items (not positional index): `const MENU_EQUIP = 0`, `const MENU_CONSUME = 1`, `const MENU_DROP = 2`
- Uses `id_pressed` signal (not `index_pressed`) to avoid positional shift when items are conditionally added

### Menu dismissal
- PopupMenu dismisses when inventory panel closes — wired via `InventoryUI`'s existing visibility toggle: call `popup_menu.hide()` when inventory panel hides
- PopupMenu's own `popup_hide` signal handles self-dismissal when clicking outside (Godot default behaviour)

### Claude's Discretion
- Exact signal parameter name casing in GDScript (`slot_index` vs `index`)
- Whether `slot_right_clicked` signal is declared on a per-slot `class_name SlotUI` or inline in `inventory_ui.gd` handler
- Unit test structure for EquipmentData (inner class stubs follow existing GUT patterns)

</decisions>

<specifics>
## Specific Ideas

- `EquipmentData` methods return the displaced item so Phase 6 can hand it back to the inventory atomically
- `unequip_weapon()` returns the previous weapon (or null) so Phase 6 can insert it back into the bag in one call
- Signal payload includes the `Item` directly (not just index) so the context menu builder never has to look it up again

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/resources/inventory.gd` — EquipmentData follows the same `extends Resource` pattern with methods on the data class
- `scripts/resources/weapon_item.gd` / `health_item.gd` — `is WeaponItem` / `is HealthItem` type checks are already valid GDScript idioms
- `scripts/attack.gd` — precedent for a lightweight `@export` Resource attached to Player with a typed field

### Established Patterns
- `@export var inventory: Inventory` on Player — EquipmentData uses the same attachment pattern
- Signal-driven communication (HealthComponent → damage_taken, Inventory → insert_rejected) — EquipmentData follows with `equipment_changed`
- `id_pressed` with named const IDs — required by prior planning decision

### Integration Points
- `scenes/inventory_ui.tscn` / `scripts/inventory_ui.gd` — slot nodes get right-click detection added; PopupMenu added as child; `_on_slot_right_clicked` handler added
- `scenes/player.tscn` — `@export var equipment_data: EquipmentData` added as new exported field
- Phase 6 will call `EquipmentData.equip_weapon()` / `unequip_weapon()` and mutate `Inventory` atomically
- Phase 7 will connect `equipment_changed` signal to HUD strip and player indicator

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 05-data-foundation*
*Context gathered: 2026-03-18*
