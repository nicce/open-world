extends Node

const SAVE_PATH = "user://save.json"
const SAVE_VERSION: String = "1.0"


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
