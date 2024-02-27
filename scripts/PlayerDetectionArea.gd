# This component detects if a player is in the area.
# If the player is in the area it will begin to chase the player.
# You need to have the animations "Idle" and "Move" available in your AnimationTree
# in order for this component to work properly.
extends Area2D

@export var speed: int #TODO take from parent?
@export var animation_tree: AnimationTree

var animation_state: AnimationNodeStateMachinePlayback
var player_in_area: bool
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready():
	player_in_area = false
	animation_state = animation_tree.get("parameters/playback")

func _physics_process(delta):
	if player_in_area:
		chase(player, delta)
	else:
		animation_state.travel("Idle")

func _on_body_entered(body):
	player = body
	player_in_area = true
		
func _on_body_exited(body):
	player_in_area = false
		
func chase(player: Player, delta: float):
	var direction = player.position - get_parent().position
	get_parent().velocity = (direction * speed).normalized() / delta
	
	animation_tree.set("parameters/Idle/blend_position", direction)
	animation_tree.set("parameters/Move/blend_position", direction)
	animation_state.travel("Move")
	
	get_parent().move_and_slide()
