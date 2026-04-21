class_name MouseParallax extends Parallax2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void: screen_offset = get_global_mouse_position()
