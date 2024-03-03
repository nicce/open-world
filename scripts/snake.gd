class_name Snake
extends CharacterBody2D

@export var attack: Attack
@export var speed: int

signal dead(respawn_position)

var spawn_position: Vector2

func _ready():
	spawn_position = global_position


func _on_health_component_health_depleated():
	dead.emit(spawn_position)
	queue_free()


func _on_health_component_damage_taken():
	$AnimationDamage.play("Damage")
	
