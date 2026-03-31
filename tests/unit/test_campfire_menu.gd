extends GutTest

# Tests for pure-logic methods in campfire_menu.gd.
# _ready(), _unhandled_input(), and _on_*_button_pressed() depend on
# scene-tree nodes and cannot be driven headlessly. The tests below
# cover the conditional logic paths that do not access node refs.

const MenuScript = preload("res://scripts/campfire_menu.gd")
var _menu: MenuScript


func before_each() -> void:
	_menu = load("res://scripts/campfire_menu.gd").new()


func after_each() -> void:
	_menu.free()


# --- campfire reference ---

func test_campfire_is_null_by_default() -> void:
	assert_null(_menu.campfire)


func test_player_is_null_by_default() -> void:
	# player is typed var; default is null for typed node vars
	assert_null(_menu.player)


# --- _refresh_fire_button null guard ---
# _refresh_fire_button() must not crash when campfire is null.
func test_refresh_fire_button_does_not_crash_when_campfire_is_null() -> void:
	_menu.campfire = null
	_menu._refresh_fire_button()
	pass_test("null guard did not crash")


# --- _on_fire_button_pressed null guard ---
func test_fire_button_pressed_does_not_crash_when_campfire_is_null() -> void:
	_menu.campfire = null
	_menu._on_fire_button_pressed()
	pass_test("null guard did not crash")
