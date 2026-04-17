class_name AttemptEntry extends Panel
## Shows information about a single attempt.

@onready var attempt_lab := $MarginContainer/HBoxContainer/Attempt
@onready var time_lab    := $MarginContainer/HBoxContainer/VBoxContainer2/Time
@onready var score_lab   := $MarginContainer/HBoxContainer/VBoxContainer/Score
@onready var rank_lab    := $MarginContainer/HBoxContainer/Rank

var ready_buffer := []

func update(data:LevelData, index:int):
	
	if is_node_ready():
		attempt_lab.text = "ATTEMPT " + Global.digitize(index + 1, 3)
		time_lab.text    = Global.seconds_as_timer(data.times[index])
		score_lab.text   = Global.digitize(data.scores[index], 7)
		rank_lab.text    = data._get_ranking(data.times[index])
		
		ready_buffer = []
	else:
		ready_buffer = [data, index]

func _ready() -> void:
	if len(ready_buffer) > 0:
		update(ready_buffer[0], ready_buffer[1])
