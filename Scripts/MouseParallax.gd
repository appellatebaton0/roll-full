class_name MouseParallax extends Parallax2D

@export var focused := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void: if focused and is_visible_in_tree(): screen_offset = scroll_scale * get_global_mouse_position()
