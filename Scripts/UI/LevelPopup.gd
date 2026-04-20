class_name LevelPopup extends MarginContainer
## Manages the popup that appears when you click on a level.

@onready var best_time_lab  := $Panel/MarginContainer/VBoxContainer/HBoxContainer/BestTime
@onready var best_score_lab := $Panel/MarginContainer/VBoxContainer/HBoxContainer/BestScore

@onready var level_name_lab := $Panel/MarginContainer/VBoxContainer/LevelName
@onready var attempt_box    := $Panel/MarginContainer/VBoxContainer/ScrollContainer/AttemptBox

@onready var rank_star      := $Panel/Polygon2D
@onready var rank_box       := $Panel/Polygon2D/HBoxContainer
@onready var rank_lab       := $Panel/Polygon2D/HBoxContainer/Rank
@onready var rank_bonus_lab := $Panel/Polygon2D/HBoxContainer/Label

@onready var play_button    := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/PlayButton
@onready var back_button    := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/BackButton

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
@export var focused := false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _process(delta: float) -> void:
	rank_star.rotate(delta * 0.7)
	
	rank_box.rotation = -rank_star.rotation
	rank_box.pivot_offset = rank_box.size / 2

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
func _on_play_pressed() -> void: if focused:
	
	Global.request_animation.emit("Levels->Game")
	
	var level = current_data.scene.instantiate()
	
	level_root.add_child(level)
	
	Global.current_level = level
	Global.current_data  = current_data
	
	Global.run_timer.reset()

func _on_back_pressed() -> void: if focused:

	if not animator.is_playing():
		animator.play("ClosePopup")
