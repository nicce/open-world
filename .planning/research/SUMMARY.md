# Project Research Summary

**Project:** Open World — v1.1 Equipment Slots
**Domain:** Godot 4 top-down RPG — weapon/tool equipment slot system with context menu UI
**Researched:** 2026-03-13
**Confidence:** HIGH

## Executive Summary

The v1.1 Equipment Slots milestone extends a proven, fully-tested v1.0 inventory foundation. The codebase already supplies every data primitive needed: `WeaponItem.damage`, `Item.category` with `WEAPON`/`TOOL` variants, `Inventory.insert/remove`, a `hit()` stub on `Player`, and the `inventory_slot_ui` rendering pattern. The primary work is connecting these pieces through a new `EquipmentData` Resource and wiring a small set of new or modified scenes. The architecture follows one clear pattern throughout: Resource classes own state and emit signals; UI nodes observe those signals and refresh; `world.gd` handles all cross-scene wiring.

The recommended approach is to build in strict dependency order: data model first, then equip/unequip logic, then combat wiring (`hit()`), then the HUD strip, then the right-click context menu, and finally the placeholder visual indicator. Each step is independently testable with GUT before the next begins. The single design decision with the most downstream impact is keeping `EquipmentData` strictly separate from `Inventory` — mixing them corrupts the bag's weight invariant and breaks the 15-slot grid assumption.

The key risks are all at the boundary between data and UI: `PopupMenu` positioning at screen edges, `id_pressed` vs `index_pressed` confusion, stale item references when the inventory changes while the menu is open, and the equip transaction not being atomic. All four have explicit prevention strategies grounded in direct codebase inspection and are straightforward to unit-test. The one area requiring runtime verification (not deeper research) is whether `attack.damage` mutation in `hit()` is read correctly by `HitboxComponent` before the hitbox fires.

## Key Findings

### Recommended Stack

The engine version is Godot 4.3 (confirmed in `project.godot` — do not use 4.2). All logic is GDScript. No new addons are needed or permitted beyond GUT (testing) and gdtoolkit (lint/format). The key new stack element is the `PopupMenu` built-in Godot node for the context menu — it handles positioning, outside-click dismissal, and viewport management natively and requires no custom implementation.

**Core technologies:**
- Godot 4.3 + GDScript: game engine and all logic — confirmed version, no downgrade permitted
- `Resource` subclass (`EquipmentData`): equipment state container — follows the exact pattern of `Inventory`; serializable, editor-inspectable, GUT-testable without scene tree
- `PopupMenu` (built-in Godot node): right-click context menu — no addon required; `id_pressed` signal dispatches actions cleanly; handles outside-click dismissal natively
- `CanvasLayer` (existing, reused): HUD strip placement — already present in `world.tscn`; HUD strip must be a sibling of `InventoryUI`, not a child

Note: `project.godot` declares `"4.3"` but the Makefile sets `GODOT_VERSION ?= 4.2.2`. This mismatch should be corrected to avoid test/editor divergence.

### Expected Features

**Must have (table stakes):**
- Always-visible HUD strip with weapon slot and tool slot — players need to see equipped state without opening the bag
- Right-click context menu on bag slots with actions filtered by `item.category` — genre convention; Equip for weapons, Consume for consumables, Drop always
- Equip from bag: atomic remove + slot-set, emitting both `inventory_changed` and `equipment_changed` — broken atomicity is the most common equip-system bug
- Unequip to bag: `inventory.insert()` with rejection handling when bag is full — silent item loss is unacceptable
- One weapon at a time: equipping when slot is occupied swaps old weapon back to bag first
- Right-click on HUD equipment slot shows "Unequip" — symmetry with equip flow
- `player.gd hit()` implementation using `equipment.weapon_slot.damage` routed through the existing `Attack` node
- Fist fallback when no weapon is equipped — player must always be able to attack
- Placeholder visual indicator on player when weapon is equipped — world feedback, not just HUD feedback

**Should have (differentiators — defer to follow-on PR):**
- Item tooltip on hover showing name, stats, weight
- Weapon damage stat badge displayed on HUD slot
- Left-click on HUD slot as a one-click unequip shortcut
- Animated equip flash on player indicator

**Defer (explicitly out of scope for v1.1):**
- Tool slot gameplay wiring — `HarvestableComponent` does not exist; tool slot is UI-only this milestone
- Drag-and-drop between bag and equipment slots — large edge-case surface area
- Armour/helmet/boot slots — separate milestone after weapon slot proves the pattern
- Item durability — no durability system exists
- Weapon-specific animations — out of scope; placeholder indicator only
- Hotbar — separate follow-on milestone per PROJECT.md
- Save/load of equipped state — no persistence layer exists yet

### Architecture Approach

The three-layer architecture (Data/Resource, Game Logic, UI) from v1.0 is unchanged. `EquipmentData extends Resource` is the single authority on what is equipped; it emits `equipment_changed` which both `EquipmentHUD` and `Player` observe. `InventoryUI` calls `EquipmentData` methods during equip/unequip but does not own equipment state. `world.gd` wires everything together using the established `set_inventory()` / `set_player()` pattern extended with `set_equipment()`.

**Major components:**
1. `EquipmentData` (Resource) — owns `weapon_slot: WeaponItem` and `tool_slot: Item` (both nullable); emits `equipment_changed`; pure data, no scene tree dependency; GUT-testable in isolation
2. `EquipmentHUD` (Control scene, always visible) — renders two slot nodes in `HBoxContainer`; observes `equipment_changed`; emits `unequip_requested`; lives in `CanvasLayer` as sibling to `InventoryUI`
3. `ContextMenu` (`PopupMenu` child of `InventoryUI`) — built dynamically at right-click time using explicit `const` IDs; dispatches to `_equip_selected()`, `_use_selected()`, `_drop_selected()`
4. `Player` (modified) — gains `@export var equipment: EquipmentData`; implements `hit()` writing `attack.damage` from `equipment.weapon_slot` before the hitbox fires; toggles `EquippedWeaponSprite` visibility
5. `world.gd` (modified) — wires `EquipmentData` to player, inventory UI, and equipment HUD; handles `unequip_requested` from HUD

**New files:** `scripts/resources/equipment_data.gd`, `scripts/equipment_hud.gd`, `scenes/equipment_hud.tscn`, `tests/unit/test_equipment_data.gd`

**Modified files:** `scripts/player.gd`, `scripts/inventory_ui.gd`, `scripts/inventory_slot_ui.gd`, `scripts/world.gd`, `scenes/world.tscn`

### Critical Pitfalls

1. **Equipment state mixed into `Inventory.slots`** — breaks the 15-slot grid, weight accounting, and stacking invariants. Use a separate `EquipmentData` Resource; never add nullable equipment slots to `Inventory`. This decision must be locked before writing any equip logic.

2. **Equip is not atomic** — if `inventory.remove()` and the equipment slot assignment are not in the same function, the item can exist in both places. Write a unit test that asserts the item is absent from every bag slot immediately after `equip()` returns.

3. **`hit()` reads `WeaponItem.damage` directly instead of writing through the `Attack` node** — `HitboxComponent._on_body_entered` reads `body.attack` (the `Attack` node on Player), not a float. The fix is `attack.damage = equipment.weapon_slot.damage` before the hitbox fires, then restore fist damage on unequip.

4. **`PopupMenu.id_pressed` vs `index_pressed` confusion** — when menu items are conditionally added, position indices shift. Always use `add_item(label, CONST_ID)` with named constants and connect `id_pressed`, not `index_pressed`.

5. **Unequip with full bag loses the item** — check bag capacity before unequipping; do not clear `equipped_weapon` unless `inventory.insert()` returns 0. Show the existing rejection label if the bag is full.

## Implications for Roadmap

Four natural implementation phases emerge from the dependency chain. Each is independently deliverable and testable before the next begins.

### Phase 1: Data Foundation + Context Menu Architecture

**Rationale:** `EquipmentData` Resource is the dependency that everything else reads. All critical architectural decisions must be locked here — separate resource, explicit menu IDs, HUD placement outside `InventoryUI` — or every subsequent phase requires rework. The right-click signal extension on `InventorySlotUI` is a trivial one-branch addition that unblocks all context menu work.

**Delivers:** `EquipmentData` Resource with signals and equip/unequip methods; GUT unit tests for the resource; `slot_right_clicked` signal on `InventorySlotUI`; `PopupMenu` child wired into `InventoryUI` with correct `const` ID strategy; context menu build logic filtering by `item.category`; HUD scene structure decision locked (sibling not child); weight accounting decision locked (equipped items do not count against bag weight).

**Avoids:** Pitfall 1 (wrong data layer), Pitfall 3 (id/index confusion), Pitfall 9 (wrong menu for HUD slots), Pitfall 14 (HUD hidden with inventory)

### Phase 2: Equip / Unequip Flow

**Rationale:** The equip transaction is the most complex logic with the highest bug risk — atomicity, full-bag rejection, swap-on-re-equip. It must be solid and fully tested before the HUD or combat wiring observes it.

**Delivers:** `_equip_selected()` in `InventoryUI` (atomic remove + slot-set + swap); `_on_unequip_requested()` in `world.gd` with bag-full rejection; inventory weight correctly reflecting equipped state; unit tests covering equip, unequip, swap, and full-bag rejection.

**Avoids:** Pitfall 4 (stale slot reference verified before acting), Pitfall 6 (item in both bag and slot), Pitfall 7 (unequip with full bag loses item), Pitfall 8 (double-refresh preserves selection state), Pitfall 11 (weight ambiguity resolved)

### Phase 3: Combat Wiring + HUD Strip

**Rationale:** With the data model correct, `Player.hit()` and `EquipmentHUD` can be wired — both observe `equipment_changed` and have no dependency on each other. `hit()` is the payoff feature of the entire milestone; the HUD strip is the primary visibility feature.

**Delivers:** `player.gd hit()` writing `attack.damage` from `equipment.weapon_slot` with fist fallback; `EquipmentHUD` scene always visible in `CanvasLayer`; `EquipmentSlotUI` nodes rendering equipped item icons; `world.gd` wiring connecting all components; placeholder `Sprite2D` visual on player toggled by equipment signals.

**Avoids:** Pitfall 5 (Attack node mismatch — weapon damage routes through existing `attack` property), Pitfall 10 (Sprite2D layering — minimal placeholder, no z-index tuning)

### Phase 4: Integration Polish + Edge Case Coverage

**Rationale:** After all functional phases are in place, a focused integration pass addresses the minor pitfalls and ensures the feature is coherent across all input paths.

**Delivers:** `PopupMenu` position clamped to viewport (not raw mouse position); `PopupMenu` hidden when inventory closes; pure context-menu-data function extracted and unit-tested (not the `PopupMenu` node); right-click on HUD slot correctly shows "Unequip" not "Equip" via slot context parameter.

**Avoids:** Pitfall 2 (popup off-screen at edges), Pitfall 12 (popup leaks when inventory closes), Pitfall 13 (GUT tests crash on PopupMenu Window subclass)

### Phase Ordering Rationale

- Data before UI: `EquipmentData` must exist before `EquipmentHUD` or `InventoryUI` can observe it — resource-first is the established v1.0 pattern
- Architecture decisions front-loaded in Phase 1: HUD placement, menu ID strategy, and weight accounting have zero rework cost when decided early but force scene restructure if decided late
- Equip/unequip before HUD wiring: the HUD displays equipment state; rendering partially-correct state during development is confusing
- Combat wiring after equip logic: `hit()` reads `equipment.weapon_slot` which only has meaning after equip/unequip is correct
- Polish phase last: minor pitfalls (popup position, leak on close) do not block functionality and are cheap to fix in isolation after the main flow works

### Research Flags

Phases with standard, well-documented patterns — skip research-phase:
- **Phase 1:** `EquipmentData` follows the exact `Inventory` Resource pattern already in the codebase; `PopupMenu` API is stable Godot 4.2+ with high-confidence training data
- **Phase 2:** `inventory.insert/remove` contracts are fully tested across 88 unit tests; equip logic is pure GDScript data manipulation with no Godot API uncertainty
- **Phase 3:** `CanvasLayer` + `HBoxContainer` for always-visible HUD is the standard Godot 4 pattern; `EquipmentHUD` rendering mirrors `InventoryUI` directly

Phases needing runtime verification (not deeper research — confirm in editor):
- **Phase 3 (`hit()` integration):** The `attack.damage` mutation approach is MEDIUM confidence — needs one runtime test to confirm `HitboxComponent` reads the mutated value correctly. If mutation is too late in the frame, the fallback is to swap the entire `Attack` node reference on equip.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Engine version read directly from `project.godot`; `PopupMenu` and `Resource` patterns confirmed from codebase inspection and stable Godot 4 training data |
| Features | HIGH | Table stakes derived from direct codebase audit — all prerequisite code confirmed present; anti-features grounded in explicit PROJECT.md scope constraints |
| Architecture | HIGH | Three-layer pattern verified across 88 existing unit tests; component boundaries follow v1.0 established contracts; one MEDIUM point on `attack.damage` mutation timing |
| Pitfalls | HIGH | 13 of 14 pitfalls rated HIGH confidence; all sourced from direct code path inspection; Sprite2D layering (Pitfall 10) is MEDIUM due to AnimationTree interaction variability |

**Overall confidence:** HIGH

### Gaps to Address

- **`attack.damage` mutation timing (MEDIUM):** During Phase 3, confirm at runtime that writing `attack.damage` in `hit()` before triggering the hitbox animation results in `HitboxComponent` reading the updated value. Fallback: swap the entire `Attack` node reference on equip rather than mutating damage inline.
- **`popup()` exact overload syntax (MEDIUM):** Verify against Godot editor autocomplete during Phase 1 whether to use `popup(Rect2i)` or `popup_on_parent(Rect2i)`. Both are valid approaches; the exact method name needs confirmation in 4.3.
- **Makefile version mismatch:** `GODOT_VERSION ?= 4.2.2` should be updated to match the `4.3` declared in `project.godot` to avoid test/editor divergence.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `scripts/player.gd`, `scripts/inventory_ui.gd`, `scripts/inventory_slot_ui.gd`, `scripts/resources/item.gd`, `scripts/resources/weapon_item.gd`, `scripts/resources/inventory.gd`, `scripts/attack.gd`, `components/hitbox_component.gd`
- `.planning/PROJECT.md` — milestone scope, anti-features, technical debt constraints
- `project.godot` — confirmed Godot 4.3 feature version
- `Makefile` — confirmed GUT and gdtoolkit toolchain; noted version mismatch

### Secondary (MEDIUM confidence)
- Godot 4 training data (through August 2025) — `PopupMenu` API (`add_item`, `id_pressed`, `popup()`), `CanvasLayer` HUD patterns, `_gui_input` `MOUSE_BUTTON_RIGHT` handling
- Genre conventions (Stardew Valley, Terraria, Diablo) — right-click context menu expectations, equip-removes-from-bag model

### Tertiary (LOW confidence)
- None — all findings are grounded in codebase inspection or stable Godot API patterns

---
*Research completed: 2026-03-13*
*Ready for roadmap: yes*
