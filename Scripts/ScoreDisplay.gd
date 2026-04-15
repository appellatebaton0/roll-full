class_name ScoreDisplay extends VBoxContainer
## Displays all the info regarding scores and combos.

@onready var score_lab := $Score

@onready var combo_box := $ComboBox
@onready var combo_sep := $ComboSeperator
@onready var combo_tot := $ComboTotal

func _ready() -> void:
	Global.finished_combo.connect(_on_combo_finished)
	Global.trick_ended.connect(_on_trick_ended)
	Global.reset_level.connect(_on_reset)
	
	_on_reset()

func _process(delta: float) -> void:
	var rdelt := delta / Engine.time_scale
	var entries := combo_box.get_children().filter(_is_entry)
	
	if len(entries) > 10:
		var ended = false
		for entry in entries: if entry is ComboEntry and not ended:
			if not entry.ending:
				entry.ending = true
				ended = true
	
	var fade_in := len(entries) > 0
	combo_sep.modulate.a = move_toward(combo_sep.modulate.a, 1.0 if fade_in else 0.0, rdelt * (3. if fade_in else 2.3))
	combo_tot.modulate.a = move_toward(combo_tot.modulate.a, 1.0 if fade_in else 0.0, rdelt * (3. if fade_in else 2.3))
	
	score_lab.text = str(int(lerp(int(score_lab.text), Global.score, 0.2)))

func _is_entry(a): return a is ComboEntry

func _on_combo_finished(combo:Global.Combo) -> void:
	
	#var score_worth := int(len(combo.key) * Global.ACTION_POINTS)
	
	push_combo_entry("+" + combo.name) #combo.name + " +" + str(score_worth) + " x" + str(combo.multiplier)
	
	combo_tot.text = str(Global.score_buffer)

func _on_trick_ended() -> void:
	clear_combo_entries()
	#score_lab.text = str(Global.score)

func push_combo_entry(text:String):
	var new = ComboEntry.new()
	
	new.real_text = text
	
	combo_box.add_child(new)
	combo_box.move_child(new, 0)

func clear_combo_entries():
	for child in combo_box.get_children():
		if child is ComboEntry:
			child.ending = true

func _on_reset() -> void:
	for child in combo_box.get_children():
		if child is ComboEntry: child.queue_free()
	
	score_lab.text = str(Global.score)
	
	combo_sep.modulate.a = 0.0
	combo_tot.modulate.a = 0.0
