extends GutTest

var _inventory: Inventory


func before_each() -> void:
	_inventory = Inventory.new()
	for i in range(5):
		_inventory.items.append(null)


func test_insert_into_empty_slot_returns_true() -> void:
	var item := Item.new()
	assert_true(_inventory.insert(item))


func test_insert_places_item_in_first_available_slot() -> void:
	var item := Item.new()
	_inventory.insert(item)
	assert_eq(_inventory.items[0], item)


func test_insert_skips_occupied_slots() -> void:
	var first := Item.new()
	var second := Item.new()
	_inventory.items[0] = first
	_inventory.insert(second)
	assert_eq(_inventory.items[1], second)


func test_insert_into_full_inventory_returns_false() -> void:
	for i in range(5):
		_inventory.items[i] = Item.new()
	var item := Item.new()
	assert_false(_inventory.insert(item))


func test_insert_does_not_modify_full_inventory() -> void:
	var existing_items: Array[Item] = []
	for i in range(5):
		var item := Item.new()
		_inventory.items[i] = item
		existing_items.append(item)

	var overflow := Item.new()
	_inventory.insert(overflow)

	for i in range(5):
		assert_eq(_inventory.items[i], existing_items[i])


func test_insert_into_empty_array_returns_false() -> void:
	var empty_inventory := Inventory.new()
	assert_false(empty_inventory.insert(Item.new()))
