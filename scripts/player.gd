class_name Player extends CharacterBody2D

signal health_changed(new_value: int)
signal item_collected(item_name: String)

enum PlayerStates { MOVE, HIT, DEAD }

@export var speed: float = 80.0
@export var attack: Attack
@export var inventory: Inventory

var health_depleated: bool = false
var current_state = PlayerStates.MOVE

@onready var animation_tree: AnimationTree = $AnimationTree
@onready
var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var advanced_camera: AdvancedCamera = $AdvancedCamera
@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	inventory = inventory.clone()
	animation_tree.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta):
	match current_state:
		PlayerStates.MOVE:
			move()
		PlayerStates.DEAD:
			die()
		PlayerStates.HIT:
			pass


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name in [&"FistNorth", &"FistSouth", &"FistEast", &"FistWest"]:
		on_attack_animation_finished()


func on_attack_animation_finished() -> void:
	on_player_state_reset()


func _on_health_component_health_depleated():
	current_state = PlayerStates.DEAD


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
		current_state = PlayerStates.HIT
		animation_state.travel("Fist")

	move_and_slide()


func hit():  # TODO how do we handle different equipped weapons?
	pass


func die():
	animation_state.travel("Dead")
	set_process(false)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func on_player_state_reset():
	current_state = PlayerStates.MOVE


func increase_health(value: int):
	health_component.increase(value)


func collect(item) -> bool:
	var success := inventory.insert(item) == 0
	if success:
		item_collected.emit(item.name)
	return success
