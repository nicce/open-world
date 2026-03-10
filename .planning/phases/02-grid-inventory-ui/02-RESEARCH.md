# Phase 2: Grid Inventory UI - Research

**Researched:** 2026-03-10
**Domain:** Godot 4 UI systems — Control nodes, GridContainer, CanvasLayer, Tween, signals for live data binding
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Slot grid configuration**
- Fixed 15 slots (5 columns × 3 rows) — matches existing GridContainer columns=5 layout
- Slots are instantiated at runtime from a script constant (SLOT_COUNT = 15), not hardcoded in the .tscn
- Inventory resource must be configured with exactly 15 InventorySlot entries

**Equipment slots**
- Phase 2 does nothing with equipment slots — Phase 3+ adds a separate always-visible HUD element (Minecraft-style, outside the inventory panel)
- No placeholder in Phase 2 inventory panel

**Slot appearance**
- Occupied slot: item abbreviation label (short, readable — e.g., "Med", "Axe", "Key") centered in slot + quantity label in bottom-right corner
- When item.texture is assigned, the icon replaces the abbreviation label
- Empty slots: slot background shown at reduced opacity (semi-transparent/dimmed) — visually distinct from occupied slots
- No hover highlight or selection interaction in Phase 2 — slots are display-only (interaction is Phase 3)

**Weight display**
- Text label only: "X.X / Y kg" format (e.g., "12.5 / 20 kg")
- Positioned at the bottom of the inventory panel, below the slot grid
- Updates in real-time via signal when inventory contents change (not just on panel open)

**Rejection feedback**
- Displayed as a HUD notification (CanvasLayer or screen-level label), always visible regardless of inventory state — player can attempt pickup while inventory is closed
- Message: "Too heavy!"
- Auto-fades after ~2 seconds (use a Timer; tween for fade is Claude's discretion)

### Claude's Discretion
- Exact font sizes, colors, and spacing for slot labels
- Tween/animation for rejection label fade
- Whether weight label changes color when near/at limit (low priority polish)
- How item abbreviation length is determined (e.g., first 3-5 chars, or trim to fit slot)

### Deferred Ideas (OUT OF SCOPE)
- Equipment slots (weapon/armor) as separate always-visible HUD element — future phase (Phase 3+)
- Hover tooltips showing full item name — future phase when interaction is added
- Weight label color change feedback — low priority, deferred if time constrained
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INV-01 | Player can open inventory and see a fixed grid of item slots with icons and quantities | InventorySlotUI scene extended with TextureRect (icon) + two Labels (abbrev, quantity); GridContainer with SLOT_COUNT=15 filled at runtime |
| INV-02 | Inventory panel shows current weight vs max capacity; player sees a rejection message when inventory is full or overweight | Weight Label on InventoryUI reads `inventory.current_weight()` / `inventory.max_weight`; rejection flow requires `Inventory.insert()` return value check + HUD label on CanvasLayer |
| INV-03 | Stackable resource items stack up to their max_stack limit instead of occupying multiple slots | Already implemented in `Inventory.insert()` / `InventorySlot.can_stack()` — Phase 2 only needs to display the resulting quantity correctly |
</phase_requirements>

---

## Summary

Phase 2 replaces the stub `inventory_ui.gd` (~20 lines) with a fully functional grid UI that reads from the live `Inventory` resource. The data layer (`Inventory`, `InventorySlot`, `Item`) is complete from Phase 1 and needs no changes for this phase. The UI work is entirely in Godot 4 Control nodes and GDScript signals.

The primary design challenge is the signal plumbing: the `Inventory` resource currently emits no signals when it changes, so a `changed` signal (or equivalent) must be added to `Inventory` and emitted after every `insert()` / `remove()` call. `InventoryUI` connects to this signal to redraw slots and update the weight label without polling in `_process()`.

The rejection feedback ("Too heavy!") lives on a `CanvasLayer` node so it is visible even when the inventory panel is closed. The `Collectable` / `Player.collect()` path already returns a boolean indicating failure; that return value is the trigger for the rejection display.

**Primary recommendation:** Add `signal inventory_changed` to `Inventory`, emit it in `insert()` and `remove()`, wire `InventoryUI` and the HUD rejection label to it, and build the slot visuals as a simple runtime-instantiated loop over `SLOT_COUNT = 15`.

---

## Standard Stack

### Core

| Library / Node | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| `Control` (Godot built-in) | Godot 4.2+ | Root UI node for InventoryUI and slot panels | Standard UI base class in Godot 4 |
| `GridContainer` (Godot built-in) | Godot 4.2+ | Automatic grid layout for slots | Already present in `inventory_ui.tscn` with columns=5 |
| `NinePatchRect` (Godot built-in) | Godot 4.2+ | Stretchable panel background | Already in `inventory_ui.tscn` using `InventoryRect.png` |
| `CanvasLayer` (Godot built-in) | Godot 4.2+ | HUD overlay that renders above game world | Already in `world.tscn`; `InventoryUI` is already its child |
| `Label` (Godot built-in) | Godot 4.2+ | Abbreviation text, quantity counter, weight display | Lightest text node; no rich text needed |
| `TextureRect` (Godot built-in) | Godot 4.2+ | Item icon display | Preferred over Sprite2D inside Control trees |
| `Timer` (Godot built-in) | Godot 4.2+ | Auto-fade countdown for rejection label | Standard one-shot timer pattern |
| `Tween` (Godot built-in) | Godot 4.2+ | Fade animation for rejection label modulate.a | `create_tween()` is the Godot 4 preferred API |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `gdtoolkit` | 4.* | Lint + format check | Every commit — already project standard |
| GUT | current | Unit tests for pure-logic functions (abbreviation, weight format) | New helper functions in `inventory_ui.gd` or extracted utility |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `TextureRect` for icon | `Sprite2D` | `Sprite2D` is already used in `inventory_slot_ui.tscn` for the slot background, but `TextureRect` respects Control layout and stretching — better fit inside a `Panel` |
| Runtime slot instantiation | Hardcoding 15 slots in .tscn | .tscn already has 15 hardcoded instances; decision is to switch to runtime instantiation — keeps SLOT_COUNT as single source of truth |
| Signal on `Inventory` resource | Polling in `_process()` | Polling violates project convention; signal is the correct Godot 4 / project pattern |

**Installation:** No new packages. All nodes are Godot built-ins.

---

## Architecture Patterns

### Recommended Project Structure

No new directories needed. Files touched:

```
scripts/
├── resources/
│   └── inventory.gd          # ADD: signal inventory_changed; emit in insert()/remove()
├── inventory_ui.gd            # REWRITE: full slot grid, weight label, signal listener
└── inventory_slot_ui.gd       # NEW: script for per-slot display logic
scenes/
├── inventory_slot_ui.tscn     # MODIFY: add TextureRect + 2 Labels
├── inventory_ui.tscn          # MODIFY: remove hardcoded slot instances; add WeightLabel
└── world.tscn                 # MODIFY: add HUD rejection label node; wire signals
tests/unit/
└── test_inventory_ui_helpers.gd  # NEW: tests for abbreviation logic and weight format
```

### Pattern 1: Signal-Driven UI Redraw

**What:** `Inventory` resource emits `inventory_changed` whenever slots mutate; `InventoryUI` listens and calls `_refresh_slots()`.

**When to use:** Any time data can change without UI initiation (pickup happens without opening inventory).

```gdscript
# In inventory.gd
signal inventory_changed

func insert(item: Item, amount: int = 1) -> int:
    # ... existing logic ...
    inventory_changed.emit()
    return remaining

func remove(item: Item, amount: int = 1) -> int:
    # ... existing logic ...
    inventory_changed.emit()
    return amount - remaining
```

```gdscript
# In inventory_ui.gd
@export var inventory: Inventory

func _ready() -> void:
    inventory.inventory_changed.connect(_refresh_slots)
    inventory.inventory_changed.connect(_refresh_weight_label)
    _refresh_slots()
    _refresh_weight_label()
```

### Pattern 2: Runtime Slot Instantiation

**What:** `InventoryUI` instantiates exactly `SLOT_COUNT` slot scenes in `_ready()`, removing any pre-existing children of the grid first.

**When to use:** Fixed-size grids where the count is a code constant, not data-driven.

```gdscript
# In inventory_ui.gd
const SLOT_COUNT: int = 15
const SLOT_SCENE: PackedScene = preload("res://scenes/inventory_slot_ui.tscn")

@onready var grid: GridContainer = $NinePatchRect/GridContainer

func _ready() -> void:
    # Clear any editor-placed slot instances
    for child in grid.get_children():
        child.queue_free()
    # Instantiate fresh slots
    for i in range(SLOT_COUNT):
        var slot_node = SLOT_SCENE.instantiate()
        grid.add_child(slot_node)
    # Wire inventory
    inventory.inventory_changed.connect(_refresh_slots)
    inventory.inventory_changed.connect(_refresh_weight_label)
    _refresh_slots()
    _refresh_weight_label()
```

### Pattern 3: Per-Slot Display Update

**What:** Each `InventorySlotUI` node has a script with `update(slot: InventorySlot)` that sets its own icon/label state. `InventoryUI` iterates slots and calls `update()` on each child node.

**When to use:** Keeps display logic encapsulated in the slot scene; `InventoryUI` only orchestrates.

```gdscript
# In inventory_slot_ui.gd
@onready var icon_rect: TextureRect = $TextureRect
@onready var abbrev_label: Label = $AbbrevLabel
@onready var quantity_label: Label = $QuantityLabel

func update(slot: InventorySlot) -> void:
    if slot.is_empty():
        icon_rect.texture = null
        abbrev_label.text = ""
        quantity_label.text = ""
        modulate.a = 0.4  # dimmed empty slot
    else:
        modulate.a = 1.0
        if slot.item.texture != null:
            icon_rect.texture = slot.item.texture
            abbrev_label.text = ""
        else:
            icon_rect.texture = null
            abbrev_label.text = _abbreviate(slot.item.name)
        quantity_label.text = str(slot.quantity)

func _abbreviate(item_name: String) -> String:
    return item_name.left(4)  # "Medi" → "Med" via left(3) or left(4) — Claude's discretion
```

### Pattern 4: HUD Rejection Label

**What:** A `Label` (or `CanvasLayer` > `Label`) node in `world.tscn` is made visible with "Too heavy!", then auto-hidden via `Timer` and faded via `Tween`.

**When to use:** Feedback that must appear regardless of whether the inventory panel is open.

**Key constraint:** The rejection signal must originate from the `Collectable` / `Player.collect()` path. `Player.collect()` already returns `false` when `inventory.insert()` returns non-zero. The `Collectable` scene can emit a signal or call a method on the HUD when `collect()` returns false. Alternatively, `Inventory` can emit a dedicated `insert_rejected` signal.

The cleanest approach (no tight coupling): add `signal insert_rejected` to `Inventory`, emitted when `insert()` returns with `remaining > 0` and `weight_budget <= 0` (i.e., weight-blocked). Then any listener (HUD label, future UI) can respond.

```gdscript
# Rejection label node (child of CanvasLayer in world.tscn)
@onready var timer: Timer = $Timer
@onready var label: Label = $Label   # "Too heavy!"

func show_rejection() -> void:
    label.modulate.a = 1.0
    label.visible = true
    timer.start(2.0)

func _on_timer_timeout() -> void:
    var tw = create_tween()
    tw.tween_property(label, "modulate:a", 0.0, 0.4)
    await tw.finished
    label.visible = false
```

### Pattern 5: Inventory Reference Wiring

**What:** `InventoryUI` receives the player's `Inventory` reference. Currently `world.tscn` has no wiring between `InventoryUI` and `Player`. Phase 2 must add this.

**Options (in order of preference):**
1. Wire from `world.gd`: in `_ready()`, get the `Player` node and assign `$CanvasLayer/InventoryUI.inventory = $Player.inventory`.
2. Use `@export var inventory: Inventory` on `InventoryUI` and assign the `.tres` resource directly in the Inspector — but this bypasses `clone()` on the Player's inventory and would reference the un-cloned asset resource. **Do not use this approach.**
3. Use `@export var player_path: NodePath` — unnecessarily indirect.

**Correct approach:** Option 1. `world.gd` connects the cloned inventory after `Player._ready()` runs (which calls `clone()`). Since `InventoryUI` is a sibling in the same scene, `world.gd` is the natural wiring point.

```gdscript
# In world.gd
@onready var player: Player = $Player
@onready var inventory_ui: Control = $CanvasLayer/InventoryUI

func _ready() -> void:
    inventory_ui.set_inventory(player.inventory)
```

### Anti-Patterns to Avoid

- **Polling in `_process()`:** Never check `inventory.current_weight()` per frame. Connect to `inventory_changed` signal instead.
- **Hardcoding slot scenes in .tscn:** The decision is runtime instantiation from `SLOT_COUNT`. Do not rely on the existing 15 hardcoded instances — remove them and regenerate at runtime.
- **Directly assigning the `.tres` asset as the InventoryUI inventory:** The player deep-copies the inventory via `clone()` in `_ready()`. The UI must reference `player.inventory` (the clone), not the raw resource file, or mutations during play will persist to disk.
- **Placing rejection label inside InventoryUI:** The panel is hidden when inventory is closed. Rejection can happen without opening the panel. The label must be a sibling or ancestor of `InventoryUI` in the `CanvasLayer`.
- **Using `Sprite2D` for item icons inside Control trees:** `TextureRect` respects UI layout sizing. `Sprite2D` ignores it and will overlap or misposition.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Grid layout math | Custom slot positioning code | `GridContainer` with `columns=5` | Already in scene; handles wrapping automatically |
| Fade animation | Manual `modulate.a` decrement in `_process()` | `create_tween().tween_property(node, "modulate:a", 0.0, 0.4)` | Godot 4 Tween API handles interpolation, cleanup, completion callbacks |
| One-shot auto-hide timer | Custom countdown in `_process()` | `Timer` node with `one_shot=true` | Built-in; no extra state management |
| Weight formatting | Custom float-to-string formatter | `"%.1f / %.0f kg" % [current, max]` | GDScript `%` string formatting handles float precision |
| Stacking logic | Any stacking in UI code | `Inventory.insert()` already handles it | Data layer is complete; UI only reads `slot.quantity` |

**Key insight:** The entire stacking requirement (INV-03) is already implemented in the data layer from Phase 1. Phase 2 only needs to read `slot.quantity` and display it. There is nothing to implement for stacking itself.

---

## Common Pitfalls

### Pitfall 1: Inventory Reference Points to Asset, Not Runtime Clone

**What goes wrong:** `InventoryUI` is given the `.tres` resource path directly. Changes during play are reflected in the `.tres` file. On next scene load, the inventory starts in a dirty state.

**Why it happens:** The `@export var inventory: Inventory` on `InventoryUI` is easy to populate via Inspector by dragging the `.tres`. This bypasses the `clone()` call in `Player._ready()`.

**How to avoid:** Always pass `player.inventory` (the runtime clone) from `world.gd` via code, not the Inspector asset reference.

**Warning signs:** Items persist across scene reloads; inventory is non-empty at game start.

### Pitfall 2: Signal Connected Before Inventory Is Assigned

**What goes wrong:** `InventoryUI._ready()` calls `inventory.inventory_changed.connect(...)` but `inventory` is null because `world.gd` has not yet called `set_inventory()`.

**Why it happens:** `_ready()` fires on scene tree entry. If `InventoryUI` enters the tree before `world.gd` assigns the inventory, the connection fails with a null reference.

**How to avoid:** Use a `set_inventory(inv: Inventory)` setter method on `InventoryUI` that handles both connection and initial refresh. `world.gd` calls it in its own `_ready()` after all children are ready.

**Warning signs:** `Cannot call method 'connect' on a null instance` error on game start.

### Pitfall 3: Rejection Label Inside InventoryUI Panel

**What goes wrong:** The rejection label is placed as a child of `InventoryUI`. When the inventory panel is hidden (`visible = false`), the label is also hidden. The player picks up an item with a full inventory while the panel is closed — no feedback appears.

**Why it happens:** Natural placement instinct is to put all inventory feedback inside the inventory panel.

**How to avoid:** The rejection label must be a direct child of the `CanvasLayer` in `world.tscn`, independent of `InventoryUI.visible`. The locked decision specifies "HUD notification... always visible regardless of inventory state."

**Warning signs:** Rejection message only appears when the inventory panel is open.

### Pitfall 4: Queue-Freeing Old Slots Creates Frame-Delay Gap

**What goes wrong:** In `_ready()`, calling `queue_free()` on existing slot children from the .tscn and immediately instantiating new ones causes a one-frame gap where `grid.get_children()` returns the new nodes mixed with nodes pending deletion.

**Why it happens:** `queue_free()` defers deletion to end of frame; child count is temporarily inflated.

**How to avoid:** After `queue_free()` on all old children, add the new instances. The old children will be freed at end-of-frame before any UI updates occur. Alternatively, verify by iterating `grid.get_child_count()` only after `_ready()` completes. In practice this is not a functional bug — just avoid reading `get_children()` immediately after the free loop in the same frame.

### Pitfall 5: `inventory_changed` Emitted on Every Insert Even When Nothing Changed

**What goes wrong:** `Inventory.insert()` emits `inventory_changed` even when `remaining == amount` (nothing was inserted — inventory was full). This causes the weight label to refresh needlessly but more importantly causes the rejection label to *not* trigger (because rejection is a separate signal path).

**Why it happens:** Emitting unconditionally is simpler but loses the semantic distinction between "something changed" and "insertion was blocked."

**How to avoid:** Emit `inventory_changed` only when `remaining < amount` (at least one item was inserted). Emit a separate signal (e.g., `insert_rejected`) when `remaining > 0` and `to_add <= 0` (weight-blocked with no items added). The test suite already covers the insert-blocked path.

---

## Code Examples

Verified patterns from official Godot 4 sources and project conventions:

### Weight Label Formatting

```gdscript
# GDScript string formatting — no external library needed
func _refresh_weight_label() -> void:
    var current := inventory.current_weight()
    var max_w := inventory.max_weight
    weight_label.text = "%.1f / %.0f kg" % [current, max_w]
```

### Tween Fade (Godot 4 API)

```gdscript
# create_tween() is the Godot 4 preferred API (SceneTreeTween was removed)
func _fade_out_label() -> void:
    var tw := create_tween()
    tw.tween_property(rejection_label, "modulate:a", 0.0, 0.4)
    await tw.finished
    rejection_label.visible = false
```

### Signal on Resource (Godot 4)

```gdscript
# Resources can emit signals normally in Godot 4
class_name Inventory extends Resource

signal inventory_changed
signal insert_rejected  # emitted when weight prevents any insertion

func insert(item: Item, amount: int = 1) -> int:
    var before_remaining := remaining
    # ... existing logic ...
    if remaining < amount:
        inventory_changed.emit()
    if remaining > 0 and weight_budget_was_zero:
        insert_rejected.emit()
    return remaining
```

### Abbreviation Helper (Testable Pure Function)

```gdscript
# Pure function — no node dependency — can be unit tested with GUT
static func abbreviate(item_name: String, max_len: int = 4) -> String:
    if item_name.length() <= max_len:
        return item_name
    return item_name.left(max_len)
```

### TextureRect vs Label Icon Toggle

```gdscript
func update(slot: InventorySlot) -> void:
    if slot.is_empty():
        modulate.a = 0.4
        icon_rect.visible = false
        abbrev_label.visible = false
        quantity_label.visible = false
        return

    modulate.a = 1.0
    quantity_label.visible = true
    quantity_label.text = str(slot.quantity)

    if slot.item.texture != null:
        icon_rect.texture = slot.item.texture
        icon_rect.visible = true
        abbrev_label.visible = false
    else:
        icon_rect.visible = false
        abbrev_label.text = abbreviate(slot.item.name)
        abbrev_label.visible = true
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `SceneTreeTween` (Godot 3) | `create_tween()` on Node | Godot 4.0 | Tween API is instance-based, auto-freed when node exits tree |
| `$Timer.connect("timeout", self, "method")` (Godot 3) | `$Timer.timeout.connect(_on_timer_timeout)` | Godot 4.0 | Signal connection uses callable syntax, not method name string |
| `yield(timer, "timeout")` (Godot 3) | `await timer.timeout` | Godot 4.0 | `await` replaces `yield` for coroutines |
| `Resource.emit_signal("name")` (Godot 3) | `signal_name.emit()` | Godot 4.0 | Typed signal emission; works the same on Resource subclasses |

**Deprecated/outdated:**
- `yield`: Replaced by `await` in all GDScript in this project.
- Method-string signal connection: Always use callable `.connect()` syntax per CLAUDE.md conventions.

---

## Open Questions

1. **Where does `insert_rejected` signal connect to the HUD label?**
   - What we know: `Inventory` is a Resource; `InventoryUI` (Control) and the HUD rejection label (Control) are both in `world.tscn`. `world.gd` is the natural wiring point.
   - What's unclear: Whether `world.gd` should directly connect `player.inventory.insert_rejected` to the HUD label's `show_rejection()` method, or whether `InventoryUI` owns the connection and forwards it to the HUD label.
   - Recommendation: Keep it simple — `world.gd._ready()` connects `player.inventory.insert_rejected` directly to the HUD label's method. No indirection needed.

2. **Should `Inventory` emit `inventory_changed` when nothing actually changed (e.g., full inventory partial fill)?**
   - What we know: Current `insert()` returns `remaining`; the caller can check if items were actually inserted.
   - What's unclear: Whether emitting on every call (even no-ops) causes UI flicker or test failures.
   - Recommendation: Emit `inventory_changed` only when `remaining < amount` (at least 1 item inserted). Emit `insert_rejected` when the weight budget prevents any insertion.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | GUT (Godot Unit Testing) — current project version |
| Config file | `.gutconfig.json` (or Makefile target `make test`) |
| Quick run command | `make test` |
| Full suite command | `make test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INV-01 | Slot grid renders correct number of slots (SLOT_COUNT = 15) | unit (pure logic) | `make test` targeting `test_inventory_ui_helpers.gd` | Wave 0 |
| INV-01 | Abbreviation function trims names to max_len | unit | `make test` | Wave 0 |
| INV-01 | `update()` shows abbrev when texture is null | unit | `make test` | Wave 0 |
| INV-01 | `update()` shows icon when texture is set | unit | `make test` | Wave 0 |
| INV-02 | Weight label format "X.X / Y kg" output string | unit | `make test` | Wave 0 |
| INV-02 | `insert_rejected` signal emitted when weight blocks insertion | unit (on Inventory resource) | `make test` targeting `test_inventory.gd` | ❌ Wave 0 |
| INV-03 | Stacking already covered by existing `test_inventory.gd` | unit | `make test` | ✅ (`test_inventory.gd` passes) |

> Note: UI node rendering tests (does the label actually appear on screen?) cannot run headlessly under GUT without scene tree. These are manual verification only. The testable surface for Phase 2 is: abbreviation helper, weight format helper, and the new `insert_rejected` signal on `Inventory`.

### Sampling Rate

- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/unit/test_inventory_ui_helpers.gd` — covers INV-01 abbreviation, INV-02 weight format string
- [ ] `test_inventory.gd` — add `test_insert_rejected_signal_emitted_when_weight_full` covering INV-02 signal path

---

## Sources

### Primary (HIGH confidence)

- Godot 4.2 official docs: Control node, GridContainer, CanvasLayer, TextureRect, Label — confirmed node tree patterns match existing `inventory_ui.tscn` structure
- `scripts/resources/inventory.gd` (project source) — `insert()`, `remove()`, `current_weight()`, `max_weight` API confirmed by direct read
- `scripts/resources/inventory_slot.gd` (project source) — `is_empty()`, `quantity`, `item` fields confirmed
- `scripts/resources/item.gd` (project source) — `texture: Texture2D`, `name: String`, `id: StringName` confirmed
- `scenes/inventory_ui.tscn` (project source) — existing GridContainer columns=5, NinePatchRect 499×286, 15 hardcoded slot instances confirmed
- `scenes/inventory_slot_ui.tscn` (project source) — Panel 87×80 with Sprite2D slot background; no Labels or TextureRect yet
- `scenes/world.tscn` (project source) — CanvasLayer exists at root; InventoryUI is already its child; no HUD rejection label present
- `scripts/player.gd` (project source) — `inventory: Inventory` field, `collect()` returns bool

### Secondary (MEDIUM confidence)

- Godot 4 Tween documentation: `create_tween()`, `tween_property()` — confirmed as current API replacing `SceneTreeTween`
- GDScript `%` string formatting: `"%.1f / %.0f kg" % [a, b]` — standard GDScript pattern, same as Python format strings

### Tertiary (LOW confidence)

- None. All findings verified against project source files or Godot 4 built-in node documentation.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all nodes are Godot 4 built-ins already used in the project
- Architecture: HIGH — patterns derived from reading existing project source files and Godot 4 signal/node conventions
- Pitfalls: HIGH — derived from direct code analysis (null inventory reference, queue_free timing, rejection label placement)
- Test gaps: HIGH — GUT framework confirmed present; UI rendering untestable headlessly is a known Godot constraint

**Research date:** 2026-03-10
**Valid until:** 2026-06-10 (stable Godot 4 built-in APIs; 90-day window reasonable)
