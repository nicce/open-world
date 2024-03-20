class_name Player extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var advanced_camera: AdvancedCamera = $AdvancedCamera
@onready var health_component: HealthComponent = $HealthComponent

@export var speed: float = 80.0
@export var attack: Attack

signal health_changed(new_value: int)

var health_depleated: bool = false

enum player_states {MOVE, HIT, DEAD}
var current_state = player_states.MOVE

func _physics_process(delta):
	match current_state:
		player_states.MOVE:
			move()
		player_states.DEAD:
			die()
		player_states.HIT:
			hit()

func _on_health_component_health_depleated():
	current_state = player_states.DEAD
	
func _on_health_component_damage_taken():
	$AnimationDamage.play("Damage")
	
func move():
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	if velocity != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Walk/blend_position", direction)
		animation_tree.set("parameters/Fist/blend_position", direction)
		animation_state.travel("Walk")
	
	if velocity == Vector2.ZERO:
		animation_state.travel("Idle")
	
	if Input.is_action_just_pressed("hit"):
		current_state = player_states.HIT
	
	move_and_slide()
	
func hit(): # TODO how do we handle different equipped weapons?
	animation_state.travel("Fist")
	
func die():
	animation_state.travel("Dead")
	set_process(false)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
	
func on_player_state_reset():
	current_state = player_states.MOVE
	
func increase_health(value: int):
	health_component.increase(value)
