@tool
class_name Trail extends Line2D
## Creates a trail as its global_position changes.

@export var trail_segments:int = 2:
	set(to):
		points.resize(to)
		trail_segments = to
@export var follow_speed:float = 40.0

@onready var start_pos := global_position

func get_follow_point() -> Vector2:
	return Vector2.ZERO
 
func _ready() -> void: 
	last_position = global_position
	if not Engine.is_editor_hint():
		Global.reset_level.connect(_on_reset)

var last_position := Vector2.ZERO
func _process(delta: float) -> void:
	
	for i in trail_segments:
		# print(to_local(followee.global_position))
		#print(i)
		if i == 0:
			set_point_position(i, Vector2.ZERO)
		else:
			var additor := Vector2.ZERO
			if global_position != last_position:
				additor = (last_position - global_position)
			set_point_position(i, get_new_position(i, additor, delta))
	
	last_position = global_position

func get_new_position(index:int, additor:Vector2, delta:float) -> Vector2:
	var from := get_point_position(index) + additor
	var to := get_point_position(index - 1)
	
	var amount := from.direction_to(to) * (from.distance_to(to) * delta * follow_speed)
	
	var result:Vector2
	result.x = move_toward(from.x, to.x, abs(amount.x))
	result.y = move_toward(from.y, to.y, abs(amount.y))
	
	return result
	

func _on_reset():
	var new_points:Array[Vector2]
	for i in trail_segments: new_points.append(Vector2.ZERO)
	
	points = new_points
	
	last_position = start_pos
