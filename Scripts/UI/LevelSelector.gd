class_name LevelSelector extends Control
## Manages the LevelSelection nodes.

signal selection_updated(to:LevelEntry)

const LEVEL_DATA_FOLDER := "res://Assets/LevelData/"
const LEVEL_ENTRY_SCENE := preload("res://Scenes/UIElements/LevelEntry.tscn")

@export var spin_container :SpinContainer
@export var entry_container:CycleContainer
var level_entries:Array[LevelEntry]

## The currently selected level entry.
var selected:LevelEntry:
	set(to):
		if selected: selected.selected = false
		selected = to
		if selected: selected.selected = true
		
		selection_updated.emit(to)

func _ready() -> void:
	create_level_entries()
	
	## Wire up the signals so that when a entry is clicked on, it's selected.
	for entry in level_entries:
		entry.pressed.connect(select.bind(entry))

func _process(delta: float) -> void:
	if selected:
		var selected_center_y := selected.global_position.y + (selected.size.y / 2)
		if abs(selected_center_y - 432) > 3:
			entry_container.scroll_offset += (432 - selected_center_y)#* 8 * delta
			print(432 - selected_center_y)
	
	
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(0, 432) - global_position, Vector2(1152,432) - global_position, Color.WHITE, 1)
	if selected:
		var selected_center_y := selected.global_position.y + (selected.size.y / 2)
		draw_circle(Vector2(selected.global_position.x, selected_center_y) - global_position, 3, Color.WHITE)
		
		draw_line(Vector2(selected.global_position.x, selected_center_y) - global_position, Vector2(selected.global_position.x, 432) - global_position, Color.RED, 1.0)


## Make a index or node the selected level entry
func select(target:Variant):
	if target is int: selected = level_entries[target]
	if target is LevelEntry: if level_entries.has(target): selected = target

## Creates all the needed level_entries, and adds them to the entry_container.
func create_level_entries() -> void:
	
	var level_data := get_level_data()
	
	var entries:Array[LevelEntry]
	for node in entry_container.get_children(): 
		if node is LevelEntry: entries.append(node)
	
	var len_dist := len(entries) - len(level_data)
	while len_dist != 0:
		if   len_dist > 0: entries.pop_back().queue_free()
		elif len_dist < 0: 
			var new:LevelEntry = LEVEL_ENTRY_SCENE.instantiate()
			
			entry_container.add_child(new)
			entries.append(new)
		
		len_dist = len(entries) != len(level_data)
	
	for i in len(level_data): entries[i].level_data = level_data[i]
	level_entries = entries

func get_level_data() -> Array[LevelData]:
	
	var file_names:Array[StringName]
	
	var dir = DirAccess.open(LEVEL_DATA_FOLDER)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			## REMAPN'T
			file_name = file_name.replace(".remap", "")
			
			if not dir.current_is_dir():
				file_names.append(LEVEL_DATA_FOLDER + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path; ", LEVEL_DATA_FOLDER)
	
	# Sort alphebetically. (A-Z then 0-9)
	var new_files := Global.merge_sort(file_names, _sort_condition)
	for i in range(len(new_files)):
		file_names[i] = new_files[i]
	
	var data:Array[LevelData]
	
	for file_name in file_names:
		var file = load(file_name)
		if file is LevelData:
			data.append(file)
	
	return data

func _sort_condition(a:String, b:String):
	
	var av := -1
	var bv := -1
	
	const alph_list := ["9", "8", "7", "6", "5", "4", "3", "2", "1", "0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
	
	var index := 0
	while av == bv:
		av = alph_list.find(a[index])
		bv = alph_list.find(b[index])
		
		index += 1
		
		if index > len(a):
			return false
	
	return av > bv
