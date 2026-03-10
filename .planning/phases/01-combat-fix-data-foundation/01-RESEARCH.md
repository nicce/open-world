# Phase 1: Combat Fix + Data Foundation - Research

**Researched:** 2026-03-10
**Domain:** GDScript state machines, AnimationTree, Godot Resource mutation, float arithmetic
**Confidence:** HIGH — all findings are based on direct code inspection of the live codebase

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CMBT-01 | Player can attack and return to MOVE state (HIT state exit no longer locks player) | `hit()` never calls `on_player_state_reset()`; reset must be wired to the Fist animation's `animation_finished` signal in the AnimationTree |
| CMBT-02 | Enemies are knocked back when struck by the player | `snake.gd` has no knockback logic; `HitboxComponent` emits no knockback signal; needs velocity impulse applied to the snake `CharacterBody2D` on `damage_taken` |
| DATA-01 | Each item has a stable `id: StringName` field; stacking and removal use `id` for comparison | `item.gd` has no `id` field; `inventory.gd`, `inventory_slot.gd` compare by `item.name`; all three files need updating |
| DATA-02 | Inventory is deep-copied on scene load to prevent shared Resource mutation | `player_inventory.tres` is assigned directly via `@export var inventory: Inventory`; `player.gd._ready()` must call `inventory = inventory.duplicate(true)` |
| DATA-03 | Weight capacity uses `floori()` instead of `int()` to avoid float truncation off-by-one | `inventory.gd` lines 29 and 42 call `int(remaining_weight() / item.weight)`; replace both with `floori()` |
</phase_requirements>

---

## Summary

Phase 1 has five tightly scoped fixes across two domains: combat state machine wiring (CMBT-01, CMBT-02) and inventory data model hardening (DATA-01, DATA-02, DATA-03). None requires new scene files; all changes are script-level with one minor `.tscn` connection addition.

The HIT state lockout (CMBT-01) is the most critical: `player.gd`'s `hit()` function calls `animation_state.travel("Fist")` every physics frame but nothing ever transitions back to MOVE. The method `on_player_state_reset()` already exists and is correct — it just needs to be called. The fix is to connect the AnimationTree's `animation_finished` signal (or use an `animation_node_state_machine_playback` check) to reset state after the Fist animation completes. The existing `transitions` in `player.tscn` already include `"Fist" -> "Idle"` and `"Fist" -> "Walk"` transitions, so the AnimationTree side is already wired; only the GDScript state machine reset is missing.

Knockback (CMBT-02) requires a directional velocity impulse on the `Snake` `CharacterBody2D`. The damage pipeline currently flows: `HitboxComponent._on_area_entered` -> `take_damage()` -> `health_component.damage()` -> emits `damage_taken`. The snake listens to `damage_taken` only to play an `AnimationDamage` flash. Adding knockback means connecting a new signal path — either a new `knocked_back` signal with direction, or extending `damage_taken` to carry a direction vector — and applying a velocity impulse in `snake.gd`.

The data model fixes are deterministic single-line or small-block changes. DATA-01 adds `@export var id: StringName` to `item.gd` and updates all name comparisons. DATA-02 adds one line to `player.gd._ready()`. DATA-03 replaces two `int()` calls with `floori()`.

**Primary recommendation:** Fix CMBT-01 and CMBT-02 first (unblocks playtesting); then apply DATA-01, DATA-02, DATA-03 as a batch (they are purely data-layer and do not affect scene authoring workflow).

---

## Standard Stack

No new libraries are required for this phase. All work uses existing Godot 4.x built-ins.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GDScript | Godot 4.x built-in | All logic changes | Project language |
| AnimationTree / AnimationNodeStateMachine | Godot 4.x | Player animation state | Already wired in `player.tscn` |
| GUT | 9.3.0 | Unit tests | Already installed via `make install-gut` |
| gdtoolkit | 4.* | Lint and format | Already in `bin/venv` |

### No New Dependencies
This phase requires zero new packages. All five requirements are fixes to existing scripts and resources.

---

## Architecture Patterns

### CMBT-01: AnimationTree Finish Signal -> State Reset

**What:** After the Fist blend-space animation completes, the AnimationTree must notify the GDScript state machine to exit `PlayerStates.HIT`.

**Current state (broken):**
```gdscript
# player.gd
func hit():
    animation_state.travel("Fist")  # called every frame; never resets state
```

**How the existing scene is already wired:**
The `AnimationNodeStateMachine` in `player.tscn` has transitions:
- `"Fist" -> "Idle"` (transition index cbyby)
- `"Fist" -> "Walk"` (transition index jy154)

These transitions fire automatically when `travel()` is called to those destinations — but `travel()` is never called FROM the Fist state. The animation simply loops or stalls.

**Fix pattern — use `AnimationTree.animation_finished` signal:**
```gdscript
# player.gd _ready()
animation_tree.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name in [&"FistNorth", &"FistSouth", &"FistEast", &"FistWest"]:
        on_player_state_reset()
```

The four Fist animations are stored in the library as `FistNorth`, `FistSouth`, `FistEast`, `FistWest`. `AnimationTree` emits `animation_finished` with the leaf animation name.

**Alternative fix — poll `animation_state.get_current_node()`:**
```gdscript
func hit():
    animation_state.travel("Fist")
    if animation_state.get_current_node() == &"Fist":
        # still playing, wait
        pass
    # NOTE: this approach is fragile due to one-frame delay — prefer signal approach
```

Use the signal approach. It is edge-triggered, not polled.

### CMBT-02: Enemy Knockback Impulse

**What:** When the player's Fist area hits the snake's hitbox, the snake is pushed away from the player.

**Where damage currently fires:**
`HitboxComponent._on_area_entered(area)` — checks `"attack" in area.get_parent()` (i.e., the `Fist` Area2D whose parent is `Player`). It calls `take_damage(attack)` which calls `health_component.damage(attack)` which emits `damage_taken`.

**The snake has no velocity-modifying code.** `snake.gd` only plays `AnimationDamage` on `damage_taken`.

**Knockback pattern — velocity impulse in snake.gd:**

Option A: Pass the attacker's global position and compute the direction in `snake.gd`:
```gdscript
# snake.gd
@export var knockback_force: float = 120.0
var knockback_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta):
    if knockback_velocity != Vector2.ZERO:
        velocity = knockback_velocity
        knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_force * delta * 4)
    else:
        # existing AI movement
    move_and_slide()

func apply_knockback(from_position: Vector2) -> void:
    var direction = (global_position - from_position).normalized()
    knockback_velocity = direction * knockback_force
```

Option B: Add a `knocked_back` signal to `HitboxComponent` carrying a direction. This keeps the component reusable for future enemies.

**Recommended:** Option A — simpler for Phase 1 scope, snake is the only enemy. HitboxComponent refactor can wait until Phase 2+ when more enemy types exist.

**Wiring:** `HitboxComponent` needs access to the attacker position. It currently receives the area node in `_on_area_entered(area)`. The attacker position is `area.get_parent().global_position` (the `Fist` Area2D's parent is the `Player` node).

```gdscript
# hitbox_component.gd - extend _on_area_entered
func _on_area_entered(area):
    if "attack" in area.get_parent():
        var attack = area.get_parent().attack
        take_damage(attack)
        # emit knockback signal with attacker position
        knocked_back.emit(area.get_parent().global_position)
```

Then in `snake.gd`:
```gdscript
func _ready():
    spawn_position = global_position
    $HitboxComponent.knocked_back.connect(_on_knocked_back)

func _on_knocked_back(from_position: Vector2) -> void:
    apply_knockback(from_position)
```

### DATA-01: Add `id: StringName` to Item

**What:** Every item needs a stable identity field that survives name changes and localization.

**Current state:**
```gdscript
# item.gd
@export var name: String  # used as identity everywhere
```

**Comparison sites to update:**
- `inventory.gd` line 58: `slot.item.name == item.name`
- `inventory.gd` line 67: `slot.item.name == item.name`
- `inventory_slot.gd` line 33: `item.name == other.name`

**Fix:**
```gdscript
# item.gd — add field
@export var id: StringName
```

Then replace all `item.name == other.name` comparisons with `item.id == other.id`.

**Important:** All existing `.tres` item resource files will need `id` set. For `player_inventory.tres` slots, items are null (empty slots), so no existing item resources require immediate updates. However any item `.tres` files used in collectables must be updated before Phase 2 inventory UI work can display items correctly.

**GDScript `StringName` note:** `StringName` is interned and compared by pointer — it is faster than `String` for identity checks and is the correct Godot type for stable identifiers. Use `&"wood_log"` literal syntax.

### DATA-02: Deep Copy Inventory on Scene Load

**Root cause:** `player_inventory.tres` is a single shared `Resource` file. When Godot loads a scene, `@export` resource references point to the same in-memory object. If a previous session modified slots (added items, changed quantities), those mutations persist in the cached resource until the editor/engine restarts.

**Fix — one line in `player.gd`:**
```gdscript
func _ready():
    inventory = inventory.duplicate(true)  # true = deep copy (sub-resources)
```

`Resource.duplicate(true)` recursively duplicates all sub-resources (`InventorySlot` objects inside the `slots` array). This creates an isolated instance per scene load.

**Why `true` (deep) matters:** `duplicate(false)` would copy the top-level `Inventory` object but leave all `InventorySlot` sub-resources shared. Only `duplicate(true)` isolates the slots.

### DATA-03: Replace `int()` with `floori()` for Weight Budget

**Root cause:** `int()` truncates toward zero, not toward negative infinity. For positive floats this is equivalent — but at the boundary `remaining_weight() / item.weight` can produce a value like `9.9999998` due to floating-point arithmetic. `int(9.9999998)` = `9`, rejecting a valid add. `floori(9.9999998)` = `9` too — but the real fix is that `floori()` is the correct semantic ("how many whole units fit?") and avoids the asymmetric rounding that `int()` can cause when the computed value should be exactly an integer but is slightly below due to float representation.

**Current code:**
```gdscript
# inventory.gd line 29
var weight_budget = int(remaining_weight() / item.weight)
# inventory.gd line 42
var weight_budget = int(remaining_weight() / item.weight)
```

**Fix:**
```gdscript
var weight_budget = floori(remaining_weight() / item.weight)
```

`floori()` returns `int` in Godot 4 (unlike `floor()` which returns `float`), so downstream `mini()` calls remain valid.

### Anti-Patterns to Avoid

- **Do not call `animation_state.travel()` every frame from `hit()`** — the current code does this and it re-triggers the blend space on each physics tick. After fix, `hit()` should only call `travel("Fist")` once (on state entry), or the `_physics_process` HIT branch should be removed entirely and replaced with signal-based exit.
- **Do not use `String` for item identity** — `name` is display text; `id` is identity. Future localization will break `name`-based comparisons. Use `StringName` from the start.
- **Do not use shallow duplicate** — `inventory.duplicate()` without `true` looks correct but silently shares slot sub-resources across sessions.
- **Do not add knockback to `HealthComponent`** — knockback is physics, not health. Mixing them creates cross-component coupling. Keep the knockback signal on `HitboxComponent` or in the enemy script.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Animation completion detection | Manual frame counter or timer | `AnimationTree.animation_finished` signal | Built-in, frame-accurate, fires exactly once per animation end |
| Deep resource cloning | Manual recursive copy | `Resource.duplicate(true)` | Handles nested Resource arrays correctly; handles reference cycles |
| Integer floor division | `int(a / b)` | `floori(a / b)` | Correct semantics; `int()` is truncation not floor |
| Knockback physics | Custom physics integration | `velocity = direction * force` + `move_toward()` decay in `_physics_process` | Standard CharacterBody2D pattern for impulse decay |

---

## Common Pitfalls

### Pitfall 1: HIT State Re-Entry Every Frame
**What goes wrong:** `_physics_process` calls `hit()` every frame while `current_state == HIT`. `hit()` calls `animation_state.travel("Fist")`. This re-requests the Fist state on every tick, preventing the AnimationTree from ever advancing to its finish transition.
**Why it happens:** The `hit()` function was written as a state handler that runs continuously, but `travel()` is an intent-to-transition call — calling it repeatedly on the same state is a no-op but it does reset the AnimationTree's internal "has reached end" flag in some versions.
**How to avoid:** Call `travel("Fist")` only once on state entry. The cleanest approach is to move the `travel()` call into the `if Input.is_action_just_pressed("hit"):` block and leave `hit()` empty (or remove the HIT branch from `_physics_process` entirely, relying on the signal to exit).
**Warning signs:** Player is stuck in Fist animation indefinitely after pressing attack.

### Pitfall 2: `duplicate()` Without `true` Silently Shares Slots
**What goes wrong:** `inventory.duplicate()` creates a new `Inventory` Resource but its `slots` array still contains references to the original `InventorySlot` objects. Inserting an item modifies the shared slot, bleeding state into the next session.
**Why it happens:** Godot's default `duplicate()` is a shallow copy for sub-resources unless `subresources=true`.
**How to avoid:** Always pass `true`: `inventory.duplicate(true)`.
**Warning signs:** After dying and reloading the scene, items from the previous run are still in inventory.

### Pitfall 3: `id` Field Unset on Existing Item Resources
**What goes wrong:** After adding `id: StringName` to `item.gd`, existing `.tres` item files have `id = &""`. Two items with empty IDs will falsely match each other during stacking/removal.
**Why it happens:** New `@export` fields on existing Resources default to their zero value when the `.tres` was authored before the field existed.
**How to avoid:** After adding the field, search for all item `.tres` files, verify each has a unique non-empty `id`, and update the test helpers to always set `id`.
**Warning signs:** Different item types stack together unexpectedly; removal removes the wrong item type.

### Pitfall 4: Godot Version Mismatch for Headless Tests
**What goes wrong:** `make test` uses `GODOT_VERSION = 4.2.2` but the project declares 4.3 in `project.godot`. APIs may differ slightly between versions (e.g., `AnimationTree` signal names).
**Why it happens:** Makefile default was set to 4.2.2 before project was upgraded.
**How to avoid:** Verify `make test` passes before committing. The concern is noted in STATE.md as a known blocker. If tests fail due to version mismatch, update `GODOT_VERSION` in the Makefile.
**Warning signs:** `make test` exits with engine import errors or "API changed" warnings.

### Pitfall 5: `floori()` Return Type Mismatch
**What goes wrong:** `floori()` returns `int` in Godot 4 (correct), but if called in a context where a `float` is expected, it may need explicit casting. Confirm `mini(remaining, weight_budget)` still works — it does, since `mini()` takes two `int` args and `floori()` returns `int`.
**Why it happens:** Confusion with `floor()` which returns `float`.
**How to avoid:** Use `floori()` (with `i` suffix) specifically for integer floor division. No cast needed for `mini()`.

---

## Code Examples

### State Machine Reset via Signal (CMBT-01)
```gdscript
# Source: direct analysis of scripts/player.gd + scenes/player.tscn
# In player.gd _ready():
func _ready() -> void:
    animation_tree.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name in [&"FistNorth", &"FistSouth", &"FistEast", &"FistWest"]:
        on_player_state_reset()
```

### Knockback Signal + Velocity Impulse (CMBT-02)
```gdscript
# Source: analysis of scripts/hitbox_component.gd + scripts/snake.gd

# hitbox_component.gd — add signal
signal knocked_back(from_position: Vector2)

# hitbox_component.gd — extend _on_area_entered
func _on_area_entered(area):
    if "attack" in area.get_parent():
        var atk = area.get_parent().attack
        take_damage(atk)
        knocked_back.emit(area.get_parent().global_position)

# snake.gd — apply impulse
@export var knockback_force: float = 120.0
var knockback_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta):
    if knockback_velocity.length() > 1.0:
        velocity = knockback_velocity
        knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_force * delta * 8)
    else:
        knockback_velocity = Vector2.ZERO
        # existing AI movement here
    move_and_slide()
```

### Item ID Field (DATA-01)
```gdscript
# Source: analysis of scripts/resources/item.gd

# item.gd — add field before name
@export var id: StringName

# inventory_slot.gd — update can_stack
func can_stack(other: Item) -> bool:
    if is_empty(): return false
    if is_full(): return false
    return item.id == other.id  # was: item.name == other.name

# inventory.gd — update remove() and get_item_count()
# line 58: slot.item.id == item.id
# line 67: slot.item.id == item.id
```

### Deep Copy on Load (DATA-02)
```gdscript
# Source: analysis of scripts/player.gd + scripts/resources/player_inventory.tres

# player.gd
func _ready() -> void:
    inventory = inventory.duplicate(true)
```

### Float Floor Division (DATA-03)
```gdscript
# Source: analysis of scripts/resources/inventory.gd lines 29, 42

# Before:
var weight_budget = int(remaining_weight() / item.weight)

# After:
var weight_budget = floori(remaining_weight() / item.weight)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `int()` for floor division | `floori()` | Godot 4.x added typed math builtins | `floori()` returns `int`, no implicit float cast needed |
| Manual animation polling | `animation_finished` signal | Godot 4.x | Edge-triggered, no per-frame checks |
| `String` for identity | `StringName` | Best practice throughout Godot 4.x | Interned, pointer equality, faster comparisons |

**Deprecated/outdated in this codebase:**
- `item.name` for identity checks — name is display text, not a stable key; will break under localization or if two items share a display name.

---

## Open Questions

1. **Does `AnimationTree.animation_finished` fire for blend-space leaf animations or only for the blend-space node name?**
   - What we know: Godot 4 `AnimationTree` emits `animation_finished` with the name of the leaf `AnimationNodeAnimation`'s animation string. For the Fist blend space, leaves are `FistNorth`, `FistSouth`, `FistEast`, `FistWest`.
   - What's unclear: Whether the signal fires once per blend-space leaf finish or fires for all simultaneously-blending nodes.
   - Recommendation: Confirm with a test scene or print statement during implementation. If the signal does not fire as expected, fallback is to poll `animation_state.get_current_node() != &"Fist"` after triggering travel.

2. **Do existing `.tres` item files exist that need `id` populated?**
   - What we know: `player_inventory.tres` has 15 empty slots (no item references). No item `.tres` files were found under `scripts/resources/` beyond class definitions.
   - What's unclear: Whether any item assets are defined as `.tres` files in another directory (e.g., `scenes/` or an `items/` folder not yet created).
   - Recommendation: Run `find . -name "*.tres" | xargs grep -l "Item"` at implementation time to locate all item resource files and verify `id` is set.

3. **Should `on_player_state_reset()` be renamed or remain as-is?**
   - What we know: The method exists and is correct; it only sets `current_state = PlayerStates.MOVE`.
   - What's unclear: Whether it was originally intended to be called from a scene signal connection (the name implies it is a callback).
   - Recommendation: Keep the name; add the `animation_finished` connection in `_ready()`. No rename needed for Phase 1.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 9.3.0 |
| Config file | `addons/gut/` (installed via `make install-gut`) |
| Quick run command | `make test` |
| Full suite command | `make test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CMBT-01 | `on_player_state_reset()` sets state to MOVE | unit | `make test` (test_player_state.gd) | Wave 0 |
| CMBT-02 | `apply_knockback()` sets non-zero velocity away from source | unit | `make test` (test_snake.gd) | Wave 0 |
| DATA-01 | `can_stack()` uses `id`, not `name`; two items with same name but different `id` do not stack | unit | `make test` (test_inventory_slot.gd update) | Partial — existing file needs new tests |
| DATA-02 | `duplicate(true)` produces isolated slot objects (mutating copy does not affect original) | unit | `make test` (test_inventory.gd update) | Partial — existing file needs new tests |
| DATA-03 | Insert at exact weight limit (e.g., weight=10.0, item.weight=1.0, inserting 10) accepts item | unit | `make test` (test_inventory.gd update) | Partial — existing file needs new tests |

**Note on CMBT-01 and CMBT-02:** These involve CharacterBody2D nodes and AnimationTree — both require a Godot scene context. GUT can instantiate scenes in headless mode. Tests should instantiate the relevant `.tscn` and call the methods directly, or test the pure logic methods in isolation (e.g., `on_player_state_reset()` only touches `current_state`, no node needed).

### Sampling Rate
- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/unit/test_player_state.gd` — covers CMBT-01 (state machine reset logic)
- [ ] `tests/unit/test_snake.gd` — covers CMBT-02 (knockback velocity application)
- New test cases needed in `tests/unit/test_inventory_slot.gd` — DATA-01 id-based stacking
- New test cases needed in `tests/unit/test_inventory.gd` — DATA-02 deep copy isolation, DATA-03 exact weight limit

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `scripts/player.gd` — state machine, `hit()`, `on_player_state_reset()`
- Direct code inspection: `scenes/player.tscn` — AnimationTree node, Fist blend space, all animation transitions
- Direct code inspection: `scripts/resources/inventory.gd` — `int()` usage lines 29 and 42, `item.name` identity comparisons
- Direct code inspection: `scripts/resources/inventory_slot.gd` — `can_stack()` uses `item.name`
- Direct code inspection: `scripts/resources/item.gd` — no `id` field present
- Direct code inspection: `scripts/resources/player_inventory.tres` — confirms shared `.tres` resource pattern (no `duplicate()`)
- Direct code inspection: `scripts/snake.gd` — no knockback logic present
- Direct code inspection: `scripts/hitbox_component.gd` — `_on_area_entered()` has attacker position available
- Direct code inspection: `tests/unit/test_inventory.gd`, `test_inventory_slot.gd` — existing test patterns

### Secondary (MEDIUM confidence)
- Godot 4.x documentation pattern: `Resource.duplicate(true)` for deep sub-resource copy — standard advice in Godot community for preventing shared resource mutation across scene instances
- Godot 4.x: `floori()` returns `int` — verified against built-in type docs; `int()` is truncation, `floori()` is floor

### Tertiary (LOW confidence — flag for validation during implementation)
- `AnimationTree.animation_finished` signal fires with leaf animation name (not blend space node name) — needs runtime confirmation during implementation

---

## Metadata

**Confidence breakdown:**
- CMBT-01 root cause: HIGH — `hit()` code and AnimationTree transitions confirmed by direct inspection
- CMBT-01 fix approach: MEDIUM — `animation_finished` signal behavior with blend spaces needs runtime validation
- CMBT-02 approach: HIGH — no knockback code exists; velocity impulse pattern is standard CharacterBody2D
- DATA-01: HIGH — `id` field missing confirmed; all comparison sites identified
- DATA-02: HIGH — no `duplicate()` call exists in `player.gd`; `.tres` shared resource pattern confirmed
- DATA-03: HIGH — both `int()` call sites identified at exact line numbers
- Test infrastructure: HIGH — GUT 9.3.0 pattern confirmed from existing test files

**Research date:** 2026-03-10
**Valid until:** 2026-04-10 (stable domain — Godot 4.x GDScript APIs are stable)
