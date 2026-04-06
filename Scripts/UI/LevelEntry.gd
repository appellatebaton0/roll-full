class_name LevelEntry extends Button
## Provides an interface into a level.

@onready var level_name := $MarginContainer/HBoxContainer/LevelName
@onready var best_time := $MarginContainer/HBoxContainer/BestTime
@onready var ranking := $MarginContainer/HBoxContainer/Ranking

@export var level_data:LevelData:
	set(to):
		if level_data:
			level_data.times_updated.disconnect(_on_times_updated)
		
		level_data = to
		
		if level_data:
			level_data.times_updated.connect(_on_times_updated)
		_on_times_updated()
@export var locked := false:
	set(to):
		locked = to
		disabled = to

func _on_times_updated() -> void: if level_data:
	
	await ready
	
	level_name.text = level_data.name
	best_time.text = Global.seconds_as_timer(level_data.best_time)
	ranking.text = level_data.ranking
