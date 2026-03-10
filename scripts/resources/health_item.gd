class_name HealthItem extends Item

@export var health: int


func _init():
	category = Category.FOOD
	consumable = true
	weight = 0.2
