class_name HealthBar
extends ProgressBar

func update(health: int):
	value = health
	
	if value >= max_value:
		visible = false
	else:
		visible = true
