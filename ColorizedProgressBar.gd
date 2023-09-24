extends ProgressBar

class_name ColorizedProgressBar

# This code works for "StyleBoxFlat" assigned to ProgressBar

func set_fill_color(color):
	var stylebox = get_theme_stylebox("fill")
	stylebox.bg_color = color
	add_theme_stylebox_override("fill", stylebox)
	
func set_background_color(color):
	var stylebox = get_theme_stylebox("background")
	stylebox.bg_color = color
	add_theme_stylebox_override("background", stylebox)
	
func _ready():
	self.max_value = 50

