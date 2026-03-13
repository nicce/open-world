# Feature Landscape: Equipment Slots (v1.1)

**Domain:** 2D top-down RPG/survival — weapon + tool equipment slot system with context menu
**Researched:** 2026-03-13
**Milestone Context:** Subsequent milestone — extending v1.0 foundation (grid inventory, signals, item resources all exist)

---

## Table Stakes

Features players expect from any equipment slot system. Missing these makes the feature feel broken or incomplete.

### HUD Equipment Strip (always visible)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Weapon slot visible at all times (not behind inventory toggle) | Players must see what is equipped without opening the bag | Low | New HUD Control node, independent of inventory_ui.gd visibility; always-on |
| Tool slot visible alongside weapon slot | Establishes the two-slot paradigm; players expect symmetry | Low | UI-only this milestone; no tool gameplay wired |
| Slot shows equipped item icon (or empty placeholder) | Immediate feedback on equipped state | Low | Reuse inventory_slot_ui.gd update() pattern — InventorySlot reference |
| Slot label/badge differentiating W (weapon) vs T (tool) | Players need to know which slot is which | Low | Static Label overlay per slot node |

### Right-Click Context Menu on Bag Items

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Right-click on bag slot opens a floating menu | Genre convention (Diablo, Stardew, Terraria all do this) | Medium | PopupMenu or custom Control node anchored to click position |
| Menu options filtered by item type | "Equip" only for weapons/tools; "Consume" only for consumables; "Drop" always available | Medium | Requires checking item.category (enum already exists in item.gd) |
| "Equip" option for WeaponItem and TOOL category items | Core equip verb | Medium | Moves item from Inventory bag to equipment slot |
| "Consume" option for consumable HealthItems | Already the E-key behaviour — right-click must expose it too | Low | Re-use existing _use_selected() logic |
| "Drop" option for all items | Already Q-key behaviour — must be accessible from context menu | Low | Re-use existing _drop_selected() logic |
| Menu closes on click-away or action taken | Standard popup dismissal | Low | Godot PopupMenu handles this natively |

### Equip / Unequip Flow

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Equipping removes item from bag and places it in equipment slot | Players expect slots to be mutually exclusive — equipping is a move, not a copy | Medium | inventory.remove() + equipment slot state update + inventory_changed signal |
| Unequipping returns item to bag (Inventory.insert) | Item must not be lost | Medium | insert() may reject if bag full/overweight — need feedback path |
| Only one weapon equipped at a time (new equip swaps old to bag) | Genre standard | Low | On equip: if slot occupied, unequip first (insert old item back), then equip new |
| Right-click on equipment slot shows "Unequip" option | Players expect symmetry — what you equip you can unequip | Medium | Equipment slot nodes need their own _gui_input right-click handling |
| "Unequip" moves item back to bag | Inverse of equip flow | Low | inventory.insert(); if rejected, block unequip and show feedback |

### Equipped Weapon Drives Combat

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| player.gd hit() uses equipped WeaponItem.damage when weapon is equipped | The whole point — swinging a sword must be different from a fist | Medium | player.gd already has `func hit(): pass` stub waiting for this; Attack resource exists |
| Fist fallback when no weapon equipped | Player must always be able to attack | Low | Conditional: if equipped_weapon != null use weapon.damage else use existing Attack resource |
| Equipped weapon damage replaces (not adds to) fist damage | Clear mental model | Low | Direct substitution in hit() |

### Placeholder Visual Indicator on Player

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Visible indicator on the player sprite when weapon is equipped | Players need world-feedback, not just HUD-feedback | Low | Modulate colour tint, or a child Sprite2D toggled visible — placeholder only, no real weapon sprite needed |

---

## Differentiators

Features that improve the system beyond the minimum viable experience. Not required for v1.1 but worth noting for roadmap ordering.

| Feature | Value Proposition | Complexity | Prerequisite | Notes |
|---------|-------------------|------------|--------------|-------|
| Item tooltip on hover (name, stats, weight) | Reduces guesswork — players know what they are equipping | Low | HUD strip + context menu | MouseEntered signal on slot; Label overlay |
| Keyboard shortcut to equip/unequip (e.g. hold Shift+click) | Faster flow for power users | Low | Context menu | Optional binding; does not replace context menu |
| Swap weapon with one click (click equipped slot directly in HUD to unequip) | Faster than right-click → Unequip for common action | Low | HUD strip + unequip flow | Direct left-click on HUD slot as unequip shortcut |
| Weapon stat display on HUD slot (damage number badge) | Immediate stat visibility | Low | HUD strip + WeaponItem.damage | Small label overlaid on slot |
| Animated equip flash on player indicator | Polish — visual confirmation equip happened | Low | Placeholder indicator | AnimationPlayer or tween on the indicator node |

---

## Anti-Features

Features to explicitly NOT build in this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Tool slot gameplay wiring (harvesting, tool checks) | HarvestableComponent does not exist yet; tool type detection belongs to the Resource Harvesting milestone | Mark tool slot as UI-only; leave tool gameplay for the harvesting milestone |
| Drag-and-drop between bag and equipment slots | Large surface area of edge cases (drop on wrong slot type, mid-drag cancel, touch input); far exceeds milestone scope | Right-click context menu is the sufficient interaction model for now |
| Armour/helmet/boot slots | Not in scope for v1.1; PROJECT.md lists armour as a future Equipment Slots feature group item | Add armour slots in a dedicated armour milestone after weapon slot proves out the pattern |
| Item durability affecting equip/unequip | No durability system exists; adding it here would scope-creep the milestone | Design durability as a standalone system later |
| Weapon animations (sword swing vs fist swing) | Animation assets and new AnimationTree branches are out of scope; placeholder indicator is the agreed visual | Defer to Expanded Combat milestone |
| Hotbar (quick-access row) | Depends on equipment slots being solid; is its own feature per PROJECT.md | Hotbar is a follow-on milestone after v1.1 ships |
| Save/load of equipped state | No save system exists yet; serialising equipment adds complexity with no persistence layer | Save & Load milestone handles this |

---

## Feature Dependency Chain

```
Existing: Inventory (bag) data model (inventory.gd, Inventory.insert/remove)
Existing: InventorySlot resource (inventory_slot.gd)
Existing: Item.category enum (MATERIAL, FOOD, WEAPON, TOOL in item.gd)
Existing: WeaponItem.damage field (weapon_item.gd)
Existing: player.gd hit() stub (@export var attack: Attack already present)
Existing: inventory_slot_ui.gd update(slot) rendering pattern
Existing: _gui_input on Panel for left-click (inventory_slot_ui.gd)

  ┌─ HUD equipment strip (new Control, always visible)
  │     └─ Equipment slot UI nodes (reuse/extend inventory_slot_ui pattern)
  │           └─ right-click _gui_input on HUD slot → "Unequip" context menu
  │
  ├─ EquipmentManager (new Resource or plain Object — holds weapon_slot, tool_slot)
  │     └─ equipped_weapon_changed signal → player.gd listens
  │     └─ Equip flow: inventory.remove(item) → equipment slot
  │     └─ Unequip flow: inventory.insert(item) ← equipment slot
  │
  ├─ Right-click context menu on bag slots (new PopupMenu or Control)
  │     └─ Reads item.category to filter menu options
  │     └─ "Equip"   → EquipmentManager.equip(item)
  │     └─ "Consume" → existing _use_selected() logic
  │     └─ "Drop"    → existing _drop_selected() logic
  │
  └─ player.gd hit() implementation
        └─ Reads EquipmentManager.weapon_slot to get damage
        └─ Fist fallback (existing Attack resource) if slot empty
        └─ Placeholder visual indicator toggled by equipped_weapon_changed signal
```

### What Already Exists (no build needed)

- `Item.category` enum with `WEAPON` and `TOOL` values — context menu filtering is free
- `WeaponItem.damage: float` — weapon damage is already a field; no new data needed
- `Inventory.remove()` and `Inventory.insert()` — equip/unequip data operations reuse these
- `inventory_slot_ui.gd update(slot)` — HUD slot rendering reuses this exact pattern
- `_gui_input` on Panel for mouse events — right-click just adds `MOUSE_BUTTON_RIGHT` branch
- `player.gd hit(): pass` stub — explicit placeholder waiting for this feature

### What Needs to Be Built

1. `EquipmentManager` — new Resource (or autoload?) holding `weapon_slot: InventorySlot` and `tool_slot: InventorySlot`; signals for changes
2. HUD equipment strip scene — a small `HBoxContainer` or `Control` with two slot nodes, always visible
3. Context menu logic in `inventory_ui.gd` — right-click handling, dynamic option list, dispatch to equip/consume/drop
4. Equipment slot right-click on HUD — unequip action
5. `player.gd hit()` implementation — reads EquipmentManager, conditional damage
6. Placeholder visual indicator — child node on player toggled by signal

---

## MVP Recommendation

Prioritise in this order:

1. `EquipmentManager` data model — all other features read from it
2. Equip/unequip flow — correctness critical; broken flow loses items
3. `player.gd hit()` wiring — the point of the whole feature
4. Right-click context menu on bag — the primary UX verb
5. HUD equipment strip — visibility of equipped state
6. Placeholder visual indicator — polish, but fast to add

Defer:
- Tooltip: not in table stakes; easy to add in a follow-on PR
- Weapon stat badge on HUD: cosmetic; defer until real art pass

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Table stakes — HUD strip | HIGH | Genre convention well-established; codebase audit confirms inventory_slot_ui pattern is directly reusable |
| Table stakes — right-click menu | HIGH | item.category enum already has WEAPON/TOOL/FOOD/MATERIAL; filter logic follows directly |
| Table stakes — equip/unequip flow | HIGH | Inventory.insert/remove confirmed correct and tested; equip is a data operation on top |
| Table stakes — combat wiring | HIGH | hit() stub explicitly present in player.gd; Attack resource and WeaponItem.damage both exist |
| Differentiators complexity | MEDIUM | Estimates from code reading; actual effort depends on Godot Control tree details |
| Anti-feature rationale | HIGH | Dependencies audited directly from codebase — HarvestableComponent genuinely absent |

---

## Sources

- Direct codebase audit: `scripts/player.gd`, `scripts/inventory_ui.gd`, `scripts/inventory_slot_ui.gd`, `scripts/resources/item.gd`, `scripts/resources/weapon_item.gd`, `scripts/resources/inventory.gd`, `scripts/attack.gd`
- `.planning/PROJECT.md` — milestone requirements, future features, technical debt list
- Genre conventions inferred from domain knowledge (Stardew Valley, Terraria, Diablo inventory systems) — MEDIUM confidence; WebSearch unavailable during this research session

---

*Research complete: 2026-03-13*
