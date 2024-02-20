extends Node2D


@onready
var home_area_audio = $HomeAreaAudio

# Called when the node enters the scene tree for the first time.
func _ready():
	home_area_audio.play()
