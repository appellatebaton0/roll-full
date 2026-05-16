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
	
	if action:
		sane_default = InputMap.action_get_events(action)
	
	input_label.text = action if not label_override else label_override
	reset_button.pressed.connect(_reset_pressed)
	
	var trebut := get_remap_button_from(template)
	if trebut: buttons.append(trebut)
	
	for i in range(button_count - 1):
		var new := template.duplicate()
		
		template.add_sibling(new)
		
		var rebut := get_remap_button_from(new)
		if rebut: 
			rebut.action_event_index = button_count - 1 - i 
			buttons.append(rebut)
	
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
