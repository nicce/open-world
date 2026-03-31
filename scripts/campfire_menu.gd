extends CanvasLayer

var player: Player


func _ready() -> void:
	get_tree().paused = true


func _on_save_button_pressed() -> void:
	if player:
		var err = SaveManager.save_game(player)
		if err != OK:
			push_error("Failed to save game: %s" % error_string(err))
	_on_close_button_pressed()


func _on_sleep_button_pressed() -> void:
	if player:
		var err = SaveManager.save_game(player)
		if err != OK:
			push_error("Failed to save game on sleep: %s" % error_string(err))
	_on_close_button_pressed()


func _on_close_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
