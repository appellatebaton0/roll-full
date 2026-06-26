@tool
class_name OffsetVBoxContainer extends VBoxContainer
# Does fancy offset stuff for the main-menu buttons.

@export var selection_offset := 30.
@export var starting_offset := -170.
@export var slide_in_time     := 0.2
@export var slide_in_interval := 0.1

var buttons:Array[BaseButton]
var tweens:Dictionary[BaseButton, Tween]

func _ready() -> void:
	# Get all the buttons
	for child in get_children():
		if child is BaseButton:
			buttons.append(child)
	
	# Tween 'em in.
	for i in buttons.size():
		var button := buttons[i] 
		var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
		tweens[button] = tween
		
		button.offset_transform_enabled = true
		button.offset_transform_position.x = starting_offset
		
		tween.tween_property(button, "offset_transform_position:x", 0.0, slide_in_time).set_delay(i * slide_in_interval)
		
		button.mouse_entered.connect(_selected.bind(button))
		button.focus_entered.connect(_selected.bind(button))
		button.mouse_exited.connect(_unselected.bind(button))
		button.focus_exited.connect(_unselected.bind(button))
	
	
func _selected(button:BaseButton):
	var tween := tweens[button]
	
	if tween and tween.is_running(): tween.kill()
	
	tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "offset_transform_position:x", selection_offset, 0.1)
	
	tweens[button] = tween
func _unselected(button:BaseButton):
	var tween := tweens[button]
	
	if tween and tween.is_running(): tween.kill()
	
	tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "offset_transform_position:x", 0.0, 0.1)
	
	tweens[button] = tween
