class_name RemapButton extends Button

signal remapped

@export var action:String
@export var action_event_index:int = 0

@export var unmap_button:Button

const CONTROLLER_LABELS := {
	JoyButton.JOY_BUTTON_A: "A",
	JoyButton.JOY_BUTTON_B: "B",
	JoyButton.JOY_BUTTON_X: "X",
	JoyButton.JOY_BUTTON_Y: "Y",
	JoyButton.JOY_BUTTON_LEFT_SHOULDER: "LB",
	JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JoyButton.JOY_BUTTON_LEFT_STICK: "L3",
	JoyButton.JOY_BUTTON_RIGHT_STICK: "R3",
	JoyButton.JOY_BUTTON_DPAD_UP: "↑",
	JoyButton.JOY_BUTTON_DPAD_DOWN: "↓",
	JoyButton.JOY_BUTTON_DPAD_RIGHT: "→",
	JoyButton.JOY_BUTTON_DPAD_LEFT: "←",
	JoyButton.JOY_BUTTON_START: "Start",
	JoyButton.JOY_BUTTON_GUIDE: "Select",
}

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
	
	_toggled(is_pressed())

func _toggled(toggled_on: bool = button_pressed) -> void: 

	if !action or !InputMap.has_action(action):
		text = ""
		return

	if toggled_on:
		text = "??"
		return
	
	if action_event_index >= InputMap.action_get_events(action).size():
		text = ""
		return
	
	var input := InputMap.action_get_events(action)[action_event_index]
	if input is InputEventJoypadButton:
		if CONTROLLER_LABELS.has(input.button_index):
			text = CONTROLLER_LABELS.get(input.button_index)
		else:
			# None found in the constant D:
			text = "Button " + str(input.button_index)
	elif input is InputEventKey:
		if input.physical_keycode != 0:
			text = OS.get_keycode_string(input.physical_keycode)
		else:
			text = OS.get_keycode_string(input.keycode)
	
	unmap_button.disabled = InputMap.action_get_events(action).size() <= 1


func _input(event: InputEvent) -> void:
	if !InputMap.has_action(action) or !is_pressed(): return
	
	if event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		var action_events_list := InputMap.action_get_events(action)
		if action_event_index < action_events_list.size():
			InputMap.action_erase_event(action, action_events_list[action_event_index])
		
		InputMap.action_add_event(action, event)
		button_pressed = false
		
		remapped.emit()
		
		# Consume the input to stop it from being registered by other
		# things, like repressing the button.
		get_viewport().set_input_as_handled()
