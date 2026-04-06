class_name Reset extends TextureProgressBar
## Allows for resetting the level when holding R

func _process(delta: float) -> void:
	if Input.is_action_pressed("Reset"):
		value = move_toward(value, max_value, delta)
	else:
		value = move_toward(value, 0, delta)
	
	if value >= max_value:
		Global.reset_level.emit()
		value = 0.0
