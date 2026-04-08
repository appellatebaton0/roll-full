class_name DeathSpike extends Area2D
## Resets the level on contact w/ player.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body:Node2D) -> void:
	
	if body is Player:
		Global.request_animation.emit("ResetIn")
