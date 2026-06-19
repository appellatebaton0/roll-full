class_name DeathBorderPlaceholder extends ScenePlaceholder
## A placeholder for the level's DeathBorder.

signal points_changed(from:PackedVector2Array, to:PackedVector2Array)

@export var drag_area_offset := 10.0

@onready var polygon  := $Polygon2D
@onready var collider := $DragArea/CollisionShape2D

@onready var hint_circle := $HintCircle

func _ready() -> void:
	super()
	
	drag_area.mouse_entered.connect(_mouse_entered)
	drag_area.mouse_exited.connect(_mouse_exited)

## Update whenever anything changes.
var last_points:PackedVector2Array
func _process(_delta: float) -> void: 
	
	if polygon.polygon != last_points:
		update_drag_points()
		
		regenerate_collider()
		
		last_points = polygon.polygon
	

# Regenerate the drag area collider to match the new polygon.
func regenerate_collider() -> void:
	
	var looped_line := polygon.polygon as PackedVector2Array
	looped_line.append(polygon.polygon[0])
	
	var gons := Geometry2D.offset_polyline(looped_line, 5.0)
	
	var outer:Array[Vector2]
	outer.assign(Array(gons[0]))
	
	var inner:Array[Vector2]
	inner.assign(Array(gons[1]))
	var inner_point:Vector2 = inner.back()
	
	var outer_point:Vector2
	for point in outer:
		
		if outer_point == null:
			outer_point = point
			continue
		
		if point.distance_to(inner_point) < outer_point.distance_to(inner_point):
			outer_point = point
	
	outer_point += inner_point.direction_to(outer_point) * 1.01
	inner_point += inner_point.direction_to(inner.front()) * 0.01
	
	inner.push_back(outer_point)
	inner.push_back(inner_point)
	
	collider.polygon = Geometry2D.clip_polygons(outer, inner)[0]


# The array of drag points. Index in this array = index of the point in the line's point array.
var drag_points:Array[DragPoint]

# Update the positions of the drag polygon, and make more (or less) if necessary.
const DRAG_POINT_SCENE := preload("res://DragPoint.tscn")
func update_drag_points() -> void:
	
	# Shave off any extra polygon.
	while polygon.polygon.size() < drag_points.size():
		var back:DragPoint = drag_points.pop_back()
		if back: back.queue_free()
	
	# Add any new ones.
	while polygon.polygon.size() > drag_points.size():
		var new:DragPoint = DRAG_POINT_SCENE.instantiate()
		
		add_child(new)
		
		drag_points.append(new)
		
		new.selected.connect(selected.emit)
		holdability_changed.connect(func(to:bool): new.can_be_held = to)
		new.can_be_held = can_be_held
		
		new.drag_started.connect(_drag_started)
		new.drag_ended.connect(_drag_ended)
		
		new.position_changed.connect(update_point_position.bind(drag_points.size() - 1))
	
	# Fix all the positions of the drag polygon.
	for i in polygon.polygon.size():
		drag_points[i].position = polygon.polygon[i]

func update_point_position(i:int):
	polygon.polygon[i] = drag_points[i].position

var drag_start_points:PackedVector2Array
func _drag_started() -> void: drag_start_points = polygon.polygon
func _drag_ended() -> void:   points_changed.emit(drag_start_points, polygon.polygon)

func _mouse_entered() -> void: hint_circle.show()
func _mouse_exited () -> void: hint_circle.hide()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	
	
	if event is InputEventMouse:
		var local_pos := get_local_mouse_position()
		hint_circle.position = local_pos
	
		if event is InputEventMouseButton and event.is_pressed():
			print("PRESSED!")
			# Something something figure out which line the press was along.
			pass
	
	pass
