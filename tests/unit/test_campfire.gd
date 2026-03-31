extends GutTest

# Tests for the pure inventory logic in campfire.gd.
# The scene children (fire, smoke, light) are not tested here.

const CampfireScript = preload("res://scripts/campfire.gd")
var _campfire: CampfireScript


func before_each() -> void:
	_campfire = load("res://scripts/campfire.gd").new()
	_campfire.inventory = 0
	_campfire.max_inventory = 10


func after_each() -> void:
	_campfire.free()


# --- add_wood ---

func test_add_wood_increases_inventory() -> void:
	_campfire.add_wood(3)
	assert_eq(_campfire.inventory, 3)


func test_add_wood_returns_zero_when_within_capacity() -> void:
	var overflow := _campfire.add_wood(3)
	assert_eq(overflow, 0)


func test_add_wood_caps_inventory_at_max() -> void:
	_campfire.add_wood(15)
	assert_eq(_campfire.inventory, 10)


func test_add_wood_returns_overflow_amount() -> void:
	_campfire.inventory = 8
	var overflow := _campfire.add_wood(5)
	assert_eq(overflow, 3)


func test_add_wood_at_exact_capacity_returns_zero() -> void:
	_campfire.inventory = 7
	var overflow := _campfire.add_wood(3)
	assert_eq(overflow, 0)
	assert_eq(_campfire.inventory, 10)


func test_add_wood_to_full_inventory_returns_full_amount() -> void:
	_campfire.inventory = 10
	var overflow := _campfire.add_wood(4)
	assert_eq(overflow, 4)
	assert_eq(_campfire.inventory, 10)


# --- withdraw_wood ---

func test_withdraw_wood_reduces_inventory() -> void:
	_campfire.inventory = 8
	_campfire.withdraw_wood(3)
	assert_eq(_campfire.inventory, 5)


func test_withdraw_wood_returns_remaining_inventory() -> void:
	_campfire.inventory = 8
	var remaining := _campfire.withdraw_wood(3)
	assert_eq(remaining, 5)


func test_withdraw_wood_clamps_to_zero() -> void:
	_campfire.inventory = 2
	_campfire.withdraw_wood(5)
	assert_eq(_campfire.inventory, 0)


func test_withdraw_wood_returns_zero_when_clamped() -> void:
	_campfire.inventory = 2
	var remaining := _campfire.withdraw_wood(5)
	assert_eq(remaining, 0)


func test_withdraw_exact_inventory_empties_campfire() -> void:
	_campfire.inventory = 5
	var remaining := _campfire.withdraw_wood(5)
	assert_eq(remaining, 0)
	assert_eq(_campfire.inventory, 0)


# --- fire_enabled flag ---

func test_fire_enabled_defaults_to_true() -> void:
	assert_true(_campfire.fire_enabled)


func test_extinguish_sets_fire_enabled_false() -> void:
	# extinguish() calls smoke() which touches scene nodes — skip the visual side,
	# test only the flag by patching is_fire to false so smoke()'s guard is a no-op.
	_campfire.is_fire = false
	_campfire.fire_enabled = true
	_campfire.extinguish()
	assert_false(_campfire.fire_enabled)


func test_light_sets_fire_enabled_true() -> void:
	_campfire.fire_enabled = false
	_campfire.is_fire = true  # fire() guard: if !is_fire — already true means no-op visual path
	_campfire.light()
	assert_true(_campfire.fire_enabled)
