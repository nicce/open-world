class_name HealthComponent
extends Node2D

@export var max_health: int
var health: int

signal health_depleated
signal damage_taken

func _ready():
	health = max_health
	
func damage(attack: Attack):
	health -= attack.damage
	print(health)
	if health <= 0:
		health_depleated.emit()
	else:
		damage_taken.emit()
		
