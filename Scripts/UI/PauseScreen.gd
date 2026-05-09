extends MarginContainer
## Manages the popup that appears when you pause the game.

@onready var best_time_lab  := $Panel/MarginContainer/VBoxContainer/HBoxContainer/BestTime
@onready var best_score_lab := $Panel/MarginContainer/VBoxContainer/HBoxContainer/BestScore

@onready var level_name_lab := $Panel/MarginContainer/VBoxContainer/LevelName
@onready var attempt_box    := $Panel/MarginContainer/VBoxContainer/ScrollContainer/AttemptBox

@onready var rank_star      := $Panel/Polygon2D
@onready var rank_box       := $Panel/Polygon2D/HBoxContainer
@onready var rank_lab       := $Panel/Polygon2D/HBoxContainer/Rank
@onready var rank_bonus_lab := $Panel/Polygon2D/HBoxContainer/Label

@onready var quit_button    := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/QuitButton
@onready var resu_button    := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/ResumeButton

@onready var level_root := get_tree().get_first_node_in_group("Main")

var current_data:LevelData:
	set(to): 
		if current_data:
			current_data.runs_updated.disconnect(_update)
		
		current_data = to
		
		if current_data:
			current_data.runs_updated.connect(_update)
			_update()

@export var animator:AnimationPlayer

func _ready() -> void:
	quit_button.pressed.connect(_on_quit_pressed)
	resu_button.pressed.connect(_on_resume_pressed)

func _process(delta: float) -> void:
	rank_star.rotate(delta * 0.7)
	
	rank_box.rotation = -rank_star.rotation
	rank_box.pivot_offset = rank_box.size / 2
	
	if Global.current_data != current_data: current_data = Global.current_data

func _update() -> void:
	
	best_time_lab.text  = "BEST TIME: "  + Global.seconds_as_timer(current_data.best_time)
	best_score_lab.text = "BEST SCORE: " + Global.digitize(current_data.best_score, 7)
	
	level_name_lab.text = current_data.name
	
	# Update the attempt entries.
	var entries := attempt_box.get_children()
	var attempts = len(current_data.runs)
	for i in range(len(entries)):
		var entry := entries[i]
		if entry is AttemptEntry:
			if attempts > 0:
				entry.update(current_data.runs[i], i)
				attempts -= 1
			else:
				entry.queue_free()
	
	for i in range(attempts):
		var entry:AttemptEntry = preload("res://Scenes/UIElements/AttemptEntry.tscn").instantiate()
		
		var index := i + len(entries)
		entry.update(current_data.runs[index], index)
		
		attempt_box.add_child(entry)
	
	rank_lab.text = current_data.best_run.ranking_as_string()  if current_data.best_run != null else "-"
	rank_bonus_lab.visible = current_data.bonused

## Load the current level, play the opening animation.
func _on_quit_pressed() -> void:# if focused:
	
	Global.request_animation.emit("Game->Levels", false)
	
	var pause:PauseScreen = get_parent()
	if pause.paused:
		pause.toggle_pause()

func _on_resume_pressed() -> void:# if focused:

	var pause:PauseScreen = get_parent()
	if pause.paused:
		pause.toggle_pause()
