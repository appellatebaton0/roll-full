class_name WorldScreen extends TextureRect

## THe folder the levels this screen will have on it are stored in.
@export_dir var levels_folder:String

## How far into the world the player has progressed.
@export var progression_index := 0:
	set(to):
		progression_index = to
		update_progression()

## The VBox holding the level entries
@onready var level_box := $MarginContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer/LevelBox

func _ready() -> void:
	
	## Load all the levels in this world into the level_box.
	for file in get_levels():
		var new := LevelEntry.new()
		new.level_scene = file
	update_progression()

func update_progression():
	for level_entry in level_box.get_children(): if level_entry is LevelEntry:
		pass

func get_levels() -> Array[PackedScene]:
	
	var levels:Array[PackedScene]
	
	var dir = DirAccess.open(levels_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				
				var file = load(file_name)
				
				if file is PackedScene:
					levels.append(file)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	return levels
