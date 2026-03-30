# Phase 9 Validation: Foundation — ItemRegistry and Resource Serialisation

## Truths
- [x] ItemRegistry resolves `&"sword"` to the correct Resource instance.
- [x] ItemRegistry logs a warning and returns `null` for unknown IDs.
- [x] Inventory `to_dict()` returns a sparse dictionary with `"id"` and `"qty"` keys.
- [x] Inventory `from_dict()` restores full state and emits `inventory_changed`.
- [x] EquipmentData `to_dict()` returns `"weapon"` and `"tool"` keys.
- [x] EquipmentData `from_dict()` restores state using `equip_*` methods.
- [x] HealthComponent `load_health()` updates health and the health bar without full re-initialisation.

## Artifacts
- [x] `scripts/item_registry.gd` exists and is an autoload.
- [x] `resources/items/sword.tres` exists as a `WeaponItem`.
- [x] `resources/items/axe.tres` exists as a `WeaponItem`.
- [x] `resources/items/medpack.tres` exists as a `HealthItem`.
- [x] `resources/items/gold_key.tres` exists as an `Item`.
- [x] `tests/unit/test_item_registry.gd` passes.
- [x] `tests/unit/test_inventory_serialisation.gd` passes.
- [x] `tests/unit/test_equipment_serialisation.gd` passes.
- [x] `tests/unit/test_health_serialisation.gd` passes.

## Key Links
- [x] `Inventory.from_dict()` -> `ItemRegistry.get_item()` (ID resolution)
- [x] `EquipmentData.from_dict()` -> `ItemRegistry.get_item()` (ID resolution)
- [x] `HealthComponent.load_health()` -> `HealthBar.update()` (UI sync)
