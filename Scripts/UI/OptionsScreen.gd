@tool
class_name OptionsScreen extends Panel
## Manages some of the happenings in the options screen.

## All the configurable inputs. Input Name : Display Name
@export var reconfigurable_inputs:Dictionary[StringName, String]

@onready var remap_box := $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ControlsBox/RemapBox

const RemapEntryScene := preload("res://Scenes/UIElements/RemapEntry.tscn")

func _ready() -> void:
	
	for input in reconfigurable_inputs:
		var new:RemapEntry = RemapEntryScene.instantiate()
		
		new.action = input
		new.label_override = reconfigurable_inputs[input]
		
		remap_box.add_child(new)
