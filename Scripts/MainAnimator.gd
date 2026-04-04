class_name MainAnimator extends AnimationPlayer
## Allows global requests for animations.

func _ready() -> void:
	Global.request_animation.connect(_on_animation_requested)
	animation_finished.connect(_on_animation_finished)

func _on_animation_requested(anim_name:String):
	if has_animation(anim_name) and not is_playing():
		play(anim_name)
		
		match anim_name:
			"Levels->Game":
				get_tree().paused = true
			"Countdown":
				get_tree().paused = true
			"Game->Levels":
				get_tree().paused = true
			"ResetIn":
				get_tree().paused = true

func _on_animation_finished(anim_name:String) -> void:
	match anim_name:
		"Game->Levels":
			## Free the current level.
			pass
		"Levels->Game":
			play("Countdown")
		"Countdown":
			get_tree().paused = false
		"ResetIn":
			Global.reset_level.emit()
			play("ResetOut")
		"ResetOut":
			play("Countdown")
