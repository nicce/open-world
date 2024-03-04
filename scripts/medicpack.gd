extends StaticBody2D

@export var value: int = 50

var player: Player
var player_within_reach: bool = false

signal health_pickup(value: int)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("interact") && player_within_reach:
		player.increase_health(value)
		queue_free()

func _on_interact_area_body_entered(body):
	player_within_reach = true
	player = body


func _on_interact_area_body_exited(body):
	player_within_reach = false
	
