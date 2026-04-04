class_name AttemptEntry extends Panel
## Shows information about a single attempt.

@onready var attempt_lab := $MarginContainer/HBoxContainer/Attempt
@onready var time_lab    := $MarginContainer/HBoxContainer/Time
@onready var rank_lab    := $MarginContainer/HBoxContainer/Rank

func update(data:LevelData, index:int):
	
	attempt_lab.text = "ATTEMPT " + Global.digitize(index, 3)
	time_lab.text    = "TIME: " + Global.seconds_as_timer(data.times[index])
	rank_lab.text    = data._get_ranking(data.times[index])
	
