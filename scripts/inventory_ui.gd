extends Control

const SLOT_COUNT: int = 15
const SLOT_SCENE: PackedScene = preload("res://scenes/inventory_slot_ui.tscn")
const COLLECTABLE_SCENE: PackedScene = preload("res://scenes/collectable.tscn")

const MENU_EQUIP = 0
const MENU_CONSUME = 1
const MENU_DROP = 2

var _inventory: Inventory = null
var _equipment_data: EquipmentData = null
var _player: Player = null
var _selected_index: int = -1
var _pending_context_index: int = -1

@onready var grid: GridContainer = $NinePatchRect/GridContainer
@onready var weight_label: Label = $NinePatchRect/WeightLabel
@onready var _popup_menu: PopupMenu = $PopupMenu


func _ready() -> void:
	# Clear any residual editor-placed children
	for child in grid.get_children():
		child.queue_free()
	for i in range(SLOT_COUNT):
		var slot := SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.right_clicked.connect(_on_slot_right_clicked)
	_popup_menu.id_pressed.connect(_on_context_menu_id_pressed)
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = !visible
		if not visible:
			_deselect()
			_popup_menu.hide()
		return
	if not visible:
		return
	if event.is_action_pressed("interact"):
		_use_selected()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("drop"):
		_drop_selected()
		get_viewport().set_input_as_handled()


func set_inventory(inv: Inventory) -> void:
	_inventory = inv
	inv.inventory_changed.connect(_refresh_slots)
	inv.inventory_changed.connect(_refresh_weight_label)
	_refresh_slots()
	_refresh_weight_label()


func set_equipment_data(ed: EquipmentData) -> void:
	_equipment_data = ed


func set_player(p: Player) -> void:
	_player = p


func _on_slot_clicked(slot_node: Panel) -> void:
	if _inventory == null:
		return
	var index := grid.get_children().find(slot_node)
	if index < 0 or index >= _inventory.slots.size() or _inventory.slots[index].is_empty():
		return
	if _selected_index == index:
		_deselect()
	else:
		_deselect()
		_selected_index = index
		grid.get_child(index).set_selected(true)


func _deselect() -> void:
	if _selected_index >= 0 and _selected_index < grid.get_child_count():
		grid.get_child(_selected_index).set_selected(false)
	_selected_index = -1


func _use_selected() -> void:
	if _selected_index < 0 or _inventory == null:
		return
	var slot := _inventory.slots[_selected_index]
	if slot.is_empty() or not slot.item.consumable:
		return
	if not slot.item is HealthItem:
		return
	var heal := (slot.item as HealthItem).health
	_inventory.remove(slot.item, 1)
	if _player != null:
		_player.increase_health(heal)
	if slot.is_empty():
		_deselect()


func _refresh_slots() -> void:
	if _inventory == null:
		return
	var slot_nodes := grid.get_children()
	for i in range(SLOT_COUNT):
		if i < _inventory.slots.size():
			slot_nodes[i].update(_inventory.slots[i])
		else:
			# Create an empty InventorySlot for display if inventory has fewer slots
			slot_nodes[i].update(InventorySlot.new())


func _drop_selected() -> void:
	if _selected_index < 0 or _inventory == null or _player == null:
		return
	var slot := _inventory.slots[_selected_index]
	if slot.is_empty():
		return
	var item_ref: Item = slot.item
	var removed := _inventory.remove(item_ref, 1)
	if removed == 0:
		return
	var node: Collectable = COLLECTABLE_SCENE.instantiate()
	node.item = item_ref
	get_tree().current_scene.add_child(node)
	var angle := randf() * TAU
	var dist := randf_range(16.0, 32.0)
	node.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
	if slot.is_empty():
		_deselect()


func _on_slot_right_clicked(slot_node: Panel) -> void:
	if _inventory == null:
		return
	var index := grid.get_children().find(slot_node)
	if index < 0 or index >= _inventory.slots.size() or _inventory.slots[index].is_empty():
		return
	var item := _inventory.slots[index].item
	_pending_context_index = index
	_popup_menu.clear()
	if item is WeaponItem:
		_popup_menu.add_item("Equip", MENU_EQUIP)
	elif item.category == Item.Category.TOOL:
		_popup_menu.add_item("Equip", MENU_EQUIP)
	elif item is HealthItem:
		_popup_menu.add_item("Consume", MENU_CONSUME)
	_popup_menu.add_item("Drop", MENU_DROP)
	_popup_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))


func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		MENU_EQUIP:
			if _equipment_data == null or _pending_context_index < 0:
				return
			var item := _inventory.slots[_pending_context_index].item
			if item is WeaponItem:
				_do_equip_weapon(item as WeaponItem)
			elif item.category == Item.Category.TOOL:
				_do_equip_tool(item)
		MENU_CONSUME:
			_selected_index = _pending_context_index
			_use_selected()
		MENU_DROP:
			_selected_index = _pending_context_index
			_drop_selected()
	_pending_context_index = -1


func _do_equip_weapon(item: WeaponItem) -> void:
	var removed := _inventory.remove(item, 1)
	if removed == 0:
		return
	var displaced: WeaponItem = _equipment_data.equip_weapon(item)
	if displaced != null:
		_inventory.insert(displaced, 1)


func _do_equip_tool(item: Item) -> void:
	var removed := _inventory.remove(item, 1)
	if removed == 0:
		return
	var displaced: Item = _equipment_data.equip_tool(item)
	if displaced != null:
		_inventory.insert(displaced, 1)


func _do_unequip_weapon() -> void:
	if _equipment_data == null or _equipment_data.weapon == null:
		return
	var weapon := _equipment_data.weapon
	var remaining := _inventory.insert(weapon, 1)
	if remaining > 0:
		return  # bag full — weapon stays equipped; insert_rejected already emitted
	_equipment_data.unequip_weapon()


func _do_unequip_tool() -> void:
	if _equipment_data == null or _equipment_data.tool == null:
		return
	var tool_item := _equipment_data.tool
	var remaining := _inventory.insert(tool_item, 1)
	if remaining > 0:
		return
	_equipment_data.unequip_tool()


func _refresh_weight_label() -> void:
	if _inventory == null:
		return
	weight_label.text = InventoryUIHelpers.format_weight(
		_inventory.current_weight(), _inventory.max_weight
	)
