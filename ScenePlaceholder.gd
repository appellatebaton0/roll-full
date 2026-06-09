class_name ScenePlaceholder extends Node2D
## Provides a placeholder for a scene in the level editor, and passes all the
## necessary information off on runtime. 

## The scene this node is a placeholder for.
@export var placeholds:PackedScene
## The properties that will be passed to the actual scene.
@export var passover_properties:Array[String]

## Create the actual version of the scene.
#@abstract func create_instance() -> Node

@onready var mouse_detector := $SelectionArea

func _ready() -> void:
	print(mouse_detector.connect("input_event", _mouse_input_event))
	#mouse_detector.input_event.connect(_mouse_input_event)

func _mouse_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	
	print(event)
	
	pass
