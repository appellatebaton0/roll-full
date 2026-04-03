@tool
class_name AnimatedPolygon extends RegularPolygon
## A regular polygon with extra settings for animation.

@export_group("Outer Animation", "outer_")
## Apply +- modifiers to every nth point.
@export var outer_wave_amounts:Dictionary[int, float]
## Cycle between the + and - of the corresponding oscillation amount every n seconds.
@export var outer_wave_intervals:Dictionary[int, float]
## Rotate n degrees per second.
@export var outer_rotation := 0.
var current_outer_rotation := 0.

@export_group("Inner Animation", "inner_")
## Apply +- modifiers to every nth point.
@export var inner_wave_amounts:Dictionary[int, float]
## Cycle between the + and - of the corresponding oscillation amount every n seconds.
@export var inner_wave_intervals:Dictionary[int, float]
## Rotate n degrees per second.
@export var inner_rotation := 0.
var current_inner_rotation := 0.

## The timers for every existing wave animation. Formatted as interval:time
var animation_timers:Dictionary[float, float]

func _process(delta: float) -> void:
	for key in animation_timers:
		animation_timers[key] = move_toward(animation_timers[key], key, delta)
		
		if animation_timers[key] >= key:
			animation_timers[key] = 0.0
	
	current_inner_rotation += inner_rotation * delta
	current_outer_rotation += outer_rotation * delta
	
	generate()

func generate():
	
	if inner_radius > outer_radius:
		inner_radius = outer_radius
	
	var new_points:Array[Vector2]
	
	if inner_radius <= 0:
		new_points = make_animated_points_for(outer_radius, outer_vertices, outer_radius_modifiers, outer_wave_amounts, outer_wave_intervals, current_outer_rotation)
	else:
		var outer_points:Array[Vector2] = make_animated_points_for(outer_radius, outer_vertices, outer_radius_modifiers, outer_wave_amounts, outer_wave_intervals, current_outer_rotation)
		var inner_points:Array[Vector2] = make_animated_points_for(inner_radius, inner_vertices, inner_radius_modifiers, inner_wave_amounts, inner_wave_intervals, current_inner_rotation)
		
		outer_points.append(outer_points.front())
		
		## Find the best inner point to use as a connection to the outer layer.
		var best_inner_point := Vector2.INF
		for point in inner_points:
			if best_inner_point == Vector2.INF:
				best_inner_point = point
				continue
			
			if point.distance_to(outer_points.front()) < best_inner_point.distance_to(outer_points.front()):
				best_inner_point = point
		
		## Cycle the inner points until it's the first element
		while inner_points.front() != best_inner_point:
			inner_points.push_front(inner_points.pop_back())
		
		## Add it to the back, reverse the array, and tack it onto the outer points.
		inner_points.append(inner_points.front())
		
		inner_points.reverse()
		
		new_points = outer_points + inner_points
		
	
	set("polygon", new_points)
	
	regenerated.emit()

func make_animated_points_for(radius:float, vertices:int, modifiers:Dictionary[int, float], wave_amounts:Dictionary[int, float], wave_intervals:Dictionary[int, float], added_rotation:float) -> Array[Vector2]:
	var points:Array[Vector2]
	
	for i in range(vertices):
			var angle := deg_to_rad((360.0 / vertices) * i + added_rotation)
			
			var distance := radius
			
			for modifier in modifiers:
				if i % modifier == 0:
					distance += modifiers[modifier]
			
			for modifier in wave_amounts:
				if i % modifier == 0:
					distance += get_modifier(wave_amounts, wave_intervals, modifier)
			
			var new_point := Vector2.from_angle(angle) * distance
			points.append(new_point)
	
	return points

func get_modifier(amounts:Dictionary[int, float], intervals:Dictionary[int, float], key:int) -> float:
	
	var safe_interval := intervals[key] if intervals.has(key) else 1.0
	
	if not animation_timers.has(safe_interval):
		animation_timers[safe_interval] = 0.0
	
	#print(round(animation_timers[safe_interval] * 10) / 10, ": ", round(bounce(animation_timers[safe_interval], safe_interval) * 10) / 10)
	return lerp(-amounts[key], amounts[key], bounce(animation_timers[safe_interval], safe_interval))

func bounce(value:float, interval:float) -> float:
	return (- ((2 * abs(value - (interval / 2))) / interval)) + 1.
