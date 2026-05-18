class_name PauseScreen extends Control
## Manages the popup that appears when you pause the game.

@export var can_pause := false
var paused := false

@onready var animator := $Animator

## Level information
@onready var ranking_bar := $Popup/PanelContainer/MarginContainer/HBoxContainer/RankingBar
@onready var level_name   := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/LevelName
@onready var options      := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Options

## Attempt Information
@onready var rank      := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Rank
@onready var bonused   := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Bonused
@onready var time      := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/VBoxContainer/Time
@onready var score     := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/Score
@onready var threshold := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/Threshold
@onready var speed     := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/Cassette/MarginContainer/VBoxContainer/VBoxContainer/Speed

## Buttons
@onready var resu_button    := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Resume
@onready var quit_button    := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Quit
@onready var options_button := $Popup/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Options

@onready var level_root := get_tree().get_first_node_in_group("Main")

var current_data:LevelData:
	set(to): 
		if current_data:
			current_data.runs_updated.disconnect(_update_options)
		
		current_data = to
		
		if current_data:
			current_data.runs_updated.connect(_update_options)
			_update_options()

func _ready() -> void: 
	options.item_selected.connect(_update_overview)
	focus_entered.connect(_on_focused)

func _on_focused() -> void: 
	resu_button.grab_focus()
	can_pause = true

var attempt_dict:Dictionary[String, LevelData.Run]
## Update the interface.
func _update_options() -> void:
	
	level_name.text = current_data.name
	
	## Regenerate the attempt dictionary and options.
	options.clear()
	
	# All the runs so far.
	for i in range(len(current_data.runs)):
		var run := current_data.runs[i]
		var id  := Global.digitize(i, 3)
		
		attempt_dict[id] = run
		
		if run == current_data.best_run:
			## Create the entry with the "best run" icon texture.
			options.add_icon_item(preload("res://Assets/Textures/BestRunIcon.png"), id, 0)
		else:
			options.add_item(id, 0)
		
	# The current run.
	var current_run := LevelData.Run.new(Global.run_timer.timer, Global.score, current_data._get_ranking(Global.run_timer.timer), current_data._is_bonused(Global.score), Global.default_time_scale)
	var current_id  := Global.digitize(len(current_data.runs), 3)
	
	attempt_dict[current_id] = current_run
	options.add_icon_item(preload("res://Assets/Textures/NewRunIcon.png"), current_id, 0)
	options.selected = 0
	
	_update_overview(options.selected)

func _update_overview(index:int) -> void:
	
	var run := attempt_dict[options.get_item_text(index)]
	
	ranking_bar.update(current_data, run)
	
	rank.text       = run.ranking_as_string()
	bonused.visible = run.bonused
	time.text       = "Time: " + Global.seconds_as_timer(run.time)
	score.text      = "Score: " + Global.digitize(run.score, 4)
	threshold.text  = "/" + Global.digitize(current_data.score_threshold, 4)
	speed.text      = "Speed: " + str(round(run.speed * 100)) + "%"


func _process(_delta: float) -> void:
	if Global.current_data != current_data: current_data = Global.current_data
	if can_pause and not animator.is_playing():
		if Input.is_action_just_pressed("Pause") or (paused and Input.is_action_just_pressed("ui_cancel")):
			toggle_pause()

func toggle_pause() -> void:
	animator.play("Unpause" if paused else "Pause", -1, 1.0 / Engine.time_scale)
	paused = !paused
	
	if paused:
		get_tree().paused = paused
	else:
		Global.request_animation.emit("Countdown")
	if paused: _update_options()

func _on_quit_pressed() -> void:# if focused:
	
	Global.request_animation.emit("Game->Levels", false)
	toggle_pause()

func _on_options_pressed() -> void:
	Global.request_animation.emit("OpenOptions", false)
	can_pause = false
	Global.return_focus = options_button
