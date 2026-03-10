extends GutTest

var _slot: InventorySlot


func before_each() -> void:
	_slot = InventorySlot.new()


# Forward-compatible helper: assigns id once the field exists (DATA-01).
# Until Plan 03 adds `id: StringName` to Item, passing a non-empty id will
# raise "Invalid set index 'id'" — keeping these tests RED.
func _make_item(item_name: String, item_weight: float = 1.0, item_id: StringName = &"") -> Item:
	var item = Item.new()
	item.name = item_name
	item.weight = item_weight
	if item_id != &"":
		item.id = item_id  # Will error until DATA-01 adds the id field.
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


# ---------------------------------------------------------------------------
# DATA-01: Item identity must be based on id (StringName), not name (String).
#
# Bug: can_stack() compares item.name — two items with the same display name
# but different ids (e.g. "Wood Log" vs "Wood Plank") incorrectly stack.
#
# These tests are RED until Plan 03 adds `id: StringName` to Item AND
# Plan 02 fixes can_stack() to use id comparison.
# ---------------------------------------------------------------------------


func test_cannot_stack_same_name_different_id() -> void:
	# Two items share the display name "Wood" but have different ids.
	# They must NOT be treated as the same item for stacking purposes.
	var wood_log = _make_item("Wood", 1.0, &"wood_log")
	_slot.item = wood_log
	_slot.quantity = 3

	var wood_plank = _make_item("Wood", 1.0, &"wood_plank")

	assert_false(
		_slot.can_stack(wood_plank),
		"Items with different ids must not stack even if name is identical"
	)


func test_can_stack_same_id() -> void:
	# Two items with the same id are the same logical item and MUST stack.
	var wood_log_a = _make_item("Wood", 1.0, &"wood_log")
	_slot.item = wood_log_a
	_slot.quantity = 3

	var wood_log_b = _make_item("Wood", 1.0, &"wood_log")

	assert_true(
		_slot.can_stack(wood_log_b),
		"Items with identical ids must be stackable"
	)
