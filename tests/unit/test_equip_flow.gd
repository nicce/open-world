extends GutTest

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _make_inventory(slot_count: int = 15, max_weight: float = 100.0) -> Inventory:
	var inv := Inventory.new()
	inv.max_weight = max_weight
	for i in range(slot_count):
		var slot := InventorySlot.new()
		slot.max_stack = 10
		inv.slots.append(slot)
	return inv


func _make_weapon(weapon_id: StringName = &"sword") -> WeaponItem:
	var weapon := WeaponItem.new()
	weapon.id = weapon_id
	weapon.name = String(weapon_id).capitalize()
	weapon.weight = 1.0
	return weapon


func _make_tool_item() -> Item:
	var item := Item.new()
	item.id = &"shovel"
	item.name = "Shovel"
	item.weight = 0.5
	item.category = Item.Category.TOOL
	return item


# ---------------------------------------------------------------------------
# EQUIP-01: equip_weapon removes item from bag, stores in equipment_data
# ---------------------------------------------------------------------------


func test_equip_weapon_removes_from_bag() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var sword := _make_weapon()

	inventory.insert(sword, 1)
	assert_false(inventory.slots[0].is_empty(), "sword should be in bag before equip")

	# Transaction sequence used by _do_equip_weapon
	var removed := inventory.remove(sword, 1)
	assert_eq(removed, 1, "remove should succeed")
	ed.equip_weapon(sword)

	assert_true(inventory.slots[0].is_empty(), "bag slot should be empty after equip")


func test_equip_weapon_stores_in_equipment_data() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var sword := _make_weapon()

	inventory.insert(sword, 1)
	inventory.remove(sword, 1)
	ed.equip_weapon(sword)

	assert_eq(ed.weapon, sword, "equipment_data.weapon should hold the sword")


# ---------------------------------------------------------------------------
# EQUIP-02: equip_weapon swap — displaced weapon returns to bag
# ---------------------------------------------------------------------------


func test_equip_weapon_swap_returns_displaced_to_bag() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var sword_a := _make_weapon(&"sword_a")
	var sword_b := _make_weapon(&"sword_b")

	# Equip sword_a first
	inventory.insert(sword_a, 1)
	inventory.remove(sword_a, 1)
	var displaced_a: WeaponItem = ed.equip_weapon(sword_a)
	if displaced_a != null:
		inventory.insert(displaced_a, 1)

	# Now equip sword_b (sword_a should be displaced back to bag)
	inventory.insert(sword_b, 1)
	inventory.remove(sword_b, 1)
	var displaced: WeaponItem = ed.equip_weapon(sword_b)
	if displaced != null:
		inventory.insert(displaced, 1)

	assert_true(inventory.has_item(sword_a, 1), "displaced sword_a should be back in the bag")


func test_equip_weapon_swap_new_weapon_in_slot() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var sword_a := _make_weapon(&"sword_a")
	var sword_b := _make_weapon(&"sword_b")

	# Equip sword_a
	inventory.insert(sword_a, 1)
	inventory.remove(sword_a, 1)
	var displaced_a: WeaponItem = ed.equip_weapon(sword_a)
	if displaced_a != null:
		inventory.insert(displaced_a, 1)

	# Equip sword_b (displaces sword_a)
	inventory.insert(sword_b, 1)
	inventory.remove(sword_b, 1)
	var displaced: WeaponItem = ed.equip_weapon(sword_b)
	if displaced != null:
		inventory.insert(displaced, 1)

	assert_eq(ed.weapon, sword_b, "equipment_data.weapon should be sword_b after swap")


# ---------------------------------------------------------------------------
# EQUIP-03: unequip_weapon — full bag keeps weapon equipped
# ---------------------------------------------------------------------------


func test_unequip_weapon_returns_to_bag() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var sword := _make_weapon()

	inventory.insert(sword, 1)
	inventory.remove(sword, 1)
	ed.equip_weapon(sword)

	# Transaction sequence used by _do_unequip_weapon
	var weapon := ed.weapon
	var remaining := inventory.insert(weapon, 1)
	if remaining == 0:
		ed.unequip_weapon()

	assert_null(ed.weapon, "equipment_data.weapon should be null after unequip")
	assert_true(inventory.has_item(sword, 1), "sword should be back in the bag")


func test_unequip_weapon_full_bag_stays_equipped() -> void:
	# Create a tiny inventory with weight capacity for exactly 1 item per slot
	# We fill all slots with items to make insert() fail
	var inventory := _make_inventory(2, 2.0)
	var ed := EquipmentData.new()
	var sword := _make_weapon()
	sword.weight = 1.0

	# Fill both slots so bag is full
	var filler_a := _make_weapon(&"filler_a")
	filler_a.weight = 1.0
	var filler_b := _make_weapon(&"filler_b")
	filler_b.weight = 1.0
	inventory.insert(filler_a, 1)
	inventory.insert(filler_b, 1)

	# Equip the sword directly (simulating it was equipped from elsewhere)
	ed.equip_weapon(sword)
	assert_eq(ed.weapon, sword, "sword should be equipped before unequip attempt")

	# Transaction sequence used by _do_unequip_weapon
	var weapon := ed.weapon
	var remaining := inventory.insert(weapon, 1)
	if remaining == 0:
		ed.unequip_weapon()

	# Bag is full — sword must remain equipped
	assert_not_null(ed.weapon, "weapon should stay equipped when bag is full")
	assert_eq(ed.weapon, sword, "equipped weapon should still be sword")


# ---------------------------------------------------------------------------
# EQUIP-04: equip_tool removes from bag, stores in equipment_data
# ---------------------------------------------------------------------------


func test_equip_tool_removes_from_bag() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var shovel := _make_tool_item()

	inventory.insert(shovel, 1)
	assert_false(inventory.slots[0].is_empty(), "shovel should be in bag before equip")

	# Transaction sequence used by _do_equip_tool
	var removed := inventory.remove(shovel, 1)
	assert_eq(removed, 1, "remove should succeed")
	ed.equip_tool(shovel)

	assert_true(inventory.slots[0].is_empty(), "bag slot should be empty after equip")
	assert_eq(ed.tool, shovel, "equipment_data.tool should hold the shovel")


# ---------------------------------------------------------------------------
# Invariant: no item in both bag and equipment slot simultaneously
# ---------------------------------------------------------------------------


func test_no_item_in_both_bag_and_weapon_slot() -> void:
	var inventory := _make_inventory()
	var ed := EquipmentData.new()
	var sword := _make_weapon()

	inventory.insert(sword, 1)
	inventory.remove(sword, 1)
	ed.equip_weapon(sword)

	# sword should not be in the bag
	assert_false(inventory.has_item(sword, 1), "sword must not be in bag after equip")
	assert_not_null(ed.weapon, "sword must be in equipment slot")
