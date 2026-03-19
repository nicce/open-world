extends Node2D

var _equipment_data: EquipmentData = null

@onready var _texture_rect: TextureRect = $IconRect
@onready var _label: Label = $NameLabel


func set_equipment_data(ed: EquipmentData) -> void:
	_equipment_data = ed
	ed.equipment_changed.connect(_on_equipment_changed)
	_on_equipment_changed()


func _on_equipment_changed() -> void:
	var weapon = _equipment_data.weapon if _equipment_data else null
	visible = weapon != null
	if weapon == null:
		return
	if weapon.texture:
		_texture_rect.texture = weapon.texture
		_texture_rect.visible = true
		_label.visible = false
	else:
		_label.text = weapon.name
		_label.visible = true
		_texture_rect.visible = false
