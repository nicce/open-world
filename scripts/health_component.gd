class_name HealthComponent
extends Node2D

signal health_depleated
signal damage_taken

@export var max_health: int
@export var health_bar: HealthBar  # TODO replace with signals

var health: int


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

	if health_bar:
		health_bar.update(health)


func load_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	if health_bar:
		health_bar.update(health)
