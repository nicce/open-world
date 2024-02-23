extends Node2D

func _on_detection_area_home_body_entered(body):
	if body.has_method("player"):
		BackgroundMusic.play_audio("home")
