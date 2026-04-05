@tool
class_name TimeSlow extends Node2D
## Slows time the closer the player is to the node.

@export var radius := 100.0
@export var easing := -2.0

@export var min_scale := 0.1

var dist:float:
	set(to):
		
		## Player left the range.
		if to > radius and dist < radius:
			Engine.time_scale = 1.0
		
		dist = to

@onready var player := get_tree().get_first_node_in_group("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void: 
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		dist = global_position.distance_to(player.global_position)
		
		if dist < radius:
			Engine.time_scale = get_scale_for_dist(dist)

func _draw() -> void: if Engine.is_editor_hint():
	
	var spacing := 10.0
	var size := 130
	for i in range(size):
		for j in range(size):
			var point := Vector2(i - (size / 2),j - (size / 2)) * spacing
			var point_dist := point.distance_to(Vector2.ZERO)
			if point_dist > radius: continue
			
			draw_rect(Rect2(point, Vector2.ONE * spacing), Color(1. - get_scale_for_dist(point_dist), 0.0, 0.0, 0.4) )
	
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.0, 0.0, 0.7), false, 15.0)
	
	
	
	

func get_scale_for_dist(distance:float):
	return lerp(min_scale, 1.0, ease(clamp(distance / radius, 0.0, 1.0), easing))
