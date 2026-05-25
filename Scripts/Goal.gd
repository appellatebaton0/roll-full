@tool
class_name Goal extends Area2D
## Ends the level on contact, and stores the time.

@export var spins:Dictionary[Node2D, float]

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body:Node2D) -> void:
	if body is Player:
		Global.request_animation.emit("Game->Levels")

func _process(delta: float) -> void: 
	for spin in spins: if spin:
		spin.rotate(spins[spin] * delta)
