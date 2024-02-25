extends CharacterBody2D

func _on_health_component_health_depleated():
	queue_free()


func _on_health_component_damage_taken():
	pass # add modulate red/white indicating dmg
