# Phase 11: Full Round-Trip — Inventory and Equipment - Research

**Researched:** 2026-03-31
**Domain:** GDScript — extending existing save/load serialization
**Confidence:** HIGH (all building blocks exist in codebase; no new APIs needed)

## Summary

All required serialization primitives were built in Phase 9 and the file I/O pipeline in Phase 10. This phase closes the gap by wiring them together inside `Player.to_dict()` / `Player.from_dict()`.

**Primary recommendation:** Modify `scripts/player.gd` only — no new files, no new APIs. Extend the two methods and expand the test in `tests/unit/test_player_save_load.gd`.

## What Exists (verified from codebase)

| Component | Location | Status |
|-----------|----------|--------|
| `Inventory.to_dict()` / `from_dict()` | `scripts/resources/inventory.gd` | ✅ Phase 9 |
| `EquipmentData.to_dict()` / `from_dict()` | `scripts/resources/equipment_data.gd` | ✅ Phase 9 |
| `HealthComponent.load_health()` | `scripts/health_component.gd` | ✅ Phase 9 |
| `ItemRegistry.get_item()` | `scripts/item_registry.gd` (autoload) | ✅ Phase 9 |
| `SaveManager.save_game()` / `load_game()` | `scripts/save_manager.gd` (autoload) | ✅ Phase 10 |
| `Player.to_dict()` / `from_dict()` | `scripts/player.gd` | ✅ Phase 10 (position + health only) |

## Gap Analysis

`Player.to_dict()` currently serialises `position` and `health` only. The `inventory` and `equipment_data` fields are already on the Player node (`@export var inventory: Inventory`, `@export var equipment_data: EquipmentData`) but their serialisation is never called.

## EQUIP-05 Invariant

During normal gameplay, equipping a weapon removes it from the bag. The save format naturally captures this correctly:
- `inventory.to_dict()` produces a sparse dict of bag slots (no equipped weapon)
- `equipment_data.to_dict()` produces the weapon/tool slot ids separately

On `from_dict()`, restoring **inventory first** then **equipment second** guarantees EQUIP-05: the bag is populated without the equipped item, then the equipment slot is populated independently. The equipped item therefore cannot appear in both.

## Ordering Requirement

`from_dict()` must call `inventory.from_dict()` **before** `equipment_data.from_dict()`. Reason: `from_dict()` on EquipmentData calls `equip_weapon()` which emits `equipment_changed` — this must fire only after the HUD strip is wired (done in `world.gd._ready()`) and after inventory is already in its restored state.

## No New APIs Required

`SaveManager.load_game()` calls `player.from_dict(result["player"])` unchanged. The extended `from_dict()` transparently handles the new keys — no SaveManager changes needed.

## Null Guard

`equipment_data` may be `null` in test scenes. The `from_dict()` extension must null-check before calling `equipment_data.from_dict()`.

## Sources

All findings from direct codebase inspection of Phase 9/10 artifacts.
