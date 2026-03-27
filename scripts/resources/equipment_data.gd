class_name EquipmentData extends Resource

signal equipment_changed

@export var weapon: WeaponItem
@export var tool: Item


func equip_weapon(item: WeaponItem) -> WeaponItem:
	var previous: WeaponItem = weapon
	weapon = item
	equipment_changed.emit()
	return previous


func unequip_weapon() -> WeaponItem:
	var previous: WeaponItem = weapon
	weapon = null
	equipment_changed.emit()
	return previous


func equip_tool(item: Item) -> Item:
	var previous: Item = tool
	tool = item
	equipment_changed.emit()
	return previous


func unequip_tool() -> Item:
	var previous: Item = tool
	tool = null
	equipment_changed.emit()
	return previous
