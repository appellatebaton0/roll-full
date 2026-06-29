@tool
class_name Spline2D extends Line2D

@export_tool_button("Force Regenerate") var freg := func():
	regenerate_sample()
	
	print("Coll for ", self, " is ", collision_mesh)

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
@export_storage var sample_points:Array[Vector2]
## The current mesh based off sample_points and width.
@export_storage var sample_mesh:PackedVector2Array

@export_range(1, 100, 1.0) var seg := 20.0:
	set(to):
		seg = to
		
		regenerate_sample()
		queue_redraw()

func _draw() -> void: if Engine.is_editor_hint() and len(sample_mesh) > 2: draw_polygon(sample_mesh, [color])

func _ready() -> void: 
	if Engine.is_editor_hint():
		default_color = Color(0,0,0,0)
		
		regenerate_sample()
		queue_redraw()
	
	if not Engine.is_editor_hint():
		default_color = color
		modulate = Color(1.437, 1.437, 1.437)
		points = sample_points
	
	## Create the collision nodes.
	fabricate_collision()

## Update whenever anything changes.
var last_points:PackedVector2Array
func _process(_delta: float) -> void: if points != last_points and Engine.is_editor_hint(): 
		
	regenerate_sample()
	
	last_points = points

## Create a bezier spline using an array of points.
func bezier(t := 0.0, with := points) -> Vector2:
	
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
	for i in seg * ceil(points.size() / 3.0):
		var t = i / seg
		
		var point = bezier(t)
		
		if not sample_points.has(point): sample_points.append(point)
	
	regenerate_mesh()

## Regenerate the mesh.
func regenerate_mesh() -> PackedVector2Array:
	
	# Set the sample mesh to the combined arrays.
	if sample_points.size() < 2:
		# If you try to make the mesh with not-enough points, it crashes everything.
		sample_mesh = []
	else:
		sample_mesh = remove_duplicates(Geometry2D.offset_polyline(sample_points, width / 2, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT)[0])
	
	if collision_mesh:  collision_mesh.polygon = sample_mesh
	
	return sample_mesh

func remove_duplicates(array:PackedVector2Array) -> PackedVector2Array:
	var dict:Dictionary[Vector2, bool]
	for item in array: dict[item] = false
	return PackedVector2Array(dict.keys())

func fabricate_collision() -> void:
	# First, look for any already existing ones.
	for child in get_children(): if child is StaticBody2D:
		for grand in child.get_children(): if grand is CollisionPolygon2D:
			if collision_mesh:
				grand.queue_free()
			else:
				collision_mesh = grand
	
	for child in get_children(): if child is StaticBody2D:
		if collision_mesh.get_parent() != child:
			child.queue_free()
	
	if collision_mesh: 
		
		collision_mesh.owner = owner
		collision_mesh.get_parent().owner = owner
		
		collision_mesh.name = "CM"
		collision_mesh.get_parent().name = "SB"
		
		
		
		return
	
	var static_body := StaticBody2D.new()
	collision_mesh = CollisionPolygon2D.new()

	add_child(static_body)
	static_body.add_child(collision_mesh)
	
	static_body.owner = owner
	collision_mesh.owner = owner

	static_body.collision_layer = collision_layer
	static_body.collision_mask  = collision_mask
	
	collision_mesh.modulate.a = 0.2

	regenerate_mesh()
	
	#print("F: ", collision_mesh.polygon)
	#print("T: ", Geometry2D.offset_polyline(points, width / 2, Geometry2D.JOIN_ROUND, Geometry2D.END_SQUARE))
	#collision_mesh.polygon = Geometry2D.offset_polyline(points, width / 2, Geometry2D.JOIN_ROUND, Geometry2D.END_SQUARE)
