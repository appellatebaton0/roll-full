extends Node

signal finished_loading

@warning_ignore("unused_signal")
signal request_animation(anim_name:String)
@warning_ignore("unused_signal")
signal reset_level
@warning_ignore("unused_signal")
signal level_complete
@warning_ignore("unused_signal")
signal starting_level

## -- GAME STATE -- ##

const PROGRESSION_OVERRIDE := false

var world_progression := 0: ## The number of worlds completed.
	set(to): pass ## Temporarily for this demo, don't allow progression to other worlds.

var current_level:Node
var current_data :LevelData

var run_timer:RunTimer

var default_time_scale := 1.0

var spinning_camera := false
var do_parallaxing := true

var return_focus:Control

## -- COMBO MANAGEMENT -- ##

signal finished_combo(combo:Combo)
signal trick_ended

const COMBO_LENGTH := 3
const ACTION_POINTS := 8 ## How many points a single direction press is worth.

enum DIR {UP, RIGHT, DOWN, LEFT}

var combo_buffer:Array[DIR]
var score := 0
var score_buffer := 0

class Combo:
	var key:Array[DIR]
	var multiplier:float
	var name:String
	
	func _init(set_name:String, set_key:Array[int], set_mult:float = 1.5) -> void:
		name = set_name
		key = set_key as Array[DIR]
		multiplier = set_mult

@onready var combos := [
	
	# 270 degree arc
	Combo.new("Arc", [0, 1, 2], 1.3), Combo.new("Arc", [1, 2, 3], 1.3), 
	Combo.new("Arc", [2, 3, 0], 1.3), Combo.new("Arc", [3, 0, 1], 1.3),
	Combo.new("Arc", [2, 1, 0], 1.3), Combo.new("Arc", [3, 2, 1], 1.3), 
	Combo.new("Arc", [0, 3, 2], 1.3), Combo.new("Arc", [1, 0, 3], 1.3),
	
	# Triple-Taps
	Combo.new("Triple", [0, 0, 0], 1.5), Combo.new("Triple", [1, 1, 1], 1.5), 
	Combo.new("Triple", [2, 2, 2], 1.5), Combo.new("Triple", [3, 3, 3], 1.5),
	
	]

func push_direction(direction:DIR):
	
	combo_buffer.append(direction)
	
	## IF this is the final action in the combo, finish the combo.
	if len(combo_buffer) >= COMBO_LENGTH: complete_combo()

## Figure out what the current combo is, and complete it.
func complete_combo() -> void:
	var this_combo:Combo
	
	# Add the action points
	score_buffer += int(len(combo_buffer) * ACTION_POINTS)
	
	## Check existing combos for a specific one.
	for combo in combos:
		if combo_buffer as Array[int] == combo.key:
			this_combo = combo
			break
	## Default combo if no specific ones found.
	if not this_combo: this_combo = Combo.new("Basic", combo_buffer as Array[int], 1.1)
	
	# Apply the multiplier
	score_buffer = int(score_buffer * this_combo.multiplier)
	
	# Emit the combo and clear the buffer.
	finished_combo.emit(this_combo)
	combo_buffer.clear()

## Push the current score_buffer into the score.
func end_trick_sequence() -> void:
	combo_buffer.clear()
	
	if score_buffer > 0:
		score += score_buffer
		score_buffer = 0
		
	trick_ended.emit()

func _ready() -> void: 
	_load()
	reset_level.connect(_on_reset)

func _on_reset() -> void: 
	end_trick_sequence()
	score = 0

## -- GENERIC -- ## 

func seconds_as_timer(amount:float, show_mili := true) -> String:
	
	var minutes:int = floor(amount / 60)
	var seconds = int(amount) % 60
	var milis = int(amount * 100) % 100
	
	if show_mili:
		return "%s:%s.%s" % [digitize(minutes, 2),digitize(seconds, 2),digitize(milis, 2)]
	else:
		return "%s:%s" % [digitize(minutes, 2),digitize(seconds, 2)]

func digitize(value:int, digits:int) -> String:
	
	var response := ""
	var string = str(value)
	
	for i in digits - len(string):
		response += "0"
	response += string
	
	return response


func d_lerp(a, b, r:float, delta:float) -> Variant:
	if a is Vector2 and b is Vector2:
		return Vector2(d_lerp(a.x, b.x, r, delta), d_lerp(a.y, b.y, r, delta))
	
	return ((a - b) * pow(r, delta)) + b

## Sorts the array via merge sort.
func merge_sort(array:Array, condition:Callable) -> Array:
	
	var length = len(array)
	
	if length <= 1: return array
	
	@warning_ignore("integer_division")
	var left = array.slice(0, floor((length + 1) / 2))
	@warning_ignore("integer_division")
	var right = array.slice(floor((length + 1) / 2), length)
	
	
	left  = merge_sort(left,  condition)
	right = merge_sort(right, condition)
	
	# The array's already sorted.
	if   len(left)  <= 0: return right 
	elif len(right) <= 0: return left 
	
	var li = 0
	var ri = 0
	
	var response:Array

	while len(response) < len(left) + len(right):
		
		# One of the arrays is empty; append the other and end.
		if li >= len(left): 
			response.append_array(right.slice(ri))
			break
		elif ri >= len(right):
			response.append_array(left.slice(li))
			break
		
		# Otherwise, append the next.
		if condition.call(left[li], right[ri]): 
			response.append(right[ri])
			ri += 1
		else:
			response.append(left[li])
			li += 1
	
	return response

## Custom Tooltip Functions

func _make_custom_tooltip(for_text: String) -> Object:
	if for_text == "": return null
	
	var tooltip:Tooltip = preload("res://Scenes/UIElements/FancyTooltip.tscn").instantiate()
	
	tooltip.text = for_text
	
	return tooltip

## -- MANAGING LEVEL DATA -- ##

const LEVEL_DATA_FOLDER := "res://Assets/LevelData/"
@onready var LEVEL_DATA := get_level_data()

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
	
	# Sort numerically
	file_names.assign(merge_sort(file_names, func(a,b): return int(a) > int(b)))
	
	var data:Array[LevelData]
	
	for file_name in file_names:
		var file = load(file_name)
		if file is LevelData:
			data.append(file)
	
	return data

const SAVE_GAME_PATH := "user://save.json"

func _save() -> void:
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	## Helper function, stores a dictionary into the save file.
	var save_dict := func(dict:Dictionary): save_file.store_line(JSON.stringify(dict))
	
	## Save all the levels' runs.
	
	var level_dict := {}
	for data in LEVEL_DATA:
		var run_array := []
		
		for run in data.runs:
			var run_dict := {}
			
			for property in ["time", "score", "ranking", "bonused", "speed"]:
				run_dict[property] = run.get(property)
				
			run_array += [run_dict]
		
		level_dict[data.name] = run_array
	
	save_dict.call({"Levels":level_dict})
	
	# Save all the settings.
	
	## InputMap
	var input_dict := {}
	
	# Input whitelist
	var valid_inputs := ["ComboDown", "ComboLeft", "ComboRight", "ComboUp", "Dash", "Jump", "Pause", "Reset", "ui_accept", "ui_cancel", "ui_down", "ui_left", "ui_right", "ui_up"]
	
	# For every action in the InputMap
	for action in InputMap.get_actions():
		# Only save the specified inputs.
		if not valid_inputs.has(action): continue
		
		var event_array:Array[Dictionary] = []
		# For every input for this action.
		for event in InputMap.action_get_events(action):
			
			var event_dict := {}
			
			var save_properties:Array[String]
			
			# Get all the properties this event needs to save, and save its class.
			if   event is InputEventKey:
				save_properties = ["physical_keycode", "keycode", "pressed"]
				event_dict["class"] = "InputEventKey"
			elif event is InputEventJoypadButton:
				save_properties = ["button_index", "pressed", "pressure"]
				event_dict["class"] = "InputEventJoypadButton"
			elif event is InputEventJoypadMotion:
				save_properties = ["axis", "axis_value"]
				event_dict["class"] = "InputEventJoypadMotion"
			
			# Save the event's properties
			for property in save_properties:
				event_dict[property] = event.get(property)
			
			# Pass to the array
			event_array += [event_dict]
		# Pass to the dictionary
		input_dict[action] = event_array
	
	save_dict.call({"InputMap":input_dict})
	
	## Audio Bus Volumes
	var save_buses := ["SFX", "Music", "Master"]
	var bus_dict := {}
	
	for bus in save_buses:
		bus_dict[bus] = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus))
	
	save_dict.call({"Audio":bus_dict})
	
	## Other misc settings.
	save_dict.call({"SpinningCamera":spinning_camera})
	save_dict.call({"DoParallaxing":do_parallaxing})
	save_dict.call({"WindowMode":DisplayServer.window_get_mode()})
	
	print("SAVED!")

func _load() -> void:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		return # No save file to load!
	
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	
	# Iterate through the lines in the save file.
	while save_file.get_position() < save_file.get_length():
		var json_string := save_file.get_line()
		
		var json := JSON.new()
		
		# Parse the JSON string and check for errors.
		var parse := json.parse(json_string)
		if not parse == OK:
			push_warning("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue # Error found, skip this line.
		
		# Finish parsing into an ID and value.
		var dict:Dictionary = json.data
		var id:String = dict.keys()[0]
		var value:Variant = dict[id]
		
		# Load the actual data.
		match id:
			"Levels": ## LevelData.
				# Make sure there's LevelData to load these into.
				if LEVEL_DATA.size() <= 0: LEVEL_DATA = get_level_data()
				
				for data in LEVEL_DATA:
					if not value.has(data.name): continue # Nothing to load for this level.
					
					# Make a new array and set to that, so the setter only gets called once.
					var new_runs:Array[LevelData.Run]
					
					# Parse the run dictionaries into runs, add them to the array.
					for run_dict in value[data.name]:
						new_runs.append(LevelData.Run.new(run_dict["time"], run_dict["score"], run_dict["ranking"], run_dict["bonused"], run_dict["speed"]))
					
					# Push the array to the LevelData
					data.runs = new_runs
			
			"InputMap": ## All the Input binding.
				for action in value:
					
					## Load the events into the action on the InputMap
					
					if not InputMap.has_action(action):
						InputMap.add_action(action) # Should never happen.
						
					InputMap.action_erase_events(action)
					
					# Parse each action's input dicts into actual InputEvents,
					# and add them to the map.
					for input_dict in value[action]:
						
						# Make the event
						var event:InputEvent
						match input_dict["class"]:
							"InputEventKey":
								event = InputEventKey.new()
							"InputEventJoypadButton":
								event = InputEventJoypadButton.new()
							"InputEventJoypadMotion":
								event = InputEventJoypadMotion.new()
						
						# Pass its properties to it
						for property in input_dict:
							if property == "class": continue
							event.set(property, input_dict[property])
						
						# Add it to the InputMap.
						InputMap.action_add_event(action, event)
			
			"Audio": ## Audio Bus Volumes
				for bus in value:
					AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), value[bus])
			
			## Other misc settings.
			"SpinningCamera":
				spinning_camera = value
			"DoParallaxing":
				do_parallaxing = value
			"WindowMode":
				DisplayServer.window_set_mode(int(value) as DisplayServer.WindowMode)
	
	finished_loading.emit()
