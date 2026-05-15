class_name OptionsScreen extends Control
## Manages some of the happenings in the options screen.

## All the configurable inputs. Input Name : Display Name
@export var reconfigurable_inputs:Dictionary[StringName, String]

@onready var remap_box := $MarginContainer/VBoxContainer/PanelContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/ControlsBox/PanelContainer/MarginContainer2/RemapBox

const RemapEntryScene := preload("res://Scenes/UIElements/RemapEntry.tscn")

@onready var scroll_cont := $MarginContainer/VBoxContainer/PanelContainer/PanelContainer/MarginContainer/ScrollContainer

func _ready() -> void:
	
	for input in reconfigurable_inputs:
		var new:RemapEntry = RemapEntryScene.instantiate()
		
		new.action = input
		new.label_override = reconfigurable_inputs[input]
		
		new.focus_neighbor_top = remap_box.get_node(remap_box.focus_neighbor_top).get_path()
		
		remap_box.add_child(new)
	
	var scroll_focusees := scroll_cont.get_children()
	while len(scroll_focusees) > 0:
		var this:Node = scroll_focusees.pop_back()
		
		if this is Control: if this.focus_mode == FOCUS_ALL:
			this.focus_entered.connect(_on_scroll_focus.bind(this))
		
		scroll_focusees += this.get_children()
	
	focus_entered.connect(_on_focused)

func _on_focused() -> void: $MarginContainer/VBoxContainer/VBoxContainer/Title/Button.grab_focus()

func _on_scroll_focus(node:Control) -> void:
	scroll_cont.scroll_vertical -= scroll_cont.global_position.y - node.global_position.y + (scroll_cont.size.y / 2)

func _process(delta: float) -> void:
	if is_visible_in_tree() and Input.is_action_just_pressed("ui_cancel"):
		close()

# This is a function so a signal can call it.
func close() -> void:
	Global.request_animation.emit("CloseOptions")
	if Global.return_focus: Global.return_focus.grab_focus()
