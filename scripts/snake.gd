extends CharacterBody2D

@export var speed = 70.0
@export var health = 100

var damage: int
var player: CharacterBody2D

var dead = false
var player_in_area = false

	
func _physics_process(delta):
	if !dead:
		$DetectionArea/CollisionShape2D.disabled = false
		if player_in_area:
			var direction = player.position - position
			velocity = (direction * speed).normalized() / delta
			var angle_degrees = rad_to_deg(direction.angle())
			print(angle_degrees)
		
			if (angle_degrees > -45 and angle_degrees <= 45):
				$AnimatedSprite2D.play("move_east")
			elif (angle_degrees > 45 and angle_degrees <= 135):
				$AnimatedSprite2D.play("move_south")
			elif (angle_degrees > -135 and angle_degrees <= -45):
				$AnimatedSprite2D.play("move_north")
			else:
				$AnimatedSprite2D.play("move_west")
			move_and_slide()
		else:
			$AnimatedSprite2D.play("idle")
	else:
		queue_free()
		

func _on_detection_area_body_entered(body):
	player = body
	player_in_area = true


func _on_detection_area_body_exited(body):
	player_in_area = false
