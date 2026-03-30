extends CanvasLayer

var player: Player


func _ready() -> void:
	get_tree().paused = true


func _on_save_button_pressed() -> void:
	if player:
		SaveManager.save_game(player)
	_on_close_button_pressed()


func _on_sleep_button_pressed() -> void:
	print("Sleeping... (Phase 12 placeholder)")
	_on_close_button_pressed()


func _on_close_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
