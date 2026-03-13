class_name Collectable extends Area2D

@export var item: Item

var is_collectable: bool = false
var collector: Player


func _ready() -> void:
	add_to_group("collectables")
	if item and item.texture:
		$Sprite2D.texture = item.texture


func _process(_delta):
	if is_collectable and Input.is_action_just_pressed("interact"):
		var my_dist := global_position.distance_squared_to(collector.global_position)
		for c: Collectable in get_tree().get_nodes_in_group("collectables"):
			if c != self and c.is_collectable:
				if c.global_position.distance_squared_to(collector.global_position) < my_dist:
					return
		collect()


func _on_body_entered(body):
	if body is Player:
		is_collectable = true
		collector = body


func _on_body_exited(_body):
	is_collectable = false


func collect():
	assert(collector.has_method("collect"), "Player script should have a collect method.")
	var success = collector.collect(item)
	if success:
		queue_free()
	# If not success: inventory.insert() already emitted insert_rejected signal.
	# The HUD label is handled by world.gd listening to that signal.
