extends CharacterBody2D

@export var attack: Attack

func _on_health_component_health_depleated():
	queue_free()


func _on_health_component_damage_taken():
	print("dmg taken!") # TODO add modulate red/white indicating dmg
