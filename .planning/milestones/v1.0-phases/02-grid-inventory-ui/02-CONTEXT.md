# Phase 2: Grid Inventory UI - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Visual overhaul of the existing inventory panel: replace the stub InventoryUI with a functional fixed-slot grid that displays item icons/abbreviations, quantities, and weight feedback. Item usage and item drop are Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Slot grid configuration
- Fixed 15 slots (5 columns × 3 rows) — matches existing GridContainer columns=5 layout
- Slots are instantiated at runtime from a script constant (SLOT_COUNT = 15), not hardcoded in the .tscn
- Inventory resource must be configured with exactly 15 InventorySlot entries

### Equipment slots
- Phase 2 does nothing with equipment slots — Phase 3+ adds a separate always-visible HUD element (Minecraft-style, outside the inventory panel)
- No placeholder in Phase 2 inventory panel

### Slot appearance
- Occupied slot: item abbreviation label (short, readable — e.g., "Med", "Axe", "Key") centered in slot + quantity label in bottom-right corner
- When item.texture is assigned, the icon replaces the abbreviation label
- Empty slots: slot background shown at reduced opacity (semi-transparent/dimmed) — visually distinct from occupied slots
- No hover highlight or selection interaction in Phase 2 — slots are display-only (interaction is Phase 3)

### Weight display
- Text label only: "X.X / Y kg" format (e.g., "12.5 / 20 kg")
- Positioned at the bottom of the inventory panel, below the slot grid
- Updates in real-time via signal when inventory contents change (not just on panel open)

### Rejection feedback
- Displayed as a HUD notification (CanvasLayer or screen-level label), always visible regardless of inventory state — player can attempt pickup while inventory is closed
- Message: "Too heavy!"
- Auto-fades after ~2 seconds (use a Timer; tween for fade is Claude's discretion)

### Claude's Discretion
- Exact font sizes, colors, and spacing for slot labels
- Tween/animation for rejection label fade
- Whether weight label changes color when near/at limit (low priority polish)
- How item abbreviation length is determined (e.g., first 3-5 chars, or trim to fit slot)

</decisions>

<specifics>
## Specific Ideas

- Abbreviation style inspired by colored-box initials concept: short readable text in the slot center, not a single letter
- The rejection message location was chosen because pickup can happen without opening the inventory panel

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inventory_ui.tscn`: Has `NinePatchRect` panel (499×286px) with a `GridContainer` (columns=5) — keep structure, replace slot children with runtime instantiation
- `inventory_slot_ui.tscn`: `Panel` node (87×80px) with slot background `Sprite2D` — add `TextureRect`/`Label` for icon/abbrev and a `Label` for quantity
- `Inventory` resource: `slots: Array[InventorySlot]`, `current_weight()`, `max_weight` — data layer is ready
- `InventorySlot` resource: `item: Item`, `quantity: int`, `is_empty()` — slot state is ready
- `Item` resource: `id: StringName`, `name: String`, `texture: Texture2D`, `category: Category` — abbreviation derived from `name`

### Established Patterns
- Signal-driven: inventory changes should emit a signal; InventoryUI listens and redraws — no polling in `_process()`
- `@onready` for node references; avoid `get_node()` in update methods
- `inventory_ui.gd` is currently a ~20-line stub — full rewrite expected

### Integration Points
- `InventoryUI` needs a reference to the player's `Inventory` resource — likely passed via `@export var inventory: Inventory` or connected from `world.gd`/`player.gd`
- HUD rejection label: new node on a `CanvasLayer` in `world.tscn` or as a child of `InventoryUI`'s parent — must be visible when inventory is closed

</code_context>

<deferred>
## Deferred Ideas

- Equipment slots (weapon/armor) as separate always-visible HUD element — future phase (Phase 3+)
- Hover tooltips showing full item name — future phase when interaction is added
- Weight label color change feedback — low priority, deferred if time constrained

</deferred>

---

*Phase: 02-grid-inventory-ui*
*Context gathered: 2026-03-10*
