extends StaticBody2D

@onready var light_flicker_animation: AnimationPlayer = $Flicker

func _ready():
	light_flicker_animation.play("light_flicker")
