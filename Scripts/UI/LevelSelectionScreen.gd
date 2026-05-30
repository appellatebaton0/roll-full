class_name LevelSelectionScreen extends Control
## The script that manages the level selection screen.

@export var focused := false:
	set(to):
		for node in focusees:
			node.set("focused", to)
		focused = to
@export var focusees:Array[Node]

func _ready() -> void: 
	focused = focused
	focus_entered.connect(_on_focused)

@export var focus_pass:Control
func _on_focused() -> void: 
	if focus_pass: focus_pass.grab_focus()
