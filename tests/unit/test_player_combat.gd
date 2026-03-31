extends GutTest


# ---------------------------------------------------------------------------
# CMBT-03: hit() sets attack.damage to weapon.damage (int cast) when equipped.
# CMBT-04: hit() leaves attack.damage unchanged when no weapon is equipped.
#
# These tests drive the combat dispatch implementation in player.gd hit().
# hit() must read equipment_data.weapon at call time (no caching).
# ---------------------------------------------------------------------------


# Helper: create a plain Player object without triggering _ready() node lookups.
class PlayerStub:
	extends Player

	func _ready() -> void:
		pass  # Skip @onready assignments that require scene tree nodes.


func _make_attack(dmg: int) -> Attack:
	var a := Attack.new()
	a.damage = dmg
	return a


func _make_weapon(dmg: float) -> WeaponItem:
	var w := WeaponItem.new()
	w.damage = dmg
	return w


func test_hit_with_weapon_sets_attack_damage() -> void:
	# CMBT-03: weapon equipped — hit() must overwrite attack.damage.
	var player := PlayerStub.new()
	player.attack = _make_attack(5)
	var ed := EquipmentData.new()
	ed.weapon = _make_weapon(15.0)
	player.equipment_data = ed

	player.hit()

	assert_eq(player.attack.damage, 15, "hit() must set attack.damage to int(weapon.damage)")
	player.free()


func test_hit_without_weapon_leaves_fist_damage() -> void:
	# CMBT-04: no weapon — hit() must not touch attack.damage.
	var player := PlayerStub.new()
	player.attack = _make_attack(5)
	player.base_damage = 5
	player.equipment_data = EquipmentData.new()  # weapon is null

	player.hit()

	assert_eq(player.attack.damage, 5, "hit() must leave attack.damage unchanged when no weapon")
	player.free()


func test_hit_without_equipment_data_leaves_fist_damage() -> void:
	# CMBT-04 edge: equipment_data itself is null — must not crash.
	var player := PlayerStub.new()
	player.attack = _make_attack(5)
	player.base_damage = 5
	player.equipment_data = null

	player.hit()

	assert_eq(player.attack.damage, 5, "hit() must leave attack.damage unchanged when equipment_data is null")
	player.free()


func test_hit_casts_float_damage_to_int() -> void:
	# CMBT-03: weapon.damage is float — int() truncates towards zero.
	var player := PlayerStub.new()
	player.attack = _make_attack(5)
	var ed := EquipmentData.new()
	ed.weapon = _make_weapon(7.9)
	player.equipment_data = ed

	player.hit()

	assert_eq(player.attack.damage, 7, "hit() must truncate float weapon damage to int")
	player.free()


func test_hit_resets_to_base_damage_after_unequip() -> void:
	# Verify that damage is reset to base_damage when no weapon is equipped.
	var player := PlayerStub.new()
	player.attack = _make_attack(1)
	player.base_damage = 1
	var ed := EquipmentData.new()
	ed.weapon = _make_weapon(15.0)
	player.equipment_data = ed

	# Equip and hit
	player.hit()
	assert_eq(player.attack.damage, 15, "Damage should be 15 with weapon")

	# Unequip and hit
	ed.weapon = null
	player.hit()
	assert_eq(player.attack.damage, 1, "Damage should reset to base_damage (1) after unequip")
	player.free()
