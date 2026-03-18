extends Panel

signal slot_clicked(slot_node: Panel)
signal right_clicked(slot_node: Panel)

var _selected_style: StyleBoxFlat = null

@onready var icon_rect: TextureRect = $IconRect
@onready var abbrev_label: Label = $AbbrevLabel
@onready var quantity_label: Label = $QuantityLabel


func _ready() -> void:
	# Panel self_modulate is 0 in scene (hides default background).
	# Restore to 1 so StyleBox border renders; use transparent default style.
	self_modulate.a = 1.0
	var default_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", default_style)

	_selected_style = StyleBoxFlat.new()
	_selected_style.border_width_left = 2
	_selected_style.border_width_right = 2
	_selected_style.border_width_top = 2
	_selected_style.border_width_bottom = 2
	_selected_style.border_color = Color(1.0, 0.85, 0.0)
	_selected_style.bg_color = Color(0, 0, 0, 0)
	_selected_style.draw_center = false


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		right_clicked.emit(self)
		get_viewport().set_input_as_handled()


func set_selected(selected: bool) -> void:
	if selected:
		add_theme_stylebox_override("panel", _selected_style)
	else:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())


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
