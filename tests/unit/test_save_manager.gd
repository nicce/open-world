extends GutTest

const TEST_SAVE_PATH = "user://test_save_data.json"

func before_each() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH + ".tmp"):
		DirAccess.remove_absolute(TEST_SAVE_PATH + ".tmp")

func after_all() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH + ".tmp"):
		DirAccess.remove_absolute(TEST_SAVE_PATH + ".tmp")

func test_save_and_load_roundtrip() -> void:
	# JSON.parse results in floats for all numbers.
	var data = {"player_pos": [100.0, 200.0], "health": 80.0}
	var err = SaveManager.save_data(data, TEST_SAVE_PATH)
	assert_eq(err, OK, "Save should be successful")

	var loaded_data = SaveManager.load_data(TEST_SAVE_PATH)
	assert_eq(loaded_data, data, "Loaded data should match saved data")

func test_load_non_existent_returns_empty() -> void:
	var loaded_data = SaveManager.load_data(TEST_SAVE_PATH)
	assert_eq(loaded_data, {}, "Loading non-existent file should return empty dictionary")

func test_atomic_write_uses_tmp() -> void:
	var data = {"test": "data"}
	SaveManager.save_data(data, TEST_SAVE_PATH)
	assert_false(FileAccess.file_exists(TEST_SAVE_PATH + ".tmp"), "TMP file should be gone after save")
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH), "SAVE file should exist")

func test_save_manager_autoload_constant() -> void:
	assert_eq(SaveManager.SAVE_PATH, "user://save.json", "SAVE_PATH constant should be correct")


func test_save_includes_version() -> void:
	var data = {"player": {"position": {"x": 0.0, "y": 0.0}}}
	SaveManager.save_data(data, TEST_SAVE_PATH)
	var loaded = SaveManager.load_data(TEST_SAVE_PATH)
	assert_true(loaded.has("version"), "Save data should contain version key")
	assert_eq(loaded["version"], SaveManager.SAVE_VERSION, "Version should match SAVE_VERSION constant")


func test_save_version_is_string() -> void:
	assert_true(SaveManager.SAVE_VERSION is String, "SAVE_VERSION should be a String")
	assert_eq(SaveManager.SAVE_VERSION, "1.0", "Initial version should be 1.0")


func test_autosave_interval_default() -> void:
	assert_eq(SaveManager.autosave_interval_seconds, 300.0, "Default autosave interval should be 300 seconds")


func test_autosave_interval_configurable() -> void:
	var original = SaveManager.autosave_interval_seconds
	SaveManager.autosave_interval_seconds = 60.0
	assert_eq(SaveManager.autosave_interval_seconds, 60.0, "Autosave interval should be configurable")
	SaveManager.autosave_interval_seconds = original


func test_should_autosave_returns_false_when_no_player() -> void:
	SaveManager._autosave_player = null
	assert_false(SaveManager._should_autosave(), "Should not autosave without player")


func test_should_autosave_returns_false_when_dead() -> void:
	var player = Player.new()
	player.current_state = Player.PlayerStates.DEAD
	SaveManager._autosave_player = player
	assert_false(SaveManager._should_autosave(), "Should not autosave when player is dead")
	SaveManager._autosave_player = null
	player.free()


func test_should_autosave_returns_true_when_alive() -> void:
	var player = Player.new()
	player.current_state = Player.PlayerStates.MOVE
	SaveManager._autosave_player = player
	assert_true(SaveManager._should_autosave(), "Should autosave when player is alive")
	SaveManager._autosave_player = null
	player.free()
