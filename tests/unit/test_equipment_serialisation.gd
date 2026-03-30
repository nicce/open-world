extends GutTest

func test_to_dict_empty() -> void:
	var ed = EquipmentData.new()
	var dict = ed.to_dict()
	assert_eq(dict["weapon"], null)
	assert_eq(dict["tool"], null)


func test_to_dict_with_items() -> void:
	var ed = EquipmentData.new()
	var sword = ItemRegistry.get_item(&"sword")
	var axe = ItemRegistry.get_item(&"axe")
	
	ed.equip_weapon(sword)
	ed.equip_tool(axe)
	
	var dict = ed.to_dict()
	assert_eq(dict["weapon"], &"sword")
	assert_eq(dict["tool"], &"axe")


func test_from_dict_restores_items() -> void:
	var ed = EquipmentData.new()
	var dict = {
		"weapon": &"sword",
		"tool": &"axe"
	}
	
	ed.from_dict(dict)
	
	assert_not_null(ed.weapon)
	assert_eq(ed.weapon.id, &"sword")
	assert_not_null(ed.tool)
	assert_eq(ed.tool.id, &"axe")


func test_from_dict_emits_signals() -> void:
	var ed = EquipmentData.new()
	var dict = {
		"weapon": &"sword",
		"tool": &"axe"
	}
	
	watch_signals(ed)
	ed.from_dict(dict)
	
	# Should emit twice, once for weapon and once for tool
	assert_signal_emit_count(ed, "equipment_changed", 2)


func test_from_dict_clears_slots_if_null() -> void:
	var ed = EquipmentData.new()
	ed.equip_weapon(ItemRegistry.get_item(&"sword"))
	ed.equip_tool(ItemRegistry.get_item(&"axe"))
	
	var dict = {
		"weapon": null,
		"tool": null
	}
	
	ed.from_dict(dict)
	assert_null(ed.weapon)
	assert_null(ed.tool)
	
func test_round_trip() -> void:
	var ed1 = EquipmentData.new()
	ed1.equip_weapon(ItemRegistry.get_item(&"sword"))
	ed1.equip_tool(ItemRegistry.get_item(&"axe"))
	
	var dict = ed1.to_dict()
	
	var ed2 = EquipmentData.new()
	ed2.from_dict(dict)
	
	assert_eq(ed2.weapon.id, ed1.weapon.id)
	assert_eq(ed2.tool.id, ed1.tool.id)
