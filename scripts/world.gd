extends Node2D

@onready var player: Player = $Player
@onready var inventory_ui: Control = $CanvasLayer/InventoryUI
@onready var rejection_label: Label = $CanvasLayer/RejectionLabel
@onready var fade_timer: Timer = $CanvasLayer/RejectionLabel/FadeTimer
@onready var pickup_label: Label = $CanvasLayer/PickupLabel
@onready var pickup_timer: Timer = $CanvasLayer/PickupLabel/PickupTimer


func _ready() -> void:
	inventory_ui.set_inventory(player.inventory)
	inventory_ui.set_player(player)
	player.inventory.insert_rejected.connect(_on_insert_rejected)
	player.item_collected.connect(_on_item_collected)
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	pickup_timer.timeout.connect(_on_pickup_timer_timeout)


func _on_insert_rejected() -> void:
	rejection_label.modulate.a = 1.0
	fade_timer.start()


func _on_fade_timer_timeout() -> void:
	var tw := create_tween()
	tw.tween_property(rejection_label, "modulate:a", 0.0, 0.4)


func _on_item_collected(item_name: String) -> void:
	pickup_label.text = "+ " + item_name
	pickup_label.modulate.a = 1.0
	pickup_timer.start()


func _on_pickup_timer_timeout() -> void:
	var tw := create_tween()
	tw.tween_property(pickup_label, "modulate:a", 0.0, 0.4)


func _on_detection_area_home_body_entered(_body):
	BackgroundMusic.play_audio("home")
