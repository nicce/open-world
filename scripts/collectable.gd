class_name Collectable extends Area2D

@export var item: Item

var is_collectable: bool = false
var collector: Player

func _process(delta):
	if is_collectable and Input.is_action_just_pressed("interact"):
		collect()

func _on_body_entered(body):
	if body is Player:
		is_collectable = true
		collector = body


func _on_body_exited(body):
	is_collectable = false
	
func collect():
	assert(collector.has_method("collect"), "Player script should have a collect method.")
	var success = collector.collect(item)
	if success:
		queue_free()
