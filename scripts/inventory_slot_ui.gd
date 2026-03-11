extends Panel

@onready var icon_rect: TextureRect = $IconRect
@onready var abbrev_label: Label = $AbbrevLabel
@onready var quantity_label: Label = $QuantityLabel


func update(slot: InventorySlot) -> void:
	if slot.is_empty():
		modulate.a = 0.4
		icon_rect.visible = false
		abbrev_label.visible = false
		quantity_label.visible = false
		return

	modulate.a = 1.0
	quantity_label.visible = true
	quantity_label.text = str(slot.quantity)

	if slot.item.texture != null:
		icon_rect.texture = slot.item.texture
		icon_rect.visible = true
		abbrev_label.visible = false
	else:
		icon_rect.visible = false
		abbrev_label.text = InventoryUIHelpers.abbreviate(slot.item.name)
		abbrev_label.visible = true
