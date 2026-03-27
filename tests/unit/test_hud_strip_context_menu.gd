extends GutTest


# ---------------------------------------------------------------------------
# Unit tests for HudStrip context-menu wiring (Task 1, Plan 08-01).
# RED: these tests are written before the PopupMenu changes exist.
#
# Tests cover:
#   - MENU_UNEQUIP / MENU_DROP const values
#   - _pending_slot_type starts at SlotType.NONE (value 0)
#   - PopupMenu child exists on the scene
#   - gui_input signals are connected on weapon and tool slots
# ---------------------------------------------------------------------------


const HUD_STRIP_SCENE: PackedScene = preload("res://scenes/hud_strip.tscn")


func _make_hud() -> Control:
	var hud = HUD_STRIP_SCENE.instantiate()
	add_child_autofree(hud)
	return hud


# ---------------------------------------------------------------------------
# Named const IDs
# ---------------------------------------------------------------------------


func test_menu_unequip_id_is_zero() -> void:
	var hud = _make_hud()
	assert_eq(hud.MENU_UNEQUIP, 0)


func test_menu_drop_id_is_one() -> void:
	var hud = _make_hud()
	assert_eq(hud.MENU_DROP, 1)


# ---------------------------------------------------------------------------
# _pending_slot_type initial state
# ---------------------------------------------------------------------------


func test_pending_slot_type_starts_at_none() -> void:
	var hud = _make_hud()
	assert_eq(hud._pending_slot_type, hud.SlotType.NONE)


# ---------------------------------------------------------------------------
# PopupMenu child exists
# ---------------------------------------------------------------------------


func test_popup_menu_child_exists() -> void:
	var hud = _make_hud()
	var popup = hud.get_node_or_null("PopupMenu")
	assert_not_null(popup, "HudStrip must have a PopupMenu child node named 'PopupMenu'")


func test_popup_menu_child_is_popup_menu_type() -> void:
	var hud = _make_hud()
	var popup = hud.get_node_or_null("PopupMenu")
	if popup != null:
		assert_true(popup is PopupMenu, "PopupMenu child must be of type PopupMenu")


# ---------------------------------------------------------------------------
# gui_input signals connected on slot panels
# ---------------------------------------------------------------------------


func test_weapon_slot_gui_input_connected() -> void:
	var hud = _make_hud()
	assert_true(
		hud._weapon_slot.gui_input.is_connected(hud._on_weapon_slot_gui_input),
		"_weapon_slot.gui_input must be connected to _on_weapon_slot_gui_input"
	)


func test_tool_slot_gui_input_connected() -> void:
	var hud = _make_hud()
	assert_true(
		hud._tool_slot.gui_input.is_connected(hud._on_tool_slot_gui_input),
		"_tool_slot.gui_input must be connected to _on_tool_slot_gui_input"
	)
