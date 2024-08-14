extends StaticBody2D

@onready var light_flicker_animation: AnimationPlayer = $Flicker
@onready var fire_scene = $Fire
@onready var smoke_scene = $Smoke
@onready var fire_light = $PointLight2D

var max_inventory: int = 10
var wood_burn_time_in_seconds: int = 60
var is_fire: bool = false
var interactable: bool = false
var inventory: int = 0
var burn_timer: Timer

func _ready():
	burn_timer = Timer.new()
	add_child(burn_timer)
	burn_timer.wait_time = wood_burn_time_in_seconds
	burn_timer.autostart = false
	burn_timer.timeout.connect(_on_burn_timer_timeout)
	if inventory > 0:
		fire()
	else:
		smoke()

func _physics_process(delta):
	if interactable && Input.is_action_just_pressed("interact"):
		add_wood(1)
		
	if inventory > 0:
		fire()
	else:
		smoke()
		
func _on_burn_timer_timeout() -> void:
	var inventory_left = withdraw_wood(1)
	
func _on_interact_area_body_entered(body):
	interactable = true


func _on_interact_area_body_exited(body):
	interactable = false

# lights the fire and light animation if not already on
func fire() -> void:
	if !is_fire:
		smoke_scene.visible = false
		fire_scene.visible = true
		fire_light.visible = true
		light_flicker_animation.play("light_flicker")
		burn_timer.start()
	
	is_fire = true
		
# removes fire and start the smoke
func smoke() -> void:
	if is_fire:
		fire_scene.visible = false
		light_flicker_animation.stop()
		fire_light.visible = false
		smoke_scene.visible = true
		burn_timer.stop()
	
	is_fire = false

# add wood to the campfire inventory, will return the amount of wood that didn't got added
func add_wood(amount: int) -> int:
	inventory += amount
	if inventory > max_inventory:
		inventory = max_inventory
		return inventory - max_inventory
	
	return 0
	
# withdraws wood from the campfire inventory, will return the amount of wood that is left.
func withdraw_wood(amount: int) -> int:
	inventory -= amount
	if inventory < 0:
		inventory = 0
	
	return inventory
