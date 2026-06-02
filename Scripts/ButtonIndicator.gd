@tool
extends Button

var timer := 0.
@export var interval := 1.0
@export var input_name:StringName

var labels:Dictionary[Global.INPUT_TYPE, String] = {
	Global.INPUT_TYPE.KEYBMOUSE:  "UNBOUND",
	Global.INPUT_TYPE.CONTROLLER: "UNBOUND"
}

func _ready() -> void:
	for event in InputMap.action_get_events(input_name):
		if event is InputEventJoypadButton and labels[Global.INPUT_TYPE.CONTROLLER] == "UNBOUND":
			labels[Global.INPUT_TYPE.CONTROLLER] = Global.input_as_string(event)
		elif event is InputEventKey and labels[Global.INPUT_TYPE.KEYBMOUSE] == "UNBOUND":
			labels[Global.INPUT_TYPE.KEYBMOUSE] = Global.input_as_string(event)
	
	Global.input_type_changed.connect(_type_changed)
	_type_changed()

func _type_changed():
	text = labels[Global.input_type]
	

func _process(delta: float) -> void:
	timer = move_toward(timer, 0., delta / Engine.time_scale)
	#size.x = 0
	#pivot_offset = size / 2
	
	button_pressed = timer <= interval / 2
	
	if timer <= 0: timer = interval
