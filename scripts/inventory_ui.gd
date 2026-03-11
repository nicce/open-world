extends Control

const SLOT_COUNT: int = 15
const SLOT_SCENE: PackedScene = preload("res://scenes/inventory_slot_ui.tscn")

var _inventory: Inventory = null
var _player: Player = null
var _selected_index: int = -1

@onready var grid: GridContainer = $NinePatchRect/GridContainer
@onready var weight_label: Label = $NinePatchRect/WeightLabel


func _ready() -> void:
	# Clear any residual editor-placed children
	for child in grid.get_children():
		child.queue_free()
	for i in range(SLOT_COUNT):
		var slot := SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.slot_clicked.connect(func(_n): _on_slot_clicked(i))
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = !visible
		if not visible:
			_deselect()
		return
	if not visible:
		return
	if event.is_action_pressed("interact"):
		_use_selected()
		get_viewport().set_input_as_handled()


func set_inventory(inv: Inventory) -> void:
	_inventory = inv
	inv.inventory_changed.connect(_refresh_slots)
	inv.inventory_changed.connect(_refresh_weight_label)
	_refresh_slots()
	_refresh_weight_label()


func set_player(p: Player) -> void:
	_player = p


func _on_slot_clicked(index: int) -> void:
	if _inventory == null:
		return
	if index >= _inventory.slots.size() or _inventory.slots[index].is_empty():
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


func _refresh_weight_label() -> void:
	if _inventory == null:
		return
	weight_label.text = InventoryUIHelpers.format_weight(
		_inventory.current_weight(), _inventory.max_weight
	)
