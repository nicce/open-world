class_name Inventory extends Resource

@export var items: Array[Item] = []

func insert(item: Item) -> bool:
	for i in range(items.size()):
		if !items[i]:
			items[i] = item
			print(items)
			return true
	
	return false
