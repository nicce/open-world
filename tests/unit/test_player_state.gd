extends GutTest


# ---------------------------------------------------------------------------
# CMBT-01: Player state resets to MOVE after attack animation completes.
#
# The bug: Player.hit() transitions to HIT state but never transitions back
# to MOVE. on_player_state_reset() exists but is never connected to any
# animation signal — so the player is permanently stuck in HIT state.
#
# These tests define the correct contract:
#   1. on_player_state_reset() must set current_state back to MOVE (positive path).
#   2. hit() must eventually lead to a MOVE state reset — tested by verifying
#      the animation signal connection drives the reset. Until Plan 02 wires
#      the AnimationPlayer signal to on_player_state_reset(), the integration
#      test will remain RED.
# ---------------------------------------------------------------------------


# Helper: create a plain Player object without triggering _ready() node lookups.
# We use a local subclass that overrides _ready() as a no-op so we can test
# pure state logic without a scene tree.
class PlayerStub:
	extends Player

	func _ready() -> void:
		pass  # Skip @onready assignments that require scene tree nodes.


func test_on_player_state_reset_sets_state_to_move() -> void:
	# Arrange: create stub, force into HIT state.
	var player := PlayerStub.new()
	player.current_state = Player.PlayerStates.HIT

	# Act
	player.on_player_state_reset()

	# Assert
	assert_eq(
		player.current_state,
		Player.PlayerStates.MOVE,
		"on_player_state_reset() must set current_state to MOVE"
	)
	player.free()


func test_initial_state_is_move() -> void:
	# A freshly created Player starts in MOVE state.
	var player := PlayerStub.new()
	assert_eq(
		player.current_state,
		Player.PlayerStates.MOVE,
		"Player must start in MOVE state"
	)
	player.free()


func test_hit_state_resets_to_move_via_animation_signal() -> void:
	# CMBT-01 acceptance test — this MUST be RED until Plan 02 wires the
	# attack animation's animation_finished signal to on_player_state_reset().
	#
	# Contract: after entering HIT state, calling the signal handler that the
	# AnimationPlayer is supposed to emit must flip current_state back to MOVE.
	# The signal handler is expected to be named on_attack_animation_finished()
	# (or similar) and call on_player_state_reset().
	#
	# Currently no such signal handler exists — calling it will fail.
	var player := PlayerStub.new()
	player.current_state = Player.PlayerStates.HIT

	# This call will fail with "Method not found" until Plan 02 adds the
	# animation-finished handler that calls on_player_state_reset().
	player.on_attack_animation_finished()

	assert_eq(
		player.current_state,
		Player.PlayerStates.MOVE,
		"After attack animation finishes, state must return to MOVE"
	)
	player.free()
