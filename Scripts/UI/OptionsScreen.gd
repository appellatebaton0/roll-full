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
	
	focus_entered.connect(_on_focused)
	

func _on_focused() -> void: $MarginContainer/VBoxContainer/Title/Button.grab_focus()

func _process(delta: float) -> void:
	if is_visible_in_tree() and Input.is_action_just_pressed("ui_cancel"):
		close()

# This is a function so a signal can call it.
func close() -> void:
	Global.request_animation.emit("CloseOptions")
	if Global.return_focus: Global.return_focus.grab_focus()


func _on_remap_box_focused() -> void:
	var children := remap_box.get_children()
	while len(children):
		for child in children:
			if child is RemapButton:
				child.grab_focus()
				return
		
		for i in range(len(children)):
			children += children.pop_front().get_children()
