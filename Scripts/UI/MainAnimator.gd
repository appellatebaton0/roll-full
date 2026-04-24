class_name MainAnimator extends AnimationPlayer
## Allows global requests for animations.

func _ready() -> void:
	Global.request_animation.connect(_on_animation_requested)
	animation_finished.connect(_on_animation_finished)

func _on_animation_requested(anim_name:String, optional_data:Variant = true):
	if has_animation(anim_name) and not is_playing():
		play(anim_name)
		
		match anim_name:
			"Levels->Game":
				get_tree().paused = true
			"Countdown":
				get_tree().paused = true
			"Game->Levels":
				get_tree().paused = true
				
				if optional_data:
					Global.level_complete.emit()
				
			"ResetIn":
				get_tree().paused = true

func _on_animation_finished(anim_name:String) -> void:
	match anim_name:
		"Game->Levels":
			## Free the current level.
			
			# Make sure all the levels are freed, actually.
			for level in get_tree().get_nodes_in_group("Level"):
				level.process_mode = Node.PROCESS_MODE_ALWAYS
				level.queue_free()
			Global.current_level = null
		"Levels->Game":
			play("Countdown")
		"Countdown":
			get_tree().paused = false
		"ResetIn":
			Global.reset_level.emit()
			play("ResetOut")
		"ResetOut":
			play("Countdown")
