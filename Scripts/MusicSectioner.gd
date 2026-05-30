@tool
class_name MusicSectioner extends Line2D
## Sections the level into 4 areas using its points, 
## for making the adaptive music change on location.

@onready var player:Player = get_tree().get_first_node_in_group("Player")
@export_tool_button("REDRAW") var rdrw := queue_redraw

const SECTOR_SIZE := 200

func closest_point(against:Vector2 = player.global_position) -> int:
	
	var best := -1
	var best_dist := INF
	
	for i in points.size():
		var dist := (points[i] + global_position).distance_to(against)
		
		if dist < best_dist:
			best = i
			best_dist = dist
	
	return best

func _draw() -> void: if Engine.is_editor_hint():
	var min_x:float = INF
	var min_y:float = INF
	var max_x:float = -INF
	var max_y:float = -INF
	
	for point in points:
		min_x = min(point.x, min_x)
		min_y = min(point.y, min_y)
		max_x = max(point.x, max_x)
		max_y = max(point.y, max_y)
	
	min_x -= 5000
	min_y -= 5000
	max_x += 5000
	max_y += 5000
	
	var colors := [Color(1,0,0,0.3), Color(1,0.5,0,0.3), Color(1,1,0,0.3), Color(0,1,0,0.3)]
	
	for x in range(min_x, max_x, SECTOR_SIZE):
		for y in range(min_y, max_y, SECTOR_SIZE):
			draw_rect(Rect2(x, y, SECTOR_SIZE, SECTOR_SIZE), colors[closest_point(Vector2(x,y) + (Vector2.ONE * SECTOR_SIZE / 2))])
			#print("DRAW")
