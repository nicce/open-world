extends GutTest


func _make_weapon() -> WeaponItem:
	var weapon = WeaponItem.new()
	weapon.id = &"sword"
	weapon.name = "Sword"
	return weapon


func _make_item() -> Item:
	var item = Item.new()
	item.id = &"potion"
	item.name = "Potion"
	return item


# ---------------------------------------------------------------------------
# equip_weapon
# ---------------------------------------------------------------------------


func test_equip_weapon_empty_slot_stores_item() -> void:
	var ed = EquipmentData.new()
	var sword = _make_weapon()
	ed.equip_weapon(sword)
	assert_eq(ed.weapon, sword)


func test_equip_weapon_empty_slot_returns_null() -> void:
	var ed = EquipmentData.new()
	var sword = _make_weapon()
	var previous = ed.equip_weapon(sword)
	assert_null(previous)


func test_equip_weapon_empty_slot_emits_signal() -> void:
	var ed = EquipmentData.new()
	watch_signals(ed)
	ed.equip_weapon(_make_weapon())
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


func test_equip_weapon_replaces_existing_weapon() -> void:
	var ed = EquipmentData.new()
	var sword = _make_weapon()
	var axe = _make_weapon()
	axe.id = &"axe"
	axe.name = "Axe"
	ed.equip_weapon(sword)
	ed.equip_weapon(axe)
	assert_eq(ed.weapon, axe)


func test_equip_weapon_returns_previous_weapon() -> void:
	var ed = EquipmentData.new()
	var sword = _make_weapon()
	var axe = _make_weapon()
	axe.id = &"axe"
	axe.name = "Axe"
	ed.equip_weapon(sword)
	var previous = ed.equip_weapon(axe)
	assert_eq(previous, sword)


func test_equip_weapon_replacement_emits_signal_once() -> void:
	var ed = EquipmentData.new()
	ed.equip_weapon(_make_weapon())
	var axe = _make_weapon()
	axe.id = &"axe"
	watch_signals(ed)
	ed.equip_weapon(axe)
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


# ---------------------------------------------------------------------------
# unequip_weapon
# ---------------------------------------------------------------------------


func test_unequip_weapon_clears_field() -> void:
	var ed = EquipmentData.new()
	ed.equip_weapon(_make_weapon())
	ed.unequip_weapon()
	assert_null(ed.weapon)


func test_unequip_weapon_returns_weapon() -> void:
	var ed = EquipmentData.new()
	var sword = _make_weapon()
	ed.equip_weapon(sword)
	var returned = ed.unequip_weapon()
	assert_eq(returned, sword)


func test_unequip_weapon_emits_signal() -> void:
	var ed = EquipmentData.new()
	ed.equip_weapon(_make_weapon())
	watch_signals(ed)
	ed.unequip_weapon()
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


func test_unequip_weapon_empty_slot_returns_null() -> void:
	var ed = EquipmentData.new()
	var returned = ed.unequip_weapon()
	assert_null(returned)


func test_unequip_weapon_empty_slot_emits_signal() -> void:
	var ed = EquipmentData.new()
	watch_signals(ed)
	ed.unequip_weapon()
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


# ---------------------------------------------------------------------------
# equip_tool
# ---------------------------------------------------------------------------


func test_equip_tool_empty_slot_stores_item() -> void:
	var ed = EquipmentData.new()
	var potion = _make_item()
	ed.equip_tool(potion)
	assert_eq(ed.tool, potion)


func test_equip_tool_empty_slot_returns_null() -> void:
	var ed = EquipmentData.new()
	var previous = ed.equip_tool(_make_item())
	assert_null(previous)


func test_equip_tool_empty_slot_emits_signal() -> void:
	var ed = EquipmentData.new()
	watch_signals(ed)
	ed.equip_tool(_make_item())
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


func test_equip_tool_replaces_existing_tool() -> void:
	var ed = EquipmentData.new()
	var potion = _make_item()
	var herb = _make_item()
	herb.id = &"herb"
	herb.name = "Herb"
	ed.equip_tool(potion)
	ed.equip_tool(herb)
	assert_eq(ed.tool, herb)


func test_equip_tool_returns_previous_tool() -> void:
	var ed = EquipmentData.new()
	var potion = _make_item()
	var herb = _make_item()
	herb.id = &"herb"
	herb.name = "Herb"
	ed.equip_tool(potion)
	var previous = ed.equip_tool(herb)
	assert_eq(previous, potion)


func test_equip_tool_replacement_emits_signal_once() -> void:
	var ed = EquipmentData.new()
	ed.equip_tool(_make_item())
	var herb = _make_item()
	herb.id = &"herb"
	watch_signals(ed)
	ed.equip_tool(herb)
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


# ---------------------------------------------------------------------------
# unequip_tool
# ---------------------------------------------------------------------------


func test_unequip_tool_clears_field() -> void:
	var ed = EquipmentData.new()
	ed.equip_tool(_make_item())
	ed.unequip_tool()
	assert_null(ed.tool)


func test_unequip_tool_returns_item() -> void:
	var ed = EquipmentData.new()
	var potion = _make_item()
	ed.equip_tool(potion)
	var returned = ed.unequip_tool()
	assert_eq(returned, potion)


func test_unequip_tool_emits_signal() -> void:
	var ed = EquipmentData.new()
	ed.equip_tool(_make_item())
	watch_signals(ed)
	ed.unequip_tool()
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)


func test_unequip_tool_empty_slot_returns_null() -> void:
	var ed = EquipmentData.new()
	var returned = ed.unequip_tool()
	assert_null(returned)


func test_unequip_tool_empty_slot_emits_signal() -> void:
	var ed = EquipmentData.new()
	watch_signals(ed)
	ed.unequip_tool()
	assert_signal_emitted(ed, "equipment_changed")
	assert_signal_emit_count(ed, "equipment_changed", 1)
