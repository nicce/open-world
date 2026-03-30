# Phase 7: Combat Wiring + HUD Strip - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire `hit()` to use the equipped weapon's damage value (fist fallback when unequipped), build an always-visible HUD strip showing weapon and tool equipment slots at the bottom of the screen, and add a placeholder visual indicator on the player character when a weapon is equipped.

</domain>

<decisions>
## Implementation Decisions

### Combat dispatch (CMBT-03, CMBT-04)
- `hit()` reads `equipment_data.weapon` **at call time** — not via a subscription to `equipment_changed`
- If weapon equipped: `attack.damage = equipment_data.weapon.damage` (overrides damage just before animation fires)
- If no weapon: leave `attack.damage` as-is (the Inspector-configured fist value on the Attack node)
- `hit()` is called from `move()` **before** `animation_state.travel("Fist")` — collision timing is handled by the animation track that toggles `Fist/CollisionShape2D:disabled` at the impact frame
- No changes to animation `.res` files; no method track needed

### Player weapon indicator (CMBT-05)
- A child node on the Player (Sprite2D or Label, Claude's discretion on node type) shows when a weapon is equipped
- **Texture if available**: shows `weapon_item.texture` in a TextureRect/Sprite2D
- **Label fallback**: if `weapon_item.texture` is null, shows `weapon_item.name` as text
- Same pattern as existing `collectable.gd` / `sword.gd` texture-or-label logic
- Visibility toggled by `equipment_data.equipment_changed` signal
- Position above the player character (exact offset: Claude's discretion)

### HUD strip layout (HUD-01)
- **Position**: bottom center of the viewport
- **Scene placement**: sibling of InventoryUI in the world's CanvasLayer — NOT a child of InventoryUI, so it remains visible when the inventory panel is closed
- Two slots: weapon slot (left) and tool slot (right)
- Slot labels "W" and "T" displayed as text **below** each slot box
- Empty slots: darker/dimmed appearance (visually distinct from filled slots)

### HUD slot icon display (HUD-02)
- Filled slot shows weapon/tool **texture if available**, falls back to **item name as a Label**
- Same texture-or-label pattern as the rest of the codebase (collectable, sword)
- Slot content updates in response to `equipment_data.equipment_changed` signal

### Claude's Discretion
- Exact node type for player indicator (Sprite2D vs TextureRect vs Label wrapper)
- Exact pixel offset for indicator position above player
- HUD slot pixel size and spacing
- Dimming implementation for empty slots (modulate vs separate StyleBox)
- Whether HUD strip is a new scene file or defined inline in world.tscn

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — CMBT-03, CMBT-04, CMBT-05, HUD-01, HUD-02 acceptance criteria

### Existing combat system
- `scripts/player.gd` — hit() stub, attack export, equipment_data export, move() attack keypress logic
- `scripts/attack.gd` — Attack Resource (damage, cooldown fields)
- `scripts/hitbox_component.gd` — reads `area.get_parent().attack` to get damage; collision timing driven by animation
- `scripts/resources/equipment_data.gd` — equip_weapon(), unequip_weapon(), equipment_changed signal, weapon field (WeaponItem)
- `scripts/resources/weapon_item.gd` — damage field (float)

### Existing HUD/UI wiring
- `scripts/world.gd` — _ready() wiring pattern; HUD strip will be wired here alongside InventoryUI
- `scenes/world.tscn` — CanvasLayer structure; HUD strip added as sibling of InventoryUI
- `scripts/inventory_ui.gd` — reference for how inventory connects to equipment_data; _do_unequip_weapon/_do_unequip_tool show signal pattern

### Texture-or-label pattern reference
- `scripts/collectable.gd` — texture-or-label display pattern (reuse in HUD slot and indicator)
- `scripts/sword.gd` — same pattern on a weapon scene

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `equipment_data.equipment_changed` signal — already emitted on every equip/unequip; HUD and indicator subscribe to this
- `Attack` node (`scripts/attack.gd`) — `@export var damage: int` mutated in `hit()` at call time; no new fields needed
- Collectable texture-or-label pattern (`scripts/collectable.gd`, `scripts/sword.gd`) — reuse directly for HUD slot and player indicator

### Established Patterns
- Signal-driven UI updates — InventoryUI connects to `inventory.inventory_changed`; HUD strip connects to `equipment_data.equipment_changed`
- `world.gd` `_ready()` as single wiring point — all new scene connections go here
- Inspector-configured Resources (`@export var attack: Attack`, `@export var equipment_data: EquipmentData`) — HUD strip will receive `equipment_data` via a `set_equipment_data()` method, same as InventoryUI

### Integration Points
- `player.gd` `move()` — add `hit()` call before `animation_state.travel("Fist")` when 'hit' action pressed
- `player.gd` `hit()` — implement damage dispatch (currently `pass` stub)
- `scenes/world.tscn` CanvasLayer — add HUD strip scene as sibling of InventoryUI node
- `scripts/world.gd` `_ready()` — wire `hud_strip.set_equipment_data(player.equipment_data)`
- `scenes/player.tscn` — add WeaponIndicator child node; wire to `equipment_data.equipment_changed`

</code_context>

<specifics>
## Specific Ideas

- hit() pattern confirmed: "read at call time" (not subscribe to equipment_changed) — avoids timing ambiguity between equip signal and hitbox reads
- Player indicator: same texture-or-label logic already in sword.gd — reuse verbatim, no new pattern needed
- HUD strip bottom center matches classic RPG hotbar convention — user confirmed this explicitly

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-combat-wiring-hud-strip*
*Context gathered: 2026-03-19*
