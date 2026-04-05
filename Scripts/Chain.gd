@tool
class_name ChainBit extends Line2D
## Creates an inverse-kinematics chain.

var collision_mesh:CollisionPolygon2D
@export_tool_button("Regenerate Mesh") var regmes_button := regenerate_mesh
@export_group("Collision", "collider_")
@export_flags_2d_physics var collision_layer:int = 1
@export_flags_2d_physics var collision_mask:int = 2

@export var segment_spacing := 50.
@export var change_depth := -1

func _ready() -> void: if not Engine.is_editor_hint(): fabricate_collision()

@export_storage var last_position:Vector2
@export_storage var last_points:PackedVector2Array
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if global_position != last_position:
		# Update the IVK chain...
		update_chain(0, 0, change_depth)
		
		last_position = global_position
	
	elif points != last_points:
		
		if len(last_points) < len(points):
			last_points = points.duplicate()
		
		var changed_point:int
		for i in range(len(points)):
			if points[i] != last_points[i]:
				changed_point = i
				break
		
		## Update from the changed point outwards.
		update_chain(changed_point, 0, change_depth)
		
		last_points = points
		

func update_chain(from := 0, dir := 1, depth := 6, last:Vector2 = Vector2.INF):
	
	if depth == 0: return
	
	# Stop if outside the bounds of the array.
	if from < 0 or from >= len(points): return
	
	var point := points[from]
	# IF there is a last point, update the wuh
	if last != Vector2.INF:
		
		# Shift it to keep global position.
		point -= global_position - last_position
		
		# Get the distance from the last point to this one.
		var distance = point - last
		
		if distance == Vector2.ZERO: distance = Vector2.DOWN
		
		# Normalize that to the distance of the segment spacing.
		distance = distance.normalized() * segment_spacing
		
		# Make that distance the new distance.
		point = last + distance
		
		set_point_position(from, point)
	
	match dir:
		0:
			update_chain(from + 1,  1, depth - 1, point)
			update_chain(from - 1, -1, depth - 1, point)
		_:
			update_chain(from + dir, dir, depth - 1, point)

func regenerate_mesh(): if collision_mesh:
	# Store the two sides of the line seperately.
	var a:Array[Vector2]
	var b:Array[Vector2]
	
	for i in len(points):
		
		var point = points[i]
		
		# Get the 2 points surrounding this one, and get the direction between them.
		
		var dir_a = points[max(i - 1, 0)]
		var dir_b = points[min(i + 1, len(points) - 1)]
		
		var dir = dir_a.direction_to(dir_b)
		
		# Place the mesh points at (width/2) distance from this 
		# point, perpendicular to the above direction.
	#
		a.append(point + Vector2(-dir.y, dir.x) * width / 2)
		b.append(point + Vector2(dir.y, -dir.x) * width / 2)
	
	# Reverse one side so they'll be continous.
	b.reverse()
	
	if Engine.is_editor_hint():
		var unre = EditorInterface.get_editor_undo_redo()
		unre.create_action("Update Collision Polygon")
		
		unre.add_do_property(collision_mesh, "polygon", a + b)
		unre.add_undo_property(collision_mesh, "polygon", collision_mesh.polygon)
		
		unre.commit_action()
	else: collision_mesh.polygon = a + b

func fabricate_collision() -> void:
	var static_body := StaticBody2D.new()
	collision_mesh = CollisionPolygon2D.new()
	
	add_child(static_body)
	static_body.add_child(collision_mesh)
	
	static_body.collision_layer = collision_layer
	static_body.collision_mask  = collision_mask
	
	regenerate_mesh()
