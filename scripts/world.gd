extends Node2D

var player_scene = preload("res://scenes/player.tscn")
var player_dead = false

func _on_detection_area_home_body_entered(body):
	BackgroundMusic.play_audio("home")
	
func _physics_process(delta):
	if player_dead:
		var player = player_scene.instantiate()
		add_child(player)
		player_dead = false


func _on_player_player_dead():
	player_dead = true
