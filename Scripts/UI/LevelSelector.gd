class_name LevelSelector extends TextureRect
## The script that manages the level selection screen.

@export var focused := false:
	set(to):
		print("!")
		for node in focusees:
			print("setting ", node)
			node.set("focused", to)
		focused = to
@export var focusees:Array[Node]

func _ready() -> void: focused = focused
