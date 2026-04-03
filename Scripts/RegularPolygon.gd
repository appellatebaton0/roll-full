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
	
	if inner_radius > outer_radius:
		inner_radius = outer_radius
	
	var new_points:Array[Vector2]
	
	if inner_radius <= 0:
		new_points = make_points_for(outer_radius, outer_vertices, outer_radius_modifiers)
	else:
		var outer_points:Array[Vector2] = make_points_for(outer_radius, outer_vertices, outer_radius_modifiers)
		var inner_points:Array[Vector2] = make_points_for(inner_radius, inner_vertices, inner_radius_modifiers)
		
		outer_points.append(outer_points.front())
		inner_points.append(inner_points.front())
		
		inner_points.reverse()
		
		new_points = outer_points + inner_points
		
	
	set("polygon", new_points)

func make_points_for(radius:float, vertices:int, modifiers:Dictionary[int, float]) -> Array[Vector2]:
	var points:Array[Vector2]
	
	for i in range(vertices):
			var angle := deg_to_rad((360.0 / vertices) * i)
			
			var distance := radius
			
			for modifier in modifiers:
				if i % modifier == 0:
					distance += modifiers[modifier]
			
			var new_point := Vector2.from_angle(angle) * distance
			points.append(new_point)
	
	return points
