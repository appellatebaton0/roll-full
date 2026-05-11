class_name ScoreDisplay extends VBoxContainer
## Displays all the info regarding scores and combos.

@onready var score_lab := $Score

@onready var combo_box := $ComboBox
@onready var combo_sep := $ComboSeperator
@onready var combo_tot := $ComboTotal

func _ready() -> void:
	Global.finished_combo.connect(_on_combo_finished)
	Global.trick_ended.connect(clear_combo_entries)
	Global.reset_level.connect(_on_reset)
	Global.starting_level.connect(_on_reset)
	
	_on_reset()

var mod_a := 1.0
func _process(delta: float) -> void:
	var rdelt := delta / Engine.time_scale
	var entries := combo_box.get_children().filter(_is_valid_entry)
	
	while len(entries) > 10:
		entries.pop_back().ending = true
	
	var fade_in := len(entries) > 0
	mod_a = move_toward(mod_a, 1.0 if fade_in else 0.0, rdelt * (3. if fade_in else 2.3))
	combo_sep.modulate.a = mod_a
	combo_tot.modulate.a = mod_a
	
	score_lab.text = Global.digitize(int(lerp(int(score_lab.text), Global.score, 0.2)), 7)

func _is_valid_entry(a): return a is ComboEntry and not a.ending

## When a new combo is performed;
func _on_combo_finished(combo:Global.Combo) -> void:
	# Add a ComboEntry to the combo_box
	push_combo_entry("+" + combo.name)
	
	# Update the score_buffer display
	combo_tot.text = str(Global.score_buffer)

## Create a new ComboEntry and add it to the box.
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
