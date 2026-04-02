class_name MainAnimator extends AnimationPlayer
## Allows global requests for animations.

func _ready() -> void:
	Global.request_animation.connect(_on_animation_requested)

func _on_animation_requested(anim_name:String):
	if has_animation(anim_name) and not is_playing():
		play(anim_name)
