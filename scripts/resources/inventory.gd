class_name Inventory extends Resource

signal inventory_changed
signal insert_rejected

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

	var inserted = amount - remaining
	if inserted > 0:
		inventory_changed.emit()
	elif remaining > 0:
		insert_rejected.emit()

	return remaining


func remove(item: Item, amount: int = 1) -> int:
	var remaining: int = amount

	for slot in slots:
		if remaining <= 0:
			break
		if not slot.is_empty() and slot.item.id == item.id:
			remaining -= slot.remove(remaining)

	var removed: int = amount - remaining
	if removed > 0:
		inventory_changed.emit()
	return removed


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


func to_dict() -> Dictionary:
	var slots_dict := {}
	for i in range(slots.size()):
		if not slots[i].is_empty():
			slots_dict[str(i)] = slots[i].to_dict()
	return {"slots": slots_dict}


func from_dict(dict: Dictionary) -> void:
	# Clear all slots first (D-06)
	for slot in slots:
		slot.item = null
		slot.quantity = 0

	var slots_dict = dict.get("slots", {})
	for i_str in slots_dict:
		var i = i_str.to_int()
		if i >= 0 and i < slots.size():
			slots[i].from_dict(slots_dict[i_str])

	inventory_changed.emit()
