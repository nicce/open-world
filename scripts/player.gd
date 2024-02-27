class_name Player
extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var advanced_camera: AdvancedCamera = $AdvancedCamera

@export var speed: float = 80.0

signal player_dead

func _physics_process(delta):
	move()
	
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


func _on_health_component_health_depleated():
	queue_free() # TODO play dead animation and after a few seconds queue_free and then restart/respawn in home base
	player_dead.emit()
	


func _on_health_component_damage_taken():
	advanced_camera.add_trauma(0.5)
