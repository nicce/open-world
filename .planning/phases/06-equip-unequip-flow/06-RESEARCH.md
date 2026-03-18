# Phase 6: Equip/Unequip Flow - Research

**Researched:** 2026-03-18
**Domain:** GDScript atomic inventory transactions, InventoryUI wiring, GUT TDD
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EQUIP-01 | Player can equip a weapon item from the bag to a dedicated weapon slot | EquipmentData.equip_weapon() exists; Inventory.remove() exists; MENU_EQUIP stub is already in InventoryUI waiting to be wired |
| EQUIP-02 | Equipping a weapon when the slot is already occupied swaps the old weapon back to the bag | equip_weapon() returns the displaced weapon; Inventory.insert() accepts it; atomicity achieved by performing remove-then-equip in one code block |
| EQUIP-03 | Player can unequip a weapon; rejected with existing message if bag is full | unequip_weapon() returns the weapon; Inventory.insert() returns remaining count > 0 on rejection; EquipmentData must re-equip the weapon if insert fails |
| EQUIP-04 | Player can equip a tool item to the dedicated tool slot (UI only, no gameplay wiring) | equip_tool() / unequip_tool() already exist on EquipmentData; Inventory.remove() covers the bag side; MENU_EQUIP const 0 is already used for both weapons and tools in the same handler |
</phase_requirements>

---

## Summary

Phase 5 built all the data primitives: `EquipmentData` with `equip_weapon`, `unequip_weapon`, `equip_tool`, `unequip_tool` methods that return the displaced item, and a `MENU_EQUIP` stub in `InventoryUI._on_context_menu_id_pressed` that currently contains only `pass`. Phase 6 has a single well-defined job: replace that `pass` stub with real logic that coordinates `EquipmentData` and `Inventory` atomically.

The implementation is entirely contained in `InventoryUI`. No new files are required. The equip transaction is: (1) determine the item category from `_pending_context_index`, (2) call `inventory.remove()` to pull it from the bag, (3) call `equipment_data.equip_weapon()` or `equip_tool()` to seat it, (4) if a displaced item was returned insert it back into the bag. The unequip transaction is symmetric but must guard against a full bag: call `inventory.insert()` first, and only call `unequip_weapon()` if insert succeeds (remaining == 0).

The main new complexity is that `InventoryUI` currently holds a reference to `_inventory` and `_player` but has no reference to `EquipmentData`. The player already has `@export var equipment_data: EquipmentData`. A `set_equipment_data(ed: EquipmentData)` method on `InventoryUI` — mirroring the existing `set_inventory` and `set_player` pattern — gives the UI access to it. `world.gd` wires it in `_ready()`.

**Primary recommendation:** Wire the `MENU_EQUIP` stub in `InventoryUI` using the return-value protocol already established by `EquipmentData`. No new data classes needed. Add `set_equipment_data()` to `InventoryUI`, wire it in `world.gd`, and implement the atomic equip/unequip sequences with full GUT test coverage.

---

## Standard Stack

### Core
| Library / Class | Version | Purpose | Why Standard |
|-----------------|---------|---------|--------------|
| GDScript + Godot 4 Resource | 4.2+ | All logic runs on existing Resource classes | No new tech introduced |
| GUT | 9.3.0 | Unit tests for transaction logic | Already installed; TDD is project DoD |
| gdtoolkit 4.x | 4.x | Lint and format enforcement | Already installed; required by DoD |

### Supporting
| Class | Purpose | When to Use |
|-------|---------|-------------|
| `EquipmentData` | Stores equipped weapon/tool, emits `equipment_changed` | Already exists — call its methods in the transaction |
| `Inventory` | Bag data; `insert()` returns remaining count | Use `insert()` return value to detect bag-full rejection |
| `InventoryUI` | UI coordinator — only file that changes | All new logic lives here |
| `world.gd` | Scene bootstrap — wires `set_equipment_data()` | One-line addition in `_ready()` |

**Installation:** No new packages. Everything is already present.

---

## Architecture Patterns

### Current call chain (Phase 5 state)

```
inventory_slot_ui.gd   right_clicked(slot_node) -->
inventory_ui.gd        _on_slot_right_clicked()   --> builds PopupMenu
inventory_ui.gd        _on_context_menu_id_pressed(MENU_EQUIP) --> pass  # STUB
```

### Target call chain (Phase 6)

```
_on_context_menu_id_pressed(MENU_EQUIP)
  item = _inventory.slots[_pending_context_index].item
  if item is WeaponItem:
      _do_equip_weapon(item)
  elif item.category == Item.Category.TOOL:
      _do_equip_tool(item)

_do_equip_weapon(item: WeaponItem):
  _inventory.remove(item, 1)          # pull from bag first
  var displaced = _equipment_data.equip_weapon(item)
  if displaced != null:
      _inventory.insert(displaced, 1)  # always succeeds — item came from bag

_do_equip_tool(item: Item):
  _inventory.remove(item, 1)
  var displaced = _equipment_data.equip_tool(item)
  if displaced != null:
      _inventory.insert(displaced, 1)

_do_unequip_weapon():
  var weapon = _equipment_data.weapon
  if weapon == null:
      return
  var remaining = _inventory.insert(weapon, 1)
  if remaining > 0:
      return  # bag full — insert_rejected already emitted by Inventory
  _equipment_data.unequip_weapon()   # only clear after bag confirms space
```

### Pattern 1: Equip (bag → slot)
**What:** Remove from bag, equip to slot, re-insert any displaced item.
**When to use:** `MENU_EQUIP` pressed on a weapon or tool bag slot.
**Why it is safe:** `EquipmentData.equip_weapon()` always returns the displaced item. Since that item was already in the bag before, inserting it back cannot fail (weight is identical and one slot just opened).
```gdscript
# Source: scripts/resources/equipment_data.gd (existing)
func equip_weapon(item: WeaponItem) -> WeaponItem:
    var previous: WeaponItem = weapon
    weapon = item
    equipment_changed.emit()
    return previous
```

### Pattern 2: Unequip (slot → bag)
**What:** Attempt bag insert first; only clear the slot if insert succeeds.
**When to use:** Unequip action (Phase 8 context menu, but the data method is wired here).
**Critical ordering:** Call `inventory.insert()` BEFORE `equipment_data.unequip_weapon()`. If insert fails, the weapon must remain equipped. Do NOT call `unequip_weapon()` optimistically and then try to roll back.
```gdscript
# Correct ordering — insert first, unequip only on success
var remaining := _inventory.insert(weapon, 1)
if remaining > 0:
    return  # bag full — weapon stays equipped; insert_rejected already fired
_equipment_data.unequip_weapon()
```

### Pattern 3: set_equipment_data() wiring
**What:** `InventoryUI` needs a reference to `EquipmentData` for the equip flow.
**When to use:** Mirrors `set_inventory()` and `set_player()` — called once from `world.gd _ready()`.
```gdscript
# In inventory_ui.gd
func set_equipment_data(ed: EquipmentData) -> void:
    _equipment_data = ed

# In world.gd _ready()
inventory_ui.set_equipment_data(player.equipment_data)
```

### Anti-Patterns to Avoid
- **Calling `unequip_weapon()` before `insert()`:** If insert fails the item is now neither in the bag nor in the slot. Data loss. Always check insert result first.
- **Calling `insert()` with a displaced item after a failed bag remove:** If `inventory.remove()` somehow returned 0, do not proceed to `equip_weapon()`. Guard on `removed == 1`.
- **Using `index_pressed` on the PopupMenu:** Project decision mandates `id_pressed` with named const IDs. Do not change this.
- **Adding a new slot type or new scene for equip UI:** Phase 8 handles HUD slot right-click. Phase 6 only wires the existing bag context menu path.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detect bag-full on unequip | Custom space-check logic | `Inventory.insert()` return value (`remaining > 0`) | `insert()` already handles weight + stack logic and emits `insert_rejected` |
| Return displaced item | Custom swap logic | `EquipmentData.equip_weapon()` return value | Already returns previous item; Phase 5 designed this contract explicitly for Phase 6 |
| Item type detection | Category int comparison | `item is WeaponItem` GDScript `is` operator | Idiomatic; `WeaponItem` is a distinct class |

**Key insight:** Every piece needed for atomicity was built in Phase 5 by design. The Phase 6 job is wiring, not engineering.

---

## Common Pitfalls

### Pitfall 1: Unequip with full bag — wrong operation order
**What goes wrong:** `unequip_weapon()` is called first; weapon slot is cleared. Then `insert()` fails. Weapon is now in neither location.
**Why it happens:** "Optimistic" thinking — assume success, roll back on failure. Rollback requires a second equip call and risks double-emit of `equipment_changed`.
**How to avoid:** Always insert first. Only call `unequip_weapon()` after `insert()` returns `remaining == 0`.
**Warning signs:** Test that asserts `equipment_data.weapon != null` after a failed unequip fails.

### Pitfall 2: Displaced item lost on weapon swap
**What goes wrong:** `equip_weapon()` is called without first capturing the return value; the displaced weapon is discarded.
**Why it happens:** Ignoring the return value, or not inserting it back into the bag.
**How to avoid:** Always `var displaced = _equipment_data.equip_weapon(item)` and always `if displaced != null: _inventory.insert(displaced, 1)`.
**Warning signs:** After swapping weapons, the bag has one fewer item than expected.

### Pitfall 3: Item still visible in bag after equip
**What goes wrong:** `equip_weapon()` is called but `inventory.remove()` is not, so the item is in both locations.
**Why it happens:** Forgetting the remove step; calling equip before remove.
**How to avoid:** Remove from bag first, then equip. If equip call is made with the item still in bag, EQUIP-05 is violated.
**Warning signs:** Bag grid shows the equipped weapon's icon after equipping.

### Pitfall 4: Tool items matched by wrong check
**What goes wrong:** Tool item detection uses `item.category == 1` (magic number) or `item is Item` (too broad, matches everything including WeaponItem).
**Why it happens:** `WeaponItem` extends `Item`; `item is Item` is true for weapons too.
**How to avoid:** Use `item.category == Item.Category.TOOL` for tools. Use `item is WeaponItem` for weapons. Check weapon first in the if/elif chain.
**Warning signs:** A weapon gets routed to `equip_tool()`.

### Pitfall 5: `_equipment_data` is null at equip time
**What goes wrong:** `_on_context_menu_id_pressed` runs with `_equipment_data == null` (not wired in `world.gd`); null reference crash.
**Why it happens:** `set_equipment_data()` not called from `world.gd _ready()`.
**How to avoid:** Guard: `if _equipment_data == null: return` at the start of the equip handler. Also add the wiring call to `world.gd`.
**Warning signs:** Engine crash on first equip attempt; stack trace points to `_equipment_data.equip_weapon()`.

---

## Code Examples

Verified patterns from existing codebase:

### Inventory.insert() return value (bag-full detection)
```gdscript
# Source: scripts/resources/inventory.gd
# Returns the number of items that could NOT be inserted (0 = full success)
func insert(item: Item, amount: int = 1) -> int:
    ...
    return remaining  # 0 on full success, >0 if some were rejected
```

### Inventory.remove()
```gdscript
# Source: scripts/resources/inventory.gd
# Returns number of items actually removed
func remove(item: Item, amount: int = 1) -> int:
    ...
    var removed: int = amount - remaining
    if removed > 0:
        inventory_changed.emit()
    return removed
```

### EquipmentData.equip_weapon() — return value is the key
```gdscript
# Source: scripts/resources/equipment_data.gd
func equip_weapon(item: WeaponItem) -> WeaponItem:
    var previous: WeaponItem = weapon
    weapon = item
    equipment_changed.emit()
    return previous  # null if slot was empty
```

### set_inventory() pattern (model for set_equipment_data)
```gdscript
# Source: scripts/inventory_ui.gd
func set_inventory(inv: Inventory) -> void:
    _inventory = inv
    inv.inventory_changed.connect(_refresh_slots)
    inv.inventory_changed.connect(_refresh_weight_label)
    _refresh_slots()
    _refresh_weight_label()
```

### world.gd wiring pattern (model for set_equipment_data call)
```gdscript
# Source: scripts/world.gd
func _ready() -> void:
    inventory_ui.set_inventory(player.inventory)
    inventory_ui.set_player(player)
    # Phase 6 adds:
    # inventory_ui.set_equipment_data(player.equipment_data)
```

### GUT test for atomicity (pattern from test_inventory.gd)
```gdscript
# Source: tests/unit/test_inventory.gd (established pattern)
func test_...:
    watch_signals(inventory)
    inventory.insert(wood, 1)
    assert_signal_emitted(inventory, "inventory_changed")
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No equip system | EquipmentData Resource with typed weapon/tool fields | Phase 5 (2026-03-18) | EquipmentData is ready; Phase 6 just wires the UI |
| MENU_EQUIP was `pass` stub | Phase 6 replaces stub with full equip logic | Phase 6 (this phase) | Context menu becomes functional |
| InventoryUI had no equipment reference | `set_equipment_data()` + `_equipment_data` field | Phase 6 (this phase) | UI can call equip/unequip atomically |

---

## Open Questions

1. **Tool item category detection**
   - What we know: `Item.Category.TOOL` enum value exists; `WeaponItem extends Item` with `category = WEAPON` forced in `_init()`
   - What's unclear: Are any existing `.tres` item resources of category TOOL? If not, EQUIP-04 test coverage may require creating a synthetic tool item in tests.
   - Recommendation: Create a minimal `Item` with `category = Item.Category.TOOL` in the unit test helper. No `.tres` resource needed for logic tests.

2. **`_do_unequip_weapon()` call site in Phase 6**
   - What we know: Phase 6 scope is the bag context menu (`MENU_EQUIP`). Unequip via context menu on the equipment slot is CTXMENU-03, which belongs to Phase 8.
   - What's unclear: Does Phase 6 need to implement the unequip data method at all, or only equip?
   - Recommendation: Phase 6 implements equip only (EQUIP-01, EQUIP-02, EQUIP-04). EQUIP-03 (unequip rejected if bag full) must also be implemented in Phase 6 per the requirement list — but the call site is the equip-slot context menu stub, which needs a temporary "Unequip" path in Phase 6 to be testable, even though the full context-menu polish is Phase 8. Plan should include a minimal unequip path invocable from tests (and optionally from a temporary UI hook).

3. **`player.equipment_data` Inspector assignment**
   - What we know: The `@export var equipment_data: EquipmentData` field exists on Player. The `.tres` player_inventory resource exists at `scripts/resources/player_inventory.tres`.
   - What's unclear: Has a corresponding `player_equipment_data.tres` been created and assigned in the scene Inspector? If not, `player.equipment_data` will be null at runtime.
   - Recommendation: Plan should include creating a `player_equipment_data.tres` resource file and assigning it to the Player scene's Inspector field — or verifying it was done in Phase 5. (Phase 5 summary notes the Inspector field could not be confirmed in-editor.)

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
| EQUIP-01 | Equip weapon from bag: item removed from bag, appears in equipment slot | unit | `make test` | ❌ Wave 0 — `tests/unit/test_equip_flow.gd` |
| EQUIP-02 | Swap weapon: old weapon returns to bag, new weapon in slot | unit | `make test` | ❌ Wave 0 — `tests/unit/test_equip_flow.gd` |
| EQUIP-03 | Unequip rejected when bag full: weapon stays equipped | unit | `make test` | ❌ Wave 0 — `tests/unit/test_equip_flow.gd` |
| EQUIP-04 | Equip tool: item removed from bag, appears in tool slot | unit | `make test` | ❌ Wave 0 — `tests/unit/test_equip_flow.gd` |

### Sampling Rate
- **Per task commit:** `make lint && make format-check && make test`
- **Per wave merge:** `make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/unit/test_equip_flow.gd` — covers EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04
- [ ] `scripts/resources/player_equipment_data.tres` — EquipmentData resource assigned to Player scene (if not created in Phase 5)

---

## Sources

### Primary (HIGH confidence)
- Direct codebase read: `scripts/resources/equipment_data.gd` — confirmed method signatures and return value contract
- Direct codebase read: `scripts/resources/inventory.gd` — confirmed `insert()` and `remove()` return value semantics
- Direct codebase read: `scripts/inventory_ui.gd` — confirmed `MENU_EQUIP` stub location, `set_inventory/set_player` patterns, `_pending_context_index` usage
- Direct codebase read: `scripts/player.gd` — confirmed `equipment_data` export field exists
- Direct codebase read: `scripts/world.gd` — confirmed wiring call site and pattern
- Direct codebase read: `tests/unit/test_equipment_data.gd` — confirmed GUT test patterns for this domain
- Phase 5 SUMMARY.md — confirmed what Phase 5 delivered and what it left as stubs for Phase 6

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` decisions log — confirmed "equip transaction must be atomic" and "return displaced item from equip methods"
- `.planning/phases/05-data-foundation/05-CONTEXT.md` — confirmed "mutate field first then emit", "return displaced item" design intent

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; everything read directly from codebase
- Architecture: HIGH — transaction patterns derived from existing `insert()`/`remove()` semantics and `equip_weapon()` return contract
- Pitfalls: HIGH — derived from reading actual code paths, not from general heuristics

**Research date:** 2026-03-18
**Valid until:** 2026-04-17 (stable codebase — 30-day window)
