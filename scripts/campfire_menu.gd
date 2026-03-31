extends CanvasLayer

var player: Player
var campfire  # Campfire node reference; typed via duck typing to avoid circular class ref


func _ready() -> void:
	get_tree().paused = true
	_refresh_fire_button()
	$Panel/VBoxContainer/SaveButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_on_close_button_pressed()


func _refresh_fire_button() -> void:
	if campfire == null:
		return
	if campfire.is_fire:
		$Panel/VBoxContainer/FireButton.text = "Extinguish Fire"
	else:
		$Panel/VBoxContainer/FireButton.text = "Light Fire"


func _on_fire_button_pressed() -> void:
	if campfire == null:
		return
	if campfire.is_fire:
		campfire.extinguish()
	else:
		campfire.light()
	_refresh_fire_button()


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
