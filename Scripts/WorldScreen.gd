class_name WorldScreen extends TextureRect

signal request_popup(data:LevelData)

@onready var next_button := $MarginContainer/HBoxContainer/NextWorld
@onready var prev_button := $MarginContainer/HBoxContainer/PrevWorld

## THe folder the level_data this screen will have on it are stored in.
## Turns this file's name into the folder name for the LevelData.
@onready var level_data_folder:String = "res://Assets/LevelData/" + Array(scene_file_path.split("/")).back().replace(".tscn", "")

## How far into the world the player has progressed.
@export var progression_index := 0:
	set(to):
		progression_index = to
		update_progression()

## The VBox holding the level entries
@onready var level_box := $MarginContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer/LevelBox

func _ready() -> void:
	
	## Load all the levels in this world into the level_box.
	for file in get_level_data():
		var new:LevelEntry = preload("res://Scenes/UIElements/LevelEntry.tscn").instantiate()
		new.level_data = file
		
		level_box.add_child(new)
		
		new.pressed.connect(_on_entry_pressed.bind(new))
		
	update_progression()

func update_progression() -> void:
	var children := level_box.get_children()
	for i in range(len(children)): if children[i] is LevelEntry:
		children[i].locked = i > progression_index

func _on_entry_pressed(entry:LevelEntry) -> void: if not entry.locked: request_popup.emit(entry.level_data)

func get_level_data() -> Array[LevelData]:
	
	var file_names:Array[StringName]
	
	var dir = DirAccess.open(level_data_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				file_names.append(level_data_folder + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	# Sort alphebetically. (A-Z then 0-9)
	file_names.sort()
	file_names.reverse()
	
	var data:Array[LevelData]
	
	for file_name in file_names:
		var file = load(file_name)
		if file is LevelData:
			data.append(file)
	
	return data
