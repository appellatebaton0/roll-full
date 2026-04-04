class_name LevelPopup extends MarginContainer
## Manages the popup that appears when you click on a level.

@onready var best_time_lab  := $Panel/MarginContainer/VBoxContainer/BestTime
@onready var level_name_lab := $Panel/MarginContainer/VBoxContainer/HBoxContainer/LevelName
@onready var attempt_box    := $Panel/MarginContainer/VBoxContainer/ScrollContainer/AttemptBox
@onready var rank_lab       := $Panel/MarginContainer/VBoxContainer/HBoxContainer/Rank

@onready var play_button    := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/PlayButton
@onready var back_button    := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/BackButton

@onready var level_root := get_tree().get_first_node_in_group("Main")

var current_data:LevelData

@export var animator:AnimationPlayer
@export var focused := false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)

func update_with(data:LevelData):
	
	current_data = data
	
	best_time_lab.text = "BEST TIME: " + Global.seconds_as_timer(data.best_time)
	
	level_name_lab.text = data.name
	
	# Update the attempt entries.
	var entries := attempt_box.get_children()
	var attempts = len(data.times)
	for i in range(len(entries)):
		var entry = entries[i]
		if entry is AttemptEntry:
			if attempts > 0:
				entry.update(data, i)
				attempts -= 1
			else:
				entry.queue_free()
	
	for i in range(attempts):
		var entry:AttemptEntry = preload("res://Scenes/UIElements/AttemptEntry.tscn").instantiate()
		
		entry.update(data, i + len(entries))
		
		attempt_box.add_child(entry)
	
	rank_lab.text = data.ranking

## Load the current level, play the opening animation.
func _on_play_pressed() -> void: if focused:
	
	Global.request_animation.emit("Levels->Game")
	
	var level = current_data.scene.instantiate()
	
	level_root.add_child(level)

func _on_back_pressed() -> void: if focused:

	if not animator.is_playing():
		animator.play("ClosePopup")
