extends GutTest

var _health_component: HealthComponent


func before_each() -> void:
	_health_component = HealthComponent.new()
	_health_component.max_health = 100
	# health_bar left null — increase() and damage() both guard it
	add_child_autoqfree(_health_component)


# --- initial state ---

func test_health_equals_max_health_after_ready() -> void:
	assert_eq(_health_component.health, 100)


# --- damage ---

func test_damage_reduces_health() -> void:
	var attack := Attack.new()
	attack.damage = 30
	_health_component.damage(attack)
	assert_eq(_health_component.health, 70)


func test_damage_emits_damage_taken_when_health_remains() -> void:
	var attack := Attack.new()
	attack.damage = 10
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_emitted(_health_component, "damage_taken")


func test_damage_does_not_emit_health_depleated_when_health_remains() -> void:
	var attack := Attack.new()
	attack.damage = 10
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_not_emitted(_health_component, "health_depleated")


func test_damage_emits_health_depleated_when_health_reaches_zero() -> void:
	var attack := Attack.new()
	attack.damage = 100
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_emitted(_health_component, "health_depleated")


func test_damage_emits_health_depleated_when_overkilled() -> void:
	var attack := Attack.new()
	attack.damage = 999
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_emitted(_health_component, "health_depleated")


func test_damage_does_not_emit_damage_taken_on_lethal_hit() -> void:
	var attack := Attack.new()
	attack.damage = 100
	watch_signals(_health_component)
	_health_component.damage(attack)
	assert_signal_not_emitted(_health_component, "damage_taken")


# --- increase ---

func test_increase_raises_health() -> void:
	var attack := Attack.new()
	attack.damage = 40
	_health_component.damage(attack)
	_health_component.increase(20)
	assert_eq(_health_component.health, 80)


func test_increase_does_not_exceed_max_health() -> void:
	_health_component.increase(50)
	assert_eq(_health_component.health, 100)


func test_increase_clamps_to_max_when_over() -> void:
	var attack := Attack.new()
	attack.damage = 10
	_health_component.damage(attack)
	_health_component.increase(999)
	assert_eq(_health_component.health, 100)
