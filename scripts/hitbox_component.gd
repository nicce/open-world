class_name HitboxComponent
extends Area2D

@export var health_component: HealthComponent # TODO replace with signal?

var cooldown_timer: Timer
var attacked = false
var cooldown = false
var attack: Attack

func _ready():
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)

func _physics_process(delta):
	if attacked and !cooldown:
		take_damage(attack)
		cooldown = true
		cooldown_timer.start(attack.cooldown)

func _on_body_entered(body):
	if "attack" in body:
		attacked = true
		attack = body.attack

func _on_body_exited(body):
	attacked = false
	
func _on_cooldown_timeout():
	cooldown = false
	
# is the function that gets triggered when an item enters the area aka weapon or fists
func _on_area_entered(area):
	if "attack" in area.get_parent():
		var attack = area.get_parent().attack
		take_damage(attack)

func take_damage(attack: Attack):
	if health_component:
		health_component.damage(attack)
