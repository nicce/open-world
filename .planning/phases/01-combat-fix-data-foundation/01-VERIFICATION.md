---
phase: 01-combat-fix-data-foundation
verified: 2026-03-10T19:50:00Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Open Godot, run res://scenes/world.tscn with F5, move player near a snake, press X or left mouse button to attack"
    expected: "Player returns to MOVE state immediately after the Fist animation completes — player can move again without any input lag or lockout"
    why_human: "animation_finished signal fires with animation names that were low-confidence during research (FistNorth/FistSouth/FistEast/FistWest). Code is wired correctly but correct StringName values can only be confirmed at runtime in the Godot editor"
  - test: "While in Godot with the game running, land a hit on a snake"
    expected: "Snake visibly recoils away from the player — a clear velocity impulse, not a static flash"
    why_human: "Physics knockback requires scene tree and CharacterBody2D move_and_slide — unit tests confirm the math but visual recoil magnitude and feel require runtime observation"
---

# Phase 1: Combat Fix + Data Foundation Verification Report

**Phase Goal:** Player can fight without locking up and the inventory data model is correct for all downstream work
**Verified:** 2026-03-10T19:50:00Z
**Status:** human_needed — all automated checks pass; 2 runtime visual behaviors need human confirmation
**Re-verification:** No — initial verification

## Goal Achievement

### Success Criteria from ROADMAP.md

| # | Criterion | Status | Evidence |
|---|-----------|--------|---------|
| 1 | Player can attack and immediately move again — no state lockout after HIT animation | ? HUMAN NEEDED | Code: `_on_animation_finished` -> `on_attack_animation_finished` -> `on_player_state_reset` chain exists and wired; unit test passes; animation name strings low-confidence |
| 2 | Enemies visibly recoil when the player lands a hit | ? HUMAN NEEDED | Code: `apply_knockback` + `_physics_process` decay exist and wired via signal; unit tests pass; visual magnitude needs runtime check |
| 3 | Each item has stable `id` field; stacking and removal use `id` for comparison | VERIFIED | `item.gd` line 5: `@export var id: StringName`; `inventory_slot.gd` line 33: `return item.id == other.id`; `inventory.gd` lines 58, 67: `slot.item.id == item.id` |
| 4 | Loading a scene does not bleed inventory state — inventory is deep-copied on load | VERIFIED | `player.gd` line 22: `inventory = inventory.clone()`; `inventory.gd` lines 79-88: `clone()` manually deep-copies all slots |
| 5 | Adding items at the exact weight limit accepts the item without off-by-one rejection | VERIFIED | `inventory.gd` lines 29, 41: `floori(remaining_weight() / item.weight)`; test passes 70/70 |

**Score:** 5/5 criteria — 3 fully automated, 2 require human runtime confirmation

### Observable Truths (derived from Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | on_attack_animation_finished() resets current_state to MOVE | VERIFIED | `test_player_state.gd` 3/3 pass; method exists at player.gd lines 41-42 |
| 2 | animation_finished signal is connected to the handler in _ready() | VERIFIED | `player.gd` line 23: `animation_tree.animation_finished.connect(_on_animation_finished)` |
| 3 | Fist animation names correctly filter the state reset | ? HUMAN NEEDED | Code filters `[&"FistNorth", &"FistSouth", &"FistEast", &"FistWest"]` — research marked these low-confidence |
| 4 | apply_knockback() sets knockback_velocity away from attacker | VERIFIED | `snake.gd` lines 30-32; test_snake.gd 3/3 pass |
| 5 | Snake knockback decays in _physics_process via move_toward | VERIFIED | `snake.gd` lines 19-27: decay threshold 1.0, `move_toward(Vector2.ZERO, knockback_force * delta * 8)` |
| 6 | HitboxComponent emits knocked_back signal with attacker position | VERIFIED | `hitbox_component.gd` line 4: `signal knocked_back(from_position: Vector2)`; line 47: `knocked_back.emit(area.get_parent().global_position)` |
| 7 | Snake connects knocked_back signal in _ready() | VERIFIED | `snake.gd` line 16: `$HitboxComponent.knocked_back.connect(_on_knocked_back)` |
| 8 | item.gd has id: StringName field | VERIFIED | `item.gd` line 5: `@export var id: StringName` |
| 9 | can_stack() uses item.id not item.name | VERIFIED | `inventory_slot.gd` line 33: `return item.id == other.id` |
| 10 | remove() and get_item_count() use id comparison | VERIFIED | `inventory.gd` lines 58, 67 |
| 11 | inventory.clone() produces isolated deep copy | VERIFIED | `inventory.gd` lines 79-88; test_duplicate_true_isolates_slots and test_duplicate_slots_are_different_references both pass |
| 12 | player._ready() calls inventory.clone() | VERIFIED | `player.gd` line 22 |
| 13 | floori() at both weight budget sites | VERIFIED | `inventory.gd` lines 29, 41 — confirmed no `int()` remains |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/unit/test_player_state.gd` | Failing test scaffold for CMBT-01 | VERIFIED | 3 tests; all 3 pass after Plan 02 implementation |
| `tests/unit/test_snake.gd` | Failing test scaffold for CMBT-02 | VERIFIED | 3 tests; all 3 pass after Plan 02 implementation |
| `tests/unit/test_inventory_slot.gd` | DATA-01 tests (id-based stacking) | VERIFIED | 18 tests total including test_cannot_stack_same_name_different_id and test_can_stack_same_id |
| `tests/unit/test_inventory.gd` | DATA-02 and DATA-03 tests | VERIFIED | Includes test_duplicate_true_isolates_slots, test_duplicate_slots_are_different_references, test_insert_at_exact_weight_limit_accepts_item |
| `scripts/player.gd` | _ready() with signal connection + clone(); _on_animation_finished(); on_attack_animation_finished() | VERIFIED | All three present at lines 21-23, 36-38, 41-42 |
| `scripts/hitbox_component.gd` | knocked_back signal; emit in _on_area_entered | VERIFIED | Signal at line 4; emit at line 47 |
| `scripts/snake.gd` | apply_knockback(); knockback_velocity decay; _ready() connection | VERIFIED | apply_knockback at lines 30-32; decay in _physics_process lines 19-27; connection at line 16 |
| `scripts/resources/item.gd` | @export var id: StringName | VERIFIED | Line 5 |
| `scripts/resources/inventory_slot.gd` | can_stack() uses item.id | VERIFIED | Line 33 |
| `scripts/resources/inventory.gd` | id comparisons in remove()/get_item_count(); floori() at both sites; clone() method | VERIFIED | Lines 29, 41 (floori); lines 58, 67 (id); lines 79-88 (clone) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `player.gd:_ready()` | `_on_animation_finished()` | `animation_tree.animation_finished.connect(...)` | VERIFIED | Line 23 — connects signal |
| `player.gd:_on_animation_finished()` | `on_attack_animation_finished()` | Fist animation name filter | VERIFIED (code) / ? (runtime) | Lines 36-38 — code path correct; animation names unconfirmed at runtime |
| `player.gd:on_attack_animation_finished()` | `on_player_state_reset()` | Direct call | VERIFIED | Line 42 |
| `hitbox_component.gd:_on_area_entered()` | `knocked_back` signal | `knocked_back.emit(...)` | VERIFIED | Line 47 |
| `snake.gd:_ready()` | `_on_knocked_back()` | `$HitboxComponent.knocked_back.connect(...)` | VERIFIED | Line 16 |
| `snake.gd:_on_knocked_back()` | `apply_knockback()` | Direct call | VERIFIED | Line 36 |
| `inventory_slot.gd:can_stack()` | `item.gd:id` | `item.id == other.id` | VERIFIED | Line 33 |
| `inventory.gd:remove()` | `item.gd:id` | `slot.item.id == item.id` | VERIFIED | Line 58 |
| `player.gd:_ready()` | `inventory.clone()` | `inventory = inventory.clone()` | VERIFIED | Line 22 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| CMBT-01 | 01-01, 01-02 | Player can attack and return to MOVE state | VERIFIED (automated) / ? (runtime) | Unit test 3/3 pass; animation signal wired; runtime names need human check |
| CMBT-02 | 01-01, 01-02 | Enemies knocked back when struck | VERIFIED (automated) / ? (runtime) | Unit test 3/3 pass; knockback logic wired; visual recoil needs human check |
| DATA-01 | 01-01, 01-03 | Stable id: StringName for item identity | VERIFIED | item.gd has id; can_stack, remove, get_item_count all use id; tests pass |
| DATA-02 | 01-01, 01-03 | Deep-copy inventory on scene load | VERIFIED | player.gd calls inventory.clone(); clone() manually copies slots; tests pass |
| DATA-03 | 01-01, 01-03 | floori() for weight budget calculation | VERIFIED | Both sites in inventory.gd confirmed; test passes |

All 5 requirements declared in the phase are accounted for. No orphaned requirements found — REQUIREMENTS.md Traceability table maps exactly CMBT-01, CMBT-02, DATA-01, DATA-02, DATA-03 to Phase 1.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scripts/player.gd` | 73 | `hit()` method with TODO comment ("TODO how do we handle different equipped weapons?") | Info | Non-blocking; method body is intentionally empty (no-op); TODO is a design note for future phases |
| `scripts/hitbox_component.gd` | 6 | `@export var health_component: HealthComponent  # TODO replace with signal?` | Info | Non-blocking; existing TODO predates this phase; component works correctly as-is |

No blockers or warnings. Both TODOs are pre-existing design notes, not stub implementations.

### Deviation from Plan: clone() vs duplicate(true)

Plan 01-03 specified `inventory.duplicate(true)` as the DATA-02 fix. The implementation used `inventory.clone()` instead. This deviation is valid and correctly documented in the SUMMARY:

Godot 4.3 does not allow overriding the native `duplicate()` method on Resource subclasses. The `clone()` method achieves the same semantic goal — a fully independent deep copy where mutating a slot in the copy does not affect the original. Tests confirm the behavior is correct. The REQUIREMENTS.md description of DATA-02 mentions `duplicate(true)` as the mechanism, but the requirement intent (isolated copy on load) is satisfied.

### Test Suite Results

| Metric | Value |
|--------|-------|
| Scripts | 6 |
| Tests | 70 |
| Passing | 70 |
| Failing | 0 |
| Regressions | 0 |
| make lint | Passed — no problems found |
| make format-check | Passed — 22 files unchanged |

All commits documented in SUMMARYs are present and verified in git history:
- `9848c2c` — CMBT-01, CMBT-02 test scaffolds
- `a99b557` — DATA-01, DATA-02, DATA-03 test scaffolds
- `1756739` — CMBT-01 fix
- `c080bf6` — CMBT-02 fix
- `a152a96` — DATA-01 implementation
- `193d98c` — DATA-02 and DATA-03 implementation

### Human Verification Required

#### 1. Player state no longer locks after attack

**Test:** Open Godot Editor, open `res://scenes/world.tscn`, press F5. Move the player near a snake. Press X (or left mouse button) to attack. Attack multiple times in quick succession.

**Expected:** Player returns to MOVE state immediately when the Fist animation completes — you can move in any direction right after swinging. Player should never get stuck frozen after attacking.

**Why human:** The code filters `animation_finished` by `[&"FistNorth", &"FistSouth", &"FistEast", &"FistWest"]`. The PLAN noted these names were "low-confidence, verify at runtime." If the AnimationTree blend space emits different string names, the filter will never match and the player will still lock. Unit tests bypass this by calling `on_attack_animation_finished()` directly and do not exercise the signal name matching. If still locked: add a temporary `print(anim_name)` inside `_on_animation_finished()` to see what name is actually emitted, then update the filter array in `player.gd` lines 37-38.

#### 2. Snake visibly recoils on hit

**Test:** In the same Godot run session, position the player adjacent to a snake and land a hit with X/left mouse.

**Expected:** The snake moves visibly away from the player position — a clear directional impulse, not just a damage flash. The recoil should last roughly 0.5 seconds before the snake returns to idle.

**Why human:** `apply_knockback()` math and `_physics_process` decay are unit-tested correctly. However, the actual knockback force (120.0 px/s default) and decay multiplier (knockback_force * delta * 8) may produce a recoil that is too subtle or too strong for a satisfying feel. Only runtime observation in Godot can confirm the visual quality.

---

_Verified: 2026-03-10T19:50:00Z_
_Verifier: Claude (gsd-verifier)_
