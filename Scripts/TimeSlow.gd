@tool
class_name TimeSlow extends Node2D
## Slows time the closer the player is to the node.

enum SHAPE{CIRCLE, RECTANGLE}
@export var show_overlay := true:
	set(to):
		show_overlay = to
		queue_redraw()
@export var shape := SHAPE.CIRCLE:
	set(to):
		shape = to
		queue_redraw()

@export var dimensions := Vector2(50., 50.):
	set(to):
		dimensions = to
		queue_redraw()
		max_dim = max(dimensions.x, dimensions.y)
@export_storage var max_dim:float
@export var radius := 100.0:
	set(to):
		radius = to
		queue_redraw()
@export var easing := -2.0:
	set(to):
		easing = to
		queue_redraw()

@export var min_scale := 0.1:
	set(to):
		min_scale = to
		queue_redraw()

@export var input_disable := ""
enum TYPE {NONE, ON_WALL, MIDAIR, HAS_DASHED}
@export var type_disable := TYPE.NONE

var dist:float:
	set(to):
		
		## Player left the range.
		if to == -1. and dist != -1.:
			Engine.time_scale = Global.default_time_scale
		
		dist = to

@onready var player:Player = get_tree().get_first_node_in_group("Player")

func _ready() -> void: Global.request_animation.connect(finish)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var was_slowing = false
var disable_toggle = false
func _process(_delta: float) -> void: 
	if not Engine.is_editor_hint():
		dist = get_slow()
		
		if dist != -1. and not disable_toggle:
			Engine.time_scale = get_scale_for_dist(dist)
			was_slowing = true
			
			var input := Input.is_action_pressed(input_disable) if InputMap.has_action(input_disable) else false
			if input or should_disable():
				disable_toggle = true
		elif was_slowing:
			# Reset the time_scale back to normal
			Engine.time_scale = Global.default_time_scale
			was_slowing = false
		
		if dist == -1.:
			disable_toggle = false

func should_disable() -> bool:
	match type_disable:
		TYPE.ON_WALL:    return player.is_on_wall()
		TYPE.MIDAIR:     return not player.is_on_wall()
		TYPE.HAS_DASHED: return player.dash_cooldown_time > 0
		_:               return false

func get_slow(a := global_position, b := player.global_position if player else global_position) -> float:
	
	var multiplier := Global.default_time_scale if not Engine.is_editor_hint() else 1.0
	var distance:float
	match shape:
		SHAPE.CIRCLE:
			
			distance = a.distance_to(b)
			
			if distance < radius:
				return multiplier * lerp(min_scale, 1.0, ease(clamp(distance / radius, 0.0, 1.0), easing))
		SHAPE.RECTANGLE:
			
			# The distance between the two points
			var vector_distance = abs(a - b)
			
			# That distance's distance to the rectangle's edges.
			distance = max(vector_distance.x - dimensions.x, vector_distance.y - dimensions.y)
			
			# If the distance is within the dimensions, return it. Spaghetti here.
			if distance < 0:
				distance = (1. - abs(distance / max_dim))# / 1.5
				return multiplier * lerp(min_scale, 1.0, ease(clamp(distance, 0.0, 1.0), easing))
	
	return -1.

func _draw() -> void: if Engine.is_editor_hint() and show_overlay:
	
	var spacing := 20.0
	var size:Vector2
	match shape:
		SHAPE.CIRCLE: size = Vector2.ONE * 2 * radius / spacing
		SHAPE.RECTANGLE: size = dimensions
	
	for i in size.x:
		for j in size.y:
			var point := Vector2(i - (size.x / 2.),j - (size.y / 2.)) * spacing
			var slow :=  get_slow(Vector2.ZERO, point)
			
			## Outside bounds / invalid, don't draw.
			if slow == -1.: continue
			
			# Draw a single pixel in the overlay.
			draw_rect(Rect2(point, Vector2.ONE * spacing), Color(1, 0.0, 0.0, 1. - slow))
	
	## Draw the outlines for the shapes.
	match shape:
		SHAPE.CIRCLE:    draw_circle(Vector2.ZERO, radius, Color(1.0, 0.0, 0.0, 0.5), false, 7.0)
		SHAPE.RECTANGLE: draw_rect(Rect2(-dimensions, dimensions * 2), Color(1.0, 0.0, 0.0, 0.5), false, 7.0)

func get_scale_for_dist(distance:float) -> float:
	return lerp(min_scale, 1.0, ease(clamp(distance / radius, 0.0, 1.0), easing))

func finish(anim_name:String) -> void: if anim_name == "Game->Levels":
	Engine.time_scale = Global.default_time_scale
	queue_free()
