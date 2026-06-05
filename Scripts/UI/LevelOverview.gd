class_name LevelOverview extends MarginContainer
## The right side of the level selection screen, displays information about
## the selected level.

@export var speed_step := 0.1
@export var focused := false

@onready var level_root := get_tree().get_first_node_in_group("Main")

## Run Overview (top half)
@onready var ranking_bar:RankingBar = $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer/RankingBar

@onready var reset_button := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var run_name := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/HBoxContainer/RunName
@onready var attempt_number := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer/AttemptNum

@onready var rank := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Rank
@onready var bonused := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Rank/Bonused

@onready var time := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/Time
@onready var score := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer2/Score
@onready var score_threshold := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer2/ScoreThreshold
@onready var speed := $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/VBoxContainer2/Speed

@onready var sort_button_box := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer2/SortButtons

## Bottom half
@onready var attempt_box := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer2/Panel/ScrollContainer/AttemptBox
@onready var play_button := $VBoxContainer/HBoxContainer2/Play
@onready var this_speed := $VBoxContainer/HBoxContainer2/HBoxContainer/Speed

var level_data:LevelData: set = _set_level_data
		

func _ready() -> void: 
	this_speed.text = str(Global.time_scale_modifiers["Gamespeed"] * 100) + "%"
	
	if level_data: _update()
	
	for button in sort_button_box.get_children(): if button is Button:
		button.pressed.connect(_request_attempt_sort.bind(button.name))

func _update():
	update_overview()
	update_attempt_box()
	update_speed_display()

func _set_level_data(to:LevelData):
	if level_data:
		level_data.runs_updated.disconnect(_update)
		
	level_data = to
	
	if level_data:
		level_data.runs_updated.connect(_update)
		
	if is_node_ready():
		_update()

func update_overview(run:Variant = null) -> int:
	if not level_data:
		## Set everything to a null state. This should never happen.
		
		ranking_bar.update()
		
		reset_button.visible = false
		run_name.text        = "Run"
		attempt_number.text  = "___"
		
		rank.text            = "-"
		bonused.visible      = false
		
		time.text            = "Time: __:__.__"
		score.text           = "Score: ____"
		score_threshold.text = "/____"
		speed.text           = "Speed: ___%"
		
		return 0
	
	var is_showing_best := false
	
	if run is int: run = level_data.runs[run]
	if run == null:
		
		if len(level_data.runs) > 0:
			run = level_data.best_run
			is_showing_best = true
		else:
			## The overview is blank. Update w/o runs.
			ranking_bar.update(level_data)
			
			reset_button.visible = false
			run_name.text        = "Run"
			attempt_number.text  = "___"
			
			rank.text            = "-"
			bonused.visible      = false
			
			time.text            = "Time: __:__.__"
			score.text           = "Score: ____"
			score_threshold.text = "/" + Global.digitize(level_data.score_threshold, 4)
			speed.text           = "Speed: ___%"
			
			return 2
	
	## Update the overview display, with runs.
	if run is LevelData.Run: if level_data.runs.has(run):
		ranking_bar.update(level_data, run)
		
		reset_button.visible = not is_showing_best
		run_name.text        = "Best Run" if is_showing_best else "Run"
		attempt_number.text  = "(%s)" % Global.digitize(level_data.runs.find(run) + 1, 3)
		
		rank.text            = run.ranking_as_string()
		bonused.visible      = run.bonused
		
		time.text            = "Time: " + Global.seconds_as_timer(run.time)
		score.text           = "Score: " + Global.digitize(run.score, 4)
		score_threshold.text = "/" + Global.digitize(level_data.score_threshold, 4)
		speed.text           = "Speed: " + str(int(round(run.speed * 100))) + "%"
		
		if is_showing_best and len(attempt_box.get_children()):
			attempt_box.get_child(0).grab_focus()
		
		return 1
	return -1

func update_attempt_box() -> bool:
	if not level_data: return false
	
	# Update the attempt entries.
	var entries:Array[AttemptEntry]
	
	for child in attempt_box.get_children(): if child is AttemptEntry:
		entries.append(child)
	
	var attempts = len(level_data.runs)
	
	# Make sure the amount of entries is correct, but use existing ones.
	var len_dist:int = len(entries) - attempts
	while len_dist != 0:
		# If extra, get rid of them.
		if   len_dist > 0: entries.pop_back().queue_free()
		# If missing some, make more.
		elif len_dist < 0: 
			var entry:AttemptEntry = preload("res://Scenes/UIElements/AttemptEntry.tscn").instantiate()
			
			attempt_box.add_child(entry)
			entries.append(entry)
		
		# Update the check.
		len_dist = len(entries) - attempts
	
	
	for i in len(entries):
		var entry := entries[i]
		if entry is AttemptEntry:
			entry.update(level_data.runs[i], i)
			
			# Set up neighbors.
			entry.focus_neighbor_bottom = play_button.get_path() if i == len(entries) - 1 else entries[i + 1].get_path()
			entry.focus_neighbor_top = reset_button.get_path() if i == 0 else entries[i - 1].get_path()
			
			if not entry.requested.is_connected(update_overview):
				entry.requested.connect(update_overview)
	
	_request_attempt_sort(current_attempt_sort_type)
	
	return true

var reverse_attempt_sort := false
var current_attempt_sort_type := "RunNumber"

const SORT_INACTIVE_ICON := preload("res://Assets/Textures/SortInactive.svg")
const SORT_ASCENDING_ICON := preload("res://Assets/Textures/SortAscending.svg")
const SORT_DESCENDING_ICON := preload("res://Assets/Textures/SortDescending.svg")

func _request_attempt_sort(type:String):
	
	# No level data? there won't be anything to sort.
	if level_data == null: return
	
	# Allow sorting the array in reverse.
	if current_attempt_sort_type == type: reverse_attempt_sort = !reverse_attempt_sort
	else: reverse_attempt_sort = false
	current_attempt_sort_type = type
	
	var entries:Array[AttemptEntry]
	for child in attempt_box.get_children(): if child is AttemptEntry:
		entries.append(child)
	
	var runs := level_data.runs.duplicate()
	
	# Sort the runs.
	match type:
		"Rank":
			runs.assign(Global.merge_sort(runs, _sort_by_rank))
		"RunNumber":
			pass # they're sorted by runnumber by default
		_: # All the others can be forced to lowercase and sorted by their property, no special function.
			runs.assign(Global.merge_sort(runs, _sort_by_generic.bind(type.to_lower())))
	
	# If the order's supposedly reversed, do that.
	if reverse_attempt_sort: runs.reverse()
	
	# Update each entry Control with its new run to display.
	for i in runs.size():
		entries[i].update(runs[i], level_data.runs.find(runs[i]))
	
	# Update the icons of every button.
	for button in sort_button_box.get_children(): if button is Button:
		if button.name == type:
			button.icon = SORT_DESCENDING_ICON if reverse_attempt_sort else SORT_ASCENDING_ICON
		else:
			button.icon = SORT_INACTIVE_ICON

func _sort_by_rank(a:LevelData.Run, b:LevelData.Run) -> bool:
	return wrapi(a.ranking, 0, 6) > wrapi(b.ranking, 0, 6)
func _sort_by_generic(a:LevelData.Run, b:LevelData.Run, property:StringName) -> bool:
	return a.get(property) > b.get(property)

## Load the current level, play the opening animation.
func _on_play_pressed() -> void: if focused:
	
	Global.request_animation.emit("Levels->Game")
	
	Global.current_data  = level_data
	
	var level = level_data.scene.instantiate()
	Global.current_level = level
	
	level_root.add_child(level)
	
	Global.run_timer.reset()
	
	Global.starting_level.emit()

func _speed_up() -> void:
	Global.set_timescale_modifier("Gamespeed", clamp(Global.time_scale_modifiers["Gamespeed"] + speed_step, speed_step, 2.))
	
	update_speed_display()

func _speed_down() -> void:
	Global.set_timescale_modifier("Gamespeed", clamp(Global.time_scale_modifiers["Gamespeed"] - speed_step, speed_step, 2.))
	
	update_speed_display()

func update_speed_display() -> void:
	this_speed.text = str(int(round(Global.time_scale_modifiers["Gamespeed"] * 100))) + "%"
	
	this_speed.material.set_shader_parameter("speed", inv_lerp(0., 2., Global.time_scale_modifiers["Gamespeed"]))

func inv_lerp(a:float,b:float,t:float):
	return (t - a) / (b - a)

func _on_attempt_box_focus_entered() -> void:
	for child in attempt_box.get_children(): if child is AttemptEntry:
		child.call_deferred("grab_focus")
		break
