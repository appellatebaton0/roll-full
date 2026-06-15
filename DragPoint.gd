class_name DragPoint extends Area2D
## A draggable point that emits a signal whenever its position changes.
## Good for making editable polygons or splines...

signal position_changed()
signal selected

signal holdability_changed(to:bool)

var can_be_held := true:
	set(to):
		can_be_held = to
		holdability_changed.emit(to)

var held := false
var hold_offset:Vector2

func _process(_delta: float) -> void:
	if held: 
		var new_position := get_global_mouse_position() - hold_offset
		if global_position != new_position:
			global_position = new_position
			position_changed.emit()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if held and event is InputEventMouse: held = event.button_mask
	if event is InputEventMouseButton:
		if event.is_pressed(): if can_be_held:
			hold_offset = get_local_mouse_position()
			held = true
			
			# Move to the end of the child list. In other words, put on top.
			get_parent().move_child(self, -1)
			
			selected.emit()
			
			get_viewport().set_input_as_handled()
		elif held: 
			held = false
	
			get_viewport().set_input_as_handled()
