extends GutTest


# ---------------------------------------------------------------------------
# Unit tests for InventoryUIHelpers static functions.
# These tests are RED until scripts/inventory_ui_helpers.gd is created (Task 2).
# ---------------------------------------------------------------------------


func test_abbreviate_short_name_unchanged() -> void:
	assert_eq(InventoryUIHelpers.abbreviate("Axe", 4), "Axe")


func test_abbreviate_long_name_trimmed() -> void:
	assert_eq(InventoryUIHelpers.abbreviate("Medicpack", 4), "Medi")


func test_abbreviate_exact_length_unchanged() -> void:
	assert_eq(InventoryUIHelpers.abbreviate("Wood", 4), "Wood")


func test_weight_format_string() -> void:
	assert_eq(InventoryUIHelpers.format_weight(12.5, 20.0), "12.5 / 20 kg")


func test_weight_format_string_zero() -> void:
	assert_eq(InventoryUIHelpers.format_weight(0.0, 50.0), "0.0 / 50 kg")
