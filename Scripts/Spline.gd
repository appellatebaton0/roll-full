@tool
class_name Spline2D extends Line2D
## Turns a Line2D into a Bezier spline.
# All I know about splines and how they work (as well as the theory behind
# my implementation) was learned from Continuity of Splines by Freya Holmér
# -> https://www.youtube.com/watch?v=jvPPXbo87ds

## Force the spline to regenerate in-editor if something's gone wrong.
@export_tool_button("Force Regenerate") var freg := func():
	regenerate_sample()
	
	print("Coll for ", self, " is ", collision_mesh)

@export var color := Color.WHITE:
	set(to):
		color = to
		
		queue_redraw()

# The actual collider for the line. The mesh is the line offset by its width.
var collision_mesh:CollisionPolygon2D
# The layer and mask for the auto-generated collider.
@export_group("Collision", "collider_")
@export_flags_2d_physics var collision_layer:int = 1
@export_flags_2d_physics var collision_mask:int = 2

## The points that make up the visible line / mesh.
## Amount depends on seg
@export_storage var sample_points:Array[Vector2]
## The current mesh based off sample_points and width.
@export_storage var sample_mesh:PackedVector2Array

## How many points to sample from each spline in the bezier.
# This is mentioned below, see the spline method, but splines are a function.
# They take in a value ranging 0.0 - 1.0, this decides the interval between
# each sample used to make the sample points, as 1. / seg. 20 -> sample at
# 0.05, 0.10, 0.15, etc.
@export_range(1, 100, 1.0) var seg := 20.0:
	set(to):
		seg = to
		
		regenerate_sample()
		queue_redraw()

# When in-editor, the Line2D is used to create the anchor points for the spline, (see spline method or video);
# This is used to still draw the final product. In-game, the Line2D becomes the final product.
func _draw() -> void: if Engine.is_editor_hint() and len(sample_mesh) > 2: draw_polygon(sample_mesh, [color])

func _ready() -> void: 
	# Make the Line2D the anchor points of the spline.
	if Engine.is_editor_hint():
		default_color = Color(0,0,0,0)
		
		regenerate_sample()
		queue_redraw()
	
	# Make the Line2D the actual spline.
	else:
		default_color = color
		modulate = Color(1.437, 1.437, 1.437)
		points = sample_points
	
	## Create the collision nodes.
	fabricate_collision()

## Update whenever anything changes.
# This only happens in-editor, which means all the processing for generating
# the splines happens before the level is loaded; this saves a HUGE amount of
# processing time. Generating 20 or so splines when a level loads is costly.
var last_points:PackedVector2Array
func _process(_delta: float) -> void: if points != last_points and Engine.is_editor_hint(): 
	
	regenerate_sample()
	
	last_points = points

## Create a bezier spline using an array of points.
# A bezier spline is a bunch of the splines mentioned in the spline method 
# with their end points (A & C in the example below) connected, to create one 
# longer spline. This turns a single T value and a list of any points into those 
# splines, and a T value within them.
# Visual Representation: https://youtu.be/jvPPXbo87ds?t=575
func bezier(t := 0.0, with := points) -> Vector2:
	
	## Create all the segments (cut the points into sets of 4 to become splines)
	# [A, B, C, D, E, F, G] -> [[A,B,C,D], [D,E,F,G]]; share end points.
	var segments:Array[Array]
	for i in with.size():
		
		if i % 3 == 0:
			var segment:Array[Vector2]
			for j in 4:
				if with.size() > i+j:
					segment.append(with[i + j])
			segments.append(segment)
	
	## Since T is 0.0 - 1.0, the decimal can be used as the spline's T value,
	## and the 1s place is the index in the splines created.
	return spline(t - floor(t), segments[floor(t)])

## Create a basic spline using an array of points.
# This is a function of T, so it returns a single point for a
# given T value, 0 through 1. The way this kind of spline works is effectively
# a recursive lerp of all the points.
# 
# 1.
#    A    B                           
#             -> Lerp [t] amount between A&B, B&D, D&C to get E,F,G
#    C    D
#
# 2.
#    A  E B
#         F   -> Lerp [t] amount between E&F, F&G to get H,I
#    C  G D
#
# 3. (I had to expand the diagram for more precision lol).
#    A    E    B
#           H
#              F   -> Lerp [t] amount between H&I to get the final point.
#           I  
#    C    G   D
# 
# This happens for every value of T to create a final spline, where A and C
# are the end points, and the curve is influenced by B & D. The spline function
# does this all recursively by itself, and can handle any number of points; I just chose 4.
# Visual Representation -> https://youtu.be/jvPPXbo87ds?t=140
func spline(t := 0.0, with := points) -> Vector2:
	
	#print(with)
	match len(with):
		0: return Vector2.ZERO
		1: return with[0]
		2: return lerp(with[0], with[1], t)
		_: 
			@warning_ignore("integer_division")
			var left = with.slice(0, len(with) / 2)
			@warning_ignore("integer_division")
			var right = with.slice(len(with)/2, len(with))
			
			
			var left_spline  = spline(t, left)
			var right_spline = spline(t, right)
			
			return lerp(left_spline, right_spline, t)

## Regenerate the sample points.
# For context:
# Splines are sort of just mathmatically recursive lerping,
# so to turn that into an array of points, they have to be sampled
# from. Ex: y=x is a function of x, not an array of points, but if you
# sample from it to get, say, [(0,0), (1,1)] that is. That's what this is doing.
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
		# offset_polyline extends a line out into a mesh. I was doing this manually before this,
		# and that method was super cool, but this is just cleaner and safer.
		sample_mesh = remove_duplicates(Geometry2D.offset_polyline(sample_points, width / 2, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT)[0])
	
	# Set the collider's mesh to this newly generated one.
	if collision_mesh:  collision_mesh.polygon = sample_mesh
	
	return sample_mesh

## Returns the PackedVector2Array with any identical points cut out.
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
