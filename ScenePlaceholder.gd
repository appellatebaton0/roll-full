class_name ScenePlaceholder extends Node2D
## Provides a placeholder for a scene in the level editor, and passes all the
## necessary information off on runtime. 

## The scene this node is a placeholder for.
@export var placeholds:PackedScene
## The properties that will be passed to the actual scene.
@export var passover_properties:Array[String]

## Create the actual version of the scene.
#@abstract func create_instance() -> Node

@onready var drag_area := $DragArea

var held := false
var hold_offset:Vector2

func _ready() -> void:
	drag_area.input_event.connect(_input_event)

func _process(_delta: float) -> void:
	if held: global_position = get_global_mouse_position() - hold_offset

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	print("!")
	if event is InputEventMouseButton:
			if event.is_pressed():
				hold_offset = get_local_mouse_position()
				held = true
				
				# Move to the end of the child list. In other words, put on top.
				get_parent().move_child(self, -1)
				
				get_viewport().set_input_as_handled()
			elif held: 
				held = false
		
				get_viewport().set_input_as_handled()
