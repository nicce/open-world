# Phase 3: Item Management - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Player can consume health items from inventory, drop items back into the world, and see feedback on pickups. Slot selection (click to highlight) is the interaction foundation. Equipping weapons is NOT in this phase — that is a v2 concern with its own equipment slot UI.

</domain>

<decisions>
## Implementation Decisions

### Slot selection
- Mouse click selects a slot; selected slot gets a visible highlight border
- Clicking the already-selected slot deselects it (toggle behavior)
- Closing the inventory panel (Tab/I) always clears the selection — no stale state across open/close
- Only occupied slots respond to clicks — clicking an empty slot is a no-op

### Use & drop controls
- E = use selected item; Q = drop selected item (while inventory panel is open only)
- E on a non-consumable (e.g., Gold Key, Axe) = silent no-op — no message or feedback
- E and Q are only active when the inventory panel is visible; they have no effect when closed
- E is safe because world interact is paused while inventory is open

### Drop quantity
- Q drops exactly 1 unit per press; player presses Q multiple times to drop more from a stack
- Dropped collectable spawns at a slight random offset from the player's position (≈16–32px in a random direction) to prevent the item sitting directly under the player and causing immediate re-pickup

### Pickup notification (ITEM-03)
- Format: `+ [Item Name]` (e.g., `+ Gold Key`, `+ Medpack`)
- Position: bottom center of screen, on a CanvasLayer (always visible)
- Behavior: replace — each new pickup resets the label text and restarts the fade timer; most recent pickup always shows
- Same implementation pattern as the existing rejection label in world.gd (Label + Timer + tween fade)

### Claude's Discretion
- Exact fade duration for pickup notification (reference: rejection label uses ~2s + 0.4s tween)
- Selection highlight color/border style on slot
- Exact pixel offset and randomization approach for drop spawn position

</decisions>

<specifics>
## Specific Ideas

- Drop spawns slightly offset from player to avoid instant re-pickup — Claude decides exact range (~16–32px)
- Pickup notification mirrors existing rejection HUD pattern for consistency
- "Use" means: restore HP from HealthItem.health, remove 1 from inventory slot — no other item type is usable in Phase 3

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/inventory_slot_ui.gd`: Panel with `update(slot)` — needs `gui_input` or `_on_gui_input` added for click detection; needs a selected-state visual (border/modulate)
- `scripts/inventory_ui.gd`: Manages slot nodes; needs to track which slot index is selected and handle E/Q input while visible
- `scripts/player.gd`: Has `increase_health(value: int)` and `collect(item) -> bool` — needs `use_item(slot_index)` and `drop_item(slot_index)` methods (or equivalent logic in inventory_ui.gd)
- `scripts/resources/inventory.gd`: `remove(item, amount)` already works — use it for both use and drop
- `scripts/collectable.gd`: `Collectable extends Area2D` with `@export var item: Item` — instantiate from `scenes/collectable.tscn` for drop spawn
- `scripts/world.gd`: CanvasLayer already has `RejectionLabel` with Timer + tween pattern — add a sibling `PickupLabel` following the same structure
- `scripts/resources/health_item.gd`: Has `.health: int` and `consumable = true` — check `item.consumable` before allowing use

### Established Patterns
- Signal-driven: inventory changes via `inventory_changed.emit()` — use the same for UI refresh after use/drop
- `@onready` for node references; no polling in `_process()`
- HUD labels on CanvasLayer (world.gd controls rejection label — add pickup label alongside it)
- `Inventory.remove(item, 1)` returns amount actually removed — check result

### Integration Points
- `inventory_ui.gd` needs access to the player node to call `drop_item()` or to know player position for collectable spawn — passed via `world.gd` or via a signal
- New `pickup_label` node added to `CanvasLayer` in `world.tscn` as sibling to `RejectionLabel`
- Player's `collect()` method already returns `bool` — connect a signal or return value to trigger pickup notification in `world.gd`

</code_context>

<deferred>
## Deferred Ideas

- Equipment slots (weapon/armor as always-visible HUD, Minecraft-style) — v2 phase; Phase 2 context already noted this
- Hotbar / quick-access row — v2 phase
- Equipping a weapon changes attack stats — v2 phase
- Drop quantity picker (choose how many to drop from a stack) — could be added if drop-1-at-a-time feels tedious; backlog

</deferred>

---

*Phase: 03-item-management*
*Context gathered: 2026-03-11*
