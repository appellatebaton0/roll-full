class_name RemapButton extends Button

signal remapped

@export var action:String
@export var action_event_index:int = 0

@export var unmap_button:Button

func _ready() -> void: 
	toggle_mode = true
	_toggled(false)
	unmap_button.pressed.connect(_unmap)

func _unmap():

	if !action or !InputMap.has_action(action): 
		return 
	
	var action_events_list := InputMap.action_get_events(action)
	if action_events_list.size() > action_event_index:
		InputMap.action_erase_event(action, action_events_list[action_event_index])
	
	remapped.emit()
	
	button_pressed = false
	
	_toggled()

func _toggled(toggled_on: bool = button_pressed) -> void: 
	
	unmap_button.disabled = InputMap.action_get_events(action).size() <= 1

	if !action or !InputMap.has_action(action):
		text = ""
		return

	if toggled_on:
		text = "??"
		return
	
	if action_event_index >= InputMap.action_get_events(action).size():
		text = ""
		return
	
	text = Global.input_as_string(InputMap.action_get_events(action)[action_event_index])

func _input(event: InputEvent) -> void:
	if !InputMap.has_action(action) or !is_pressed(): return
	
	if event.is_pressed():
		if (event is InputEventKey or event is InputEventJoypadButton):
			var action_events_list := InputMap.action_get_events(action)
			
			# Delete the existing input from the map.
			if action_event_index < action_events_list.size():
				InputMap.action_erase_event(action, action_events_list[action_event_index])
			
			# Add the new one
			InputMap.action_add_event(action, event)
			
			# Untoggle the button (which in turn updates the label again)
			button_pressed = false
			
			# Tell the entry.
			remapped.emit()
			
			# Consume the input to stop it from being registered by other
			# things, like repressing the button.
			get_viewport().set_input_as_handled()
			
		# Assumes you're trying to get out of binding an input.
		elif event is InputEventMouseButton:
			_unmap()
	
	
