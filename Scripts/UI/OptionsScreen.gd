#@tool
class_name OptionsScreen extends Control
## Manages some of the happenings in the options screen.

## All the configurable inputs. Input Name : Display Name
@export var reconfigurable_inputs:Dictionary[StringName, String]
@export var reconfig_sane_defaults:Dictionary[StringName, Array]

## Used to set up sane defaults.
#@export_tool_button("LOAD") var lfs := func():
	#InputMap.load_from_project_settings()
	#
	#for action in InputMap.get_actions(): if reconfigurable_inputs.has(action):
		#reconfig_sane_defaults[action] = InputMap.action_get_events(action)

@onready var remap_box := $MarginContainer/VBoxContainer/PanelContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/ControlsBox/PanelContainer/MarginContainer2/RemapBox

const RemapEntryScene := preload("res://Scenes/UIElements/RemapEntry.tscn")

@onready var scroll_cont := $MarginContainer/VBoxContainer/PanelContainer/PanelContainer/MarginContainer/ScrollContainer

func _ready() -> void:
	

	for i in len(reconfigurable_inputs):
		var input:String = reconfigurable_inputs.keys()[i]
		var new:RemapEntry = RemapEntryScene.instantiate()
		
		new.action = input
		new.label_override = reconfigurable_inputs[input]
		new.sane_default = reconfig_sane_defaults[input]
		
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
	
	# Ignore any focusing caused by the mouse.
	if not node.has_focus(true): return
	
	scroll_cont.scroll_vertical -= scroll_cont.global_position.y - node.global_position.y + (scroll_cont.size.y / 2)

func _process(_delta: float) -> void:
	if is_visible_in_tree() and Input.is_action_just_pressed("ui_cancel"):
		close()

# This is a function so a signal can call it.
func close() -> void:
	Global.request_animation.emit("CloseOptions")
	Global._save()
	if Global.return_focus: Global.return_focus.grab_focus()
