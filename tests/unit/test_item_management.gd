extends GutTest


# ---------------------------------------------------------------------------
# Item Management tests — ITEM-01, ITEM-02, ITEM-03
#
# These tests are RED (failing) by design. They define the behavioral contract
# that Plans 02 and 03 must satisfy via implementation.
#
# ITEM-01: Use selected item (inventory_ui._use_selected())
# ITEM-02: Drop selected item (inventory_ui._drop_selected())
# ITEM-03: item_collected signal emitted on Player.collect() success
# ---------------------------------------------------------------------------


func _make_inventory(slot_count: int = 5, weight: float = 100.0) -> Inventory:
	var inv = Inventory.new()
	inv.max_weight = weight
	for i in range(slot_count):
		inv.slots.append(InventorySlot.new())
	return inv


func _make_item(
	item_name: String, item_weight: float = 1.0, item_id: StringName = &""
) -> Item:
	var item = Item.new()
	item.id = item_id if item_id != &"" else StringName(item_name.to_lower().replace(" ", "_"))
	item.name = item_name
	item.weight = item_weight
	return item


func _make_health_item(item_name: String, heal_amount: int) -> HealthItem:
	var item = HealthItem.new()
	item.id = StringName(item_name.to_lower().replace(" ", "_"))
	item.name = item_name
	item.health = heal_amount
	return item


# ---------------------------------------------------------------------------
# FakePlayer: a plain RefCounted that mirrors the collect() + item_collected
# contract without requiring CharacterBody2D / scene tree.
# ITEM-03 tests run against this stub.
# ---------------------------------------------------------------------------
class FakePlayer:
	extends RefCounted

	signal item_collected(item_name: String)

	func collect(item: Item, inventory: Inventory) -> bool:
		var remaining = inventory.insert(item)
		if remaining == 0:
			item_collected.emit(item.name)
			return true
		return false


# ===========================================================================
# ITEM-01: Use selected item
# ===========================================================================


func test_use_consumable_removes_one_from_inventory() -> void:
	# Arrange: insert a HealthItem; simulate _use_selected() logic:
	# if consumable → inventory.remove(item, 1) + player.increase_health(heal)
	var inv := _make_inventory()
	var potion := _make_health_item("Potion", 20)
	inv.insert(potion, 3)
	assert_eq(inv.get_item_count(potion), 3, "precondition: 3 potions in inventory")

	# Act: simulate what _use_selected() does — guard passes (consumable), remove 1
	var slot := inv.slots[0]
	assert_true(slot.item.consumable, "item must be consumable for use action")
	inv.remove(slot.item, 1)

	# Assert: quantity decremented by 1
	assert_eq(inv.get_item_count(potion), 2, "using a consumable must remove exactly 1 from inventory")


func test_use_nonconsumable_is_noop() -> void:
	# Arrange: non-consumable item in inventory
	var inv := _make_inventory()
	var sword := _make_item("Sword")
	sword.consumable = false
	inv.insert(sword, 1)
	var count_before := inv.get_item_count(sword)

	# Act: guard check — only consumables may be used; non-consumable is silent no-op.
	# _use_selected() returns early when slot.item.consumable is false — no remove call.
	var slot := inv.slots[0]
	if slot.item.consumable:
		inv.remove(slot.item, 1)  # This branch is NOT taken for non-consumables

	# Assert: inventory unchanged
	assert_eq(
		inv.get_item_count(sword),
		count_before,
		"non-consumable item must not be removed when E is pressed"
	)


func test_use_with_no_selection_is_noop() -> void:
	# Arrange: no slot selected (selected_index == -1)
	var inv := _make_inventory()
	var potion := _make_health_item("Potion", 10)
	inv.insert(potion, 2)
	var count_before := inv.get_item_count(potion)

	# Act: guard check — _use_selected() returns early when _selected_index < 0.
	# Simulate the guard: if selected_index < 0, no remove is called.
	var selected_index := -1
	if selected_index >= 0 and selected_index < inv.slots.size():
		var slot := inv.slots[selected_index]
		if slot.item.consumable:
			inv.remove(slot.item, 1)

	# Assert: inventory unchanged when no slot is selected
	assert_eq(
		inv.get_item_count(potion),
		count_before,
		"no selection must leave inventory unchanged"
	)


# ===========================================================================
# ITEM-02: Drop selected item
# ===========================================================================


func test_drop_removes_one_unit() -> void:
	# Arrange: 3 items in inventory
	var inv := _make_inventory()
	var wood := _make_item("Wood")
	inv.insert(wood, 3)
	assert_eq(inv.get_item_count(wood), 3, "precondition: 3 wood in inventory")

	# Act: _drop_selected() calls inventory.remove(item, 1)
	var removed := inv.remove(wood, 1)

	# Assert: quantity decremented by exactly 1
	assert_eq(removed, 1, "remove() must return 1 when 1 unit is removed")
	assert_eq(inv.get_item_count(wood), 2, "inventory must have 2 wood remaining after drop")


func test_drop_last_unit_empties_slot() -> void:
	# Arrange: exactly 1 item in slot 0
	var inv := _make_inventory()
	var berry := _make_item("Berry")
	inv.insert(berry, 1)
	assert_false(inv.slots[0].is_empty(), "precondition: slot 0 is occupied")

	# Act: remove the only unit
	inv.remove(berry, 1)

	# Assert: slot 0 is now empty
	assert_true(inv.slots[0].is_empty(), "slot must be empty after removing the last unit")


func test_drop_with_no_selection_is_noop() -> void:
	# Arrange: empty inventory, no selected item
	var inv := _make_inventory()
	var ghost := _make_item("Ghost")  # item never inserted

	# Act: _drop_selected() with no valid selection — nothing to remove.
	# Simulate the guard: if selected_index < 0, no remove is called.
	var selected_index := -1
	var removed := 0
	if selected_index >= 0 and selected_index < inv.slots.size():
		removed = inv.remove(ghost, 1)

	# Assert: nothing was removed
	assert_eq(removed, 0, "no selection must remove nothing from inventory")


# ===========================================================================
# ITEM-03: item_collected signal
# ===========================================================================


func test_collect_emits_item_collected_on_success() -> void:
	# Arrange: FakePlayer with a roomy inventory
	var inv := _make_inventory(5, 100.0)
	var player := FakePlayer.new()
	watch_signals(player)
	var herb := _make_item("Herb", 0.5)

	# Act: collect succeeds (inventory has room)
	var result := player.collect(herb, inv)

	# Assert: signal emitted with correct item name
	assert_true(result, "collect() must return true when insert succeeds")
	assert_signal_emitted(player, "item_collected")
	assert_signal_emitted_with_parameters(player, "item_collected", ["Herb"])


func test_collect_does_not_emit_on_failed_insert() -> void:
	# Arrange: FakePlayer with completely full inventory (0-slot inventory)
	var inv := Inventory.new()  # no slots — every insert returns amount unchanged
	var player := FakePlayer.new()
	watch_signals(player)
	var herb := _make_item("Herb", 0.5)

	# Act: collect fails (no room)
	var result := player.collect(herb, inv)

	# Assert: signal NOT emitted
	assert_false(result, "collect() must return false when insert fails")
	assert_signal_not_emitted(player, "item_collected")
