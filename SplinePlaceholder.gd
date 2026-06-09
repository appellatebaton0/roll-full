class_name SplinePlaceholder extends ScenePlaceholder
## A placeholder for a spline, with all the usual customizability.

@onready var line:Line2D = $Line2D
@onready var drag_area_collider := $DragArea/CollisionShape2D

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
var sample_mesh:Array[Vector2]

var seg := 20.0:
	set(to):
		seg = to
		
		regenerate_sample()
		queue_redraw()

func _draw() -> void: if len(sample_mesh) > 2: draw_polygon(sample_mesh, [color])

func _ready() -> void: 
	super._ready()
	
	line.default_color = Color(0.17, 0.17, 0.17)
	
	regenerate_sample()
	queue_redraw()

## Update whenever anything changes.
var last_points:PackedVector2Array
func _process(_delta: float) -> void: 
	
	super._process(_delta)
	
	if line.points != last_points:
		
		print("!?")
		
		regenerate_sample()
		
		update_drag_points()
		
		last_points = line.points
		
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
func regenerate_mesh() -> Array[Vector2]:
	# Store the two sides of the line seperately.
	var a:Array[Vector2]
	var b:Array[Vector2]
	
	for i in len(sample_points):
		
		var point = sample_points[i]
		
		# Get the two line.points surrounding this one, and get the direction between them.
		
		var dir_a = sample_points[max(i - 1, 0)]
		var dir_b = sample_points[min(i + 1, len(sample_points) - 1)]
		
		var dir = dir_a.direction_to(dir_b)
	
		# Note that these numbers are usually divided by 2. Doubled for easier selection.
		a.append(point + Vector2(-dir.y, dir.x) * line.width)
		b.append(point + Vector2(dir.y, -dir.x) * line.width)
	
	# Reverse one side so they'll be continous.
	b.reverse()
	
	# Set the sample mesh to the combined arrays.
	sample_mesh = a + b
	
	drag_area_collider.polygon = sample_mesh
	
	return sample_mesh

## -- Placeholder Functionality -- ##

# Update the positions of the drag points, and make more (or less) if necessary.
const DRAG_POINT_SCENE := preload("res://DragPoint.tscn")
func update_drag_points() -> void:
	
	# Shave off any extra points.
	print(line.points.size(), " v ", drag_points.size())
	while line.points.size() < drag_points.size():
		var back:DragPoint = drag_points.pop_back()
		if back: queue_free()
	
	# Add any new ones.
	while line.points.size() > drag_points.size():
		var new:DragPoint = DRAG_POINT_SCENE.instantiate()
		
		add_child(new)
		
		drag_points.append(new)
		
		new.position_changed.connect(update_point_position.bind(drag_points.size() - 1))
	
	# Fix all the positions of the drag points.
	for i in line.points.size():
		drag_points[i].position = line.points[i]

func update_point_position(i:int):
	line.points[i] = drag_points[i].position

# Adding new points between existing ones.
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	
	if event is InputEventMouseButton: if event.double_click:
		print("!!")
		print("add a point between the two closest ones?")
		
	print("?")
	super._input_event(_viewport, event, _shape_idx)
	
	
