class_name Reset extends TextureProgressBar
## Allows for resetting the level when holding R

func _process(delta: float) -> void:
	var rdelta := delta / Engine.time_scale
	
	if Input.is_action_pressed("Reset"):
		value = move_toward(value, max_value, rdelta)
	else:
		value = move_toward(value, 0, rdelta)
	
	if value >= max_value:
		Global.request_animation.emit("ResetIn")
		value = 0.0
