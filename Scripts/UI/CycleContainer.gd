@tool
class_name CycleContainer extends Container

@export var seperation := 0:
	set(to):
		seperation = to
		queue_sort()

@export var distance_curve:Curve:
	set(to):
		distance_curve = to
		queue_sort()

@export var scale_curve:Curve:
	set(to):
		scale_curve = to
		queue_sort()

@export var scroll_offset := 0.0:
	set(to):
		scroll_offset = to
		queue_sort()

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		# Must re-sort the children
		# See Godot's page on making custom containers.
		
		var children := get_children()
		for i in len(children):
			var child:Control = children[i]
			
			# Get the new size and position.
			var new_size = Vector2(size.x, (size.y / len(children) - seperation))
			var new_pos  = Vector2(0, (i * size.y / len(children)) + seperation/2. + scroll_offset)
			
			# Apply the distance according to the curve.
			new_pos.x = distance_curve.sample(wrap((new_pos.y + (new_size.y / 2)) / size.y,0.0, 1.0))
			# Wrap the Y.
			new_pos.y = wrap(new_pos.y, 0.0, size.y)
			
			# Resort the child.
			fit_child_in_rect(child, Rect2(new_pos, new_size))
			
			# Apply the scaling according to the curve
			child.scale = Vector2.ONE * scale_curve.sample(wrap((new_pos.y + (new_size.y / 2)) / size.y,0.0, 1.0))
