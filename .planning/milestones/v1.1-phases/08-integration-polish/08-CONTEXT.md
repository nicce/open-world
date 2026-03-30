# Phase 8: Integration Polish - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire CTXMENU-03 (right-clicking an equipment slot shows Unequip + Drop), make popup positioning viewport-safe, and ensure popup lifecycle is clean across all input paths. HUD strip right-click must work independently of inventory open/closed state.

</domain>

<decisions>
## Implementation Decisions

### HUD slot right-click scope
- Right-click on HUD strip slots responds **regardless of whether the inventory panel is open or closed** — HUD is always visible, right-click should always work
- Right-clicking an **empty** HUD slot (nothing equipped) shows no menu — consistent with bag slot behaviour

### Popup ownership
- **HudStrip owns its own PopupMenu** — a child node added directly to the HudStrip scene
- HudStrip handles unequip + drop logic internally: calls `_equipment_data.unequip_weapon()` / `unequip_tool()` directly and spawns the collectable in world
- HudStrip gets a `set_player(p: Player)` method — same injection pattern as InventoryUI
- `world.gd` `_ready()` wires `hud_strip.set_player(player)` alongside the existing `set_equipment_data()` call
- Menu items for HUD popup: `MENU_UNEQUIP` and `MENU_DROP` (named const IDs with `id_pressed` — same pattern as InventoryUI's popup)

### Drop from equipment slot
- "Drop" on an equipped item: **unequip the item and spawn collectable directly in the world at player position** — bypasses the bag entirely
- This works even when the bag is full (drop is not unequip-to-bag)
- Drop appears only where the item lives: HUD menu shows `Unequip` + `Drop`; bag menu already shows `Equip`/`Consume` + `Drop` (no change needed there)

### Viewport-safe popup positioning
- Popup position is **manually clamped** before calling `popup()`: calculate popup minimum size, clamp the mouse position so the popup fits within viewport bounds
- Fix applies to **both** InventoryUI's popup and HudStrip's popup — consistent behaviour across all context menus
- Helper logic: `var pos = get_viewport().get_mouse_position(); var vp = get_viewport().get_visible_rect().size; pos.x = clampf(pos.x, 0, vp.x - popup_min_width); pos.y = clampf(pos.y, 0, vp.y - popup_min_height)` then `popup(Rect2i(pos, Vector2i.ZERO))`

### Claude's Discretion
- Whether viewport clamping helper is a static function in a shared autoload/utility or duplicated inline in both InventoryUI and HudStrip
- Exact PopupMenu min-size estimation approach (get_contents_minimum_size() or a fixed constant like 120x60)
- Node type for HudStrip PopupMenu (regular PopupMenu child is sufficient)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — CTXMENU-03 acceptance criteria (right-clicking equipment slot shows Unequip + Drop)

### Existing popup implementation (to extend / fix)
- `scripts/inventory_ui.gd` — existing PopupMenu, `_on_slot_right_clicked()`, `_on_context_menu_id_pressed()`, `_do_unequip_weapon/tool()` methods; viewport clamping fix goes here
- `scripts/hud_strip.gd` — new PopupMenu and right-click handling added here; `set_player()` added
- `scripts/inventory_slot_ui.gd` — existing `right_clicked` signal on bag slots (reference for HUD slot signal pattern)

### Collectable spawning pattern
- `scripts/inventory_ui.gd` `_drop_selected()` — existing drop pattern (remove from inventory, instantiate collectable, position at player, add to scene); HudStrip drop reuses this exact pattern

### Wiring point
- `scripts/world.gd` — `_ready()` wiring; `hud_strip.set_player(player)` added here

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_drop_selected()` in `inventory_ui.gd` — exact drop pattern to replicate in HudStrip: instantiate `COLLECTABLE_SCENE`, set `node.item`, random offset from `_player.global_position`, `get_tree().current_scene.add_child(node)`
- `_do_unequip_weapon()` / `_do_unequip_tool()` in `inventory_ui.gd` — unequip logic already written; HudStrip needs its own variant that goes straight to drop instead of bag insert
- Named const IDs pattern (`MENU_EQUIP = 0`, `MENU_DROP = 2`) — HudStrip uses same style with `MENU_UNEQUIP = 0`, `MENU_DROP = 1`

### Established Patterns
- `set_inventory()` / `set_equipment_data()` / `set_player()` injection pattern in world.gd `_ready()` — HudStrip's `set_player()` follows the same pattern
- `id_pressed` signal with const IDs in PopupMenu — required by Phase 5 decision
- `popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))` — current (unsafe) call site in `inventory_ui.gd`; both locations get the clamping fix

### Integration Points
- `scripts/hud_strip.gd` — add `_player` var, `set_player()`, PopupMenu child, `_on_hud_slot_right_clicked()`, `_on_hud_popup_id_pressed()`, `_do_drop_equipped(slot_type)`
- `scripts/world.gd` `_ready()` — add `hud_strip.set_player(player)`
- `scripts/inventory_ui.gd` `_on_slot_right_clicked()` — apply viewport clamping fix to the existing `popup()` call
- `scenes/hud_strip.tscn` — add PopupMenu as child node of HudStrip root

</code_context>

<specifics>
## Specific Ideas

- Drop from HUD slot bypasses the bag intentionally — player said "drop", not "unequip". Bag-full state is irrelevant for drop.
- Empty HUD slot → no menu: same behaviour as empty bag slot. No need to hint the player — they can open inventory to equip.
- Viewport clamping applied to both popup sites for consistency: the bag popup can also overflow if opened near the right/bottom edge when the inventory is positioned there.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 08-integration-polish*
*Context gathered: 2026-03-25*
