class_name ScenePlaceholder extends Node2D
## Provides a placeholder for a scene in the level editor, and passes all the
## necessary information off on runtime. 

## When this placeholder is clicked, note it as selected
signal selected
signal holdability_changed(to:bool)

var can_be_held := true:
	set(to):
		can_be_held = to
		holdability_changed.emit(to)
	

@export var display_name:String

## The scene this node is a placeholder for.
@export var placeholds:PackedScene
## The properties that will be passed to the actual scene.
@export var passover_properties:Array[String]

@onready var drag_area:Area2D = $DragArea

var held := false
var hold_offset:Vector2

func _ready() -> void:
	drag_area.input_event.connect(_input_event)

func _process(_delta: float) -> void:
	if held: global_position = get_global_mouse_position() - hold_offset

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if held and event is InputEventMouse: held = event.button_mask
	if event is InputEventMouseButton:
		if event.is_pressed():
			start_hold()
			
			get_viewport().set_input_as_handled()
		elif held: 
			held = false
	
			get_viewport().set_input_as_handled()

func start_hold() -> void: if can_be_held:
	hold_offset = (get_local_mouse_position() * scale).rotated(rotation)
	held = true
	
	# Move to the end of the child list. In other words, put on top.
	get_parent().move_child(self, -1)
	
	selected.emit()
