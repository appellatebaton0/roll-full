extends AnimationPlayer
# Makes an animation player's speed independent of the timescale.

func _process(_delta: float) -> void: speed_scale = 1. / Engine.time_scale
