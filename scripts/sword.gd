class_name Sword extends Collectable

@export var weapon_item: WeaponItem


func _process(delta):
	super._process(delta)


func collect():
	assert(collector.has_method("collect"), "Player script should have a collect method.")
	var success = collector.collect(weapon_item)
	if success:
		queue_free()
