# Project Research Summary

**Project:** Open World — Stardew-like 2D Survival/Adventure
**Domain:** Top-down 2D RPG / survival game in Godot 4
**Researched:** 2026-03-10
**Confidence:** HIGH

## Executive Summary

This is a top-down 2D survival/adventure game built on Godot 4.3 with GDScript, following established patterns from the genre (Stardew Valley, Terraria, Valheim). The project has a solid structural foundation — component-based composition, signal-driven communication, and a typed Resource hierarchy for inventory data — but critical gaps block playability: the player is permanently stuck in the HIT state after one attack, and the inventory UI is a non-functional stub. Research confirms that fixing these two blockers before any new feature work is the only viable path forward.

The recommended approach is to work in strict dependency order: unblock combat first, then harden the inventory data model (item identity, signal bus, Resource duplication), then deliver a working grid UI, and only then layer in item use, item drop, and combat feel improvements. The architecture is already well-suited to this expansion — the three-layer separation (UI / Game Logic / Resource data) needs to be extended, not redesigned. No third-party addons beyond GUT are needed or permitted.

The key risk is architectural drift: UI gaining game-logic responsibilities, item identity remaining name-string-based as the catalog grows, and equipment slot layout being bolted on after the bag grid is built. All three of these are preventable with explicit contracts decided before implementation begins — specifically: dispatch by `item.category` in Player (not in UI), `id: StringName` on Item (not `name`), and reserving a separate equipment panel layout from the start.

---

## Key Findings

### Recommended Stack

The project runs on Godot 4.3 (confirmed via `project.godot`) with all game logic in GDScript. There is a version mismatch: the Makefile downloads Godot 4.2.2 for headless tests while the project declares 4.3. This should be corrected to avoid test/editor divergence.

Inventory data is correctly modeled as typed `Resource` subclasses (`Item`, `InventorySlot`, `Inventory`) — this must be maintained. The future save system can use `ResourceSaver` directly because the data model is already Resource-based.

**Core technologies:**
- Godot 4.3 + GDScript: engine runtime and all logic — no alternative; engine-native, full editor integration
- `Resource` subclasses: all item/inventory data — serializable, Inspector-configurable, type-safe
- `GridContainer`: fixed-slot bag grid UI — standard Godot node for grid layouts, set `columns` to constant
- GUT 9.3.0 + gdtoolkit 4.*: testing and linting — already integrated via `make test` / `make lint`

### Expected Features

The genre requires a functional combat loop and a visible inventory before any other feature feels justified. The current codebase has the data model but not the UX.

**Must have (table stakes):**
- Fix HIT state exit bug — game is unplayable after first attack; confirmed blocker
- Grid inventory UI with item icons and quantities — current UI renders nothing
- Weight/capacity feedback (current vs max) — players need to know their limit
- Full-inventory rejection message — silent failure breaks trust
- Consume health item from inventory — core consumable use case
- Item drop from inventory to world — players must be able to discard
- Enemy loot drops on death — expected from any combat encounter
- Item pickup toast/notification — basic feedback that interaction worked

**Should have (differentiators, after table stakes):**
- Equipment slots (weapon, tool) separate from bag grid
- Hotbar quick-access row
- Weapon equip modifying attack stats
- Item tooltip on hover
- Knockback on hit
- Resource harvesting (trees, rocks) via HarvestableComponent

**Defer to v2+:**
- Crafting system — requires item registry (id-based) not yet built
- Farming / crop system — requires TimeManager and tile manipulation
- Day/night cycle — requires TimeManager singleton
- NPC dialogue — no entities, dialogue tree, or quest system
- Save / load — game state will expand significantly before this stabilizes
- Hunger / stamina — no food loop to refill it; pure punishment without payoff
- Multiplayer — explicitly excluded per PROJECT.md

### Architecture Approach

The existing three-layer architecture (UI / Game Logic / Resource data) is the correct foundation and must be preserved. The inventory system extends cleanly from this: `Inventory` Resource holds `InventorySlot` array and emits a `changed` signal; `InventoryUI` observes it and refreshes slot nodes in-place (never rebuilds the list); `Player` is the authority on all stat effects from item use. Equipment slots use a separate panel, not slots inside the bag grid.

**Major components:**
1. `Inventory` (Resource) — slot array, weight tracking, `changed` signal; single source of truth
2. `InventorySlotUI` (Control, preloaded) — dumb display node; instantiated once at `_ready()`, updated in-place
3. `Player` — authority for all game-logic dispatch; handles `item_used` and `item_dropped` signals from UI
4. `Item` (Resource base) — id (StringName), name, weight, category enum, texture, stackable flag; extended by `HealthItem` and `WeaponItem`
5. `Collectable` — scene that Player can interact with; reused for item drop by instantiating `item.collectable_scene`

### Critical Pitfalls

1. **HIT state never exits** — Add state transition back to MOVE on attack animation completion. Must fix before any other work; blocks all combat iteration.
2. **Item identity by name string** — Replace `slot.item.name == item.name` with `slot.item.id == item.id` everywhere. Add `@export var id: StringName` to `Item` before defining any new items.
3. **No consumable dispatch contract** — Do not add `use()` to Item Resource. Player dispatches by `item.category` enum. UI emits `item_used(item)`; Player acts. Decide this pattern before writing any use logic.
4. **Shared Resource mutation across sessions** — Call `inventory = inventory.duplicate(true)` in `Player._ready()` to deep-copy slots and items; without this, inventory state bleeds between play sessions.
5. **Fixed grid vs. dynamic slot count** — Instantiate exactly N slots at `_ready()` (e.g., 20). Never add/remove slots based on item count. Empty slots display as blank.

---

## Implications for Roadmap

Based on combined research, the dependency chain is clear and dictates a strict phase order. Each phase has hard prerequisites from the phase before it.

### Phase 1: Combat Fix + Inventory Foundation

**Rationale:** The HIT state bug makes the game unplayable and blocks all combat iteration. Item identity by name string will corrupt any new item work. The `Inventory.changed` signal and Resource duplication are prerequisites for every UI feature. These must all land together before any visible UI work.

**Delivers:** Playable combat loop; correct item identity; inventory signal bus; Resource duplication safety; `collectable_scene` field on Item; `floori()` fix for weight calculation.

**Addresses:** Fix HIT state exit (FEATURES.md table stakes); item id field; inventory signal (ARCHITECTURE.md foundation).

**Avoids:** Pitfalls 1 (HIT state), 2 (name-string identity), 4 (float truncation), 5 (signal stub), 9 (shared Resource mutation).

**Research flag:** Standard patterns — no phase research needed.

---

### Phase 2: Grid Inventory UI

**Rationale:** Depends entirely on Phase 1 (`Inventory.changed` signal, fixed slot model). Delivers the first visible inventory experience. Equipment slot layout decision must be made here (separate panel reserved, even if empty), to avoid structural rework in Phase 3.

**Delivers:** Working grid UI (N×M fixed slots), item icons, quantity labels, weight display (current/max), full-inventory feedback toast, equipment slot panel placeholder.

**Addresses:** Grid UI with icons + quantities, weight feedback, rejection message (FEATURES.md table stakes).

**Avoids:** Pitfalls 6 (dynamic slot count), 7 (equipment slot architecture), 10 (no full-inventory feedback).

**Research flag:** Standard patterns — GridContainer behavior is well-documented in Godot 4.

---

### Phase 3: Item Use + Item Drop

**Rationale:** Both depend on the working grid UI for interaction surface. Item use requires `HealthComponent` (already exists). Item drop requires `item.collectable_scene: PackedScene` field (added in Phase 1) and Player handling world instantiation — UI must never touch the scene tree.

**Delivers:** Consuming health items from inventory (removes item, heals player), dropping items back to world as collectables, UI feedback on both actions.

**Addresses:** Consume health item from inventory, item drop (FEATURES.md table stakes).

**Avoids:** Pitfalls 3 (no dispatch contract), 11 (drop logic in UI layer).

**Research flag:** Standard patterns — dispatch and signal flow are well-established in this codebase.

---

### Phase 4: Enemy Loot + Combat Feel

**Rationale:** Now that inventory is functional end-to-end, enemy loot drops have a destination. Knockback enhances combat feel. Both are low-to-medium complexity and share the item drop infrastructure from Phase 3.

**Delivers:** Enemies drop configurable loot on death, item pickup toasts, knockback on player hit, HitboxComponent null-reference assertions.

**Addresses:** Enemy loot drops, item pickup toast, knockback (FEATURES.md table stakes and differentiators).

**Avoids:** Pitfall 12 (HitboxComponent null reference).

**Research flag:** Standard patterns — death signals and loot spawning follow existing component patterns.

---

### Phase 5: Equipment Slots + Hotbar

**Rationale:** Requires the equipment panel placeholder from Phase 2 and the item category enum from Phase 1. Weapon equip affecting attack stats requires `Player` to hold `equipped_weapon: WeaponItem` and apply it to the attack system.

**Delivers:** Separate equipment slots (weapon, tool) above bag grid, hotbar row always visible, weapon equip changes attack stats, item tooltips on hover.

**Addresses:** Equipment slots, hotbar, weapon stats, tooltip (FEATURES.md differentiators).

**Research flag:** May need brief research on Godot hotbar UI patterns and `InputEvent` handling for hotkey-to-slot mapping.

---

### Phase 6: Resource Harvesting

**Rationale:** Depends on the item drop system (Phase 3), enemy loot patterns (Phase 4), and — eventually — a tool equip system (Phase 5). `HarvestableComponent` follows the same component pattern as `HitboxComponent`. This is a large feature requiring its own planning.

**Delivers:** Trees and rocks as harvestable nodes, tool-gated harvesting, resource item types, HarvestableComponent.

**Addresses:** Resource harvesting (FEATURES.md differentiator).

**Research flag:** Needs phase research — HarvestableComponent is new architecture; tool-gating logic and tile interaction patterns need validation.

---

### Phase Ordering Rationale

- Phase 1 before everything: two confirmed blockers (HIT state, name-string identity) corrupt all downstream work if not fixed first.
- Phase 2 before 3: item use and drop need UI interaction surface.
- Phase 3 before 4: loot drops need a functional inventory to land in.
- Phase 4 before 5: equipment slot UI builds on the same slot scene established in Phase 2; combat feel improvements are natural companions to loot.
- Phase 5 before 6: tool equip is a prerequisite for tool-gated harvesting.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 5 (Equipment + Hotbar):** Hotkey-to-hotbar-slot input mapping and UI layout for always-visible hotbar need verification against Godot 4 patterns.
- **Phase 6 (Resource Harvesting):** HarvestableComponent is new architecture with no existing analogue in the codebase; harvesting interaction patterns need design.

Phases with standard patterns (skip research-phase):
- **Phase 1:** All fixes follow established GDScript and Resource patterns.
- **Phase 2:** GridContainer grid UI is documented and stable in Godot 4.
- **Phase 3:** Item use and drop follow the existing signal/dispatch pattern.
- **Phase 4:** Loot drops and knockback follow existing component patterns.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified directly from `project.godot`, Makefile, and existing source files |
| Features | HIGH | Table stakes confirmed via direct code audit and genre conventions; differentiator ordering is MEDIUM |
| Architecture | HIGH | Three-layer pattern is already implemented correctly; extension points are clear |
| Pitfalls | HIGH | Critical pitfalls confirmed in source code; moderate pitfalls confirmed by pattern analysis |

**Overall confidence:** HIGH

### Gaps to Address

- **Godot version mismatch:** Makefile uses 4.2.2 for headless tests; project declares 4.3. Update `GODOT_VERSION` in Makefile before CI diverges from editor behavior.
- **ResourceSaver sub-resource bundling:** `ResourceSaver.FLAG_BUNDLE_RESOURCES` may be required when saving `Inventory` containing nested `InventorySlot` and `Item` sub-resources. Validate during Phase 1 or when save system is added.
- **Differentiator effort estimates:** Complexity estimates for Phase 5 and 6 features are informed but not verified against implementation. Re-estimate during phase planning.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection (`project.godot`, `Makefile`, `scripts/resources/`, `scripts/player.gd`, `scripts/inventory.gd`, `scripts/inventory_ui.gd`) — all stack, architecture, and pitfall findings
- `CONCERNS.md` in repository — confirmed HIT state bug

### Secondary (MEDIUM confidence)
- Godot 4 documentation (engine knowledge through August 2025) — GridContainer behavior, ResourceSaver flags, `user://` path semantics
- Genre conventions (Stardew Valley, Terraria, Valheim) — feature expectations and anti-feature rationale

### Tertiary (LOW confidence)
- Complexity estimates for Phase 5 and 6 features — informed inference; needs validation during phase planning

---

*Research completed: 2026-03-10*
*Ready for roadmap: yes*
