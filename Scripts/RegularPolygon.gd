@tool 
class_name RegularPolygon extends Polygon2D
## Provides tools for making a regular polygon, with several available modifications

@export_tool_button("Regenerate") var regen_button := generate

@export_group("Outer", "outer_")
## The number of points on this polygon.
@export_range(3,500,1.0) var outer_vertices := 3:
	set(to):
		outer_vertices = to
		generate()

@export var outer_radius := 0.0: ## The outer radius of this polygon.
	set(to):
		outer_radius = to
		generate()
@export var outer_radius_modifiers:Dictionary[int, float]: ## Any modifiers to the radius. Formatted as [every n points], [radius modification]
	set(to):
		outer_radius_modifiers = to
		generate()

@export_group("Inner", "inner_")
## The number of points on this polygon.
@export_range(3,500,1.0) var inner_vertices := 3:
	set(to):
		inner_vertices = to
		generate()

@export var inner_radius := 0.0: ## The inner radius of this polygon. If <=0, is not hollow.
	set(to):
		inner_radius = to
		generate()
@export var inner_radius_modifiers:Dictionary[int, float]: ## Any modifiers to the radius. Formatted as [every n points], [radius modification]
	set(to):
		inner_radius_modifiers = to
		generate()

func generate():
	
	# The inner radius has to be (0 <= inner radius < outer_radius)
	if inner_radius < 0 or inner_radius >= outer_radius: return
	
	var new_points:Array[Vector2]
	
	if inner_radius <= 0: 
		# No inner polygon, just make the new points the outer points.
		new_points = make_points_for(outer_radius, outer_vertices, outer_radius_modifiers)
	else:
		var outer_points:Array[Vector2] = make_points_for(outer_radius, outer_vertices, outer_radius_modifiers)
		var inner_points:Array[Vector2] = make_points_for(inner_radius, inner_vertices, inner_radius_modifiers)
		
		# Put each array's first array at the end as well. [0,1,2] -> [0,1,2,0]
		outer_points.append(outer_points.front())
		inner_points.append(inner_points.front())
		
		inner_points.reverse()
		
		# The new polygon is just the two arrays added together
		new_points = outer_points + inner_points
	
	# Update the polygon.
	set("polygon", new_points)

func make_points_for(radius:float, vertices:int, modifiers:Dictionary[int, float]) -> Array[Vector2]:
	var points:Array[Vector2]
	
	# For each vertice.
	for i in vertices:
			# Get the angle of this point
			var angle := deg_to_rad((360.0 / vertices) * i)
			
			# Stored in a seperate variable so the modifiers don't affect the radius.
			var distance := radius
			
			# Apply Modulo Modifiers.
			for modifier in modifiers:              # Check for each modifier,
				if i % modifier == 0:               # If the remainder is 0,
					distance += modifiers[modifier] # Apply the modifier.
			
			# Create the point and add it to the new array.
			var new_point := Vector2.from_angle(angle) * distance
			points.append(new_point)
	
	return points
