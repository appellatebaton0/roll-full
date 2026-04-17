class_name VelocityAmplifier extends Area2D

@export var additor := 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	for child in get_children(): if child is RegularPolygon:
		child.modulate.r = 1.0 - (additor / 80)
	
func _on_body_entered(body:Node2D): if body is Player:
	var direction:Vector2 = body.velocity.normalized()
	var magnitude:float   = body.velocity.distance_to(Vector2.ZERO)
	
	body.velocity = direction * (magnitude + (additor * 60))
	body.was_on_wall = false # Hijack it so the projection works.
