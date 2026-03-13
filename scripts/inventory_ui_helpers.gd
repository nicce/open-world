class_name InventoryUIHelpers extends RefCounted


static func abbreviate(item_name: String, max_len: int = 4) -> String:
	if item_name.length() <= max_len:
		return item_name
	return item_name.left(max_len)


static func format_weight(current: float, max_w: float) -> String:
	return "%.1f / %.0f kg" % [current, max_w]
