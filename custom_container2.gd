@tool
extends Container

@export_range(-720, 720, 1.0, "hide_control") var add_angle := 0.:
	set(to):
		add_angle = to
		queue_sort()

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		# Must re-sort the children
		var children := get_children()
		for i in len(children):
			var child:Control = children[i]
			
			var angle = deg_to_rad(360. / len(children) * i + add_angle)
			
			fit_child_in_rect(child, Rect2(Vector2.ONE.rotated(angle) * 100, Vector2(0,0)))
			child.rotation = Vector2.ONE.rotated(angle).direction_to(Vector2.ZERO).angle()
