class_name Player
extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@export var speed: float = 80.0


func _physics_process(delta):
	move()

func _on_hitbox_body_entered(body):
	pass # add screen shake
	
func move():
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	if velocity != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Walk/blend_position", direction)
		animation_state.travel("Walk")
	else:
		animation_state.travel("Idle")
	
	move_and_slide()
	
