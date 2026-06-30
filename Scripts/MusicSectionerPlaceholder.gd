class_name MusicSectionerPlaceholder extends ScenePlaceholder
## A placeholder for a MusicSectioner, complete w/ display and point moving.

signal points_changed(from:PackedVector2Array, to:PackedVector2Array)


const SECTOR_SIZE := 50

@onready var line:Line2D = $Line2D
@onready var cam:Camera2D:
	get():
		if not cam:
			cam = get_viewport().get_camera_2d()
		return cam

@export_storage var initial_points:PackedVector2Array # A copy of line.points for initial setting when this gets packed.

@export var shader_mat:ShaderMaterial # The material for the shader used to render sectors.
@export var shader_rect:ColorRect # The control used to render the shader.

# The array of drag points. Index in this array = index of the point in the line's point array.
var drag_points:Array[DragPoint]

var color := Color.WHITE:
	set(to):
		color = to
		
		_update_shader()

## The line.points that make up the visible line / mesh.
## Amount depends on seg
var sample_points:Array[Vector2]
## The current mesh based off sample_points and the line width.
var sample_mesh:PackedVector2Array

@export var width := 40.0

func _set_holdability(to) -> void:
	can_be_held = to
	for point in drag_points:
		point.can_be_held = to
		point.visible = to
	holdability_changed.emit(to)
	shader_rect.visible = to;

func _ready() -> void: 
	super._ready()
	
	_set_holdability(can_be_held)
	
	line.points = initial_points if initial_points else line.points
	
	_update_shader()

## Update whenever anything changes.
var last_points:PackedVector2Array
var last_cam_pos:Vector2
func _process(_delta: float) -> void: 
	
	super._process(_delta)
	
	line.width = 15. / get_viewport().get_camera_2d().zoom.x
	
	if line.points != last_points:
		update_drag_points()
		
		last_points = line.points
		
		last_points = line.points
		initial_points = last_points
		
		_update_shader()
	if cam.global_position != last_cam_pos:
		last_cam_pos = cam.global_position
		
		_update_shader()

## Update the pointset passed to the shader for drawing sectors.
func _update_shader() -> void:
	
	
	var cam_rect := Rect2(cam.global_position, get_viewport_rect().size / cam.zoom)
	var pass_points:Array[Vector2]
	pass_points.assign(Array(line.points.duplicate())) 
	
	for i in pass_points.size():
		# Start by making the points relative to the camera's top left corner.
		pass_points[i] = pass_points[i] - cam_rect.position + (cam_rect.size / 2.)
		
		# Convert to linear (?) space; top left of screen is 0,0, bottom right is 1,1.
		pass_points[i] = pass_points[i] / cam_rect.size
	
	# Fit the shader to the viewport (w/o a separate CanvasLayer so it's still under the DeathBorder.
	shader_rect.position = cam_rect.position - (cam_rect.size / 2.)
	shader_rect.size = cam_rect.size
	
	shader_mat.set_shader_parameter("points", pass_points)

func closest_point(against:Vector2) -> int:
	
	var best := -1
	var best_dist := INF
	
	for i in line.points.size():
		var dist := (line.points[i] + global_position).distance_to(against)
		
		if dist < best_dist:
			best = i
			best_dist = dist
	
	return best

## -- Placeholder Functionality -- ##

# Update the positions of the drag points, and make more (or less) if necessary.
const DRAG_POINT_SCENE := preload("res://Scenes/DragPoint.tscn")
func update_drag_points() -> void:
	
	if not is_node_ready(): await ready
	
	# Shave off any extra points.
	while line.points.size() < drag_points.size():
		var back:DragPoint = drag_points.pop_back()
		if back: back.queue_free()
	
	# Add any new ones.
	while line.points.size() > drag_points.size():
		var new:DragPoint = DRAG_POINT_SCENE.instantiate()
		
		add_child(new)
		
		drag_points.append(new)
		
		new.selected.connect(selected.emit)
		holdability_changed.connect(func(to:bool): new.can_be_held = to)
		new.can_be_held = can_be_held
		
		# Wire up so that the signal for dragging is fired correctly.
		new.drag_started.connect(_drag_started)
		new.drag_ended.connect(_drag_ended)
		
		# Update the actual spline when this point moves.
		new.position_changed.connect(update_point_position.bind(drag_points.size() - 1))
	
	# Fix all the positions of the drag points.
	for i in line.points.size():
		drag_points[i].position = line.points[i]

func update_point_position(i:int):
	var new_line := line.points
	new_line.set(i, drag_points[i].position)
	line.points = new_line

var drag_start_points:PackedVector2Array
func _drag_started() -> void: drag_start_points = line.points
func _drag_ended() -> void:   points_changed.emit(drag_start_points, line.points)

# Adding new points between existing ones.
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if held and event is InputEventMouse: 
		held = event.button_mask
		
		if not held:
			drag_ended.emit(drag_start_pos, global_position)
	if event is InputEventMouseButton: 
		if event.is_pressed():
			start_hold()
			
			get_viewport().set_input_as_handled()
		elif held: 
			held = false
			
			drag_ended.emit(drag_start_pos, global_position)
			
			get_viewport().set_input_as_handled()

# Get a fresh instance of what this is a placeholder for.
func get_instance() -> Node:
	
	var new := MusicSectioner.new()
	
	for property in passover_properties:
		new.set(property, get(property))
	
	return new
