extends Node

const SAVE_PATH = "user://save.json"
const SAVE_VERSION: String = "1.0"

## Autosave interval in seconds. Set to 0 to disable autosave.
var autosave_interval_seconds: float = 300.0

var _autosave_player: Player = null
var _autosave_timer: Timer = null


func save_data(data: Dictionary, path: String = SAVE_PATH) -> Error:
	data["version"] = SAVE_VERSION
	var json_string = JSON.stringify(data)
	var tmp_path = path + ".tmp"

	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	file.store_string(json_string)
	file.close()

	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err != OK:
			DirAccess.remove_absolute(tmp_path)
			return err

	var err = DirAccess.rename_absolute(tmp_path, path)
	return err


func load_data(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var json_string := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(json_string)

	if data is Dictionary:
		return data

	if data != null:
		push_warning("Save data in '%s' is not a valid dictionary." % path)

	return {}


func save_game(player: Player, path: String = SAVE_PATH) -> Error:
	var data = {"player": player.to_dict()}
	return save_data(data, path)


func load_game(player: Player, path: String = SAVE_PATH) -> void:
	var result = load_data(path)
	if result.has("player"):
		player.from_dict(result["player"])


func start_autosave(player: Player) -> void:
	_autosave_player = player
	if _autosave_timer:
		_autosave_timer.queue_free()
		_autosave_timer = null

	if autosave_interval_seconds <= 0:
		return

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = autosave_interval_seconds
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func stop_autosave() -> void:
	if _autosave_timer:
		_autosave_timer.stop()
		_autosave_timer.queue_free()
		_autosave_timer = null
	_autosave_player = null


func _should_autosave() -> bool:
	if not is_instance_valid(_autosave_player):
		return false
	if _autosave_player.current_state == Player.PlayerStates.DEAD:
		return false
	return true


func _on_autosave_timeout() -> void:
	if _should_autosave():
		var err = save_game(_autosave_player)
		if err != OK:
			push_warning("Autosave failed: %s" % error_string(err))
