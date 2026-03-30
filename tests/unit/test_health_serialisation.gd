extends GutTest

func test_load_health_sets_value() -> void:
	var hc = HealthComponent.new()
	hc.max_health = 100
	hc._ready()
	
	hc.load_health(25)
	assert_eq(hc.health, 25)


func test_load_health_clamps_value() -> void:
	var hc = HealthComponent.new()
	hc.max_health = 100
	hc._ready()
	
	hc.load_health(150)
	assert_eq(hc.health, 100)
	
	hc.load_health(-10)
	assert_eq(hc.health, 0)


func test_load_health_updates_health_bar() -> void:
	var hc = HealthComponent.new()
	hc.max_health = 100
	
	# Using HealthBar.new() because HealthComponent calls health_bar.update()
	var hb = HealthBar.new()
	hc.health_bar = hb
	
	hc._ready()
	hc.load_health(50)
	
	assert_eq(hb.value, 50.0)
