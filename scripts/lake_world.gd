extends Node2D

func _on_detection_area_lake_body_entered(body):
	BackgroundMusic.play_audio("dark_woodlands")
