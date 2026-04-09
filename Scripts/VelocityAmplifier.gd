class_name VelocityAmplifier extends Area2D

@export var additor := 40.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	
func _on_body_entered(body:Node2D): if body is Player:
	var direction:Vector2 = body.velocity.normalized()
	var magnitude:float   = body.velocity.distance_to(Vector2.ZERO)
	
	body.velocity = direction * (magnitude + (additor * 60))
	body.was_on_wall = false # Hijack it so the projection works.
	
	print(direction * magnitude, " -> ", direction * (magnitude + additor))
		
