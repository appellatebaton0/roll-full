@tool
class_name OptionsScreen extends Panel
## Manages most of the happenings in the options screen.

func _process(delta: float) -> void: if not Engine.is_editor_hint():
	if Input.is_action_just_pressed("ComboUp"): 
		print(InputMap.action_get_events("ComboUp"))
