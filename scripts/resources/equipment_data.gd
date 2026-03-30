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


func to_dict() -> Dictionary:
	return {"weapon": weapon.id if weapon else null, "tool": tool.id if tool else null}


func from_dict(dict: Dictionary) -> void:
	if dict.has("weapon") and dict["weapon"] != null:
		var weapon_item = ItemRegistry.get_item(dict["weapon"])
		if weapon_item is WeaponItem:
			equip_weapon(weapon_item)
	else:
		unequip_weapon()

	if dict.has("tool") and dict["tool"] != null:
		var tool_item = ItemRegistry.get_item(dict["tool"])
		if tool_item:
			equip_tool(tool_item)
	else:
		unequip_tool()
