class_name Goal extends Area2D
## Ends the level on contact, and stores the time.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body:Node2D) -> void:
	if body is Player:
		Global.request_animation.emit("Game->Levels")
