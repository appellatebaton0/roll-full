@tool
class_name Spline2D extends Line2D

@export var color := Color.WHITE:
	set(to):
		color = to
		
		queue_redraw()

var collision_mesh:CollisionPolygon2D
@export_group("Collision", "collider_")
@export_flags_2d_physics var collision_layer:int = 1
@export_flags_2d_physics var collision_mask:int = 2

## The points that make up the visible line / mesh.
## Amount depends on seg
var sample_points:Array[Vector2]
## The current mesh based off sample_points and width.
var sample_mesh:Array[Vector2]

@export_range(1, 100, 1.0) var seg := 20.0:
	set(to):
		seg = to
		
		regenerate_sample()
		queue_redraw()
		generate()

#@export_tool_button("GenerateShape") var gen := generate
func generate(): if collision_mesh: collision_mesh.polygon = regenerate_mesh()

func _draw() -> void: if Engine.is_editor_hint(): draw_polygon(sample_mesh, [color])

func _ready() -> void: 
	default_color = Color(0,0,0,0)
	
	regenerate_sample()
	queue_redraw()
	
	
	if not Engine.is_editor_hint():
		default_color = color
		points = sample_points
		
		## Create the collision nodes.
		fabricate_collision()

## Update whenever anything changes.
var last_points
func _process(_delta: float) -> void: if points != last_points: 
		
	regenerate_sample()
	queue_redraw()
	generate()
	
	last_points = points

## Create a bezier spline using an array of points.
func bezier(t := 0.0, with := points) -> Vector2:
	
	## Create all the segments
	var segments:Array[Array]
	for i in range(len(with)):
		
		if i % 3 == 0:
			var segment:Array[Vector2]
			for j in range(4):
				if len(with) > i+j:
					segment.append(with[i + j])
			segments.append(segment)
	
	
	return spline(t - floor(t), segments[floor(t)])

## Create a basic spline using an array of points.
func spline(t := 0.0, with := points) -> Vector2:
	
	#print(with)
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

## Regenerate the sample points.
func regenerate_sample() -> void:
	sample_points.clear()
	for i in range(seg * ceil(len(points) / 3.0)):
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
		
		# Get the 2 points surrounding this one, and get the direction between them.
		
		var dir_a = sample_points[max(i - 1, 0)]
		var dir_b = sample_points[min(i + 1, len(sample_points) - 1)]
		
		var dir = dir_a.direction_to(dir_b)
		
		# Place the mesh points at (width/2) distance from this 
		# point, perpendicular to the above direction.
	#
		a.append(point + Vector2(-dir.y, dir.x) * width / 2)
		b.append(point + Vector2(dir.y, -dir.x) * width / 2)
	
	# Reverse one side so they'll be continous.
	b.reverse()
	
	sample_mesh = a + b
	return sample_mesh

func fabricate_collision() -> void:
	var static_body := StaticBody2D.new()
	collision_mesh = CollisionPolygon2D.new()
	
	add_child(static_body)
	static_body.add_child(collision_mesh)
	
	static_body.collision_layer = collision_layer
	static_body.collision_mask  = collision_mask
	
	generate()
