@tool
class_name GearPolygon extends Polygon2D
## Generates a gear polygon of any size and teeth density.

@export_tool_button("Regenerate") var regen_button := generate

@export_group("Outer", "outer_")
## The number of points on this polygon.
@export_range(3,500,1.0) var vertices := 9:
	set(to):
		vertices = to
		generate()

@export var radius := 200.0: ## The radius of this gear.
	set(to):
		radius = to
		generate()
@export var tooth_length := 50.0:
	set(to):
		tooth_length = to
		generate()
@export var tooth_angle := 3.0:
	set(to):
		tooth_angle = to
		generate()

@export var inner_radius := 90.0: ## The radius of this gear.
	set(to):
		inner_radius = to
		generate()

func _ready() -> void: generate()

func generate():
	
	if inner_radius > radius:
		inner_radius = radius
	
	var new_points:Array[Vector2]
	
	if inner_radius <= 0:
		new_points = make_points(radius)
	else:
		var outer_points:Array[Vector2] = make_points(radius)
		var inner_points:Array[Vector2] = make_points(inner_radius, false)
		
		outer_points.append(outer_points.front())
		inner_points.append(inner_points.front())
		
		inner_points.reverse()
		
		new_points = outer_points + inner_points
		
	
	set("polygon", new_points)

func make_points(point_radius:float, toothed := true) -> Array[Vector2]:
	var points:Array[Vector2]
	
	for i in range(vertices * 2):
		var angle := deg_to_rad((180.0 / vertices) * i)
		
		var new_point_a := Vector2.from_angle(angle) * point_radius
		if toothed:
			var new_point_b := Vector2.from_angle(angle + deg_to_rad(tooth_angle * (1 if i % 2 else -1))) * (point_radius + tooth_length)
			
			if i % 2:
				points.append(new_point_a)
				points.append(new_point_b)
			else:
				points.append(new_point_b)
				points.append(new_point_a)
		else: points.append(new_point_a)
	
	return points
