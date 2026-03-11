# Phase 3: Item Management - Research

**Researched:** 2026-03-11
**Domain:** GDScript / Godot 4 — inventory interaction, slot selection UI, collectable instantiation, HUD notifications
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Slot selection**
- Mouse click selects a slot; selected slot gets a visible highlight border
- Clicking the already-selected slot deselects it (toggle behavior)
- Closing the inventory panel (Tab/I) always clears the selection — no stale state across open/close
- Only occupied slots respond to clicks — clicking an empty slot is a no-op

**Use & drop controls**
- E = use selected item; Q = drop selected item (while inventory panel is open only)
- E on a non-consumable (e.g., Gold Key, Axe) = silent no-op — no message or feedback
- E and Q are only active when the inventory panel is visible; they have no effect when closed
- E is safe because world interact is paused while inventory is open

**Drop quantity**
- Q drops exactly 1 unit per press; player presses Q multiple times to drop more from a stack
- Dropped collectable spawns at a slight random offset from the player's position (≈16–32px in a random direction) to prevent the item sitting directly under the player and causing immediate re-pickup

**Pickup notification (ITEM-03)**
- Format: `+ [Item Name]` (e.g., `+ Gold Key`, `+ Medpack`)
- Position: bottom center of screen, on a CanvasLayer (always visible)
- Behavior: replace — each new pickup resets the label text and restarts the fade timer; most recent pickup always shows
- Same implementation pattern as the existing rejection label in world.gd (Label + Timer + tween fade)

### Claude's Discretion
- Exact fade duration for pickup notification (reference: rejection label uses ~2s + 0.4s tween)
- Selection highlight color/border style on slot
- Exact pixel offset and randomization approach for drop spawn position

### Deferred Ideas (OUT OF SCOPE)
- Equipment slots (weapon/armor as always-visible HUD, Minecraft-style) — v2 phase
- Hotbar / quick-access row — v2 phase
- Equipping a weapon changes attack stats — v2 phase
- Drop quantity picker (choose how many to drop from a stack) — backlog
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ITEM-01 | Player can select a consumable (health item) in inventory and use it to restore HP | `item.consumable` flag + `Player.increase_health()` + `Inventory.remove()` already exist; need slot selection state in `inventory_ui.gd` and E-key handler |
| ITEM-02 | Player can drop an item from inventory and it reappears as a collectable in the world at the player's position | `scenes/collectable.tscn` is the base scene; instantiate it at runtime, set `.item`, position at `player.global_position + random_offset`, add to world tree |
| ITEM-03 | Player sees a brief notification when an item is successfully picked up | `collectable.gd::collect()` already calls `collector.collect(item)` and checks return value; add a signal from player/collectable, wire to new `PickupLabel` in `world.gd` following the `RejectionLabel` pattern |
</phase_requirements>

---

## Summary

Phase 3 extends the existing inventory system with three pure-logic behaviors that build directly on the infrastructure already in place. All data-model operations (`remove`, `insert`, `has_item`, `consumable` flag, `increase`) exist and are tested. The gap is entirely in the interaction layer: slot selection state, keyboard handlers while the panel is open, runtime collectable instantiation, and a HUD notification label.

The most structurally significant decision is where slot selection state lives. `inventory_ui.gd` owns the slot nodes and handles `_input`, making it the natural home for `_selected_slot_index: int` and the E/Q dispatch. `inventory_slot_ui.gd` handles the visual highlight. `world.gd` continues to own HUD labels and connects to player signals for pickup notification.

The drop pattern — preloading `collectable.tscn`, instantiating at runtime, setting `.item`, positioning with a random offset, then calling `get_tree().current_scene.add_child()` — is identical to the pattern used to spawn temporary nodes in Godot 4 games. No new architectural concepts are required.

**Primary recommendation:** Add `_selected_slot_index` to `inventory_ui.gd`, handle E/Q inside its `_input` guard, add slot click via `gui_input` in `inventory_slot_ui.gd`, wire a new `item_collected` signal from the collectable/player path to `world.gd` for the pickup label.

---

## Standard Stack

### Core (already in project)

| Library / System | Version | Purpose | Status |
|-----------------|---------|---------|--------|
| GDScript / Godot 4 | 4.2+ | Language and engine | Installed |
| GUT | 9.3.0 | Unit test framework | Installed via `make install-gut` |
| gdtoolkit | 4.* | Lint + format | Installed via `pip install "gdtoolkit==4.*"` |

No new dependencies are required for this phase.

### Supporting Scripts (already exist)

| Script | Role in Phase 3 |
|--------|----------------|
| `scripts/inventory_ui.gd` | Add selection state + E/Q handlers + drop logic |
| `scripts/inventory_slot_ui.gd` | Add `gui_input` click handler + selected visual state |
| `scripts/player.gd` | Add `drop_item()` helper (position access) or expose `global_position` |
| `scripts/resources/inventory.gd` | `remove(item, 1)` used as-is |
| `scripts/collectable.gd` | Instantiated at runtime for drops; `collect()` return value used for ITEM-03 |
| `scripts/world.gd` | Add `PickupLabel` node wiring and handler |
| `scripts/resources/health_item.gd` | `consumable = true`, `.health: int` — already works |

---

## Architecture Patterns

### Recommended File Changes

```
scripts/
  inventory_ui.gd         # + selection state, _input E/Q, _on_slot_selected(index)
  inventory_slot_ui.gd    # + gui_input signal handler, set_selected(bool) visual
  player.gd               # + drop_item(slot_index) OR inventory_ui receives player ref
  world.gd                # + PickupLabel node reference, _on_item_collected(item_name)
scenes/
  world.tscn              # + PickupLabel Label + FadeTimer nodes under CanvasLayer
  inventory_ui.tscn       # (no structural change — slot layout unchanged)
  inventory_slot_ui.tscn  # (no structural change — Panel with existing children)
tests/unit/
  test_item_management.gd # New: unit tests for use/drop logic
```

### Pattern 1: Slot Selection State in inventory_ui.gd

**What:** A single integer index tracks which slot is selected. -1 means nothing selected.
**When to use:** Only the UI owner needs to know selection; slots get told their visual state.

```gdscript
# In inventory_ui.gd
var _selected_index: int = -1

func _on_slot_clicked(index: int) -> void:
    if _inventory.slots[index].is_empty():
        return  # no-op for empty slots
    if _selected_index == index:
        _deselect()
    else:
        _deselect()
        _selected_index = index
        grid.get_child(index).set_selected(true)

func _deselect() -> void:
    if _selected_index >= 0:
        grid.get_child(_selected_index).set_selected(false)
    _selected_index = -1
```

Clearing selection on close (Tab/I toggle):

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("inventory"):
        visible = !visible
        if not visible:
            _deselect()  # always clear on close
```

### Pattern 2: Slot Click via gui_input

**What:** `gui_input` on the Panel node catches mouse button events without needing a separate Button node.
**When to use:** Panel-based slots that already exist — avoids restructuring the scene.

```gdscript
# In inventory_slot_ui.gd
signal slot_clicked(slot_node)  # or index — parent decides

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        slot_clicked.emit(self)
```

inventory_ui.gd connects this in `_ready()` after instantiating slot nodes:

```gdscript
for i in range(SLOT_COUNT):
    var slot = SLOT_SCENE.instantiate()
    grid.add_child(slot)
    slot.slot_clicked.connect(_on_slot_clicked.bind(i))
```

### Pattern 3: Runtime Collectable Instantiation (Drop)

**What:** Load `collectable.tscn`, instantiate, configure item + position, add to scene tree.
**When to use:** Dropping items — the base `Collectable` scene already handles interact + collect.

```gdscript
# In inventory_ui.gd (needs reference to player for position)
const COLLECTABLE_SCENE: PackedScene = preload("res://scenes/collectable.tscn")

func _drop_selected() -> void:
    if _selected_index < 0:
        return
    var slot := _inventory.slots[_selected_index]
    if slot.is_empty():
        return
    var item_ref := slot.item  # capture before remove clears it
    var removed := _inventory.remove(slot.item, 1)
    if removed == 0:
        return

    var node := COLLECTABLE_SCENE.instantiate()
    node.item = item_ref
    # Random offset ≈16–32px to avoid immediate re-pickup
    var angle := randf() * TAU
    var dist := randf_range(16.0, 32.0)
    node.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
    get_tree().current_scene.add_child(node)

    if slot.is_empty():
        _deselect()
    # inventory_changed already emitted by remove()
```

### Pattern 4: Pickup Notification — Mirroring RejectionLabel

**What:** Add a `PickupLabel` (Label + Timer child) to `CanvasLayer` in `world.tscn`, wire it identically to `RejectionLabel`.
**When to use:** ITEM-03 — brief replace-behavior HUD notification.

Existing pattern from `world.gd`:

```gdscript
func _on_insert_rejected() -> void:
    rejection_label.modulate.a = 1.0
    fade_timer.start()

func _on_fade_timer_timeout() -> void:
    var tw := create_tween()
    tw.tween_property(rejection_label, "modulate:a", 0.0, 0.4)
```

New parallel pattern for pickup:

```gdscript
# world.gd additions
@onready var pickup_label: Label = $CanvasLayer/PickupLabel
@onready var pickup_timer: Timer = $CanvasLayer/PickupLabel/PickupTimer

func _on_item_collected(item_name: String) -> void:
    pickup_label.text = "+ " + item_name
    pickup_label.modulate.a = 1.0
    pickup_timer.start()

func _on_pickup_timer_timeout() -> void:
    var tw := create_tween()
    tw.tween_property(pickup_label, "modulate:a", 0.0, 0.4)
```

The replace-behavior (restart timer on new pickup) is automatic: calling `pickup_timer.start()` restarts it even if already running, resetting the fade.

### Pattern 5: Signal Chain for Pickup Notification

The cleanest chain for ITEM-03 given existing architecture:

```
collectable.gd::collect()
  -> calls collector.collect(item)  [already exists, returns bool]
  -> if success: emit item_collected(item.name) on the collectable
     OR: player.gd emits item_collected after successful insert

world.gd connects player.item_collected -> _on_item_collected(item_name)
```

The player already has `collect(item) -> bool`. The least-invasive extension adds a signal on `Player`:

```gdscript
# player.gd
signal item_collected(item_name: String)

func collect(item) -> bool:
    var success := inventory.insert(item) == 0
    if success:
        item_collected.emit(item.name)
    return success
```

`world.gd` in `_ready()`:

```gdscript
player.item_collected.connect(_on_item_collected)
```

### Anti-Patterns to Avoid

- **Polling `_process()` for E/Q key state:** Use `_input(event)` with `is_action_pressed()` guard; only inside `if visible:` block.
- **Direct node path calls across scenes:** `inventory_ui.gd` should receive a player reference via `set_player(player)` from `world.gd`, not via `get_node("/root/World/Player")`.
- **Removing item before capturing the item reference:** `slot.item` becomes `null` after `slot.remove()` clears the slot. Capture `item_ref = slot.item` before calling `remove()`.
- **Using `visible` as a toggle guard alone:** Toggling on the same frame as `_input` can cause flicker. The existing `is_action_pressed` pattern is correct — do not change to `_process`.
- **add_child to InventoryUI for drops:** Add dropped collectables to the world scene, not the UI layer, so they exist in world space.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Random direction for drop offset | Custom angle math | `randf() * TAU` + `Vector2(cos, sin) * dist` | Godot built-in; one line |
| Fade animation | Manual alpha decrement in `_process` | `create_tween().tween_property(label, "modulate:a", 0.0, duration)` | Tweens handle delta, easing, cleanup automatically |
| Item removal | Custom slot-clearing code | `Inventory.remove(item, 1)` | Already exists, tested, handles multi-slot removal |
| Collectable spawning base | New scene from scratch | Instantiate `scenes/collectable.tscn` | Already has collision, sprite, interact logic |
| Consumable check | New item type hierarchy | `item.consumable` bool on `Item` resource | Already set to `true` on `HealthItem` |

---

## Common Pitfalls

### Pitfall 1: Item Reference Null After Remove

**What goes wrong:** `_inventory.remove(slot.item, 1)` can clear the slot (set `item = null`, `quantity = 0`) when the last unit is removed. Any code that reads `slot.item` after the call gets `null`.
**Why it happens:** `InventorySlot.remove()` nulls the item when quantity hits zero.
**How to avoid:** Always capture `var item_ref := slot.item` before calling `remove()`. Use `item_ref` for drop spawn and deselect check.
**Warning signs:** Null reference errors when accessing `item_ref.name` in `_drop_selected()`.

### Pitfall 2: E/Q Keys Leaking Outside Inventory

**What goes wrong:** E in the game world triggers the world interact action AND the inventory use action simultaneously if both are processed.
**Why it happens:** `_input()` fires regardless of UI visibility unless guarded.
**How to avoid:** All E/Q inventory handling must be inside `if not visible: return` at the top of `_input()`. The CONTEXT.md decision confirms E is safe because world interact is paused while inventory is open — but the guard is still required in `inventory_ui.gd`.

### Pitfall 3: Stale Selection After inventory_changed

**What goes wrong:** Use/drop removes the last unit from a slot; slot becomes empty but `_selected_index` still points to it. Subsequent E/Q on an empty selected slot tries to operate on `null` item.
**Why it happens:** Selection index is not cleared when the underlying data changes.
**How to avoid:** After `remove()`, check `if _inventory.slots[_selected_index].is_empty(): _deselect()`. Do this inside `_drop_selected()` and `_use_selected()`.

### Pitfall 4: gui_input vs _input Propagation

**What goes wrong:** `_gui_input` on a slot Panel is consumed, but `_input` in the parent `inventory_ui.gd` may also fire for the same click event, causing double-handling or E/Q triggering on click.
**Why it happens:** Godot 4 propagates unhandled events up the node tree.
**How to avoid:** In `inventory_slot_ui.gd`, call `get_viewport().set_input_as_handled()` after processing a click in `_gui_input` to stop propagation. Alternatively, emit a signal and let `inventory_ui.gd` handle all logic centrally.

### Pitfall 5: Dropped Collectable Re-Picked Up Immediately

**What goes wrong:** Collectable spawns directly at `player.global_position`. Collectable's `_on_body_entered` fires in the same frame, setting `is_collectable = true` and collector. Player may re-collect immediately.
**Why it happens:** The collision area overlaps the player at spawn time.
**How to avoid:** Apply the ≈16–32px random offset (locked decision). This moves the collectable outside the player's collision shape. Additionally, `collectable.gd` already requires `interact` key press — the player must press E to collect, so even overlapping is safe unless the player is holding E at the exact moment.

### Pitfall 6: Tween Not Restarted on Rapid Pickups

**What goes wrong:** Player picks up two items in quick succession. Second pickup starts a new tween while the first tween is still running. Both tweens write to `modulate.a` simultaneously, causing a flicker or premature fade-out.
**Why it happens:** `create_tween()` creates a new tween each call without stopping the previous one.
**How to avoid:** Store the tween reference as a variable and call `kill()` before creating a new one, OR rely on the Timer restart behavior: since the timer restarts, the second tween call only happens after the timer fires again — as long as the tween is only created in the timeout handler, not in the show handler. The RejectionLabel pattern already does this correctly: show handler sets alpha=1 + starts timer; tween only created on timer timeout. Follow the same pattern for PickupLabel.

---

## Code Examples

### Use Item (ITEM-01)

```gdscript
# inventory_ui.gd
func _use_selected() -> void:
    if _selected_index < 0:
        return
    var slot := _inventory.slots[_selected_index]
    if slot.is_empty() or not slot.item.consumable:
        return  # silent no-op for non-consumables
    if not slot.item is HealthItem:
        return  # only HealthItem is usable in Phase 3
    _player.increase_health((slot.item as HealthItem).health)
    _inventory.remove(slot.item, 1)
    if slot.is_empty():
        _deselect()
```

### Drop Item (ITEM-02)

```gdscript
# inventory_ui.gd
const COLLECTABLE_SCENE: PackedScene = preload("res://scenes/collectable.tscn")

func _drop_selected() -> void:
    if _selected_index < 0:
        return
    var slot := _inventory.slots[_selected_index]
    if slot.is_empty():
        return
    var item_ref := slot.item  # capture BEFORE remove
    var removed := _inventory.remove(item_ref, 1)
    if removed == 0:
        return
    var node := COLLECTABLE_SCENE.instantiate()
    node.item = item_ref
    var angle := randf() * TAU
    var dist := randf_range(16.0, 32.0)
    node.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
    get_tree().current_scene.add_child(node)
    if slot.is_empty():
        _deselect()
```

### Pickup Notification Signal (ITEM-03)

```gdscript
# player.gd addition
signal item_collected(item_name: String)

func collect(item) -> bool:
    var success := inventory.insert(item) == 0
    if success:
        item_collected.emit(item.name)
    return success
```

```gdscript
# world.gd additions in _ready()
player.item_collected.connect(_on_item_collected)

func _on_item_collected(item_name: String) -> void:
    pickup_label.text = "+ " + item_name
    pickup_label.modulate.a = 1.0
    pickup_timer.start()

func _on_pickup_timer_timeout() -> void:
    var tw := create_tween()
    tw.tween_property(pickup_label, "modulate:a", 0.0, 0.4)
```

### Selected Slot Visual (inventory_slot_ui.gd)

```gdscript
func set_selected(selected: bool) -> void:
    if selected:
        add_theme_stylebox_override("panel", _selected_style)
    else:
        remove_theme_stylebox_override("panel")
```

Where `_selected_style` is a `StyleBoxFlat` with a colored border set up in `_ready()`.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Direct node references across scenes | Signals + explicit `set_inventory()` / `set_player()` injection | Already established in Phase 2 — follow the same pattern |
| `int()` for weight flooring | `floori()` | Already fixed in Phase 1 — no change needed |
| `duplicate(true)` for inventory copy | `clone()` | Already fixed in Phase 1 — no change needed |

---

## Open Questions

1. **Should `_use_selected()` and `_drop_selected()` live in `inventory_ui.gd` or `player.gd`?**
   - What we know: `inventory_ui.gd` already has the selection index and inventory reference; `player.gd` has `increase_health()` and the `global_position` for drop spawn.
   - What's unclear: Whether passing a player reference into `inventory_ui.gd` (via `set_player()`) is cleaner than emitting signals upward to `world.gd`.
   - Recommendation: Put use/drop logic in `inventory_ui.gd` with a `_player` reference set from `world.gd` during `_ready()`. This keeps selection and action dispatch co-located and avoids an additional signal layer.

2. **`HealthItem` type check in `_use_selected()`**
   - What we know: `item.consumable = true` on `HealthItem`; no other consumable types exist in Phase 3.
   - What's unclear: Whether to check `item is HealthItem` or just `item.consumable` and cast.
   - Recommendation: Check `item.consumable` first as the guard (respects the silent no-op requirement for non-consumables). Then check `item is HealthItem` before casting to access `.health`. This is forward-safe if other consumable types are added later.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | GUT 9.3.0 |
| Config file | `addons/gut/` (installed via `make install-gut`) |
| Quick run command | `make test` |
| Full suite command | `make test` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ITEM-01 | Using a consumable slot removes 1 from inventory and calls increase_health | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-01 | Using a non-consumable is a silent no-op (inventory unchanged) | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-01 | Using with no slot selected is a no-op | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-02 | Dropping 1 unit removes exactly 1 from inventory | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-02 | Dropping last unit from a slot deselects that slot | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-02 | Dropping with no selection is a no-op | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-03 | collect() emits item_collected signal with item name on success | unit | `make test` (test_item_management.gd) | Wave 0 |
| ITEM-03 | collect() does not emit item_collected on failed insert | unit | `make test` (test_item_management.gd) | Wave 0 |

Note: Slot click → visual highlight and collectable world-spawn are scene-tree-dependent behaviors; they are manual-only verification items (no headless unit test possible without scene instantiation overhead).

### Sampling Rate

- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green + manual smoke test (open inventory, use medpack, drop key, verify pickup label) before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/unit/test_item_management.gd` — covers ITEM-01, ITEM-02, ITEM-03 (use/drop/signal pure logic)

*(Existing test infrastructure — `test_inventory.gd`, `test_inventory_slot.gd`, `test_inventory_ui_helpers.gd` — covers the data layer already. No framework config changes needed.)*

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection of `scripts/inventory_ui.gd`, `scripts/inventory_slot_ui.gd`, `scripts/player.gd`, `scripts/world.gd`, `scripts/collectable.gd`, `scripts/resources/inventory.gd`, `scripts/resources/health_item.gd`, `scripts/resources/inventory_slot.gd`, `scripts/resources/item.gd` — all implementation details above are grounded in the actual current code.
- `scenes/collectable.tscn`, `scenes/medicpack.tscn`, `scenes/gold_key.tscn` — scene structure confirmed.
- `tests/unit/test_inventory.gd`, `tests/unit/test_inventory_ui_helpers.gd` — test pattern confirmed (GUT `extends GutTest`, `watch_signals`, `assert_signal_emitted`).
- `.planning/phases/03-item-management/03-CONTEXT.md` — all locked decisions sourced from here.

### Secondary (MEDIUM confidence)
- Godot 4 `_gui_input` / `get_viewport().set_input_as_handled()` propagation behavior — consistent with Godot 4 documentation and known engine behavior; not re-verified against live docs in this session.
- `create_tween()` concurrent tween behavior — based on engine knowledge; the mitigation pattern (tween only in timeout handler) is verified against the existing working `RejectionLabel` code.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project, no new dependencies
- Architecture: HIGH — patterns directly derived from existing working code in the repo
- Pitfalls: HIGH — item reference null after remove and stale selection are verified code-path risks; others are engine-behavior derived
- Test patterns: HIGH — GUT pattern confirmed from existing test files

**Research date:** 2026-03-11
**Valid until:** 2026-06-11 (stable domain — Godot 4 GDScript patterns; no fast-moving dependencies)
