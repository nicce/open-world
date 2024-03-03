extends Node2D

var snake_scene = preload("res://scenes/snake.tscn")
var snake_start_position = Vector2(329, 50)
var snake_spawn_cooldown: Timer

func _ready():
	spawn_snake()
	snake_spawn_cooldown = Timer.new()
	add_child(snake_spawn_cooldown)
	snake_spawn_cooldown.one_shot = true
	snake_spawn_cooldown.timeout.connect(_on_snake_spawn_timeout)

func _on_detection_area_lake_body_entered(body):
	BackgroundMusic.play_audio("dark_woodlands")

func _on_child_exiting_tree(node):
	if node is Snake:
		snake_spawn_cooldown.start(60)
		
func _on_snake_spawn_timeout():
	spawn_snake()
		
func spawn_snake():
	var snake = snake_scene.instantiate()
	snake.position = snake_start_position
	
	add_child(snake)
