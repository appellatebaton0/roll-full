class_name VolumeSlider extends HSlider

@export var bus_name:StringName
@onready var bus_id := AudioServer.get_bus_index(bus_name)

@export var value_display:Label

func _ready() -> void:
	# Start as the bus's value.
	value = AudioServer.get_bus_volume_linear(bus_id)

func _value_changed(new_value: float) -> void:
	
	# Update the bus.
	AudioServer.set_bus_volume_linear(bus_id, new_value)
	
	# Update the display
	value_display.text = str(round(new_value * 100) / 100)
	
	# Always show the hundreths place.
	if value_display.text.length() == 3: value_display.text += "0"
