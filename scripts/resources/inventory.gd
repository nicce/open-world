class_name Inventory extends Resource

@export var slots: Array[InventorySlot] = []
@export var max_weight: float = 100.0


func current_weight() -> float:
	var total := 0.0
	for slot in slots:
		total += slot.total_weight()
	return total


func remaining_weight() -> float:
	return max_weight - current_weight()


func insert(item: Item, amount: int = 1) -> int:
	if amount <= 0:
		return 0

	var remaining = amount

	# Try stacking into existing slots first
	for slot in slots:
		if remaining <= 0:
			break
		if slot.can_stack(item):
			var weight_budget = floori(remaining_weight() / item.weight)
			var to_add = mini(remaining, weight_budget)
			if to_add <= 0:
				break
			var leftover = slot.add(to_add)
			remaining -= (to_add - leftover)

	# Then try empty slots
	for slot in slots:
		if remaining <= 0:
			break
		if slot.is_empty():
			var weight_budget = floori(remaining_weight() / item.weight)
			var to_add = mini(remaining, weight_budget)
			if to_add <= 0:
				break
			slot.item = item
			var leftover = slot.add(to_add)
			remaining -= (to_add - leftover)

	return remaining


func remove(item: Item, amount: int = 1) -> int:
	var remaining = amount

	for slot in slots:
		if remaining <= 0:
			break
		if not slot.is_empty() and slot.item.id == item.id:
			remaining -= slot.remove(remaining)

	return amount - remaining


func get_item_count(item: Item) -> int:
	var total := 0
	for slot in slots:
		if not slot.is_empty() and slot.item.id == item.id:
			total += slot.quantity
	return total


func has_item(item: Item, amount: int = 1) -> bool:
	return get_item_count(item) >= amount


## Returns an independent deep copy of this Inventory.
## Use this instead of duplicate(true) because Godot 4 does not deep-copy
## typed Array[InventorySlot] elements via the native duplicate() method.
func clone() -> Inventory:
	var copy := Inventory.new()
	copy.max_weight = max_weight
	for slot in slots:
		var slot_copy := InventorySlot.new()
		slot_copy.item = slot.item
		slot_copy.quantity = slot.quantity
		slot_copy.max_stack = slot.max_stack
		copy.slots.append(slot_copy)
	return copy
