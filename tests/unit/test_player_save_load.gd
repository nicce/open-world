extends GutTest

const TEST_SAVE_PATH = "user://test_player_round_trip.json"

var player_scene = preload("res://scenes/player.tscn")
var player: Player
var sword_res = preload("res://resources/items/sword.tres")

func before_each():
	player = player_scene.instantiate()
	player.inventory = Inventory.new()
	# Set some default equipment to avoid null reference if hit() is called or similar
	add_child(player)

func after_each():
	if is_instance_valid(player):
		player.free()
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

func test_player_to_dict():
	player.position = Vector2(100, 200)
	player.health_component.health = 50
	var dict = player.to_dict()
	assert_eq(dict.position.x, 100.0)
	assert_eq(dict.position.y, 200.0)
	assert_eq(dict.health, 50)

func test_player_from_dict():
	var dict = {
		"position": {"x": 300.0, "y": 400.0},
		"health": 25
	}
	player.from_dict(dict)
	assert_eq(player.position, Vector2(300, 400))
	assert_eq(player.health_component.health, 25)

func test_player_round_trip():
	player.position = Vector2(123, 456)
	player.health_component.health = 75
	SaveManager.save_game(player, TEST_SAVE_PATH)

	var new_player = player_scene.instantiate()
	new_player.inventory = Inventory.new()
	add_child(new_player)
	SaveManager.load_game(new_player, TEST_SAVE_PATH)

	assert_eq(new_player.position, Vector2(123, 456))
	assert_eq(new_player.health_component.health, 75)
	new_player.free()


func test_inventory_round_trip():
	player.inventory = Inventory.new()
	for i in range(5):
		player.inventory.slots.append(InventorySlot.new())
	player.inventory.insert(sword_res, 1)
	SaveManager.save_game(player, TEST_SAVE_PATH)

	var new_player = player_scene.instantiate()
	new_player.inventory = Inventory.new()
	for i in range(5):
		new_player.inventory.slots.append(InventorySlot.new())
	add_child(new_player)
	SaveManager.load_game(new_player, TEST_SAVE_PATH)

	assert_true(new_player.inventory.has_item(sword_res, 1), "inventory should contain sword after load")
	new_player.free()


func test_equipment_round_trip():
	player.inventory = Inventory.new()
	for i in range(5):
		player.inventory.slots.append(InventorySlot.new())
	if player.equipment_data:
		player.equipment_data.equip_weapon(sword_res)
	SaveManager.save_game(player, TEST_SAVE_PATH)

	var new_player = player_scene.instantiate()
	new_player.inventory = Inventory.new()
	for i in range(5):
		new_player.inventory.slots.append(InventorySlot.new())
	add_child(new_player)
	SaveManager.load_game(new_player, TEST_SAVE_PATH)

	if new_player.equipment_data:
		assert_not_null(new_player.equipment_data.weapon, "weapon slot should be restored after load")
		assert_eq(new_player.equipment_data.weapon.id, &"sword", "equipped weapon id should be sword")
	new_player.free()


func test_equip05_invariant_after_load():
	player.inventory = Inventory.new()
	for i in range(5):
		player.inventory.slots.append(InventorySlot.new())
	player.inventory.insert(sword_res, 1)
	player.inventory.remove(sword_res, 1)
	if player.equipment_data:
		player.equipment_data.equip_weapon(sword_res)
	SaveManager.save_game(player, TEST_SAVE_PATH)

	var new_player = player_scene.instantiate()
	new_player.inventory = Inventory.new()
	for i in range(5):
		new_player.inventory.slots.append(InventorySlot.new())
	add_child(new_player)
	SaveManager.load_game(new_player, TEST_SAVE_PATH)

	if new_player.equipment_data:
		assert_not_null(new_player.equipment_data.weapon, "weapon should be in equipment slot")
		assert_false(
			new_player.inventory.has_item(sword_res, 1),
			"sword must NOT be in bag after load (EQUIP-05)"
		)
	new_player.free()
