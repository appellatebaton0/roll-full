class_name LevelEntry extends Button
## Provides an interface into a level.

@onready var level_name := $MarginContainer/HBoxContainer/LevelName
@onready var ranking := $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Rank
@onready var bonused := $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Bonused

var needs_update := false

@export var level_data:LevelData:
	set(to):
		if level_data:
			level_data.runs_updated.disconnect(_on_runs_updated)
		
		level_data = to
		
		if level_data:
			level_data.runs_updated.connect(_on_runs_updated)
		_on_runs_updated()

@export var selected := false

func _on_runs_updated() -> void: if level_data:
	
	if not is_node_ready():
		needs_update = true
		return
	
	level_name.text = level_data.name
	
	ranking.text = level_data.best_run.ranking_as_string()  if level_data.best_run != null else "-"
	bonused.modulate.a = (1.0 if level_data.best_run.bonused else 0.0) if level_data.best_run != null else 0.0

func _ready() -> void: if needs_update: _on_runs_updated()

func _process(delta: float) -> void:
	pivot_offset = Vector2(0, size.y / 2)
	scale.x = move_toward(scale.x, 1.1 if selected else 1., delta * 2.)
	scale.y = move_toward(scale.y, 1.1 if selected else 1., delta * 2.)
