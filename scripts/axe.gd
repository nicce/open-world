class_name Axe extends Collectable

@export var weapon_item: WeaponItem

func _process(delta):
	super._process(delta)

func collect():
	assert(collector.has_method("collect"), "Player script should have a collect method.")
	collector.collect(weapon_item)
	queue_free()
