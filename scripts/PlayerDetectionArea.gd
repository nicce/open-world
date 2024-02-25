# This component detects if a player is in the area.
# If the player is in the area it will begin to chase the player.
# You need to have the following animation in order for this component to look good:
# idle, move_east, move_west, move_south and move_north
extends Area2D

@export var speed: int

var player_in_area: bool
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready():
	player_in_area = false

func _physics_process(delta):
	if player_in_area:
		chase(player, delta)
	else:
		get_parent().get_node("AnimatedSprite2D").play("idle")

func _on_body_entered(body):
	player = body
	player_in_area = true
		
func _on_body_exited(body):
	player_in_area = false
		
func chase(player: Player, delta: float):
	var direction = player.position - get_parent().position
	get_parent().velocity = (direction * speed).normalized() / delta
	var angle_degrees = rad_to_deg(direction.angle())

	if (angle_degrees > -45 and angle_degrees <= 45):
		get_parent().get_node("AnimatedSprite2D").play("move_east")
	elif (angle_degrees > 45 and angle_degrees <= 135):
		get_parent().get_node("AnimatedSprite2D").play("move_south")
	elif (angle_degrees > -135 and angle_degrees <= -45):
		get_parent().get_node("AnimatedSprite2D").play("move_north")
	else:
		get_parent().get_node("AnimatedSprite2D").play("move_west")
	
	get_parent().move_and_slide()
