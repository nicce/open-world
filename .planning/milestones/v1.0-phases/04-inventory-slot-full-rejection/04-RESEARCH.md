# Phase 4: Inventory Slot-Full Rejection — Research

**Researched:** 2026-03-12
**Domain:** GDScript inventory data logic / signal emission
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INV-02 | Inventory panel shows current weight vs max capacity; player sees a rejection message when inventory is full or overweight | Root cause identified in `inventory.gd:insert()` lines 55-58; fix is a single conditional branch; HUD wiring already in place |
</phase_requirements>

---

## Summary

Phase 4 is a targeted bug fix with a surgical scope. The entire gap traces to a single missing branch in `scripts/resources/inventory.gd:insert()`. When `insert()` exhausts all 15 slots but the weight budget still has room, the function returns `remaining > 0` silently — it never emits `insert_rejected`. The downstream HUD wiring (`world.gd`, `RejectionLabel`) is already complete and tested for the weight-overflow path; it just needs the signal to fire.

The fix requires:
1. One additional conditional branch in `inventory.gd:insert()` to detect the slot-full-but-weight-ok state and emit `insert_rejected`.
2. One new GUT unit test in `tests/unit/test_inventory.gd` asserting `insert_rejected` fires when slots are full but weight remains.
3. A regression test confirming weight-overflow rejection is unaffected.

No new scenes, no UI changes, no new signals, no new node wiring. This is the smallest possible fix that closes INV-02.

**Primary recommendation:** Add a slot-full check branch immediately after the existing `weight_budget <= 0` branch in `inventory.gd:insert()`, then add one GUT signal test to cover the new code path.

---

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|---|---|---|---|
| GDScript (Godot 4) | 4.2+ | Logic implementation | Project language |
| GUT | 9.3.0 | Unit testing | Project test framework (see Makefile) |
| gdtoolkit | 4.* | Lint + format | Project quality gate |

No new libraries needed. This phase touches one existing file.

**Commands:**
```bash
make lint
make format-check
make test
```

---

## Architecture Patterns

### Relevant Project Structure

```
scripts/
  resources/
    inventory.gd          # WHERE THE BUG LIVES — lines 55-58
    inventory_slot.gd     # Slot data model (is_empty, is_full)
scripts/
  world.gd                # Already wired: insert_rejected -> _on_insert_rejected
tests/unit/
  test_inventory.gd       # WHERE THE NEW TEST GOES
```

### Pattern: Signal Emission in insert()

The existing `insert()` tail (lines 52-59) already establishes the pattern:

```gdscript
var inserted = amount - remaining
if inserted > 0:
    inventory_changed.emit()
elif remaining > 0:
    var weight_budget = floori(remaining_weight() / item.weight)
    if weight_budget <= 0:
        insert_rejected.emit()
```

The slot-full branch belongs inside the same `elif remaining > 0` block, as a second condition when `weight_budget > 0` but no empty or stackable slot was found:

```gdscript
elif remaining > 0:
    var weight_budget = floori(remaining_weight() / item.weight)
    if weight_budget <= 0:
        insert_rejected.emit()
    else:
        # Slots exhausted (weight budget available but no empty slot)
        insert_rejected.emit()
```

Which can be simplified to:

```gdscript
elif remaining > 0:
    insert_rejected.emit()
```

**Why the simplification is safe:** The `elif remaining > 0` branch is only reached when `inserted == 0` (nothing went in). If nothing was inserted and there are items remaining, the insert failed — regardless of cause (weight or slots). Emitting `insert_rejected` in both cases is the correct behavior for INV-02 ("full or overweight"). The original two-branch structure (`weight_budget <= 0` guard) was defensive over-engineering that missed the slot-full path.

### Pattern: GUT Signal Test

Existing signal test pattern from `test_inventory.gd` (lines 307-314):

```gdscript
func test_insert_rejected_emitted_when_weight_blocks_all() -> void:
    var inv := _make_inventory(5, 5.0)
    var too_heavy := _make_item("Boulder", 10.0)
    watch_signals(inv)
    inv.insert(too_heavy, 1)
    assert_signal_emitted(inv, "insert_rejected")
    assert_signal_emit_count(inv, "insert_rejected", 1)
```

The new test follows this exact pattern, using `_make_inventory(2)` with two slots both filled, then inserting a third item with ample weight remaining.

### Anti-Patterns to Avoid

- **Narrowing the fix to only the weight branch:** The current guard `if weight_budget <= 0` is the root problem — do not preserve it as the sole emission trigger.
- **Changing the signal name or adding a new signal:** `insert_rejected` is already wired in `world.gd`. A new signal would require re-wiring with no benefit.
- **Modifying `world.gd` or `inventory_ui.gd`:** HUD wiring is already correct. The bug is data-layer only.
- **Modifying `InventorySlot.is_full()`:** The slot logic is correct; the bug is in how `insert()` diagnoses the failure reason.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting slot exhaustion | Custom `has_empty_slot()` traversal | Read `remaining > 0` after loops | `insert()` already tracks `remaining`; when both loops complete with `remaining > 0` and `inserted == 0`, slots are exhausted by definition |
| New "slot full" signal | `insert_slot_full` signal | Existing `insert_rejected` | HUD already wired to `insert_rejected`; adding a second signal creates duplicate wiring with no new behavior |

---

## Common Pitfalls

### Pitfall 1: Partial fix — only one code path gets the emit

**What goes wrong:** Developer adds `insert_rejected.emit()` only to the stacking loop exit, missing the empty-slot loop.
**Why it happens:** The two loops (stack → empty) look like independent code paths.
**How to avoid:** Simplify to `elif remaining > 0: insert_rejected.emit()` — executed once after both loops complete, covering both failure causes.
**Warning signs:** Test for slot-full-stackable-item passes but slot-full-non-stackable-item does not.

### Pitfall 2: Breaking weight-overflow regression

**What goes wrong:** Removing the `weight_budget <= 0` guard without verifying the `elif remaining > 0` path also covers weight-blocked cases.
**Why it happens:** The simplified form covers ALL insert failures — including weight-blocked ones — because weight-blocked also produces `inserted == 0` and `remaining > 0`.
**How to avoid:** Run the existing test `test_insert_rejected_emitted_when_weight_blocks_all` after the change. It should still pass.
**Warning signs:** Test suite failure on the existing weight-rejection test.

### Pitfall 3: Emitting `insert_rejected` on partial inserts

**What goes wrong:** Some items inserted, some rejected — signal fires when it should not.
**Why it happens:** The condition is checked before confirming nothing was inserted.
**How to avoid:** The `elif remaining > 0` is already inside an `elif` that only runs when `inserted == 0`. Partial inserts have `inserted > 0` so they fall into the `if inserted > 0` branch and never reach the rejection branch.

### Pitfall 4: Forgetting `make format-check` before commit

**What goes wrong:** Lint passes but format check fails CI.
**Why it happens:** gdformat enforces whitespace and line length conventions that gdlint does not check.
**How to avoid:** Always run `make format-check` (or `make format`) before committing — project memory requirement.

---

## Code Examples

### Current Bug Location

```gdscript
# scripts/resources/inventory.gd  lines 52-60 (current, BUGGY)
var inserted = amount - remaining
if inserted > 0:
    inventory_changed.emit()
elif remaining > 0:
    var weight_budget = floori(remaining_weight() / item.weight)
    if weight_budget <= 0:
        insert_rejected.emit()   # <-- only fires on weight-blocked, not slot-full

return remaining
```

### Minimal Correct Fix

```gdscript
# scripts/resources/inventory.gd  lines 52-58 (after fix)
var inserted = amount - remaining
if inserted > 0:
    inventory_changed.emit()
elif remaining > 0:
    insert_rejected.emit()   # fires on ANY complete failure (weight OR slot-full)

return remaining
```

### New Test to Add (in test_inventory.gd)

```gdscript
func test_insert_rejected_emitted_when_slots_full_but_weight_allows() -> void:
    # 2 slots, 100 kg max — fill both slots, then try a third light item.
    var inv := _make_inventory(2, 100.0)
    var wood := _make_item("Wood")
    inv.insert(wood, 10)   # fills slot 0 to max_stack (10)
    inv.insert(wood, 10)   # fills slot 1 to max_stack (10)
    # Weight used: 20 kg of 100 kg — plenty of budget remains.
    var new_item := _make_item("Stone")
    watch_signals(inv)
    inv.insert(new_item, 1)
    assert_signal_emitted(inv, "insert_rejected")
    assert_signal_emit_count(inv, "insert_rejected", 1)
```

**Note on test setup:** `_make_inventory(2)` creates 2 slots (default max_stack=10 each). Two insertions of 10 fill both slots. `Stone` is a different item id so it cannot stack — confirming no open slot is found.

### Regression Test to Verify (already exists)

```gdscript
# This test MUST still pass after the fix:
func test_insert_rejected_emitted_when_weight_blocks_all() -> void:
    var inv := _make_inventory(5, 5.0)
    var too_heavy := _make_item("Boulder", 10.0)
    watch_signals(inv)
    inv.insert(too_heavy, 1)
    assert_signal_emitted(inv, "insert_rejected")
    assert_signal_emit_count(inv, "insert_rejected", 1)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| `insert_rejected` only on weight-block | `insert_rejected` on any complete failure | Phase 4 | Closes INV-02 slot-full gap |

---

## Open Questions

None. The bug, fix location, test pattern, and regression surface are all fully identified.

---

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | GUT 9.3.0 |
| Config file | `.gutconfig.json` (project root) / configured via `gut_cmdln.gd` args in Makefile |
| Quick run command | `make test` |
| Full suite command | `make test` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INV-02 (slot-full path) | `insert_rejected` emitted when slots full, weight allows | unit | `make test` | ❌ Wave 0 — add to `tests/unit/test_inventory.gd` |
| INV-02 (weight-overflow regression) | `insert_rejected` still emitted when item too heavy | unit | `make test` | Already exists in `test_inventory.gd:307` |

### Sampling Rate

- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make lint && make format-check && make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/unit/test_inventory.gd` — add `test_insert_rejected_emitted_when_slots_full_but_weight_allows()` covering INV-02 slot-full path

*(All other test infrastructure is in place. Only the new signal assertion test is missing.)*

---

## Sources

### Primary (HIGH confidence)

- `scripts/resources/inventory.gd` — direct code inspection of the bug location (lines 55-58) and the insert logic
- `scripts/world.gd` — confirmed HUD wiring: `insert_rejected` already connected to `_on_insert_rejected`
- `tests/unit/test_inventory.gd` — confirmed existing signal test patterns (GUT `watch_signals` / `assert_signal_emitted`)
- `.planning/v1.0-MILESTONE-AUDIT.md` — authoritative bug description with exact file + line references
- `scripts/resources/inventory_slot.gd` — confirmed `is_empty()` / `is_full()` behavior; no change needed

### Secondary (MEDIUM confidence)

- `.planning/STATE.md` decision log — confirmed "insert_rejected only emitted when weight_budget <= 0 (weight-blocked), not when slots are full" was a known gap logged during Phase 2

---

## Metadata

**Confidence breakdown:**
- Bug location: HIGH — confirmed by code inspection and audit
- Fix approach: HIGH — logic is straightforward; simplified `elif remaining > 0` covers both failure modes
- Test pattern: HIGH — existing GUT signal tests in same file provide exact template
- Regression surface: HIGH — one existing test fully covers the weight-overflow path

**Research date:** 2026-03-12
**Valid until:** 2026-04-12 (stable domain; GDScript and GUT APIs are not changing)
