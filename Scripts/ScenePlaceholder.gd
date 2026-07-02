class_name ScenePlaceholder extends Node2D
## Provides a placeholder for a scene in the level editor, and passes all the
## necessary information off on runtime. 

## When this placeholder is clicked, note it as selected
signal selected
signal holdability_changed(to:bool)

signal drag_ended(from:Vector2, to:Vector2)

var can_be_held := false: set = _set_holdability
func _set_holdability(to) -> void:
	can_be_held = to
	holdability_changed.emit(to)

@export var display_name:String

## The scene this node is a placeholder for.
@export var placeholds:PackedScene
## The properties that will be passed to the actual scene.
@export var passover_properties:Array[String] = [
	"position", "scale", "rotation"
]

## Whether this placeholder can be deleted.
@export var deletable := false
## Whether this placeholder can be scaled
@export var scalable := true
## Whether this placeholder can be rotated.
@export var rotatable := true

@onready var drag_area:Area2D = $DragArea

var held := false
var hold_offset:Vector2
var drag_start_pos:Vector2

func _ready() -> void:
	if drag_area: drag_area.input_event.connect(_input_event)

func _process(_delta: float) -> void:
	if held: global_position = get_global_mouse_position() - hold_offset

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

func start_hold() -> void: if can_be_held:
	hold_offset = (get_local_mouse_position() * scale).rotated(rotation)
	held = true
	
	drag_start_pos = global_position
	
	# Move to the end of the child list. In other words, put on top.
	get_parent().move_child(self, -1)
	
	selected.emit()

# Get a fresh instance of what this is a placeholder for.
func get_instance() -> Node:
	
	var new := placeholds.instantiate() if placeholds else null
	
	if not new: print(new)
	else:
	
		for property in passover_properties:
			new.set(property, get(property))
	
	return new
