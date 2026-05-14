@tool
class_name OffsetVBoxContainer extends VBoxContainer

@export var offset := 30.0

func _process(_delta: float) -> void:
	
	var best := _best_option()
	
	for child in get_children(): if child is Control:
		child.position.x = offset if child.has_focus(true) else 0.0
	
	if best: if not best.has_focus(): best.grab_focus()

func _best_option() -> Control:
	
	var best:Control = null
	for child in get_children(): if child is Control:
		var selection_rank := _selected(child)
		
		## If it's focused, it'll be chosen if nothing is hovered.
		if selection_rank == 1 and best == null:
			best = child
		## If it's hovered, it's chosen.
		elif selection_rank == 2: return child
	
	return best

func _selected(child:Control) -> int:
	if child.has_focus(): return 1
	
	#if child is BaseButton: if child.is_hovered(): return 2
	
	return 0
