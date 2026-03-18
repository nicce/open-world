# Phase 5: Data Foundation - Research

**Researched:** 2026-03-18
**Domain:** GDScript Resource pattern, Godot 4 PopupMenu, gui_input signal wiring
**Confidence:** HIGH

## Summary

Phase 5 establishes two foundational building blocks for the equipment system: (1) `EquipmentData`, a new `Resource` subclass that owns the weapon and tool slots, and (2) right-click signal plumbing on bag slot UI nodes that feeds a context-aware `PopupMenu` in `InventoryUI`.

All implementation decisions are locked in CONTEXT.md. The patterns map cleanly onto what is already in the codebase: `EquipmentData` follows the `Inventory` / `Attack` resource pattern exactly, and right-click detection follows the same `_gui_input` hook that the existing `inventory_slot_ui.gd` already uses for left-click.

The unit-testing approach follows the existing GUT suite style: pure GDScript `RefCounted` stubs for node-free tests, `watch_signals` for signal assertions, inner-class fakes where a full scene is unavailable. No new test infrastructure is required.

**Primary recommendation:** Implement `EquipmentData` first (data layer, fully testable in isolation), then add right-click + PopupMenu wiring to the UI layer.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### EquipmentData Resource shape
- Two explicitly typed fields: `@export var weapon: WeaponItem` and `@export var tool: Item`
- Lives in `scripts/resources/equipment_data.gd` extending `Resource` — same pattern as `Inventory`
- Attached to Player as `@export var equipment_data: EquipmentData` — configured in Inspector, same as `inventory` and `attack`
- Methods live on the Resource: `equip_weapon(item: WeaponItem)`, `unequip_weapon() -> WeaponItem`, `equip_tool(item: Item)`, `unequip_tool() -> Item`
- Emits `signal equipment_changed()` from equip/unequip methods — HUD and player indicator (Phase 7) connect to it

#### Right-click signal payload
- Each bag slot node emits `signal slot_right_clicked(slot_index: int, item: Item)` on right-click via `gui_input`
- `InventoryUI` connects to each slot's signal in `_ready()`
- `InventoryUI` is the decision-maker: receives `(slot_index, item)`, checks `item is WeaponItem` vs `item is HealthItem`, builds `PopupMenu` with correct options
- `WeaponItem` → menu shows `Equip` + `Drop`; `HealthItem` → menu shows `Consume` + `Drop`
- Right-clicking an empty slot shows no menu

#### Context menu architecture
- `PopupMenu` is a child node of `InventoryUI` — no separate scene needed for Phase 5
- Named const IDs for menu items (not positional index): `const MENU_EQUIP = 0`, `const MENU_CONSUME = 1`, `const MENU_DROP = 2`
- Uses `id_pressed` signal (not `index_pressed`) to avoid positional shift when items are conditionally added

#### Menu dismissal
- PopupMenu dismisses when inventory panel closes — wired via `InventoryUI`'s existing visibility toggle: call `popup_menu.hide()` when inventory panel hides
- PopupMenu's own `popup_hide` signal handles self-dismissal when clicking outside (Godot default behaviour)

### Claude's Discretion
- Exact signal parameter name casing in GDScript (`slot_index` vs `index`)
- Whether `slot_right_clicked` signal is declared on a per-slot `class_name SlotUI` or inline in `inventory_ui.gd` handler
- Unit test structure for EquipmentData (inner class stubs follow existing GUT patterns)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EQUIP-05 | An item cannot exist simultaneously in the bag and an equipment slot | EquipmentData methods return the displaced item so Phase 6 handles bag removal atomically; Phase 5 establishes the Resource API that enforces this contract |
| CTXMENU-01 | Right-clicking a bag slot shows a context menu | `_gui_input` hook for MOUSE_BUTTON_RIGHT on each slot node; `slot_right_clicked` signal connected in InventoryUI._ready() |
| CTXMENU-02 | Context menu for weapon/tool items shows "Equip" + "Drop"; for consumables shows "Consume" + "Drop" | `item is WeaponItem` / `item is HealthItem` type checks; named const IDs with `id_pressed` on PopupMenu child of InventoryUI |
| CTXMENU-04 | Context menu dismisses when inventory panel is closed | `popup_menu.hide()` called in InventoryUI visibility toggle; Godot default `popup_hide` signal for click-outside |
</phase_requirements>

---

## Standard Stack

### Core
| Library / API | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| GDScript `Resource` subclass | Godot 4.2+ | Data container with `@export` fields, signals | Established project pattern — `Inventory`, `Attack`, `Item` all follow this shape |
| Godot `PopupMenu` | Godot 4.2+ | In-tree context menu node | Built-in; handles click-outside dismissal automatically via `popup_hide` signal |
| `_gui_input` / `InputEventMouseButton` | Godot 4.2+ | Per-node input capture without consuming global input | Already used in `inventory_slot_ui.gd` for left-click detection |
| GUT test framework | 4.x (project standard) | Unit testing | Existing suite; `make test` runs all tests headlessly |

### Supporting
| Library / API | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| `watch_signals` / `assert_signal_emitted` | GUT built-in | Signal assertion in unit tests | Verify `equipment_changed` fires on equip/unequip |
| `id_pressed` signal on PopupMenu | Godot 4.2+ | Menu item selection by stable ID | Always — avoids positional index bugs when items are conditionally added |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `id_pressed` | `index_pressed` | `index_pressed` is positionally unstable when items are added conditionally; `id_pressed` with named consts is robust |
| PopupMenu child of InventoryUI | Separate PopupMenu scene | Separate scene adds boilerplate for no benefit at this scope |
| `slot_right_clicked` signal on slot node | Direct node lookup in InventoryUI | Signal approach decouples slot and parent — matches project signal-first convention |

**Installation:** No new packages. All APIs are Godot built-ins or already present in the project.

---

## Architecture Patterns

### Recommended Project Structure

```
scripts/
  resources/
    equipment_data.gd        # NEW — EquipmentData Resource
  inventory_slot_ui.gd       # MODIFIED — add slot_right_clicked signal + right-click detection
  inventory_ui.gd            # MODIFIED — connect right-click, build PopupMenu, wire hide
scenes/
  player.tscn                # MODIFIED — add equipment_data @export field
tests/
  unit/
    test_equipment_data.gd   # NEW — unit tests for EquipmentData methods
```

### Pattern 1: Resource with typed fields and signals (EquipmentData)

**What:** A `Resource` subclass holds typed nullable fields for each equipment slot. Methods mutate the fields and emit `equipment_changed`. This is the same shape as `Inventory` (signal-on-mutation) and `Attack` (@export typed field).

**When to use:** Any time a collection of game data needs lifecycle methods and change notifications without being a scene node.

**Example:**
```gdscript
# scripts/resources/equipment_data.gd
# Source: mirrors scripts/resources/inventory.gd pattern
class_name EquipmentData extends Resource

signal equipment_changed

@export var weapon: WeaponItem
@export var tool: Item


func equip_weapon(item: WeaponItem) -> WeaponItem:
    var previous := weapon
    weapon = item
    equipment_changed.emit()
    return previous  # null if slot was empty; Phase 6 inserts this back into bag


func unequip_weapon() -> WeaponItem:
    var previous := weapon
    weapon = null
    equipment_changed.emit()
    return previous


func equip_tool(item: Item) -> Item:
    var previous := tool
    tool = item
    equipment_changed.emit()
    return previous


func unequip_tool() -> Item:
    var previous := tool
    tool = null
    equipment_changed.emit()
    return previous
```

### Pattern 2: Right-click detection via `_gui_input`

**What:** The existing `inventory_slot_ui.gd` already handles `_gui_input` for left-click. Add a parallel branch for `MOUSE_BUTTON_RIGHT`.

**When to use:** Any time a UI node needs per-mouse-button awareness. `_gui_input` fires before global `_input`, making it the right hook for node-local UI interactions.

**Example:**
```gdscript
# In scripts/inventory_slot_ui.gd — add alongside existing _gui_input
signal slot_right_clicked(slot_index: int, item: Item)

# The slot node does NOT know its own index; it passes self so InventoryUI
# can call grid.get_children().find(slot_node) — same as existing slot_clicked pattern.
# OR: emit a signal that InventoryUI wires with a bound index (see Pattern 3).

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            slot_clicked.emit(self)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            right_clicked.emit(self)   # InventoryUI resolves index + item
            get_viewport().set_input_as_handled()
```

**Note on signal design (Claude's Discretion):** The slot node itself does not know its inventory index. Two valid approaches:
1. Emit `right_clicked(self)` (same as `slot_clicked`) and let InventoryUI call `grid.get_children().find(slot_node)` to resolve the index — consistent with existing pattern, zero extra coupling.
2. Declare `slot_right_clicked(slot_index: int, item: Item)` as a signal on a named `class_name SlotUI` and have InventoryUI bind index+item at connection time via `connect("right_clicked", _on_slot_right_clicked.bind(i, slot))`.

**Recommendation:** Option 1 (emit self, resolve in InventoryUI) is the path of least resistance and keeps slot_ui.gd identical in shape to the existing pattern.

### Pattern 3: PopupMenu child of InventoryUI

**What:** `PopupMenu` is added as a child node of `InventoryUI` in the scene or programmatically. On right-click, clear the menu, add items by named const ID, and call `popup()` at the mouse position.

**When to use:** Context menus that are owned by a single parent UI node.

**Example:**
```gdscript
# In scripts/inventory_ui.gd
const MENU_EQUIP = 0
const MENU_CONSUME = 1
const MENU_DROP = 2

@onready var _popup_menu: PopupMenu = $PopupMenu

func _ready() -> void:
    # ... existing slot setup ...
    _popup_menu.id_pressed.connect(_on_context_menu_id_pressed)

func _on_slot_right_clicked(slot_node: Panel) -> void:
    if _inventory == null:
        return
    var index := grid.get_children().find(slot_node)
    if index < 0 or index >= _inventory.slots.size() or _inventory.slots[index].is_empty():
        return
    var item := _inventory.slots[index].item
    _pending_context_index = index   # store for _on_context_menu_id_pressed

    _popup_menu.clear()
    if item is WeaponItem:
        _popup_menu.add_item("Equip", MENU_EQUIP)
    elif item is HealthItem:
        _popup_menu.add_item("Consume", MENU_CONSUME)
    _popup_menu.add_item("Drop", MENU_DROP)
    _popup_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))

func _on_context_menu_id_pressed(id: int) -> void:
    match id:
        MENU_EQUIP:
            pass  # Phase 6 wires this
        MENU_CONSUME:
            pass  # Phase 6 or existing _use_selected logic
        MENU_DROP:
            _selected_index = _pending_context_index
            _drop_selected()
```

### Pattern 4: Dismissal on inventory hide

**What:** When the inventory panel becomes invisible, call `_popup_menu.hide()`. The existing `_input` handler toggles `visible`; add the hide call there.

**Example:**
```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("inventory"):
        visible = !visible
        if not visible:
            _deselect()
            _popup_menu.hide()   # NEW
        return
```

### Anti-Patterns to Avoid

- **Using `index_pressed` on PopupMenu:** Positional index shifts when items are conditionally added. Always use `id_pressed` with named const IDs.
- **Storing item type in a string ("weapon", "consumable"):** Use GDScript `is` type checks (`item is WeaponItem`) — these are O(1) and the class hierarchy is already in place.
- **Emitting `equipment_changed` before setting the field:** Listeners that read `equipment.weapon` would get the stale value. Always mutate the field first, then emit.
- **Calling `popup_menu.hide()` inside `popup_hide` signal handler:** Creates a re-entrant call. `popup_hide` fires when the menu is already being hidden; just connect to it for cleanup, don't call `hide()` again.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Context menu with conditional items | Custom Panel/VBoxContainer menu | `PopupMenu` (Godot built-in) | Handles input blocking, click-outside dismiss, keyboard navigation, positioning clamp to screen bounds |
| Menu item identity | Positional integer from `index_pressed` | `id_pressed` with named const IDs | Godot's `PopupMenu.id_pressed` is purpose-built for stable ID dispatch |
| Right-click input capture | `_input()` with node position math | `_gui_input` on the slot node | `_gui_input` is scoped to the node's rect; no hit-testing needed |

**Key insight:** Godot's `PopupMenu` is the canonical solution for in-game context menus. Its `popup_hide` signal, automatic click-outside dismissal, and `id_pressed`-based dispatch eliminate an entire class of state-management bugs.

---

## Common Pitfalls

### Pitfall 1: `@export var weapon: WeaponItem` defaults to null — forgetting null guards
**What goes wrong:** `equip_weapon()` returns `previous` which is null on first equip. Phase 6 code that calls `inventory.insert(previous)` without a null check will error.
**Why it happens:** Typed `@export` Resource fields default to null in Godot 4 unless pre-populated in the Inspector.
**How to avoid:** `equip_weapon` and `unequip_weapon` must return null cleanly — document that callers must guard (`if previous != null: inventory.insert(previous)`).
**Warning signs:** `Invalid call. Nonexistent function 'insert' on base 'Nil'` at runtime.

### Pitfall 2: PopupMenu `popup()` call coordinate system
**What goes wrong:** `popup()` takes global screen coordinates. Using a node's local position produces a menu far off-screen or at the wrong position.
**Why it happens:** `get_viewport().get_mouse_position()` returns global coords; node positions are local.
**How to avoid:** Always use `get_viewport().get_mouse_position()` (Vector2) converted to Vector2i for the popup rect origin.
**Warning signs:** Menu appears at (0,0) or offset from cursor.

### Pitfall 3: Connecting slot signals after grid children are created
**What goes wrong:** Connecting `right_clicked` before `SLOT_SCENE.instantiate()` adds the child means no signal fires.
**Why it happens:** Signal connections must happen after `add_child()` and before user interaction.
**How to avoid:** Connect inside the `for i in range(SLOT_COUNT)` loop in `_ready()`, immediately after `grid.add_child(slot)` — exactly as `slot_clicked` is currently connected.
**Warning signs:** Right-click produces no popup; no errors (silent miss).

### Pitfall 4: `PopupMenu.clear()` not called before rebuilding
**What goes wrong:** Items from a previous right-click accumulate; the menu shows stale entries.
**Why it happens:** `add_item()` appends; `PopupMenu` does not auto-clear between calls.
**How to avoid:** Call `_popup_menu.clear()` at the top of every `_on_slot_right_clicked` handler before adding items.
**Warning signs:** Menu shows duplicate or wrong entries on second right-click.

### Pitfall 5: EquipmentData `equipment_changed` signal not connected at game start
**What goes wrong:** HUD/indicator in Phase 7 never updates because no listener connected to the signal.
**Why it happens:** Unlike `Inventory` (connected in `InventoryUI.set_inventory()`), `EquipmentData` needs an explicit connection point. Phase 5 defines the signal; Phase 7 wires it.
**How to avoid:** Phase 5 only needs to define and emit the signal correctly — Phase 7 is responsible for connecting consumers. No action needed in Phase 5 beyond emit.
**Warning signs:** N/A for Phase 5; relevant for Phase 7.

---

## Code Examples

Verified patterns from existing project source:

### Existing `_gui_input` left-click pattern (inventory_slot_ui.gd line 29)
```gdscript
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        slot_clicked.emit(self)
        get_viewport().set_input_as_handled()
```
Right-click detection follows this identically — change `MOUSE_BUTTON_LEFT` to `MOUSE_BUTTON_RIGHT`.

### Existing signal connection in InventoryUI._ready() (inventory_ui.gd line 22)
```gdscript
for i in range(SLOT_COUNT):
    var slot := SLOT_SCENE.instantiate()
    grid.add_child(slot)
    slot.slot_clicked.connect(_on_slot_clicked)
```
Add `slot.right_clicked.connect(_on_slot_right_clicked)` in the same loop.

### Existing Resource pattern (inventory.gd line 1)
```gdscript
class_name Inventory extends Resource

signal inventory_changed
signal insert_rejected

@export var slots: Array[InventorySlot] = []
```
`EquipmentData` follows this exactly: `class_name EquipmentData extends Resource`, `signal equipment_changed`, typed `@export` fields.

### Existing type-check idiom (inventory_ui.gd line 81)
```gdscript
if not slot.item is HealthItem:
    return
```
Context menu branch uses `item is WeaponItem` and `item is HealthItem` — same GDScript `is` pattern.

### GUT signal assertion pattern (test_inventory.gd line 287)
```gdscript
watch_signals(inv)
inv.insert(wood, 1)
assert_signal_emitted(inv, "inventory_changed")
assert_signal_emit_count(inv, "inventory_changed", 1)
```
`test_equipment_data.gd` uses `watch_signals(ed)` then `assert_signal_emitted(ed, "equipment_changed")` for each equip/unequip call.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `index_pressed` on PopupMenu | `id_pressed` with const IDs | Godot 4.0 | Menu item identity is stable regardless of conditional item insertion |
| `_input()` global handler for UI clicks | `_gui_input()` per-node | Godot 4.0 | No hit-testing; input is automatically scoped to node rect |

---

## Open Questions

1. **`slot_right_clicked` signal declaration location**
   - What we know: Locked decision is that `InventoryUI` handles context logic. The slot node needs to emit something on right-click.
   - What's unclear: Whether signal is declared on the slot class with `(slot_node: Panel)` payload (consistent with existing `slot_clicked`), or with `(slot_index: int, item: Item)` (requires slot to know its own index — which it currently does not).
   - Recommendation: Declare `signal right_clicked(slot_node: Panel)` on the slot (matching `slot_clicked` shape exactly). InventoryUI resolves index and item via `grid.get_children().find(slot_node)` — identical to existing `_on_slot_clicked` logic. This is pure convention, no research blocker.

2. **Godot version mismatch in Makefile (known from STATE.md)**
   - What we know: Makefile targets Godot 4.2.2 headless; project declares 4.3. This is a pre-existing concern logged in STATE.md.
   - What's unclear: Whether Phase 5 GDScript patterns differ between 4.2.2 and 4.3.
   - Recommendation: All APIs used in this phase (`Resource`, `PopupMenu`, `_gui_input`, `id_pressed`) are stable and unchanged between 4.2 and 4.3. No Phase 5 blocker; the version mismatch remains a CI concern for a future fix.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 4.x |
| Config file | `tests/.gutconfig.json` (project standard) |
| Quick run command | `make test` |
| Full suite command | `make test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EQUIP-05 | Item absent from all bag slots after equip returns | unit | `make test` (test_equipment_data.gd) | Wave 0 |
| EQUIP-05 | `equip_weapon` returns displaced weapon (not null) when slot occupied | unit | `make test` (test_equipment_data.gd) | Wave 0 |
| EQUIP-05 | `equip_weapon` returns null when slot was empty | unit | `make test` (test_equipment_data.gd) | Wave 0 |
| EQUIP-05 | `unequip_weapon` returns the weapon and sets field to null | unit | `make test` (test_equipment_data.gd) | Wave 0 |
| CTXMENU-01 | Right-clicking non-empty bag slot emits right-click signal | unit (signal) | `make test` (test_equipment_data.gd or test_inventory_ui.gd) | Wave 0 |
| CTXMENU-01 | Right-clicking empty slot emits no popup (no menu built) | unit | `make test` | Wave 0 |
| CTXMENU-02 | WeaponItem slot → menu contains MENU_EQUIP and MENU_DROP IDs | unit | `make test` | Wave 0 |
| CTXMENU-02 | HealthItem slot → menu contains MENU_CONSUME and MENU_DROP IDs | unit | `make test` | Wave 0 |
| CTXMENU-04 | Hiding inventory panel hides popup (signal/state check) | unit or manual | `make test` | Wave 0 |

**Note:** CTXMENU-01/02/04 context menu construction is UI-node-dependent. Pure logic (item type → menu IDs) can be extracted into a helper function and unit tested. The `PopupMenu` node interaction itself requires a scene tree and is validated manually or via GUT scene-loaded test.

### Sampling Rate
- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/unit/test_equipment_data.gd` — covers EQUIP-05 (equip/unequip method contracts, signal emission, return values)
- [ ] `tests/unit/test_context_menu_builder.gd` (optional) — covers CTXMENU-02 item-type-to-menu-options logic if extracted to a pure function

*(Existing `tests/unit/` infrastructure covers all other needs — no new fixtures or framework install required.)*

---

## Sources

### Primary (HIGH confidence)
- Direct read of `scripts/resources/inventory.gd` — Resource + signal pattern confirmed
- Direct read of `scripts/inventory_slot_ui.gd` — `_gui_input` + `MOUSE_BUTTON_LEFT` pattern confirmed
- Direct read of `scripts/inventory_ui.gd` — slot connection loop, `_on_slot_clicked`, visibility toggle confirmed
- Direct read of `scripts/player.gd` — `@export var attack: Attack` pattern confirmed for EquipmentData attachment
- Direct read of `tests/unit/test_inventory.gd` — GUT `watch_signals` / `assert_signal_emitted` pattern confirmed
- Direct read of `.planning/phases/05-data-foundation/05-CONTEXT.md` — all locked decisions

### Secondary (MEDIUM confidence)
- Godot 4 `PopupMenu` `id_pressed` vs `index_pressed` behaviour: confirmed by CONTEXT.md locked decision (based on prior planning research)
- `popup()` coordinate system: standard Godot 4 API — `get_viewport().get_mouse_position()` for screen-space popup placement

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs read directly from project source; no external dependencies
- Architecture: HIGH — patterns traced directly to existing working code in the repo
- Pitfalls: HIGH — identified from direct code analysis; null-return and coordinate pitfalls are Godot 4 fundamentals
- Test structure: HIGH — mirrors existing GUT test files in the project

**Research date:** 2026-03-18
**Valid until:** 2026-04-18 (stable Godot 4 APIs; project patterns unlikely to change)
