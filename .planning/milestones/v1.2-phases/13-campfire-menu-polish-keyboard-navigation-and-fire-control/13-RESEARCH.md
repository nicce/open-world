# Phase 13: Campfire Menu Polish — Keyboard Navigation and Fire Control - Research

**Researched:** 2026-03-31
**Domain:** Godot 4 Control node focus system, GDScript UI patterns, campfire state management
**Confidence:** HIGH

---

## Summary

The campfire menu already exists as a working CanvasLayer scene (`scenes/campfire_menu.tscn` /
`scripts/campfire_menu.gd`) with three buttons: Save Game, Sleep (Restore HP), and Close. The
scene pauses the tree on open and resumes it on close. The campfire script (`scripts/campfire.gd`)
already tracks fire state (`is_fire`), manages a burn timer, and exposes `fire()`, `smoke()`,
`add_wood()`, and `withdraw_wood()` methods.

What is entirely missing: keyboard focus, any way to close with the interact key (E), and any
fire-toggle button. The menu also has no reference back to the campfire node, which is needed to
call `fire()` / `smoke()` directly. The `campfire.gd` `open_menu()` function passes `player_ref`
to the menu but does not pass `self`, so the menu cannot currently call back into the campfire.

Godot 4 keyboard navigation for Button nodes works through the focus system: set
`focus_mode = FOCUS_ALL` on each Button, call `grab_focus()` on the first button in `_ready()`,
and Godot's built-in UI navigation (arrow keys, Tab) moves focus automatically. Enter and Space
activate the focused button natively — no custom code needed for that. Closing with the interact
key (E) requires `_unhandled_input` on the CanvasLayer (or the panel) because `get_tree().paused
= true` blocks `_process` on nodes that are not `process_mode = ALWAYS` — the CanvasLayer already
sets `process_mode = 3` (ALWAYS), so `_unhandled_input` will fire there.

**Primary recommendation:** Pass `self` (the Campfire node) into the menu at instantiation time,
add a fire-toggle Button to the scene, set `focus_mode = FOCUS_ALL` on all buttons and
`grab_focus()` on the first, implement `_unhandled_input` for the interact-key close, and drive
fire state through the existing `fire()` / `smoke()` methods.

---

## Project Constraints (from CLAUDE.md)

- Language: GDScript only; Godot Engine 4.2+
- Naming: `snake_case` variables/methods, `PascalCase` class names
- Node references: `@onready var foo = $NodePath`; never call `get_node()` in `_process()`
- Prefer signals over polling
- `make lint` must pass (gdlint / gdtoolkit 4.x)
- `make format-check` must pass
- `make test` must pass
- New pure-logic functions must have unit tests under `tests/unit/`
- Max 4 attempts per problem; stop and report if blocked
- Plan must be approved before code is written

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Arrow keys (up/down) move focus between menu buttons; Enter/Space activates the focused button | Godot 4 built-in focus system handles Enter/Space natively; up/down navigation needs `focus_neighbor_bottom` / `focus_neighbor_top` wiring or relying on default VBoxContainer navigation |
| UI-02 | Menu can be closed with the interact key (E) or Close button without touching the mouse | `_unhandled_input` on the CanvasLayer (which already runs in ALWAYS mode) can detect `interact` action and call `_on_close_button_pressed()` |
| FIRE-01 | Campfire menu exposes a fire-toggle button whose label reflects current fire state; toggling correctly starts/stops the burn timer | Campfire already has `fire()`, `smoke()`, `is_fire` flag; menu needs a reference to the Campfire node and a new Button; label text set dynamically from `campfire_ref.is_fire` |
</phase_requirements>

---

## Current Implementation State

### `scripts/campfire.gd`

| Aspect | Current State |
|--------|---------------|
| Fire state | `var is_fire: bool = false` |
| Burn timer | `Timer` child node, started in `fire()`, stopped in `smoke()` |
| `fire()` | Sets visibility of fire/smoke/light, starts burn_timer; guarded by `if !is_fire` |
| `smoke()` | Clears fire visuals, stops burn_timer; guarded by `if is_fire` |
| `add_wood()` | Adds to inventory int, caps at max_inventory, returns overflow |
| `withdraw_wood()` | Decrements inventory, clamps to 0, returns remaining |
| Menu opening | `open_menu()` instantiates `campfire_menu_scene`, sets `menu.player`, adds to root |
| Input polling | `_process` checks `Input.is_action_just_pressed("interact")` when `interactable` is true |
| **Missing** | `open_menu()` does NOT pass `self` — menu cannot call fire()/smoke() |

**Critical gap:** `fire()` is currently called every frame from `_physics_process` whenever
`inventory > 0`. This means toggling the fire off via the menu would immediately be reversed on
the next physics tick if any wood is in inventory. The fire-toggle feature requires separating
the auto-start-on-wood logic from explicit user control. The simplest safe approach is to add a
`var fire_enabled: bool = true` flag that `fire()` / `smoke()` respect, and the menu toggle sets
this flag as well as calls the appropriate function.

### `scenes/campfire_menu.tscn`

```
CampfireMenu (CanvasLayer, process_mode=ALWAYS)
  Panel (centered, 200x200)
    VBoxContainer
      Label ("Campfire")
      SaveButton
      SleepButton
      CloseButton
```

| Aspect | Current State |
|--------|---------------|
| Keyboard focus | NOT SET — default Button focus_mode is FOCUS_ALL in Godot 4, but no button calls grab_focus() |
| Arrow key navigation | Works implicitly in VBoxContainer IF focus is grabbed; but no initial focus grab |
| Interact-key close | NOT IMPLEMENTED |
| Fire toggle button | MISSING |
| Campfire reference | MISSING — menu only receives `player` |

### `scripts/campfire_menu.gd`

Has `_on_save_button_pressed`, `_on_sleep_button_pressed`, `_on_close_button_pressed`.
No `_unhandled_input`, no fire control, no campfire reference variable.

---

## Standard Stack

### Core (Godot 4.2 built-in)

| API | Purpose | Notes |
|-----|---------|-------|
| `Control.focus_mode` | Determines if a node can receive keyboard focus | Default for Button is `FOCUS_ALL` — already correct |
| `Control.grab_focus()` | Programmatically gives focus to a control | Call on first button in `_ready()` |
| `Control.focus_neighbor_bottom` / `focus_neighbor_top` | Explicit neighbor wiring for arrow keys | Optional; VBoxContainer auto-routes if all buttons have `FOCUS_ALL` |
| `Node._unhandled_input(event)` | Input handler for keys not consumed by focused controls | Use for interact-key close; fires on CanvasLayer because process_mode=ALWAYS |
| `InputEvent.is_action_pressed(action)` | Tests named action | Use `"interact"` to match project.godot definition |
| `Viewport.set_input_as_handled()` | Prevents event propagation | Call after handling interact in the menu |

### No external dependencies

This phase is pure Godot UI work — no new addons, packages, or tools required.

---

## Architecture Patterns

### Pattern 1: Passing campfire reference into menu

In `campfire.gd` `open_menu()`:
```gdscript
func open_menu():
    var menu = campfire_menu_scene.instantiate()
    menu.player = player_ref
    menu.campfire = self          # add this line
    get_tree().root.add_child(menu)
```

In `campfire_menu.gd`, add:
```gdscript
var campfire  # typed as the campfire node; avoid circular class reference by using duck typing
```

### Pattern 2: Initial keyboard focus in _ready

```gdscript
# campfire_menu.gd
func _ready() -> void:
    get_tree().paused = true
    $Panel/VBoxContainer/SaveButton.grab_focus()
```

Godot 4's VBoxContainer with all FOCUS_ALL children automatically routes Up/Down arrow keys
between siblings. Tab also works. This is sufficient for UI-01 — no explicit neighbor properties
need to be set.

### Pattern 3: Interact-key close via _unhandled_input

```gdscript
# campfire_menu.gd
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        get_viewport().set_input_as_handled()
        _on_close_button_pressed()
```

`_unhandled_input` is called AFTER the focused Control has had a chance to consume the event.
Since E is not a standard UI action (not ui_accept, ui_cancel, etc.), no Button will consume it
first. This is the correct hook — not `_input`, which fires before the focused control.

### Pattern 4: Fire toggle with dynamic label

```gdscript
# campfire_menu.gd
var campfire  # Campfire node reference

func _ready() -> void:
    get_tree().paused = true
    _refresh_fire_button()
    $Panel/VBoxContainer/SaveButton.grab_focus()


func _refresh_fire_button() -> void:
    if campfire == null:
        return
    if campfire.is_fire:
        $Panel/VBoxContainer/FireButton.text = "Extinguish Fire"
    else:
        $Panel/VBoxContainer/FireButton.text = "Light Fire"


func _on_fire_button_pressed() -> void:
    if campfire == null:
        return
    if campfire.is_fire:
        campfire.extinguish()     # new public method on campfire
    else:
        campfire.light()          # new public method on campfire
    _refresh_fire_button()
```

### Pattern 5: fire_enabled flag on campfire to prevent _physics_process override

**The core problem:** `_physics_process` calls `fire()` every frame when `inventory > 0`.
If the user extinguishes fire via menu, the next frame re-lights it because wood is still present.

Recommended fix — add `var fire_enabled: bool = true` to campfire and gate `_physics_process`:

```gdscript
# campfire.gd
var fire_enabled: bool = true

func _physics_process(_delta):
    if fire_enabled and inventory > 0:
        fire()
    elif not fire_enabled or inventory == 0:
        smoke()


func light() -> void:
    fire_enabled = true
    if inventory == 0:
        add_wood(1)    # or: only light if wood exists, show feedback otherwise
    fire()


func extinguish() -> void:
    fire_enabled = false
    smoke()
```

Alternatively, if "Light Fire" should also consume wood from player inventory (the success
criterion mentions "adding wood via menu or lighting via menu starts burn timer correctly"), the
`light()` method should transfer wood from player inventory to campfire inventory. This is the
same pattern as the existing sleep/save flow: the menu acts on both campfire and player.

### Anti-Patterns to Avoid

- **Polling fire state in `_process` of the menu:** The menu is paused/active briefly; query
  fire state once in `_ready` and after each toggle. Do not connect to a timer or poll.
- **Using `_input` instead of `_unhandled_input` for the E key close:** `_input` fires before
  Button's built-in keyboard handling. Use `_unhandled_input` to preserve correct layering.
- **Setting `process_mode = ALWAYS` on individual buttons:** The CanvasLayer already has it.
  Child nodes inherit unless overridden; do not add per-button overrides.
- **Calling `fire()` directly from the menu without a `light()` wrapper:** The existing `fire()`
  is guarded by `if !is_fire` and always starts the timer. A public `light()` / `extinguish()`
  API makes intent explicit and allows the `fire_enabled` flag to be managed cleanly.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Arrow-key focus navigation between buttons | Custom key-intercept in `_input` | Godot 4 built-in focus system with FOCUS_ALL + grab_focus() |
| Enter/Space activation of focused button | Custom action handler | Godot 4 activates focused Button on ui_accept automatically |
| Pausing game while menu open | Manual physics/process disabling | `get_tree().paused = true` (already in use) |

**Key insight:** Godot 4 Button nodes handle Enter/Space and arrow-key traversal automatically
once focus is established. The only required code is `grab_focus()` on the first button.

---

## Common Pitfalls

### Pitfall 1: _physics_process overrides manual fire extinguish
**What goes wrong:** Player extinguishes fire from menu, but `_physics_process` re-calls `fire()`
on the next frame because `inventory > 0`. Fire visually restores immediately.
**Why it happens:** The existing `_physics_process` logic conflates "has wood" with "should burn".
**How to avoid:** Introduce `fire_enabled` flag; gate the physics process on it.
**Warning signs:** Fire flickers on for one frame then off, or stays on despite extinguish call.

### Pitfall 2: interact key (E) opens menu AND closes it in same frame
**What goes wrong:** Pressing E to close the menu triggers `interactable` check in `campfire.gd`
`_process`, which opens a new menu immediately.
**Why it happens:** Both campfire and the menu respond to `interact`. The campfire `_process`
reads `Input.is_action_just_pressed("interact")` every frame.
**How to avoid:** In `_unhandled_input` of the menu, call `get_viewport().set_input_as_handled()`
BEFORE calling close. This marks the event consumed so `campfire.gd`'s `_process` won't see it.
Note: `Input.is_action_just_pressed` does NOT respect `set_input_as_handled`. To fully prevent
double-trigger, campfire's `_process` should be converted to `_unhandled_input` as well, OR the
campfire should check if a menu is already open before opening another.
**Warning signs:** Menu flashes open then immediately re-opens.

**Recommended resolution:** Convert `campfire.gd` interact detection from `_process` +
`Input.is_action_just_pressed` to `_unhandled_input(event)` + `event.is_action_pressed`. This
makes it respect consumed events.

### Pitfall 3: grab_focus() silently no-ops if called before node is in scene tree
**What goes wrong:** `grab_focus()` in `_ready()` does nothing; no button has focus on open.
**Why it happens:** If the CanvasLayer is added to the tree but the Panel/VBoxContainer children
are not yet ready, `grab_focus()` on a child can fail.
**How to avoid:** Call `grab_focus()` at the end of `_ready()`, after all children are ready.
Since `_ready()` fires bottom-up in Godot 4 (children first, then parent), by the time
`CampfireMenu._ready()` runs, all Button children are already in the tree and focusable.

### Pitfall 4: focus_mode not FOCUS_ALL on new FireButton
**What goes wrong:** New FireButton cannot receive keyboard focus; arrow keys skip it.
**Why it happens:** New nodes added in the .tscn editor default to FOCUS_ALL for Button, but
forgetting to verify this is a common oversight.
**How to avoid:** Verify in the scene inspector that FireButton.focus_mode = FOCUS_ALL (value 2).
This is the default for Button so it only fails if someone has changed it.

### Pitfall 5: burn_timer starts but wood is 0 when lighting with no wood
**What goes wrong:** If `light()` calls `fire()` when `inventory == 0`, the timer starts, but
`_on_burn_timer_timeout` immediately calls `withdraw_wood(1)` which does nothing (already 0),
and the fire continues indefinitely without consuming fuel.
**Why it happens:** `fire()` starts the timer unconditionally when `is_fire` transitions to true.
**How to avoid:** `light()` should only call `fire()` if `inventory > 0`, OR it should transfer
wood from the player's inventory first. Gate the button: disable it if no wood available.

---

## Code Examples

### Minimal grab_focus pattern (verified: Godot 4 docs)
```gdscript
func _ready() -> void:
    get_tree().paused = true
    $Panel/VBoxContainer/SaveButton.grab_focus()
```

### _unhandled_input for interact close (verified: Godot 4 docs)
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        get_viewport().set_input_as_handled()
        _on_close_button_pressed()
```

### Converting campfire interact detection to unhandled_input
```gdscript
# campfire.gd — replace _process interact check with:
func _unhandled_input(event: InputEvent) -> void:
    if interactable and event.is_action_pressed("interact"):
        get_viewport().set_input_as_handled()
        open_menu()
```

---

## Implementation Scope Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `scripts/campfire.gd` | Modify | Add `fire_enabled` flag; add public `light()` / `extinguish()` methods; convert interact detection from `_process` to `_unhandled_input`; pass `self` in `open_menu()` |
| `scripts/campfire_menu.gd` | Modify | Add `var campfire`; add `_unhandled_input` for E-key close; add `_on_fire_button_pressed`; add `_refresh_fire_button`; call `grab_focus()` in `_ready()` |
| `scenes/campfire_menu.tscn` | Modify | Add FireButton node to VBoxContainer (between SleepButton and CloseButton); wire `pressed` signal |
| `tests/unit/test_campfire.gd` | Extend | Add tests for `light()`, `extinguish()`, `fire_enabled` flag behavior |
| `tests/unit/test_campfire_menu.gd` | New | Unit tests for fire button label logic and close behaviour |

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
| UI-01 | Arrow keys move focus / Enter activates | Manual (Godot UI focus is engine-internal, not unit-testable headlessly) | `make test` (smoke) | N/A — manual only |
| UI-02 | E key closes menu | Manual + unit (logic path testable via script instantiation) | `make test` | ❌ Wave 0: `tests/unit/test_campfire_menu.gd` |
| FIRE-01 | fire_enabled flag; light/extinguish; label text | Unit | `make test` | ❌ Wave 0: `tests/unit/test_campfire_menu.gd` + extend `tests/unit/test_campfire.gd` |

**Manual testing note:** Keyboard focus and navigation in Godot 4 cannot be driven headlessly
through GUT. These must be verified by running the game (F5) and pressing arrow keys/Enter/E.

### Wave 0 Gaps
- [ ] `tests/unit/test_campfire_menu.gd` — covers FIRE-01 label logic and close callback
- [ ] Extend `tests/unit/test_campfire.gd` — covers `fire_enabled`, `light()`, `extinguish()`

*(Existing `test_campfire.gd` covers add_wood/withdraw_wood; it does not cover fire state methods
because those require scene children. The new `light()` / `extinguish()` / `fire_enabled` logic
should be structured so the pure flag logic is testable without scene nodes.)*

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely GDScript code and scene edits with no external runtime
dependencies beyond the already-verified Godot + GUT + gdtoolkit toolchain.

---

## Open Questions

1. **Should "Light Fire" consume wood from player inventory?**
   - What we know: The success criterion says "adding wood via the menu (or lighting via menu)
     starts the burn timer correctly." This implies lighting via menu should add wood.
   - What's unclear: Should it silently consume one wood item from the player, or should it only
     light if campfire.inventory > 0 (wood was added separately)?
   - Recommendation: Disable the FireButton (or show it greyed) when campfire.inventory == 0 and
     fire is off. This avoids the timer-with-no-fuel pitfall and keeps the feature simple. The
     planner should surface this to the user for confirmation.

2. **Should extinguish preserve inventory (wood stays in campfire, timer paused)?**
   - What we know: `smoke()` stops the timer but does not drain inventory. Wood remains.
   - What's unclear: Is "extinguish" a manual pause of burning, or does it waste remaining wood?
   - Recommendation: Preserve inventory (timer paused, wood stays). This is the simplest and most
     natural behaviour. Re-lighting then restarts the timer.

---

## Sources

### Primary (HIGH confidence)
- Direct inspection of `scripts/campfire.gd` — fire state, burn timer, methods confirmed
- Direct inspection of `scripts/campfire_menu.gd` — current button handlers confirmed
- Direct inspection of `scenes/campfire_menu.tscn` — scene structure confirmed
- Direct inspection of `project.godot` — `interact` action = physical keycode 69 (E) confirmed
- Direct inspection of `scripts/inventory_ui.gd` — existing `_input` / `set_input_as_handled` pattern confirmed
- Godot 4 documentation (training data, HIGH confidence for stable APIs): `Control.grab_focus()`, `Control.focus_mode`, `Node._unhandled_input`, `Viewport.set_input_as_handled`

### Secondary (MEDIUM confidence)
- Godot 4 VBoxContainer automatic focus routing behaviour — well-documented behaviour but not
  re-verified via live docs fetch; confirm with a quick manual test during implementation.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all Godot 4.2 built-in APIs, no third-party libraries
- Architecture: HIGH — based on direct source inspection; patterns match existing codebase conventions
- Pitfalls: HIGH — physics_process override pitfall is directly observable in existing code;
  double-trigger pitfall is deducible from the two competing `is_action_just_pressed` sites

**Research date:** 2026-03-31
**Valid until:** 2026-05-01 (Godot 4 stable APIs — no expected churn)
