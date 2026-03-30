extends GutTest

func test_get_item_resolves_sword() -> void:
	var item = ItemRegistry.get_item(&"sword")
	assert_not_null(item, "Sword should be resolved")
	assert_eq(item.id, &"sword", "ID should match")
	assert_true(item is WeaponItem, "Sword should be a WeaponItem")


func test_get_item_resolves_medpack() -> void:
	var item = ItemRegistry.get_item(&"medpack")
	assert_not_null(item, "Medpack should be resolved")
	assert_eq(item.id, &"medpack", "ID should match")
	assert_true(item is HealthItem, "Medpack should be a HealthItem")


func test_get_item_returns_null_for_unknown_id() -> void:
	# This will also trigger a warning in the console/logs
	var item = ItemRegistry.get_item(&"unknown_item_123")
	assert_null(item, "Unknown ID should return null")
