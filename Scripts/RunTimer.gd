class_name RunTimer extends Label
## Manages the time taken in the current run, and saving the time and score.

@export var timer := 0.0
var running := false
@export var can_save := true

func _ready() -> void:
	Global.run_timer = self
	Global.level_complete.connect(save)
	Global.reset_level.connect(reset)

func _process(delta: float) -> void:
	if running:
		timer += delta
	
	text = Global.seconds_as_timer(timer)

func save() -> void: if can_save:
	if Global.current_data:
		Global.current_data.log_run(timer, Global.score)
	Global.score = 0
	
	running = false
	timer = 0.0
	
	Global._save()

func reset() -> void:
	running = true
	timer = 0.
	text = Global.seconds_as_timer(timer)
