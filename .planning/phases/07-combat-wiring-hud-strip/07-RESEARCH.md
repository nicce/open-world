# Phase 7: Combat Wiring + HUD Strip - Research

**Researched:** 2026-03-19
**Domain:** GDScript combat dispatch, Godot UI (Control/CanvasLayer), signal-driven HUD
**Confidence:** HIGH

## Summary

Phase 7 is a pure wiring and UI phase with no new architecture. Every building block
already exists in the codebase: the `hit()` stub, the `Attack` resource with a mutable
`damage` field, the `equipment_data.equipment_changed` signal, and the texture-or-label
display pattern used consistently across `collectable.gd` and `sword.gd`.

The three deliverables are tightly scoped:
1. **Combat dispatch** — fill the `hit()` stub in `player.gd` to read `equipment_data.weapon`
   at call time and overwrite `attack.damage` before the animation drives the hitbox.
2. **HUD strip** — a new `Control` scene added as a sibling of `InventoryUI` inside the
   existing `CanvasLayer`, wired via `world.gd _ready()` in the established pattern.
3. **Player weapon indicator** — a child node on the Player scene that subscribes to
   `equipment_data.equipment_changed` and mirrors the texture-or-label pattern.

No new patterns are needed. The only medium-confidence concern is attack.damage mutation
timing relative to when `HitboxComponent._on_area_entered()` reads the value — this is
confirmed safe because `hit()` runs synchronously before `animation_state.travel("Fist")`
returns, while the hitbox fires several frames later on the animation's collision track.

**Primary recommendation:** Implement as three self-contained tasks in one wave.
Combat dispatch is pure GDScript logic and fully unit-testable. HUD strip and player
indicator are scene/UI tasks — test coverage is integration-level (manual or smoke).

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Combat dispatch (CMBT-03, CMBT-04)**
- `hit()` reads `equipment_data.weapon` at call time — not via a subscription to `equipment_changed`
- If weapon equipped: `attack.damage = equipment_data.weapon.damage` (overrides damage just before animation fires)
- If no weapon: leave `attack.damage` as-is (the Inspector-configured fist value on the Attack node)
- `hit()` is called from `move()` before `animation_state.travel("Fist")` — collision timing is handled by the animation track that toggles `Fist/CollisionShape2D:disabled` at the impact frame
- No changes to animation `.res` files; no method track needed

**Player weapon indicator (CMBT-05)**
- A child node on the Player (Sprite2D or Label, Claude's discretion on node type) shows when a weapon is equipped
- Texture if available: shows `weapon_item.texture` in a TextureRect/Sprite2D
- Label fallback: if `weapon_item.texture` is null, shows `weapon_item.name` as text
- Same pattern as existing `collectable.gd` / `sword.gd` texture-or-label logic
- Visibility toggled by `equipment_data.equipment_changed` signal
- Position above the player character (exact offset: Claude's discretion)

**HUD strip layout (HUD-01)**
- Position: bottom center of the viewport
- Scene placement: sibling of InventoryUI in the world's CanvasLayer — NOT a child of InventoryUI
- Two slots: weapon slot (left) and tool slot (right)
- Slot labels "W" and "T" displayed as text below each slot box
- Empty slots: darker/dimmed appearance (visually distinct from filled slots)

**HUD slot icon display (HUD-02)**
- Filled slot shows weapon/tool texture if available, falls back to item name as a Label
- Same texture-or-label pattern as the rest of the codebase (collectable, sword)
- Slot content updates in response to `equipment_data.equipment_changed` signal

### Claude's Discretion
- Exact node type for player indicator (Sprite2D vs TextureRect vs Label wrapper)
- Exact pixel offset for indicator position above player
- HUD slot pixel size and spacing
- Dimming implementation for empty slots (modulate vs separate StyleBox)
- Whether HUD strip is a new scene file or defined inline in world.tscn

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CMBT-03 | Player's `hit()` attack uses the equipped weapon's damage value | `attack.damage` is `@export var damage: int` on an `Attack` node; mutating it at call time in `hit()` is safe because `HitboxComponent._on_area_entered()` reads `area.get_parent().attack` several animation frames later |
| CMBT-04 | Player falls back to fist attack when no weapon is equipped | Guard: `if equipment_data.weapon != null:` — when null, `attack.damage` is left at the Inspector-configured fist value; no branch needed for the no-weapon path |
| CMBT-05 | A placeholder visual indicator appears on the player when a weapon is equipped | WeaponIndicator child on player.tscn; subscribes to `equipment_data.equipment_changed`; texture-or-label pattern from `collectable.gd` |
| HUD-01 | Weapon and tool slots visible at all times independent of inventory state | New `hud_strip` scene added as sibling of InventoryUI in CanvasLayer; visibility is unconditional (never hidden by inventory toggle) |
| HUD-02 | Equipment slots display the equipped item's icon when occupied | `_on_equipment_changed()` handler reads `_equipment_data.weapon` / `_equipment_data.tool`; updates slot texture or label; same texture-or-label logic |
</phase_requirements>

---

## Standard Stack

### Core (all already in project — no new installs)

| Component | Where defined | Role in Phase 7 |
|-----------|--------------|-----------------|
| `Attack` resource | `scripts/attack.gd` | Mutable `damage: int` field; `hit()` overwrites this |
| `EquipmentData` resource | `scripts/resources/equipment_data.gd` | `weapon` field; `equipment_changed` signal |
| `WeaponItem` resource | `scripts/resources/weapon_item.gd` | `damage: float` field read by `hit()` |
| GDScript signal pattern | project-wide | `equipment_changed.connect(_on_equipment_changed)` |
| `Control` node | Godot built-in | Base for HUD strip scene |
| `PanelContainer` or `Panel` | Godot built-in | Slot frame for HUD |
| `TextureRect` | Godot built-in | Displays item texture in slot / indicator |
| `Label` | Godot built-in | Fallback text in slot / indicator |
| `HBoxContainer` | Godot built-in | Lays out weapon slot + tool slot side by side |
| `VBoxContainer` | Godot built-in | Stacks slot box + slot label ("W"/"T") |

**Installation:** None required. All Godot built-ins and existing project resources.

---

## Architecture Patterns

### Pattern 1: hit() — read at call time (CMBT-03, CMBT-04)

**What:** `hit()` is called from `move()` when the "hit" action is pressed, immediately
before `animation_state.travel("Fist")`. It reads `equipment_data.weapon` once, mutates
`attack.damage` if a weapon is present, then returns.

**Why it is safe:** `HitboxComponent._on_area_entered()` is called when the Fist
`Area2D` enters an enemy's hitbox. This happens on the physics frame where the animation
track enables the collision shape — several frames after `hit()` executes. At that point
`attack.damage` already holds the correct value.

**Why NOT via subscription:** Subscribing to `equipment_changed` and caching damage
would create a timing gap: if the signal fires between a button press and the hitbox
read, the cached value could be stale. Reading at call time is atomic relative to the
physics step.

```gdscript
# In player.gd — confirmed pattern, reads directly from equipment_data
func hit() -> void:
    if equipment_data != null and equipment_data.weapon != null:
        attack.damage = int(equipment_data.weapon.damage)
    # else: attack.damage retains its Inspector-configured fist value
```

```gdscript
# In move() — existing location, add hit() call before travel("Fist")
if Input.is_action_just_pressed("hit"):
    hit()
    current_state = PlayerStates.HIT
    animation_state.travel("Fist")
```

### Pattern 2: set_equipment_data() injection (HUD-01, HUD-02)

**What:** The HUD strip script receives `EquipmentData` via a `set_equipment_data()`
method called from `world.gd _ready()`. It connects to `equipment_changed` in that
setter, matching the `inventory_ui.gd` pattern exactly.

```gdscript
# hud_strip.gd
var _equipment_data: EquipmentData = null

func set_equipment_data(ed: EquipmentData) -> void:
    _equipment_data = ed
    ed.equipment_changed.connect(_on_equipment_changed)
    _on_equipment_changed()  # Paint initial state immediately


func _on_equipment_changed() -> void:
    _refresh_slot(_weapon_slot, _equipment_data.weapon if _equipment_data else null)
    _refresh_slot(_tool_slot, _equipment_data.tool if _equipment_data else null)
```

### Pattern 3: Texture-or-label display (HUD-02, CMBT-05)

**What:** Already established in `collectable.gd` and `sword.gd`. If the item has a
non-null `texture`, display it in a `TextureRect`; otherwise show `item.name` in a
`Label`. This is the canonical pattern for all item display in this codebase.

```gdscript
# Reuse verbatim — from collectable.gd lines 11-15
if item and item.texture:
    texture_rect.texture = item.texture
    texture_rect.visible = true
    label.visible = false
elif item:
    label.text = item.name
    label.visible = true
    texture_rect.visible = false
else:
    # empty slot
    texture_rect.visible = false
    label.visible = false
```

### Pattern 4: WeaponIndicator child on Player (CMBT-05)

**What:** A child node added to `player.tscn`. Recommended node: a `Node2D` container
holding a `TextureRect` (for texture path) and a `Label` (for name fallback), positioned
above the player with a `position` offset of approximately `Vector2(0, -24)`.

```gdscript
# weapon_indicator.gd (or inline in player.gd via @onready ref)
func _on_equipment_changed() -> void:
    var weapon = _equipment_data.weapon if _equipment_data else null
    visible = weapon != null
    if weapon == null:
        return
    if weapon.texture:
        _texture_rect.texture = weapon.texture
        _texture_rect.visible = true
        _label.visible = false
    else:
        _label.text = weapon.name
        _label.visible = true
        _texture_rect.visible = false
```

### Pattern 5: world.gd _ready() as single wiring point

**What:** All scene-graph wiring lives in `world.gd _ready()`. New HUD strip wiring
follows the same structure as `inventory_ui` wiring.

```gdscript
# world.gd _ready() — add after existing inventory_ui wiring
hud_strip.set_equipment_data(player.equipment_data)
```

### Anti-Patterns to Avoid

- **Subscribe to equipment_changed for damage caching:** Creates stale-value risk between
  equip and attack. Read at call time instead (locked decision).
- **Parent HUD strip under InventoryUI:** Makes HUD hidden when inventory closes.
  It must be a sibling in CanvasLayer.
- **Hardcode damage value in player.gd:** The weapon's damage lives on `WeaponItem.damage`.
  Always read from the resource.
- **Casting `weapon.damage` to int inside EquipmentData:** Do the cast in `hit()` where
  context is clear; EquipmentData remains a pure data resource.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Item texture display | Custom render logic | TextureRect + Label (existing pattern) | Already proven; consistent with all other item display |
| Signal subscription pattern | Custom observer | GDScript `signal.connect()` | Built-in; zero boilerplate |
| HUD layout | Absolute positioning math | HBoxContainer + VBoxContainer | Godot containers handle resize/anchor automatically |
| Slot dimming | Custom shader | `modulate = Color(0.4, 0.4, 0.4)` | One-liner; no shader compilation needed |

---

## Common Pitfalls

### Pitfall 1: attack.damage type mismatch

**What goes wrong:** `WeaponItem.damage` is `float`; `Attack.damage` is `int`. Direct
assignment `attack.damage = equipment_data.weapon.damage` causes a type error in
strict-mode GDScript.

**How to avoid:** Cast explicitly: `attack.damage = int(equipment_data.weapon.damage)`
in `hit()`.

**Warning signs:** Lint error "Cannot assign float to int variable" at the assignment line.

### Pitfall 2: HUD strip receiving null equipment_data at startup

**What goes wrong:** If `hud_strip.set_equipment_data()` is called before `player._ready()`
has run, `player.equipment_data` may not yet be initialized (depending on node order).

**How to avoid:** `world.gd _ready()` runs after all children's `_ready()`. Godot
guarantees bottom-up `_ready()` execution, so `player.equipment_data` is valid by the
time `world.gd _ready()` runs. No deferred call needed.

**Warning signs:** Null reference error on `equipment_data.equipment_changed.connect()`.

### Pitfall 3: WeaponIndicator position not visible above player sprite

**What goes wrong:** The indicator node is added as a child of the Player's root
`CharacterBody2D`, but the player sprite is offset. A `position` of `Vector2(0, 0)`
places the indicator at the Player's origin, which may overlap the sprite.

**How to avoid:** Use `position = Vector2(0, -24)` as a starting offset; adjust in the
Inspector after the first run.

**Warning signs:** Indicator is invisible or hidden under the player sprite in-game.

### Pitfall 4: equipment_changed signal fires before indicator node is in scene tree

**What goes wrong:** If the Player's `_ready()` connects to `equipment_changed` and
`equipment_data` already has a weapon set (e.g., from an Inspector preset), the signal
may have already fired before the indicator node's `@onready` vars are populated.

**How to avoid:** Call `_on_equipment_changed()` explicitly at the end of `_ready()` to
paint the initial state regardless of signal history. This matches the `set_equipment_data`
pattern used in `inventory_ui.gd` and the proposed HUD strip.

### Pitfall 5: HUD strip visible property toggled by inventory input handler

**What goes wrong:** `inventory_ui.gd _input()` toggles `visible` on the InventoryUI
Control. If the HUD strip is accidentally placed as a child of InventoryUI, its visibility
is inherited.

**How to avoid:** Add HUD strip as a direct child of CanvasLayer (sibling of InventoryUI,
NOT child). Confirmed by locked decision and existing world.tscn structure.

---

## Code Examples

### Verified: hitbox_component.gd — how attack is read at impact

```gdscript
# Source: scripts/hitbox_component.gd lines 43-47
func _on_area_entered(area):
    if "attack" in area.get_parent():
        var attack = area.get_parent().attack
        take_damage(attack)
        knocked_back.emit(area.get_parent().global_position)
```

`area.get_parent()` here is the Player node. `Player.attack` is the same `Attack`
resource object whose `damage` field `hit()` mutates. Because `hit()` runs before the
animation drives the hitbox, the mutated value is read correctly.

### Verified: inventory_ui.gd — set_equipment_data injection pattern

```gdscript
# Source: scripts/inventory_ui.gd lines 61-63
func set_equipment_data(ed: EquipmentData) -> void:
    _equipment_data = ed
```

Note: `inventory_ui` does not connect to `equipment_changed` — HUD strip must. The
pattern to follow: store the reference AND connect in `set_equipment_data`.

### Verified: world.gd — established _ready() wiring point

```gdscript
# Source: scripts/world.gd lines 12-18
func _ready() -> void:
    inventory_ui.set_inventory(player.inventory)
    inventory_ui.set_player(player)
    inventory_ui.set_equipment_data(player.equipment_data)
    player.inventory.insert_rejected.connect(_on_insert_rejected)
    player.item_collected.connect(_on_item_collected)
    # ...
```

### Verified: collectable.gd — texture-or-label (canonical pattern)

```gdscript
# Source: scripts/collectable.gd lines 11-15
if item and item.texture:
    $Sprite2D.texture = item.texture
elif item:
    $Label.text = item.name
    $Label.visible = true
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `hit()` is a `pass` stub | Mutate `attack.damage` at call time | Phase 7 implementation |
| No HUD strip | Always-visible CanvasLayer sibling | Phase 7 implementation |
| No weapon indicator on player | WeaponIndicator child node | Phase 7 implementation |

**Confirmed current:**
- `EquipmentData.equipment_changed` signal is emitted on every equip/unequip (verified in `equipment_data.gd`)
- `Attack.damage` is a plain `int` field with no setter guard (verified in `attack.gd`)
- `inventory_ui.gd set_equipment_data()` does not connect to `equipment_changed` — the HUD strip must add that connection itself

---

## Open Questions

1. **attack.damage timing — MEDIUM confidence runtime risk**
   - What we know: `hit()` mutates `attack.damage` synchronously; `_on_area_entered()` fires on a
     later physics frame driven by the animation collision track (several frames later)
   - What's unclear: exact frame gap is not verified by a unit test — only by reading animation
     behaviour description in CONTEXT.md
   - Recommendation: Add a unit test asserting `attack.damage` equals `weapon.damage` after
     `hit()` is called with a weapon equipped. This is the safest way to lock the contract without
     needing a running scene.

2. **HUD strip: new scene file vs inline in world.tscn**
   - What we know: Claude's discretion; both approaches work
   - Recommendation: Create `scenes/hud_strip.tscn` + `scripts/hud_strip.gd` as a new scene.
     Keeps scene files small and makes the HUD reusable/testable in isolation. Matches the
     established pattern where every significant UI node has its own scene file.

3. **Player indicator: Sprite2D vs TextureRect**
   - What we know: Claude's discretion; both can display textures
   - Recommendation: Use a `Node2D` parent containing a `TextureRect` + `Label` sibling pair,
     controlled by the texture-or-label logic. `TextureRect` is easier to size than `Sprite2D`
     in a 2D-UI hybrid context and does not require setting the offset manually.

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
| CMBT-03 | `hit()` sets `attack.damage` to `weapon.damage` when weapon equipped | unit | `make test` (test_player_combat.gd) | ❌ Wave 0 |
| CMBT-04 | `hit()` leaves `attack.damage` unchanged when no weapon equipped | unit | `make test` (test_player_combat.gd) | ❌ Wave 0 |
| CMBT-05 | WeaponIndicator visible when weapon equipped, hidden when not | manual/smoke | — | N/A — scene node visibility |
| HUD-01 | HUD strip always visible regardless of inventory state | manual/smoke | — | N/A — CanvasLayer visibility |
| HUD-02 | HUD slot shows correct texture or label when equipment changes | manual/smoke | — | N/A — UI rendering |

**Note on CMBT-05, HUD-01, HUD-02:** These require a running scene tree and visual
inspection. They are manual verification items. The `PlayerStub` pattern (overriding
`_ready()`) from `test_player_state.gd` can be reused for combat unit tests without
needing a scene.

### Sampling Rate

- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/unit/test_player_combat.gd` — covers CMBT-03 and CMBT-04 using `PlayerStub`
  pattern from `test_player_state.gd`

*(HUD and indicator tests are manual-only — no file gaps for those)*

---

## Sources

### Primary (HIGH confidence)

- `scripts/player.gd` — `hit()` stub, `attack` export, `equipment_data` export, `move()` attack keypress; read directly
- `scripts/attack.gd` — `damage: int` and `cooldown: float` fields; read directly
- `scripts/hitbox_component.gd` — `_on_area_entered()` reads `area.get_parent().attack`; confirms timing safety; read directly
- `scripts/resources/equipment_data.gd` — `equipment_changed` signal, `weapon` field, `equip_weapon()`; read directly
- `scripts/resources/weapon_item.gd` — `damage: float` field; read directly
- `scripts/collectable.gd` — canonical texture-or-label pattern; read directly
- `scripts/sword.gd` — texture-or-label variant on weapon scene; read directly
- `scripts/world.gd` — `_ready()` wiring pattern, `CanvasLayer` node references; read directly
- `scripts/inventory_ui.gd` — `set_equipment_data()` injection pattern, signal handling; read directly
- `scenes/world.tscn` — CanvasLayer structure confirmed (InventoryUI is direct child of CanvasLayer at line 1957)
- `.planning/phases/07-combat-wiring-hud-strip/07-CONTEXT.md` — locked decisions, integration points
- `.planning/config.json` — `nyquist_validation: true` confirmed

### Secondary (MEDIUM confidence)

- STATE.md blocker note: "attack.damage mutation timing is MEDIUM confidence — needs runtime verification" — confirms the open question is known and accepted

### Tertiary (LOW confidence)

- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components read directly from source files; no new dependencies
- Architecture: HIGH — patterns are verbatim from existing scripts; no speculation
- Pitfalls: HIGH (type mismatch, null guard, indicator position) / MEDIUM (timing) — timing is flagged
- Validation: HIGH — GUT framework confirmed installed; test pattern (`PlayerStub`) exists and verified

**Research date:** 2026-03-19
**Valid until:** 2026-04-19 (stable codebase; no fast-moving dependencies)
