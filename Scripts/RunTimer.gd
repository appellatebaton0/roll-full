class_name RunTimer extends Label
## Manages the time taken in the current run.

@export var timer := 0.0
var running := false

func _ready() -> void:
	Global.run_timer = self
	Global.level_complete.connect(save)
	Global.reset_level.connect(reset)

func _process(delta: float) -> void:
	if running:
		timer += delta
	
	text = Global.seconds_as_timer(timer)

func save() -> void:
	if Global.current_data:
		Global.current_data.times += [timer]
		Global.current_data.scores += [Global.score]
	
	running = false
	timer = 0.0

func reset() -> void:
	running = true
	timer = 0.
	text = Global.seconds_as_timer(timer)
