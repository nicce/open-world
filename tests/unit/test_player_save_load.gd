extends GutTest

var player_scene = preload("res://scenes/player.tscn")
var player: Player

func before_each():
	player = player_scene.instantiate()
	player.inventory = Inventory.new()
	# Set some default equipment to avoid null reference if hit() is called or similar
	add_child(player)

func after_each():
	if is_instance_valid(player):
		player.free()
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)

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
	SaveManager.save_game(player)
	
	var new_player = player_scene.instantiate()
	new_player.inventory = Inventory.new()
	add_child(new_player)
	SaveManager.load_game(new_player)
	
	assert_eq(new_player.position, Vector2(123, 456))
	assert_eq(new_player.health_component.health, 75)
	new_player.free()
