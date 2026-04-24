@tool
class_name Trail extends Line2D
## Creates a trail as its global_position changes.

@export var trail_segments:int = 2:
	set(to):
		points.resize(to)
		trail_segments = to
@export_range(0.0, 1.0, 0.05) var lerp_weight:float = 0.0

@onready var start_pos := global_position

func get_follow_point() -> Vector2:
	return Vector2.ZERO
 
func _ready() -> void: 
	last_position = global_position
	if not Engine.is_editor_hint():
		Global.reset_level.connect(_on_reset)

var last_position := Vector2.ZERO
func _process(_delta: float) -> void:
	
	for i in trail_segments:
		# print(to_local(followee.global_position))
		#print(i)
		if i == 0:
			set_point_position(i, Vector2.ZERO)
		else:
			var additor := Vector2.ZERO
			if global_position != last_position:
				additor = (last_position - global_position)
			set_point_position(i, lerp(get_point_position(i) + additor, get_point_position(i - 1), lerp_weight))
	
	last_position = global_position

func _on_reset():
	var new_points:Array[Vector2]
	for i in trail_segments: new_points.append(Vector2.ZERO)
	
	points = new_points
	
	last_position = start_pos
