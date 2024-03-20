extends Control

var is_open: bool = false

func _ready() -> void:
	visible = false

func _input(event) -> void:
	if event.is_action_pressed("inventory"):
		toggle()

func toggle() -> void:
	visible = !is_open
	is_open = !is_open
	
