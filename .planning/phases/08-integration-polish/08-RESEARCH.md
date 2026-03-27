# Phase 8: Integration Polish - Research

**Researched:** 2026-03-25
**Domain:** Godot 4 PopupMenu lifecycle, viewport-safe positioning, HUD input handling
**Confidence:** HIGH

## Summary

Phase 8 is a surgical integration phase with no new external dependencies. Every
required pattern already exists in the codebase — the work is replication and
repair, not invention. The three concerns (HUD right-click context menu, viewport-
safe popup positioning, popup lifecycle on inventory close) are fully resolved by
inspecting the current source files.

`inventory_ui.gd` already contains the complete reference implementation: PopupMenu
child node, `_on_slot_right_clicked()` handler, `_on_context_menu_id_pressed()` with
named const IDs, `_do_unequip_weapon/tool()`, `_drop_selected()`, and the existing
(unsafe) `popup()` call that needs the clamping fix. `hud_strip.gd` needs the same
pattern added to it, plus a `_player` var and `set_player()` injection. The viewport-
clamping algorithm is fully specified in the UI-SPEC.

The only discretionary decision remaining is whether to extract the clamping logic
into a shared utility or keep it inline. Given that exactly two call sites exist and
the codebase has no shared UI utility class, inline duplication is the lower-risk
choice — but either approach is valid and the planner may decide.

**Primary recommendation:** Follow the patterns already in `inventory_ui.gd` exactly.
Mirror them in `hud_strip.gd`. Apply the clamping algorithm to both `popup()` call sites.
Wire `set_player()` in `world.gd`. No new libraries, no new scenes beyond a PopupMenu
child node in `hud_strip.tscn`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**HUD slot right-click scope**
- Right-click on HUD strip slots responds regardless of whether the inventory panel is open or closed — HUD is always visible, right-click should always work
- Right-clicking an empty HUD slot (nothing equipped) shows no menu — consistent with bag slot behaviour

**Popup ownership**
- HudStrip owns its own PopupMenu — a child node added directly to the HudStrip scene
- HudStrip handles unequip + drop logic internally: calls `_equipment_data.unequip_weapon()` / `unequip_tool()` directly and spawns the collectable in world
- HudStrip gets a `set_player(p: Player)` method — same injection pattern as InventoryUI
- `world.gd` `_ready()` wires `hud_strip.set_player(player)` alongside the existing `set_equipment_data()` call
- Menu items for HUD popup: `MENU_UNEQUIP` and `MENU_DROP` (named const IDs with `id_pressed` — same pattern as InventoryUI's popup)

**Drop from equipment slot**
- "Drop" on an equipped item: unequip the item and spawn collectable directly in the world at player position — bypasses the bag entirely
- This works even when the bag is full (drop is not unequip-to-bag)
- Drop appears only where the item lives: HUD menu shows `Unequip` + `Drop`; bag menu already shows `Equip`/`Consume` + `Drop` (no change needed there)

**Viewport-safe popup positioning**
- Popup position is manually clamped before calling `popup()`: calculate popup minimum size, clamp the mouse position so the popup fits within viewport bounds
- Fix applies to both InventoryUI's popup and HudStrip's popup — consistent behaviour across all context menus
- Algorithm: `var pos = get_viewport().get_mouse_position(); var vp = get_viewport().get_visible_rect().size; pos.x = clampf(pos.x, 0, vp.x - popup_min_width); pos.y = clampf(pos.y, 0, vp.y - popup_min_height)` then `popup(Rect2i(pos, Vector2i.ZERO))`

### Claude's Discretion
- Whether viewport clamping helper is a static function in a shared autoload/utility or duplicated inline in both InventoryUI and HudStrip
- Exact PopupMenu min-size estimation approach (get_contents_minimum_size() or a fixed constant like 120x60)
- Node type for HudStrip PopupMenu (regular PopupMenu child is sufficient)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CTXMENU-03 | Right-clicking an equipment slot shows "Unequip" and "Drop" | Fully supported: PopupMenu pattern in inventory_ui.gd is directly replicable in hud_strip.gd; slot Panel nodes support `_gui_input` for right-click detection; EquipmentData.unequip_weapon/tool() already exist |
</phase_requirements>

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot PopupMenu | Built-in (4.2+) | Context menu UI | Godot's native popup with auto-hide, keyboard nav, id_pressed signal |
| GDScript | 4.x | Implementation language | Project standard |
| GUT | 9.3.0 | Unit testing | Already installed; `make test` is the test runner |
| gdtoolkit | 4.* | Lint + format | `make lint`, `make format-check` — required before every commit |

No new packages. No installation step.

### Architecture: Existing Patterns Already Verified

| Pattern | Location | Phase 8 Reuse |
|---------|----------|---------------|
| PopupMenu child node | `inventory_ui.tscn` → `$PopupMenu` | Add identical child to `hud_strip.tscn` |
| Named const IDs | `MENU_EQUIP=0`, `MENU_CONSUME=1`, `MENU_DROP=2` in inventory_ui.gd | HudStrip: `MENU_UNEQUIP=0`, `MENU_DROP=1` |
| id_pressed signal | `_popup_menu.id_pressed.connect(_on_context_menu_id_pressed)` | Same connection in hud_strip.gd |
| Injection pattern | `set_inventory()`, `set_equipment_data()`, `set_player()` in world.gd `_ready()` | Add `hud_strip.set_player(player)` |
| Drop collectable | `_drop_selected()` in inventory_ui.gd | Replicate in `_do_drop_equipped(slot_type)` in hud_strip.gd |
| Unequip safe no-op | `_do_unequip_weapon/tool()` — insert first, unequip only if remaining==0 | HudStrip "Unequip" follows same contract |

---

## Architecture Patterns

### Recommended Project Structure (no changes to directory layout)

Phase 8 touches exactly four files:

```
scripts/
├── hud_strip.gd          # ADD: _player, set_player(), PopupMenu logic, drop logic
├── inventory_ui.gd       # FIX: viewport clamping on existing popup() call
└── world.gd              # ADD: hud_strip.set_player(player) in _ready()
scenes/
└── hud_strip.tscn        # ADD: PopupMenu child node
tests/unit/
└── test_hud_strip_context_menu.gd   # NEW: unit tests for HUD popup
```

### Pattern 1: HudStrip PopupMenu — Mirror of InventoryUI

**What:** Add a PopupMenu child to HudStrip. Wire right-click on WeaponSlot and ToolSlot
panels. Track which slot was right-clicked with `_pending_slot_type` (enum or StringName).
Use `MENU_UNEQUIP=0`, `MENU_DROP=1` const IDs. Connect `id_pressed`.

**When to use:** Whenever a HUD slot is right-clicked and the slot is occupied.

**Example — signal wiring in hud_strip.gd _ready():**
```gdscript
# Source: inventory_ui.gd _ready() pattern (adapted)
_popup_menu.id_pressed.connect(_on_hud_popup_id_pressed)
_weapon_slot.gui_input.connect(_on_weapon_slot_gui_input)
_tool_slot.gui_input.connect(_on_tool_slot_gui_input)
```

**Note:** The slot Panels in hud_strip.tscn currently have `mouse_filter = 2`
(MOUSE_FILTER_IGNORE). This MUST be changed to `mouse_filter = 0`
(MOUSE_FILTER_STOP) on WeaponSlot and ToolSlot panels, or right-click events
will not reach those nodes. This is a critical scene property change.

### Pattern 2: Viewport-Safe Popup Positioning

**What:** Before calling `popup()`, clamp the mouse position so the popup rectangle
stays within the visible viewport. Apply to both `inventory_ui.gd` and `hud_strip.gd`.

**When to use:** Every `popup()` call site in the project.

**Verified algorithm (from UI-SPEC):**
```gdscript
# Source: 08-UI-SPEC.md — Interaction Contract
var pos: Vector2 = get_viewport().get_mouse_position()
var vp: Vector2 = get_viewport().get_visible_rect().size
var popup_min := _popup_menu.get_contents_minimum_size()
if popup_min == Vector2.ZERO:
    popup_min = Vector2(120.0, 60.0)
pos.x = clampf(pos.x, 0.0, vp.x - popup_min.x)
pos.y = clampf(pos.y, 0.0, vp.y - popup_min.y)
_popup_menu.popup(Rect2i(pos, Vector2i.ZERO))
```

**Discretionary note:** `get_contents_minimum_size()` returns `Vector2.ZERO` before
the popup has been shown once (Godot does not compute layout until the first render).
The fallback constant `Vector2(120.0, 60.0)` is the safe floor. Either extract this
as a static helper (e.g., in a new `UIHelpers` autoload or a static method on
`InventoryUIHelpers`) or duplicate it inline at both sites. Two sites is a trivially
low duplication cost; inline is simpler for this phase.

### Pattern 3: Drop From HUD Slot (bypass-bag drop)

**What:** Unequip the item from EquipmentData, then spawn a Collectable at a random
offset from the player position — exactly as `_drop_selected()` does for bag items.
The bag is not involved.

**Exact reference:**
```gdscript
# Source: scripts/inventory_ui.gd _drop_selected()
var node: Collectable = COLLECTABLE_SCENE.instantiate()
node.item = item_ref
get_tree().current_scene.add_child(node)
var angle := randf() * TAU
var dist := randf_range(16.0, 32.0)
node.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
```

HudStrip drop variant calls `_equipment_data.unequip_weapon()` / `unequip_tool()`
first (which returns the item), then uses the pattern above.

### Pattern 4: Pending Slot Tracking in HudStrip

**What:** Track which slot type was right-clicked so the `id_pressed` handler knows
whether to act on weapon or tool slot.

**Approach:** Use an enum or a string constant. Recommend an enum for clarity:
```gdscript
enum SlotType { NONE, WEAPON, TOOL }
var _pending_slot_type: SlotType = SlotType.NONE
```

Reset to `SlotType.NONE` at end of `_on_hud_popup_id_pressed()` (mirrors
`_pending_context_index = -1` in InventoryUI).

### Anti-Patterns to Avoid

- **Sharing the InventoryUI PopupMenu with HudStrip:** Popup ownership must be
  separate — each control owns its own PopupMenu child. The InventoryUI popup
  should only appear when InventoryUI is visible; the HudStrip popup must work
  regardless of InventoryUI visibility.
- **Leaving mouse_filter=2 on HUD slot Panels:** Panels with MOUSE_FILTER_IGNORE
  will silently swallow no events — right-click handlers on them will never fire.
- **Calling unequip_weapon() before checking for null:** `_equipment_data.weapon`
  can be null if the slot is empty; guard with `if _equipment_data.weapon == null: return`.
- **Attempting to insert into bag on Drop:** Drop bypasses the bag. Do not call
  `_inventory.insert()` in the Drop path.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Context menu UI | Custom Panel with buttons | Godot `PopupMenu` | Auto-hide on outside click, keyboard nav, `id_pressed` signal — all free |
| Min-size estimation | Manual pixel counting | `get_contents_minimum_size()` with fallback | Godot computes this from item count and font metrics |
| Collectable spawning | Custom drop system | `_drop_selected()` pattern from inventory_ui.gd | Already handles scene ownership, random offset, item reference |
| Unequip logic | New unequip function | `EquipmentData.unequip_weapon()` / `unequip_tool()` | Already return the item and emit `equipment_changed` |

**Key insight:** All necessary logic already exists in the codebase. Phase 8 is
wiring + extension, not new system design.

---

## Common Pitfalls

### Pitfall 1: mouse_filter on HUD slot Panels

**What goes wrong:** Right-click events never arrive at the slot Panel's `_gui_input`
or connected `gui_input` signal. The handler is connected correctly but never fires.

**Why it happens:** `hud_strip.tscn` sets `mouse_filter = 2` (MOUSE_FILTER_IGNORE)
on all Panel nodes including WeaponSlot and ToolSlot. This was correct for Phase 7
(slots were display-only). Phase 8 needs them to receive input.

**How to avoid:** Change WeaponSlot and ToolSlot `mouse_filter` to `0`
(MOUSE_FILTER_STOP) in `hud_strip.tscn`. Leave HBoxContainer and VBoxContainer
parents at `mouse_filter = 2` to avoid intercepting world clicks.

**Warning signs:** Right-click on HUD slot does nothing; no signal fires; no errors.

### Pitfall 2: get_contents_minimum_size() returns Vector2.ZERO

**What goes wrong:** Popup appears partially off-screen on the first right-click.

**Why it happens:** Godot's PopupMenu does not calculate layout until it has been
rendered at least once. Before the first `popup()` call, `get_contents_minimum_size()`
returns `Vector2.ZERO`, making the clamping a no-op.

**How to avoid:** Apply the fallback: `if popup_min == Vector2.ZERO: popup_min = Vector2(120.0, 60.0)`.
This is the specified approach in the UI-SPEC.

**Warning signs:** First popup overflows; subsequent ones do not.

### Pitfall 3: Forgetting to reset _pending_slot_type

**What goes wrong:** Stale slot type causes wrong item to be dropped/unequipped on
subsequent popup interactions.

**Why it happens:** If `_pending_slot_type` is not reset to `SlotType.NONE` at the
end of `_on_hud_popup_id_pressed()`, the previous value persists.

**How to avoid:** Always reset at the end of the `id_pressed` handler, mirroring
`_pending_context_index = -1` in InventoryUI.

### Pitfall 4: InventoryUI popup still vulnerable after fix

**What goes wrong:** Developer fixes HudStrip clamping but forgets to apply the same
fix to the existing `popup()` call in `inventory_ui.gd`.

**Why it happens:** Two call sites; CONTEXT.md explicitly says both must be fixed.

**How to avoid:** The fix in `inventory_ui.gd` is `_on_slot_right_clicked()` line 153
(current code: `_popup_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))`).
Replace with the clamped algorithm.

### Pitfall 5: Unequip action on HudStrip ignoring full-bag

**What goes wrong:** Calling `_equipment_data.unequip_weapon()` directly without
first attempting bag insert causes item duplication or silent loss if bag is full.

**Why it happens:** The Drop path bypasses the bag (intentional), but the Unequip
path must attempt bag insert first. Mixing them up is an easy mistake.

**How to avoid:** Unequip handler: `inventory.insert(item, 1)` first; if `remaining > 0`,
return without calling `unequip_weapon()`. Drop handler: call `unequip_weapon()`
directly, no bag insert.

---

## Code Examples

### HudStrip _gui_input for a slot Panel

```gdscript
# Pattern to connect right-click on a Panel in hud_strip.gd _ready()
# Source: inventory_slot_ui.gd _gui_input() — adapted for direct connection
func _on_weapon_slot_gui_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.pressed):
        return
    if event.button_index == MOUSE_BUTTON_RIGHT:
        _on_hud_slot_right_clicked(SlotType.WEAPON)
        get_viewport().set_input_as_handled()
```

### HudStrip right-click handler

```gdscript
# Source: inventory_ui.gd _on_slot_right_clicked() — adapted
func _on_hud_slot_right_clicked(slot_type: SlotType) -> void:
    if _equipment_data == null:
        return
    var item = _equipment_data.weapon if slot_type == SlotType.WEAPON else _equipment_data.tool
    if item == null:
        return  # empty slot — no menu
    _pending_slot_type = slot_type
    _popup_menu.clear()
    _popup_menu.add_item("Unequip", MENU_UNEQUIP)
    _popup_menu.add_item("Drop", MENU_DROP)
    # apply viewport clamping before popup()
    var pos: Vector2 = get_viewport().get_mouse_position()
    var vp: Vector2 = get_viewport().get_visible_rect().size
    var popup_min := _popup_menu.get_contents_minimum_size()
    if popup_min == Vector2.ZERO:
        popup_min = Vector2(120.0, 60.0)
    pos.x = clampf(pos.x, 0.0, vp.x - popup_min.x)
    pos.y = clampf(pos.y, 0.0, vp.y - popup_min.y)
    _popup_menu.popup(Rect2i(pos, Vector2i.ZERO))
```

### HudStrip drop helper

```gdscript
# Source: inventory_ui.gd _drop_selected() — adapted for equipment slot
const COLLECTABLE_SCENE: PackedScene = preload("res://scenes/collectable.tscn")

func _do_drop_equipped(slot_type: SlotType) -> void:
    if _equipment_data == null or _player == null:
        return
    var item_ref: Item
    if slot_type == SlotType.WEAPON:
        item_ref = _equipment_data.unequip_weapon()
    else:
        item_ref = _equipment_data.unequip_tool()
    if item_ref == null:
        return
    var node: Collectable = COLLECTABLE_SCENE.instantiate()
    node.item = item_ref
    get_tree().current_scene.add_child(node)
    var angle := randf() * TAU
    var dist := randf_range(16.0, 32.0)
    node.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
```

### world.gd wiring addition

```gdscript
# Source: scripts/world.gd _ready() — existing pattern extended
func _ready() -> void:
    inventory_ui.set_inventory(player.inventory)
    inventory_ui.set_player(player)
    inventory_ui.set_equipment_data(player.equipment_data)
    hud_strip.set_equipment_data(player.equipment_data)
    hud_strip.set_player(player)   # NEW in Phase 8
    # ... existing signal wiring unchanged
```

### InventoryUI viewport-clamping fix (existing call site)

```gdscript
# Source: scripts/inventory_ui.gd _on_slot_right_clicked() — line 153 replacement
# BEFORE (unsafe):
# _popup_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))
# AFTER (safe):
var pos: Vector2 = get_viewport().get_mouse_position()
var vp: Vector2 = get_viewport().get_visible_rect().size
var popup_min := _popup_menu.get_contents_minimum_size()
if popup_min == Vector2.ZERO:
    popup_min = Vector2(120.0, 60.0)
pos.x = clampf(pos.x, 0.0, vp.x - popup_min.x)
pos.y = clampf(pos.y, 0.0, vp.y - popup_min.y)
_popup_menu.popup(Rect2i(pos, Vector2i.ZERO))
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `popup(Rect2i(mouse_pos, Vector2i.ZERO))` | Clamp mouse_pos before popup() | Phase 8 | Prevents popup overflow at viewport edges |
| HUD slots display-only (mouse_filter=IGNORE) | WeaponSlot and ToolSlot set to mouse_filter=STOP | Phase 8 | Enables right-click input on HUD slots |
| HudStrip has no player reference | HudStrip gets `_player` via `set_player()` | Phase 8 | Required for collectable spawn position |

---

## Open Questions

1. **mouse_filter change scope in hud_strip.tscn**
   - What we know: All Panels in hud_strip.tscn currently use `mouse_filter = 2`
   - What's unclear: Whether the parent VBoxContainer and HBoxContainer nodes also
     need adjustment, or whether changing only WeaponSlot and ToolSlot is sufficient
   - Recommendation: Change only the leaf Panel nodes (WeaponSlot, ToolSlot).
     Parent containers can remain MOUSE_FILTER_IGNORE since they do not need input.

2. **gui_input signal vs _gui_input override in HudStrip**
   - What we know: `inventory_slot_ui.gd` overrides `_gui_input` on the Panel subclass.
     HudStrip Panels are not subclassed — they are plain `Panel` type.
   - What's unclear: Whether to connect the `gui_input` signal from hud_strip.gd or
     create a small sub-scene/script for each slot.
   - Recommendation: Connect the `gui_input` signal from `hud_strip.gd` `_ready()`.
     This avoids creating extra scripts and keeps logic centralized in hud_strip.gd.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | GUT 9.3.0 |
| Config file | `addons/gut/` (installed via `make install-gut`) |
| Quick run command | `make test` |
| Full suite command | `make test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CTXMENU-03 | Right-clicking occupied weapon slot shows Unequip + Drop | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | Right-clicking occupied tool slot shows Unequip + Drop | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | Right-clicking empty HUD slot shows no menu | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | MENU_UNEQUIP=0, MENU_DROP=1 const values | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | Unequip action calls unequip_weapon/tool() on equipment_data | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | Drop action: unequip + collectable spawn (no bag insert) | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | Viewport clamping: pos.x clamped to vp.x - popup_min.x | unit | `make test` | ❌ Wave 0 |
| CTXMENU-03 | HUD popup works when inventory panel is closed | manual-only | n/a — requires game runtime | N/A |

Manual-only justification: Inventory open/closed state depends on `_input()` toggle
which requires a running Godot window; cannot be driven headlessly via GUT.

### Sampling Rate

- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/unit/test_hud_strip_context_menu.gd` — covers CTXMENU-03 unit cases above
  - Pattern: instantiate `hud_strip.tscn`, inject mock EquipmentData, call
    `_on_hud_slot_right_clicked()` directly, assert popup item count and const IDs;
    test `_do_drop_equipped()` logic with a stub collectable.
  - Reference: `test_inventory_ui_context_menu.gd` for structure/pattern.

---

## Sources

### Primary (HIGH confidence)

- `scripts/inventory_ui.gd` — complete reference for PopupMenu pattern, drop logic,
  unequip logic, existing unsafe popup() call site
- `scripts/hud_strip.gd` — current state; confirms mouse_filter=2 on all Panels,
  no _player var, no PopupMenu
- `scenes/hud_strip.tscn` — node structure confirms WeaponSlot and ToolSlot Panel
  paths and mouse_filter=2 property
- `scripts/world.gd` — confirms injection wiring pattern in _ready()
- `scripts/resources/equipment_data.gd` — confirms unequip_weapon/tool() API
- `.planning/phases/08-integration-polish/08-CONTEXT.md` — locked decisions
- `.planning/phases/08-integration-polish/08-UI-SPEC.md` — viewport clamping algorithm,
  interaction contract, component inventory

### Secondary (MEDIUM confidence)

- `scripts/inventory_slot_ui.gd` — _gui_input override pattern for Panel right-click
  (reference, not directly reused since HudStrip Panels are not subclassed)
- `tests/unit/test_inventory_ui_context_menu.gd` — test structure reference for
  new hud_strip context menu tests

### Tertiary (LOW confidence)

None. All claims are verified against source files.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; existing codebase verified
- Architecture: HIGH — all patterns sourced directly from existing scripts
- Pitfalls: HIGH — identified from direct reading of hud_strip.tscn (mouse_filter=2)
  and Godot PopupMenu known behaviour (get_contents_minimum_size() pre-show)
- Test gaps: HIGH — test files enumerated, missing file confirmed by filesystem check

**Research date:** 2026-03-25
**Valid until:** 2026-04-24 (stable domain; Godot 4 PopupMenu API does not change in patch releases)
