class_name ComboEntry extends Label
## A fancy lil entry for a combo.

var end_font_size := 36.0
var real_text := ""

var transition_progress := 0.0

var ending := false
var real_ending := false

func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _process(delta: float) -> void:
	
	text = real_text if transition_progress > 0.5 else ""
	
	add_theme_font_size_override("font_size", lerp(2.0, end_font_size, clamp(transition_progress * 2, 0.0, 1.0)))
	modulate.a = clamp((transition_progress - 0.5) * 2.0, 0.0, 1.0)
	
	transition_progress = move_toward(transition_progress, 0.0 if real_ending else 1.0, delta * (1.5 if real_ending else 3.0))
	
	if ending and transition_progress == 1.0: real_ending = true
	
	if real_ending and transition_progress == 0.0:
		queue_free()
		real_ending = false # Stop from calling repeatedly while freeing.
