class_name HealthBar
extends ProgressBar

var sb = StyleBoxFlat.new()

func _ready():
	add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("5cff61")

func update(health: int):
	value = health
	modulate_bar(health)
	if value >= max_value:
		visible = false
	else:
		visible = true
		
func modulate_bar(health):
	if health > max_value * 0.67:
		sb.bg_color = Color("5cff61")
	if health <= max_value * 0.67 and health > max_value * 0.33:
		sb.bg_color = Color("eedc3e")
	if health <= max_value * 0.33:
		sb.bg_color = Color("dd0716")
		
