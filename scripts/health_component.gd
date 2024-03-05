class_name HealthComponent
extends Node2D

@export var max_health: int
@export var health_bar: HealthBar # TODO replace with signals
var health: int

signal health_depleated
signal damage_taken

func _ready():
	health = max_health
	
	if health_bar:
		health_bar.max_value = health
	
func damage(attack: Attack):
	health -= attack.damage
	
	if health_bar:
		health_bar.update(health)
		
	if health <= 0:
		health_depleated.emit()
	else:
		damage_taken.emit()
		
func increase(value: int):
	health += value
	if health > max_health:
		health = max_health
		
	health_bar.update(health)
		
