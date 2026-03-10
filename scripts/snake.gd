class_name Snake
extends CharacterBody2D

signal dead(respawn_position)

@export var attack: Attack
@export var speed: int
@export var knockback_force: float = 120.0

var spawn_position: Vector2
var knockback_velocity: Vector2 = Vector2.ZERO


func _ready():
	spawn_position = global_position
	$HitboxComponent.knocked_back.connect(_on_knocked_back)


func _physics_process(delta):
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(
			Vector2.ZERO, knockback_force * delta * 8
		)
	else:
		knockback_velocity = Vector2.ZERO
	move_and_slide()


func apply_knockback(from_position: Vector2) -> void:
	var direction = (global_position - from_position).normalized()
	knockback_velocity = direction * knockback_force


func _on_knocked_back(from_position: Vector2) -> void:
	apply_knockback(from_position)


func _on_health_component_health_depleated():
	dead.emit(spawn_position)
	queue_free()


func _on_health_component_damage_taken():
	$AnimationDamage.play("Damage")
