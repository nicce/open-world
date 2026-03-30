class_name InventorySlot extends Resource

const DEFAULT_MAX_STACK: int = 10

@export var item: Item
@export var quantity: int = 0
@export var max_stack: int = DEFAULT_MAX_STACK


func is_empty() -> bool:
	return item == null or quantity <= 0


func is_full() -> bool:
	return quantity >= max_stack


func space_remaining() -> int:
	return max_stack - quantity


func total_weight() -> float:
	if is_empty():
		return 0.0
	return item.weight * quantity


func can_stack(other: Item) -> bool:
	if is_empty():
		return false
	if is_full():
		return false
	return item.id == other.id


func add(amount: int = 1) -> int:
	var can_add = mini(amount, space_remaining())
	quantity += can_add
	return amount - can_add


func remove(amount: int = 1) -> int:
	var removed = mini(amount, quantity)
	quantity -= removed
	if quantity <= 0:
		item = null
		quantity = 0
	return removed


func to_dict() -> Dictionary:
	return {
		"id": item.id if item else "",
		"qty": quantity
	}


func from_dict(dict: Dictionary) -> void:
	var id = dict.get("id", "")
	if id == "":
		item = null
		quantity = 0
	else:
		item = ItemRegistry.get_item(id)
		quantity = dict.get("qty", 0)
