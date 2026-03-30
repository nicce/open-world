extends GutTest

var sword_res = preload("res://resources/items/sword.tres")
var axe_res = preload("res://resources/items/axe.tres")

func test_inventory_round_trip():
	var inv = Inventory.new()
	# Add 5 slots
	for i in range(5):
		inv.slots.append(InventorySlot.new())
	
	inv.slots[1].item = sword_res
	inv.slots[1].quantity = 1
	inv.slots[3].item = axe_res
	inv.slots[3].quantity = 2
	
	var data = inv.to_dict()
	
	assert_has(data, "slots")
	assert_eq(data["slots"].size(), 2)
	assert_has(data["slots"], "1")
	assert_has(data["slots"], "3")
	assert_eq(data["slots"]["1"]["id"], &"sword")
	assert_eq(data["slots"]["1"]["qty"], 1)
	assert_eq(data["slots"]["3"]["id"], &"axe")
	assert_eq(data["slots"]["3"]["qty"], 2)
	
	var new_inv = Inventory.new()
	for i in range(5):
		new_inv.slots.append(InventorySlot.new())
	
	new_inv.from_dict(data)
	
	assert_eq(new_inv.slots[1].item.id, &"sword")
	assert_eq(new_inv.slots[1].quantity, 1)
	assert_eq(new_inv.slots[3].item.id, &"axe")
	assert_eq(new_inv.slots[3].quantity, 2)
	assert_true(new_inv.slots[0].is_empty())
	assert_true(new_inv.slots[2].is_empty())
	assert_true(new_inv.slots[4].is_empty())

func test_from_dict_clears_inventory():
	var inv = Inventory.new()
	for i in range(2):
		inv.slots.append(InventorySlot.new())
	
	inv.slots[0].item = sword_res
	inv.slots[0].quantity = 1
	
	var empty_data = {"slots": {}}
	inv.from_dict(empty_data)
	
	assert_true(inv.slots[0].is_empty())

func test_inventory_changed_emitted():
	var inv = Inventory.new()
	for i in range(2):
		inv.slots.append(InventorySlot.new())
	
	watch_signals(inv)
	inv.from_dict({"slots": {}})
	assert_signal_emitted(inv, "inventory_changed")
