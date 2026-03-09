extends GutTest

var _slot: InventorySlot


func before_each() -> void:
	_slot = InventorySlot.new()


func _make_item(item_name: String, item_weight: float = 1.0) -> Item:
	var item = Item.new()
	item.name = item_name
	item.weight = item_weight
	return item


func test_new_slot_is_empty() -> void:
	assert_true(_slot.is_empty())


func test_slot_with_item_is_not_empty() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 1
	assert_false(_slot.is_empty())


func test_is_full_at_max_stack() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 10
	assert_true(_slot.is_full())


func test_is_not_full_below_max() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 5
	assert_false(_slot.is_full())


func test_space_remaining() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 7
	assert_eq(_slot.space_remaining(), 3)


func test_total_weight() -> void:
	_slot.item = _make_item("Wood", 2.5)
	_slot.quantity = 4
	assert_almost_eq(_slot.total_weight(), 10.0, 0.001)


func test_total_weight_empty_slot() -> void:
	assert_almost_eq(_slot.total_weight(), 0.0, 0.001)


func test_can_stack_same_item() -> void:
	var wood = _make_item("Wood")
	_slot.item = wood
	_slot.quantity = 3
	var other_wood = _make_item("Wood")
	assert_true(_slot.can_stack(other_wood))


func test_cannot_stack_different_item() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 3
	var stone = _make_item("Stone")
	assert_false(_slot.can_stack(stone))


func test_cannot_stack_on_empty_slot() -> void:
	assert_false(_slot.can_stack(_make_item("Wood")))


func test_cannot_stack_when_full() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 10
	assert_false(_slot.can_stack(_make_item("Wood")))


func test_add_returns_zero_leftover_when_space() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 5
	var leftover = _slot.add(3)
	assert_eq(leftover, 0)
	assert_eq(_slot.quantity, 8)


func test_add_returns_leftover_when_exceeds_max() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 8
	var leftover = _slot.add(5)
	assert_eq(leftover, 3)
	assert_eq(_slot.quantity, 10)


func test_remove_returns_removed_count() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 5
	var removed = _slot.remove(3)
	assert_eq(removed, 3)
	assert_eq(_slot.quantity, 2)


func test_remove_clears_slot_when_empty() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 2
	_slot.remove(2)
	assert_true(_slot.is_empty())
	assert_null(_slot.item)


func test_remove_caps_at_available_quantity() -> void:
	_slot.item = _make_item("Wood")
	_slot.quantity = 3
	var removed = _slot.remove(10)
	assert_eq(removed, 3)
	assert_true(_slot.is_empty())
