class_name RemapEntry extends BoxContainer

@onready var input_label  := $HBoxContainer2/InputLabel
@onready var reset_button := $HBoxContainer2/MarginContainer/Button

@export var action:String
@export var label_override:String

@export var template:Control
@export var button_count := 4

var buttons:Array[RemapButton]
var sane_default:Array[InputEvent]

func _ready() -> void:
	
	# The currently bound input isn't the default, allow resettng.
	# Used when loading from save with non-default bindings.
	var c_events := InputMap.action_get_events(action)
	for i in min(sane_default.size(), c_events.size()):
		var event_a = sane_default[i]
		var event_b = c_events[i]
		for property in ["physical_keycode", "axis", "axis_value", "button_index", "pressed", "pressure"]:
			if event_a.get(property) != event_b.get(property):
				reset_button.disabled = false
				break
	
	# Update the display label.
	input_label.text = action if not label_override else label_override
	# Wire up the reset-to-default button.
	reset_button.pressed.connect(_reset_pressed)
	
	# Create all the buttons.
	var template_remap_button := get_remap_button_from(template)
	if template_remap_button: buttons.append(template_remap_button)
	
	for i in button_count - 1:
		var new := template.duplicate()
		
		template.add_sibling(new)
		
		var remap_button := get_remap_button_from(new)
		if remap_button: 
			remap_button.action_event_index = button_count - 1 - i 
			buttons.append(remap_button)
	
	# This is a seperate loop because it's a nested loop.
	# If this happened in the above loop, the buttons wouldn't all connect
	# to each other.
	for button in buttons:
		button.action = action
		button.remapped.connect(_any_remapped)
		
		for targ in buttons: 
			if targ == button: continue
			
			button.remapped.connect(targ._toggled)
		
		button._toggled()

func get_remap_button_from(control:Control) -> RemapButton:
	if not control: return null
	
	if control is RemapButton:
		return control
	
	for child in control.get_children():
		var test := get_remap_button_from(child)
		if test: return test
	
	return null

func _any_remapped() -> void: reset_button.disabled = false
func _reset_pressed() -> void:
	
	InputMap.action_erase_events(action)
	for event in sane_default:
		InputMap.action_add_event(action, event)
	
	buttons[0]._toggled()
	buttons[0].remapped.emit()
	
	buttons[0].grab_focus()
	
	reset_button.disabled = true
	
	pass
