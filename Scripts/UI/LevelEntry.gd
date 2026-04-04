class_name LevelEntry extends Button
## Provides an interface into a level.

@export var level_data:LevelData
@export var locked := false:
	set(to):
		locked = to
		disabled = to
