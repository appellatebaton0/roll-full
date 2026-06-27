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

@export var item_seperation := 60.0:
	set(to):
		item_seperation = to
		queue_sort()


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		# Must re-sort the children
		# See Godot's page on making custom containers.
		
		var children := get_children().filter(func(a): return a.visible)
		#var summative_offset := 0.
		for i in len(children):
			
			var child:Control = children[i]
			
			var midpoint:float = (size.y / 2.)
			var offset := i * item_seperation
			
			# Get the new size and position.
			#var new_size = Vector2(size.x, (size.y / len(children) - seperation))
			var new_pos  = Vector2(0, midpoint + offset + scroll_offset)#+(i * size.y / len(children)) + seperation/2. + scroll_offset)
			
			#print(children.size() - i)
			var j := floori(size.y / 2 / item_seperation) + 1
			var wrap_point := midpoint + (children.size() - j) * item_seperation
			# Wrap the Y.
			new_pos.y = wrap(new_pos.y, midpoint - (j * item_seperation), wrap_point)#midpoint - ((children.size() - i) * item_seperation)
			# Apply the distance according to the curve.
			new_pos.x = distance_curve.sample(wrap((new_pos.y) / size.y,0.0, 1.0))
			

			# Apply the scaling according to the curve
			var new_scale := Vector2.ONE * scale_curve.sample(wrap((new_pos.y) / size.y,0.0, 1.0))
			
			new_pos.y -= ((child.size.y * child.scale.y) / 2.)
			
			# Resort the child.
			fit_child_in_rect(child, Rect2(new_pos, child.size))
			child.scale = new_scale
			#summative_offset += ((size.y + 200) / children.size()) + item_seperation
