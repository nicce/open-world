extends StaticBody2D

@export var value: int = 50

var interacter: Node2D
var interactable: bool = false

func _process(_delta):
	if Input.is_action_just_pressed("interact") && interactable:
		interacter.increase_health(value)
		queue_free()

func _on_interact_area_body_entered(body):
	if body.has_method("increase_health"):
		interactable = true
		interacter = body


func _on_interact_area_body_exited(body):
	interactable = false
	
