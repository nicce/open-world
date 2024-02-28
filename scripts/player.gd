class_name Player
extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var advanced_camera: AdvancedCamera = $AdvancedCamera

@export var speed: float = 80.0

signal player_dead

var health_depleated: bool = false

func _physics_process(delta):
	if health_depleated:
		die()
	if !health_depleated:
		move()

func _on_health_component_health_depleated():
	health_depleated = true
	
func _on_health_component_damage_taken():
	$AnimationDamage.play("Damage")
	
func move():
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	if velocity != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Walk/blend_position", direction)
		animation_tree.set("parameters/Damage/blend_position", direction)
		animation_state.travel("Walk")
	else:
		animation_state.travel("Idle")
	
	move_and_slide()
	
	
func die():
	animation_state.travel("Dead")
	set_process(false)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
