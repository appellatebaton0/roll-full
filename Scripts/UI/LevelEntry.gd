class_name LevelEntry extends Button
## Provides an interface into a level.

@onready var level_name := $MarginContainer/HBoxContainer/LevelName
@onready var best_time := $MarginContainer/HBoxContainer/BestTime
@onready var best_score := $MarginContainer/HBoxContainer/BestScore
@onready var ranking := $MarginContainer/HBoxContainer/HBoxContainer/Rank
@onready var bonused := $MarginContainer/HBoxContainer/HBoxContainer/Label

var needs_update := false

@export var level_data:LevelData:
	set(to):
		if level_data:
			level_data.runs_updated.disconnect(_on_runs_updated)
		
		level_data = to
		
		if level_data:
			level_data.runs_updated.connect(_on_runs_updated)
		_on_runs_updated()
@export var locked := false:
	set(to):
		locked = to
		disabled = to

func _on_runs_updated() -> void: if level_data:
	
	if not is_node_ready():
		needs_update = true
		return
	
	level_name.text = level_data.name
	
	best_time.text = Global.seconds_as_timer(level_data.best_time)
	best_score.text = Global.digitize(level_data.best_score, 7)
	
	ranking.text = level_data.best_run.ranking_as_string()  if level_data.best_run != null else "-"
	bonused.modulate.a = (1.0 if level_data.best_run.bonused else 0.0) if level_data.best_run != null else 0.0

func _ready() -> void:
	if needs_update: _on_runs_updated()
