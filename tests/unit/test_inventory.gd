extends GutTest

var _inventory: Inventory


func _make_inventory(slot_count: int = 5, weight: float = 100.0) -> Inventory:
	var inv = Inventory.new()
	inv.max_weight = weight
	for i in range(slot_count):
		inv.slots.append(InventorySlot.new())
	return inv


# Forward-compatible helper: assigns id once the field exists (DATA-01).
# Until Plan 03 adds `id: StringName` to Item, passing a non-empty id will
# raise "Invalid set index 'id'" — tests that use ids remain RED.
func _make_item(item_name: String, item_weight: float = 1.0, item_id: StringName = &"") -> Item:
	var item = Item.new()
	item.id = item_id if item_id != &"" else StringName(item_name.to_lower().replace(" ", "_"))
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


# ---------------------------------------------------------------------------
# DATA-02: Inventory.duplicate(true) must produce a fully independent copy.
#
# Bug: Godot's default Resource.duplicate(true) does not deep-copy typed
# Array[InventorySlot] — the slots array entries still share references with
# the original, so mutating the copy mutates the original.
#
# The fix (Plan 02) must override duplicate() or implement a clone() method
# that manually copies each slot.
#
# These tests are RED until Plan 02 implements true deep-copy isolation.
# ---------------------------------------------------------------------------


func test_duplicate_true_isolates_slots() -> void:
	# Arrange: original inventory with 5 wood in slot 0.
	var original := _make_inventory(3, 100.0)
	var wood := _make_item("Wood")
	original.insert(wood, 5)
	assert_eq(original.slots[0].quantity, 5, "precondition: slot 0 has 5 wood")

	# Act: deep-copy via clone() then mutate the copy.
	# Note: Godot 4 native duplicate(true) does not deep-copy typed Array[InventorySlot]
	# elements, so Inventory.clone() is used instead.
	var copy := original.clone()
	copy.insert(wood, 3)

	# Assert: original must be unchanged.
	assert_eq(
		original.slots[0].quantity,
		5,
		"Mutating the clone must not affect the original inventory slot quantity"
	)


func test_duplicate_slots_are_different_references() -> void:
	# The slot objects in the copy must not be the same object instances as
	# those in the original.
	var original := _make_inventory(3, 100.0)
	var wood := _make_item("Wood")
	original.insert(wood, 1)

	var copy := original.clone()

	assert_ne(
		original.slots[0],
		copy.slots[0],
		"clone() must produce independent InventorySlot instances"
	)


# ---------------------------------------------------------------------------
# DATA-03: Weight budget must use floori() to avoid float precision errors.
#
# Bug: inventory.insert() computes `int(remaining_weight() / item.weight)`.
# Due to floating-point representation, 1.0 / 1.0 may yield 0.9999… which
# int() truncates to 0, refusing an item that should fit exactly.
#
# The fix (Plan 02) must replace int() with floori() at lines 29 and 41.
#
# The exact-boundary test IS expected to be RED on the buggy code path.
# ---------------------------------------------------------------------------


func test_insert_at_exact_weight_limit_accepts_item() -> void:
	# Arrange: 10-unit max weight, 9 units already used (9 × 1.0 kg items).
	var inv := _make_inventory(5, 10.0)
	var light := _make_item("Pebble", 1.0)
	inv.insert(light, 9)
	assert_almost_eq(inv.remaining_weight(), 1.0, 0.001, "precondition: exactly 1.0 weight left")

	# Act: insert one more item with weight == remaining_weight exactly.
	var last := _make_item("Pebble", 1.0)
	var leftover := inv.insert(last, 1)

	# Assert: item must be accepted — 0 leftover.
	assert_eq(
		leftover,
		0,
		"An item whose weight exactly equals remaining_weight must be accepted"
	)
	assert_almost_eq(
		inv.remaining_weight(),
		0.0,
		0.001,
		"Inventory must be exactly full after inserting at the boundary"
	)


# ---------------------------------------------------------------------------
# Signal tests: inventory_changed and insert_rejected
# ---------------------------------------------------------------------------


func test_inventory_changed_emitted_on_successful_insert() -> void:
	var inv := _make_inventory(5, 100.0)
	var wood := _make_item("Wood")
	watch_signals(inv)
	inv.insert(wood, 1)
	assert_signal_emitted(inv, "inventory_changed")
	assert_signal_emit_count(inv, "inventory_changed", 1)


func test_inventory_changed_not_emitted_when_nothing_inserted() -> void:
	# Fill inventory completely then try to insert one more item.
	var inv := _make_inventory(2, 10.0)
	var heavy := _make_item("Boulder", 5.0)
	inv.insert(heavy, 1)
	inv.insert(heavy, 1)
	# Inventory is now full (10/10 kg, both slots used).
	watch_signals(inv)
	inv.insert(heavy, 1)
	assert_signal_not_emitted(inv, "inventory_changed")


func test_insert_rejected_emitted_when_weight_blocks_all() -> void:
	# Item weighs 10 kg, inventory max weight is 5 kg — nothing can fit.
	var inv := _make_inventory(5, 5.0)
	var too_heavy := _make_item("Boulder", 10.0)
	watch_signals(inv)
	inv.insert(too_heavy, 1)
	assert_signal_emitted(inv, "insert_rejected")
	assert_signal_emit_count(inv, "insert_rejected", 1)


func test_insert_rejected_not_emitted_on_successful_insert() -> void:
	var inv := _make_inventory(5, 100.0)
	var wood := _make_item("Wood")
	watch_signals(inv)
	inv.insert(wood, 1)
	assert_signal_not_emitted(inv, "insert_rejected")


# ---------------------------------------------------------------------------
# INV-02 gap closure: insert_rejected must fire when slots are full even
# when weight budget is available.
# ---------------------------------------------------------------------------


func test_insert_rejected_emitted_when_slots_full_but_weight_allows() -> void:
	# 2 slots, 100 kg max — fill both slots, then try a third distinct item.
	var inv := _make_inventory(2, 100.0)
	var wood := _make_item("Wood")
	inv.insert(wood, 10)  # fills slot 0 to max_stack (10)
	inv.insert(wood, 10)  # fills slot 1 to max_stack (10)
	# Weight used: 20 kg of 100 kg — plenty of budget remains.
	var stone := _make_item("Stone")
	watch_signals(inv)
	inv.insert(stone, 1)
	assert_signal_emitted(inv, "insert_rejected")
	assert_signal_emit_count(inv, "insert_rejected", 1)
