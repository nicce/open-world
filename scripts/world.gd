extends Node2D


func _on_detection_area_home_body_entered(_body):
	BackgroundMusic.play_audio("home")
