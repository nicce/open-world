extends Node

const SAVE_PATH = "user://save.json"
const TMP_PATH = "user://save.tmp"


func save_data(data: Dictionary, path: String = SAVE_PATH) -> Error:
	var json_string = JSON.stringify(data)
	var current_tmp_path = path.replace(".json", ".tmp")

	var file = FileAccess.open(current_tmp_path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	file.store_string(json_string)
	file.close()

	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err != OK:
			return err

	var err = DirAccess.rename_absolute(current_tmp_path, path)
	return err


func load_data(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_string)
	if err != OK:
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		return {}

	return json.data


func save_game(player: Player) -> void:
	var data = {"player": player.to_dict()}
	save_data(data)


func load_game(player: Player) -> void:
	var result = load_data()
	if result.has("player"):
		player.from_dict(result["player"])
