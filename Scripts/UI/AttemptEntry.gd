class_name AttemptEntry extends Panel
## Shows information about a single attempt.

@onready var attempt_lab := $MarginContainer/HBoxContainer/Attempt
@onready var time_lab    := $MarginContainer/HBoxContainer/VBoxContainer2/Time
@onready var score_lab   := $MarginContainer/HBoxContainer/VBoxContainer/Score
@onready var rank_lab    := $MarginContainer/HBoxContainer/HBoxContainer/Rank
@onready var bonus_lab   := $MarginContainer/HBoxContainer/HBoxContainer/Bonused

var ready_buffer := []

func update(run:LevelData.Run, index:int):
	
	if is_node_ready():
		attempt_lab.text = "ATTEMPT " + Global.digitize(index + 1, 3)
		time_lab.text    = Global.seconds_as_timer(run.time)
		score_lab.text   = Global.digitize(run.score, 7)
		rank_lab.text    = run.ranking_as_string()
		bonus_lab.visible = run.bonused
		
		ready_buffer = []
	else:
		ready_buffer = [run, index]

func _ready() -> void:
	if len(ready_buffer) > 0:
		update(ready_buffer[0], ready_buffer[1])
