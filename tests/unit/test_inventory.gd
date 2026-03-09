extends GutTest

var _inventory: Inventory


func _make_inventory(slot_count: int = 5, weight: float = 100.0) -> Inventory:
	var inv = Inventory.new()
	inv.max_weight = weight
	for i in range(slot_count):
		inv.slots.append(InventorySlot.new())
	return inv


func _make_item(item_name: String, item_weight: float = 1.0) -> Item:
	var item = Item.new()
	item.name = item_name
	item.weight = item_weight
	return item


func before_each() -> void:
	_inventory = _make_inventory()


# --- insert basics ---

func test_insert_single_item_returns_zero_remaining() -> void:
	var wood = _make_item("Wood")
	assert_eq(_inventory.insert(wood), 0)


func test_insert_places_item_in_first_empty_slot() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood)
	assert_eq(_inventory.slots[0].item, wood)
	assert_eq(_inventory.slots[0].quantity, 1)


func test_insert_zero_amount_returns_zero() -> void:
	assert_eq(_inventory.insert(_make_item("Wood"), 0), 0)


# --- stacking ---

func test_insert_stacks_same_item() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 3)
	_inventory.insert(wood, 4)
	assert_eq(_inventory.slots[0].quantity, 7)
	assert_true(_inventory.slots[1].is_empty())


func test_insert_overflow_to_new_slot() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 8)
	_inventory.insert(wood, 5)
	assert_eq(_inventory.slots[0].quantity, 10)
	assert_eq(_inventory.slots[1].quantity, 3)


func test_insert_different_items_use_separate_slots() -> void:
	var wood = _make_item("Wood")
	var stone = _make_item("Stone")
	_inventory.insert(wood, 3)
	_inventory.insert(stone, 2)
	assert_eq(_inventory.slots[0].item.name, "Wood")
	assert_eq(_inventory.slots[1].item.name, "Stone")


# --- weight limits ---

func test_insert_respects_max_weight() -> void:
	var inv = _make_inventory(5, 10.0)
	var heavy = _make_item("Log", 5.0)
	var remaining = inv.insert(heavy, 3)
	assert_eq(remaining, 1)
	assert_eq(inv.get_item_count(heavy), 2)


func test_insert_rejects_when_overweight() -> void:
	var inv = _make_inventory(5, 5.0)
	var heavy = _make_item("Boulder", 10.0)
	var remaining = inv.insert(heavy, 1)
	assert_eq(remaining, 1)


func test_current_weight_sums_all_slots() -> void:
	var wood = _make_item("Wood", 2.0)
	_inventory.insert(wood, 5)
	assert_almost_eq(_inventory.current_weight(), 10.0, 0.001)


func test_remaining_weight() -> void:
	var inv = _make_inventory(5, 50.0)
	var wood = _make_item("Wood", 2.0)
	inv.insert(wood, 10)
	assert_almost_eq(inv.remaining_weight(), 30.0, 0.001)


# --- stack limit ---

func test_stack_limit_splits_across_slots() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 15)
	assert_eq(_inventory.slots[0].quantity, 10)
	assert_eq(_inventory.slots[1].quantity, 5)


# --- full inventory ---

func test_insert_into_full_inventory_returns_remaining() -> void:
	var inv = _make_inventory(2)
	var wood = _make_item("Wood")
	inv.insert(wood, 10)
	inv.insert(wood, 10)
	var remaining = inv.insert(wood, 5)
	assert_eq(remaining, 5)


func test_insert_into_empty_slots_array_returns_amount() -> void:
	var inv = Inventory.new()
	assert_eq(inv.insert(_make_item("Wood"), 3), 3)


# --- remove ---

func test_remove_returns_count_removed() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 5)
	var removed = _inventory.remove(wood, 3)
	assert_eq(removed, 3)


func test_remove_decreases_quantity() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 5)
	_inventory.remove(wood, 3)
	assert_eq(_inventory.get_item_count(wood), 2)


func test_remove_across_slots() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 15)
	var removed = _inventory.remove(wood, 12)
	assert_eq(removed, 12)
	assert_eq(_inventory.get_item_count(wood), 3)


func test_remove_more_than_available_returns_available() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 3)
	var removed = _inventory.remove(wood, 10)
	assert_eq(removed, 3)


func test_remove_clears_slot() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 5)
	_inventory.remove(wood, 5)
	assert_true(_inventory.slots[0].is_empty())


# --- queries ---

func test_get_item_count() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 15)
	assert_eq(_inventory.get_item_count(wood), 15)


func test_has_item_true() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 5)
	assert_true(_inventory.has_item(wood, 5))


func test_has_item_false() -> void:
	var wood = _make_item("Wood")
	_inventory.insert(wood, 3)
	assert_false(_inventory.has_item(wood, 5))


func test_has_item_not_in_inventory() -> void:
	var wood = _make_item("Wood")
	assert_false(_inventory.has_item(wood))
