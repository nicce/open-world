extends Node2D

@export var music: AudioStreamPlayer


func _on_detection_area_lake_body_entered(body):
	BackgroundMusic.play_audio("dark_woodlands")
