extends Node2D

@onready var test = $Test


func _on_detection_area_body_entered(body):
	print(body)
	if body.has_method("player"):
		test.play()
