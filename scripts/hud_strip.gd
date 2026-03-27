extends Control

enum SlotType { NONE, WEAPON, TOOL }

const COLLECTABLE_SCENE: PackedScene = preload("res://scenes/collectable.tscn")
const MENU_UNEQUIP = 0
const MENU_DROP = 1

var _equipment_data: EquipmentData = null
var _inventory: Inventory = null
var _player: Player = null
var _pending_slot_type: SlotType = SlotType.NONE

@onready var _weapon_slot: Panel = $HBoxContainer/WeaponSlotGroup/WeaponSlot
@onready var _weapon_icon: TextureRect = $HBoxContainer/WeaponSlotGroup/WeaponSlot/IconRect
@onready var _weapon_name: Label = $HBoxContainer/WeaponSlotGroup/WeaponSlot/NameLabel
@onready var _tool_slot: Panel = $HBoxContainer/ToolSlotGroup/ToolSlot
@onready var _tool_icon: TextureRect = $HBoxContainer/ToolSlotGroup/ToolSlot/IconRect
@onready var _tool_name: Label = $HBoxContainer/ToolSlotGroup/ToolSlot/NameLabel
@onready var _popup_menu: PopupMenu = $PopupMenu


func _ready() -> void:
	_popup_menu.id_pressed.connect(_on_hud_popup_id_pressed)
	_weapon_slot.gui_input.connect(_on_weapon_slot_gui_input)
	_tool_slot.gui_input.connect(_on_tool_slot_gui_input)


func set_equipment_data(ed: EquipmentData) -> void:
	_equipment_data = ed
	ed.equipment_changed.connect(_on_equipment_changed)
	_on_equipment_changed()


func set_inventory(inv: Inventory) -> void:
	_inventory = inv


func set_player(p: Player) -> void:
	_player = p


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


func _on_weapon_slot_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_on_hud_slot_right_clicked(SlotType.WEAPON)
		get_viewport().set_input_as_handled()


func _on_tool_slot_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_on_hud_slot_right_clicked(SlotType.TOOL)
		get_viewport().set_input_as_handled()


func _on_hud_slot_right_clicked(slot_type: SlotType) -> void:
	if _equipment_data == null:
		return
	var item = _equipment_data.weapon if slot_type == SlotType.WEAPON else _equipment_data.tool
	if item == null:
		return
	_pending_slot_type = slot_type
	_popup_menu.clear()
	_popup_menu.add_item("Unequip", MENU_UNEQUIP)
	_popup_menu.add_item("Drop", MENU_DROP)
	var pos: Vector2 = get_viewport().get_mouse_position()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var popup_min := _popup_menu.get_contents_minimum_size()
	if popup_min == Vector2.ZERO:
		popup_min = Vector2(120.0, 60.0)
	pos.x = clampf(pos.x, 0.0, vp.x - popup_min.x)
	pos.y = clampf(pos.y, 0.0, vp.y - popup_min.y)
	_popup_menu.popup(Rect2i(pos, Vector2i.ZERO))


func _on_hud_popup_id_pressed(id: int) -> void:
	match id:
		MENU_UNEQUIP:
			_do_unequip(_pending_slot_type)
		MENU_DROP:
			_do_drop_equipped(_pending_slot_type)
	_pending_slot_type = SlotType.NONE


func _do_unequip(slot_type: SlotType) -> void:
	if _equipment_data == null or _inventory == null:
		return
	if slot_type == SlotType.WEAPON:
		if _equipment_data.weapon == null:
			return
		var weapon := _equipment_data.weapon
		var remaining := _inventory.insert(weapon, 1)
		if remaining > 0:
			return
		_equipment_data.unequip_weapon()
	elif slot_type == SlotType.TOOL:
		if _equipment_data.tool == null:
			return
		var tool_item := _equipment_data.tool
		var remaining := _inventory.insert(tool_item, 1)
		if remaining > 0:
			return
		_equipment_data.unequip_tool()


func _do_drop_equipped(slot_type: SlotType) -> void:
	if _equipment_data == null or _player == null:
		return
	var item_ref: Item
	if slot_type == SlotType.WEAPON:
		item_ref = _equipment_data.unequip_weapon()
	else:
		item_ref = _equipment_data.unequip_tool()
	if item_ref == null:
		return
	var node: Collectable = COLLECTABLE_SCENE.instantiate()
	node.item = item_ref
	get_tree().current_scene.add_child(node)
	var angle := randf() * TAU
	var dist := randf_range(16.0, 32.0)
	node.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
