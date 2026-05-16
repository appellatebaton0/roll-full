class_name AttemptEntry extends Button
## Shows information about a single attempt.

signal requested(run:LevelData.Run)

@onready var attempt_lab := $HBoxContainer/RunNumber
@onready var time_lab    := $HBoxContainer/Time
@onready var score_lab   := $HBoxContainer/Score
@onready var rank_lab    := $HBoxContainer/Rank
@onready var bonus_lab   := $HBoxContainer/Rank/Bonused
@onready var speed_lab   := $HBoxContainer/Speed

var ready_buffer := []
var run:LevelData.Run

func _pressed() -> void: requested.emit(run)

func update(set_run:LevelData.Run, index:int):
	run = set_run
	
	if is_node_ready():
		attempt_lab.text  = Global.digitize(index + 1, 3)
		time_lab.text     = Global.seconds_as_timer(run.time)
		score_lab.text    = Global.digitize(run.score, 4)
		rank_lab.text     = run.ranking_as_string()
		bonus_lab.visible = run.bonused
		speed_lab.text    = str(int(round(run.speed * 100))) + "%"
		
		ready_buffer = []
	else:
		ready_buffer = [run, index]

func _ready() -> void:
	if len(ready_buffer) > 0:
		update(ready_buffer[0], ready_buffer[1])
