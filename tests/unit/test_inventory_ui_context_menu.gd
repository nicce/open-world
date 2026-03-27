extends GutTest


# ---------------------------------------------------------------------------
# Unit tests for InventoryUI context-menu wiring (Task 2, Plan 05-02).
# RED: these tests are written before the PopupMenu changes exist.
#
# Tests cover:
#   - MENU_EQUIP / MENU_CONSUME / MENU_DROP const values
#   - _pending_context_index starts at -1
#   - PopupMenu child exists on the scene
#   - right_clicked signal is connected for every slot created in _ready
# ---------------------------------------------------------------------------


const INVENTORY_UI_SCENE: PackedScene = preload("res://scenes/inventory_ui.tscn")


func _make_ui() -> Control:
	var ui = INVENTORY_UI_SCENE.instantiate()
	add_child_autofree(ui)
	return ui


# ---------------------------------------------------------------------------
# Named const IDs
# ---------------------------------------------------------------------------


func test_menu_equip_id_is_zero() -> void:
	var ui = _make_ui()
	assert_eq(ui.MENU_EQUIP, 0)


func test_menu_consume_id_is_one() -> void:
	var ui = _make_ui()
	assert_eq(ui.MENU_CONSUME, 1)


func test_menu_drop_id_is_two() -> void:
	var ui = _make_ui()
	assert_eq(ui.MENU_DROP, 2)


# ---------------------------------------------------------------------------
# PopupMenu child exists
# ---------------------------------------------------------------------------


func test_popup_menu_child_exists() -> void:
	var ui = _make_ui()
	var popup = ui.get_node_or_null("PopupMenu")
	assert_not_null(popup, "InventoryUI must have a PopupMenu child node named 'PopupMenu'")


func test_popup_menu_child_is_popup_menu_type() -> void:
	var ui = _make_ui()
	var popup = ui.get_node_or_null("PopupMenu")
	if popup != null:
		assert_true(popup is PopupMenu, "PopupMenu child must be of type PopupMenu")


# ---------------------------------------------------------------------------
# _pending_context_index initial state
# ---------------------------------------------------------------------------


func test_pending_context_index_starts_at_minus_one() -> void:
	var ui = _make_ui()
	assert_eq(ui._pending_context_index, -1)


# ---------------------------------------------------------------------------
# right_clicked signal connected for all slots
# ---------------------------------------------------------------------------


func test_all_slots_have_right_clicked_connected() -> void:
	var ui = _make_ui()
	var grid = ui.get_node("NinePatchRect/GridContainer")
	for slot in grid.get_children():
		assert_true(
			slot.right_clicked.is_connected(ui._on_slot_right_clicked),
			"slot.right_clicked must be connected to _on_slot_right_clicked"
		)
