class_name LevelSelectionScreen extends TextureRect
## The script that manages the level selection screen.

@export var focused := false:
	set(to):
		for node in focusees:
			node.set("focused", to)
		focused = to
@export var focusees:Array[Node]

func _ready() -> void: focused = focused
