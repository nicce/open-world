extends CharacterBody2D

const SPEED = 100.0
const IDLE_STATE = "idle"
const WALKING_STATE = "walking"

var player_state

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction.x == 0 and direction.y == 0:
		player_state = IDLE_STATE
	elif direction.x != 0 or direction.y != 0:
		player_state = WALKING_STATE
	
	velocity = direction * SPEED
	move_and_slide()
	
	play_animation(direction)
	
func play_animation(dir):
	if player_state == IDLE_STATE:
		$AnimatedSprite2D.play("idle")
	if player_state == WALKING_STATE:
		$AnimatedSprite2D.flip_h = false
		if dir.y == -1:
			$AnimatedSprite2D.play("walk_north")
		elif dir.y == 1:
			$AnimatedSprite2D.play("walk_south")
		elif dir.x == -1:
			$AnimatedSprite2D.flip_h = true
			$AnimatedSprite2D.play("walk_east")
		elif dir.x == 1:
			$AnimatedSprite2D.play("walk_east")

