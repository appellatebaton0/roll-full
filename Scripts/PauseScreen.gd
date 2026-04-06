class_name PauseScreen extends TextureRect
## The screen showing available options when the game is paused.

var paused := false
var can_pause := true

@onready var animator := $AnimationPlayer

func _process(_delta: float) -> void:
	if can_pause and not animator.is_playing():
		if Input.is_action_just_pressed("Pause"):
			animator.play("Unpause" if paused else "Pause")
			paused = !paused
			
			get_tree().paused = paused
