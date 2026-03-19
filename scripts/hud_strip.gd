extends Control

var _equipment_data: EquipmentData = null

@onready var _weapon_slot: Panel = $HBoxContainer/WeaponSlotGroup/WeaponSlot
@onready var _weapon_icon: TextureRect = $HBoxContainer/WeaponSlotGroup/WeaponSlot/IconRect
@onready var _weapon_name: Label = $HBoxContainer/WeaponSlotGroup/WeaponSlot/NameLabel
@onready var _tool_slot: Panel = $HBoxContainer/ToolSlotGroup/ToolSlot
@onready var _tool_icon: TextureRect = $HBoxContainer/ToolSlotGroup/ToolSlot/IconRect
@onready var _tool_name: Label = $HBoxContainer/ToolSlotGroup/ToolSlot/NameLabel


func set_equipment_data(ed: EquipmentData) -> void:
	_equipment_data = ed
	ed.equipment_changed.connect(_on_equipment_changed)
	_on_equipment_changed()


func _on_equipment_changed() -> void:
	var weapon = _equipment_data.weapon if _equipment_data else null
	var tool_item = _equipment_data.tool if _equipment_data else null
	_refresh_slot(_weapon_slot, _weapon_icon, _weapon_name, weapon)
	_refresh_slot(_tool_slot, _tool_icon, _tool_name, tool_item)


func _refresh_slot(slot_panel: Panel, icon: TextureRect, name_label: Label, item) -> void:
	if item and item.texture:
		icon.texture = item.texture
		icon.visible = true
		name_label.visible = false
		slot_panel.modulate.a = 1.0
		_set_slot_border(slot_panel, true)
	elif item:
		name_label.text = item.name
		name_label.visible = true
		icon.visible = false
		slot_panel.modulate.a = 1.0
		_set_slot_border(slot_panel, true)
	else:
		icon.visible = false
		name_label.visible = false
		slot_panel.modulate.a = 0.4
		_set_slot_border(slot_panel, false)


func _set_slot_border(slot_panel: Panel, occupied: bool) -> void:
	var style: StyleBoxFlat = slot_panel.get_theme_stylebox("panel").duplicate()
	if occupied:
		style.border_color = Color(1.0, 0.85, 0.0)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
	else:
		style.border_width_top = 0
		style.border_width_bottom = 0
		style.border_width_left = 0
		style.border_width_right = 0
	slot_panel.add_theme_stylebox_override("panel", style)
