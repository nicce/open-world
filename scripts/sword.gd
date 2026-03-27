class_name Sword extends Collectable

@export var weapon_item: WeaponItem


func _ready() -> void:
	super._ready()
	if weapon_item and not weapon_item.texture:
		$Label.text = weapon_item.name
		$Label.visible = true


func _process(delta):
	super._process(delta)


func collect():
	assert(collector.has_method("collect"), "Player script should have a collect method.")
	var success = collector.collect(weapon_item)
	if success:
		queue_free()
