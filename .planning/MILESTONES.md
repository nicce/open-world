# Milestones

## v1.1 Equipment Slots (Shipped: 2026-03-27)

**Phases completed:** 4 phases (5–8), 9 plans
**Timeline:** 2026-03-18 → 2026-03-27 (9 days)
**Files changed:** 61 | **GDScript LOC:** ~17,600

**Key accomplishments:**

- `EquipmentData` Resource with weapon/tool slots, displaced-item return contract, and `equipment_changed` signal — pure Resource testable without scene tree
- Right-click context menu on bag slots with item-type-aware actions (Equip/Consume/Drop) using named const IDs with `id_pressed`
- Atomic equip/unequip transaction in InventoryUI — remove-before-equip ordering, displaced-weapon-return, full-bag guard (14 requirements, 144 unit tests)
- Player `hit()` reads equipped weapon damage at call time with `int()` cast; fist damage fallback when no weapon
- Always-visible HUD strip (48×48 W/T slots anchored bottom-center) subscribing to `equipment_changed` with modulate dimming + gold border
- HUD strip right-click context menu (Unequip/Drop) with viewport-safe clamped positioning across all UI entry points

---

## v1.0 Inventory & Combat (Shipped: 2026-03-13)

**Phases completed:** 4 phases, 11 plans, 0 tasks

**Key accomplishments:**

- (none recorded)

---
