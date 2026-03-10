extends GutTest


# ---------------------------------------------------------------------------
# CMBT-02: Knockback velocity is applied to the snake, directed away from
# the attacker's position, when the snake takes damage.
#
# The bug: Snake has no apply_knockback() method. When damaged, the snake
# plays a flash animation but receives no impulse — it never moves away from
# the player.
#
# These tests define the correct contract:
#   1. apply_knockback(from_position) must exist on Snake.
#   2. It must set knockback_velocity to a non-zero Vector2.
#   3. The resulting direction must point AWAY from from_position.
#   4. Passing global_position as from_position (zero direction) must not crash.
#
# All tests are RED until Plan 02 implements apply_knockback().
# ---------------------------------------------------------------------------


# Helper: create a Snake without _ready() needing a scene tree.
class SnakeStub:
	extends Snake

	func _ready() -> void:
		pass  # Skip scene-tree-dependent initialisation.


func test_apply_knockback_sets_nonzero_velocity() -> void:
	# Arrange: snake at (100, 100), attacker at (0, 0).
	var snake := SnakeStub.new()
	snake.global_position = Vector2(100.0, 100.0)

	# Act — will fail with "Method not found: apply_knockback" until Plan 02.
	snake.apply_knockback(Vector2(0.0, 0.0))

	# Assert
	assert_ne(
		snake.knockback_velocity,
		Vector2.ZERO,
		"knockback_velocity must be non-zero after apply_knockback()"
	)
	snake.free()


func test_apply_knockback_direction_is_away_from_attacker() -> void:
	# Snake at (100, 100), attacker at (0, 0).
	# Direction away from attacker is roughly (1, 1) normalised — both x and y positive.
	var snake := SnakeStub.new()
	snake.global_position = Vector2(100.0, 100.0)

	snake.apply_knockback(Vector2(0.0, 0.0))

	assert_gt(
		snake.knockback_velocity.x,
		0.0,
		"knockback x must be positive when snake is to the right of attacker"
	)
	assert_gt(
		snake.knockback_velocity.y,
		0.0,
		"knockback y must be positive when snake is below attacker"
	)
	snake.free()


func test_apply_knockback_zero_direction_does_not_crash() -> void:
	# Edge case: attacker is at the exact same position as the snake.
	# The normalised zero vector is Vector2.ZERO — this must not divide-by-zero
	# or produce a crash.
	var snake := SnakeStub.new()
	snake.global_position = Vector2(50.0, 50.0)

	# Must not crash even with identical positions.
	snake.apply_knockback(Vector2(50.0, 50.0))

	# No assertion on direction — just verify no crash occurred.
	assert_true(true, "apply_knockback with zero direction must not crash")
	snake.free()
