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
#
#var held := false
#var hold_offset:Vector2
#
#func _ready() -> void:
	#print(mouse_detector.connect("input_event", _mouse_input_event))
	##mouse_detector.input_event.connect(_mouse_input_event)
#
#func _process(delta: float) -> void:
	#if held: global_position = get_global_mouse_position() - hold_offset
#
#func _mouse_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	#if event is InputEventMouseButton:
		#if event.is_pressed():
			#print(event.position)
			#print("START DRAG")
			#hold_offset = get_local_mouse_position()
			#held = true
		#elif held: held = false
	#
		#get_viewport().set_input_as_handled()
