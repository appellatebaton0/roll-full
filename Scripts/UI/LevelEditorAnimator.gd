class_name LevelEditorAnimator extends AnimationPlayer
## Catches animation requests meant for the main animator, and uses them
## For the level instead.

func _ready() -> void:
	Global.request_animation.connect(_on_animation_requested)
	animation_finished.connect(_on_animation_finished)

func _on_animation_requested(anim_name:String, _optional_data:Variant = true):
	#print(anim_name)
	if has_animation(anim_name) and not is_playing():
		
		match anim_name:
			"Countdown":
				get_tree().paused = true
			"ResetIn":
				# Only allow if a level isn't entered.
				if Global.current_level: return
				
				get_tree().paused = true
		
		play(anim_name, -1, 1.0 / Engine.time_scale)

func _on_animation_finished(anim_name:String) -> void:
	match anim_name:
		"Countdown":
			get_tree().paused = false
		"ResetIn":
			
			Global.reset_level.emit()
			play("ResetOut", -1, 1.0 / Engine.time_scale)
		"ResetOut":
			play("Countdown", -1, 1.0 / Engine.time_scale)
