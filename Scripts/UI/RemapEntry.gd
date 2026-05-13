class_name RemapEntry extends BoxContainer

@export var action:String
@export var label_override:String

@export var template:Control
@export var button_count := 4

var buttons:Array[RemapButton]

func _ready() -> void:
	
	$InputLabel.text = action if not label_override else label_override
	
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
