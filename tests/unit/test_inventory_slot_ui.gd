extends GutTest


# ---------------------------------------------------------------------------
# Unit tests for inventory_slot_ui.gd right_clicked signal.
# RED: these tests are written before the right_clicked signal exists.
# ---------------------------------------------------------------------------


const SLOT_SCENE: PackedScene = preload("res://scenes/inventory_slot_ui.tscn")


func _make_slot() -> Panel:
	var slot = SLOT_SCENE.instantiate()
	add_child_autofree(slot)
	return slot


# ---------------------------------------------------------------------------
# signal declarations
# ---------------------------------------------------------------------------


func test_slot_has_right_clicked_signal() -> void:
	var slot = _make_slot()
	assert_true(slot.has_signal("right_clicked"), "right_clicked signal must be declared")


func test_slot_has_slot_clicked_signal() -> void:
	var slot = _make_slot()
	assert_true(slot.has_signal("slot_clicked"), "slot_clicked signal must still exist")


# ---------------------------------------------------------------------------
# right_clicked emission
# ---------------------------------------------------------------------------


func test_right_click_emits_right_clicked() -> void:
	var slot = _make_slot()
	watch_signals(slot)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	slot._gui_input(event)
	assert_signal_emitted(slot, "right_clicked")


func test_right_clicked_emitted_with_self() -> void:
	var slot = _make_slot()
	var received: Array = []
	slot.right_clicked.connect(func(node): received.append(node))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	slot._gui_input(event)
	assert_eq(received.size(), 1)
	assert_eq(received[0], slot)


func test_right_click_release_does_not_emit() -> void:
	var slot = _make_slot()
	watch_signals(slot)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = false
	slot._gui_input(event)
	assert_signal_not_emitted(slot, "right_clicked")


# ---------------------------------------------------------------------------
# left_clicked still works unchanged
# ---------------------------------------------------------------------------


func test_left_click_emits_slot_clicked() -> void:
	var slot = _make_slot()
	watch_signals(slot)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	slot._gui_input(event)
	assert_signal_emitted(slot, "slot_clicked")


func test_left_click_does_not_emit_right_clicked() -> void:
	var slot = _make_slot()
	watch_signals(slot)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	slot._gui_input(event)
	assert_signal_not_emitted(slot, "right_clicked")


func test_right_click_does_not_emit_slot_clicked() -> void:
	var slot = _make_slot()
	watch_signals(slot)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	slot._gui_input(event)
	assert_signal_not_emitted(slot, "slot_clicked")
