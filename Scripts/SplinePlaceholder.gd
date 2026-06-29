class_name SplinePlaceholder extends ScenePlaceholder
## A placeholder for a spline, with all the usual customizability.

signal points_changed(from:PackedVector2Array, to:PackedVector2Array)

@onready var line:Line2D = $Line2D
@onready var spline_collider := $DragArea/CollisionShape2D

@export_storage var initial_points:PackedVector2Array # A copy of line.points for initial setting when this gets packed.

# The array of drag points. Index in this array = index of the point in the line's point array.
var drag_points:Array[DragPoint]

var color := Color.WHITE:
	set(to):
		color = to
		
		queue_redraw()

## The line.points that make up the visible line / mesh.
## Amount depends on seg
var sample_points:Array[Vector2]
## The current mesh based off sample_points and the line width.
var sample_mesh:PackedVector2Array

@export var width := 40.0

var seg := 20.0:
	set(to):
		seg = to
		
		regenerate_sample()
		queue_redraw()

func _set_holdability(to) -> void:
	can_be_held = to
	for point in drag_points:
		point.can_be_held = to
		point.modulate = Color(1.0, 1.0, 1.0, 1.0) if to else Color(0.56, 0.56, 0.56, 0.69)
	holdability_changed.emit(to)

func _draw() -> void:
	if len(sample_mesh) > 2: draw_polygon(sample_mesh, [color])
	draw_line(Vector2.UP * 20,   Vector2.DOWN * 20, Color.ORANGE, 5.0)
	draw_line(Vector2.LEFT * 20, Vector2.RIGHT * 20, Color.ORANGE, 5.0)
	#if len(line_collider.polygon) > 2: draw_polygon(line_collider.polygon, [Color.RED])

func _ready() -> void: 
	super._ready()
	
	line.points = initial_points if initial_points else line.points
	
	regenerate_sample()
	queue_redraw()

## Update whenever anything changes.
var last_points:PackedVector2Array
func _process(_delta: float) -> void: 
	
	super._process(_delta)
	
	line.width = 15. / get_viewport().get_camera_2d().zoom.x
	
	if line.points != last_points:
		update_drag_points()
		
		regenerate_sample()
		
		last_points = line.points
		initial_points = last_points
		
		queue_redraw()


## -- Spline Generation -- ##

## Create a bezier spline using an array of line.points.
func bezier(t := 0.0, with := line.points) -> Vector2:
	
	## Create all the segments
	var segments:Array[Array]
	for i in with.size():
		
		if i % 3 == 0:
			var segment:Array[Vector2]
			for j in 4:
				if with.size() > i+j:
					segment.append(with[i + j])
			segments.append(segment)
	
	
	return spline(t - floor(t), segments[floor(t)])

## Create a basic spline using an array of line.points.
func spline(t := 0.0, with := line.points) -> Vector2:
	
	match len(with):
		0: return Vector2.ZERO
		1: return with[0]
		2: return lerp(with[0], with[1], t)
		_: 
			#print(with)
			@warning_ignore("integer_division")
			var left = with.slice(0, len(with) / 2)
			@warning_ignore("integer_division")
			var right = with.slice(len(with)/2, len(with))
			
			
			var left_spline  = spline(t, left)
			var right_spline = spline(t, right)
			
			return lerp(left_spline, right_spline, t)

## Regenerate the sample line.points.
func regenerate_sample() -> void:
	sample_points.clear()
	for i in seg * ceil(line.points.size() / 3.0):
		var t = i / seg
		
		var point = bezier(t)
		
		if not sample_points.has(point): sample_points.append(point)
	
	regenerate_mesh()

## Regenerate the mesh.
func regenerate_mesh(from_points := sample_points, mesh_width := width) -> PackedVector2Array:
	# Store the two sides of the line seperately.
	# Set the sample mesh to the combined arrays.
	var result:PackedVector2Array
	
	if from_points.size() < 2:
		# If you try to make the mesh with not-enough points, it crashes everything.
		result = []
	else:
		result = Geometry2D.offset_polyline(from_points, mesh_width / 2, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT)[0]
	
	if from_points == sample_points:  
		if spline_collider:
			spline_collider.polygon = result
		
		sample_mesh = result
	
	return result

## -- Placeholder Functionality -- ##

# Update the positions of the drag points, and make more (or less) if necessary.
const DRAG_POINT_SCENE := preload("res://Scenes/DragPoint.tscn")
func update_drag_points() -> void:
	
	if not is_node_ready(): await ready
	
	# Shave off any extra points.
	while line.points.size() < drag_points.size():
		var back:DragPoint = drag_points.pop_back()
		if back: back.queue_free()
	
	# Add any new ones.
	while line.points.size() > drag_points.size():
		var new:DragPoint = DRAG_POINT_SCENE.instantiate()
		
		add_child(new)
		
		drag_points.append(new)
		
		new.selected.connect(selected.emit)
		holdability_changed.connect(func(to:bool): new.can_be_held = to)
		new.can_be_held = can_be_held
		
		# Wire up so that the signal for dragging is fired correctly.
		new.drag_started.connect(_drag_started)
		new.drag_ended.connect(_drag_ended)
		
		# Update the actual spline when this point moves.
		new.position_changed.connect(update_point_position.bind(drag_points.size() - 1))
	
	# Fix all the positions of the drag points.
	for i in line.points.size():
		drag_points[i].position = line.points[i]
	

func update_point_position(i:int):
	var new_line := line.points
	new_line.set(i, drag_points[i].position)
	line.points = new_line

var drag_start_points:PackedVector2Array
func _drag_started() -> void: drag_start_points = line.points
func _drag_ended() -> void:   points_changed.emit(drag_start_points, line.points)

# Adding new points between existing ones.
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if held and event is InputEventMouse: 
		held = event.button_mask
		
		if not held:
			drag_ended.emit(drag_start_pos, global_position)
	if event is InputEventMouseButton: 
		if event.is_pressed():
			start_hold()
			
			get_viewport().set_input_as_handled()
		elif held: 
			held = false
			
			drag_ended.emit(drag_start_pos, global_position)
			
			get_viewport().set_input_as_handled()

# Get a fresh instance of what this is a placeholder for.
func get_instance() -> Node:
	
	var new := Spline2D.new()
	
	for property in passover_properties:
		new.set(property, get(property))
	
	new.points = line.points
	new.width = 40.
	
	new.regenerate_sample()
	
	
	print(new, " -> ", new.points)
	
	return new
