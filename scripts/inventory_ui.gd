extends Control

const SLOT_COUNT: int = 15
const SLOT_SCENE: PackedScene = preload("res://scenes/inventory_slot_ui.tscn")

var _inventory: Inventory = null

@onready var grid: GridContainer = $NinePatchRect/GridContainer
@onready var weight_label: Label = $NinePatchRect/WeightLabel


func _ready() -> void:
	# Clear any residual editor-placed children
	for child in grid.get_children():
		child.queue_free()
	for i in range(SLOT_COUNT):
		grid.add_child(SLOT_SCENE.instantiate())
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = !visible


func set_inventory(inv: Inventory) -> void:
	_inventory = inv
	inv.inventory_changed.connect(_refresh_slots)
	inv.inventory_changed.connect(_refresh_weight_label)
	_refresh_slots()
	_refresh_weight_label()


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
