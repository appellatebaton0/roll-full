class_name RankingBar extends HBoxContainer
## Displays an attempt's time as a ranking percentage.

@onready var bar              := $MarginContainer/Panel/Bar
@onready var label_container  := $LabelContainer
@onready var sample_label_box := $LabelContainer/LabelBox
var label_boxes:Dictionary[LevelData.RANKINGS, HBoxContainer]
var label_tweens:Dictionary[HBoxContainer, Tween]

var tween:Tween

func _ready() -> void:
	
	# Create all the label boxes from the sample.
	for i in LevelData.RANKINGS.keys().size():
		var new = sample_label_box.duplicate()
		label_boxes[i as LevelData.RANKINGS] = new
		label_container.add_child(new)
	sample_label_box.queue_free()
	
	update()

func update(level_data:LevelData = null, run:Variant = null):
	
	## Allow for inputting an int as the run.
	if run is int: run = level_data.runs[run]
	
	## Update the interface
	if level_data:
		var d := level_data.ranking_maximums[LevelData.RANKINGS.D]
		var s := level_data.ranking_maximums[LevelData.RANKINGS.S]
		
		var from_value:float = lerp(-d, -s, inv_lerp(bar.min_value, bar.max_value, bar.value))
		
		# Bar
		bar.min_value = -d
		bar.max_value = -s
		bar.value = from_value
		
		# Run time
		if run is LevelData.Run: tween_value_to(-run.time)
		else:                    tween_value_to(-d)
		
		# Label Boxes, has level data.
		for i in LevelData.RANKINGS.keys().size():
			var box := label_boxes[i as LevelData.RANKINGS]
			
			# Information
			box.get_child(0).text = ['S','A','B','C','D'][i]
			box.get_child(1).text = "<" + Global.seconds_as_timer(level_data.ranking_maximums[i], false)
			
			# Tween the new position
			var label_tween := label_tweens[box]
			
			if label_tween and label_tween.is_running(): label_tween.kill()
			
			label_tween = create_tween().set_trans(Tween.TRANS_QUAD)
			label_tween.tween_property(box, "position:y", lerp(0, 285, inv_lerp(s, d, level_data.ranking_maximums[i])), 0.1)
			
			label_tweens[box] = label_tween
	else:
		# Label Boxes, no level data.
		for i in LevelData.RANKINGS.keys().size():
			var box := label_boxes[i as LevelData.RANKINGS]
			
			# Information
			box.get_child(0).text = ['S','A','B','C','D'][i]
			box.get_child(1).text = "<--:--"
			
			# Tween the new position
			var label_tween := label_tweens[box] if label_tweens.has(box) else null
			
			if label_tween and label_tween.is_running(): label_tween.kill()
			
			label_tween = create_tween().set_trans(Tween.TRANS_QUAD)
			label_tween.tween_property(box, "position:y", lerp(0, 285, float(i) / (len(LevelData.RANKINGS.keys()) - 1)), 0.1)
			
			label_tweens[box] = label_tween

func tween_value_to(new_value:float):
	if tween and tween.is_running(): tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(bar, "value", new_value, 0.1)

func inv_lerp(a:float, b:float, t:float): return (t-a) / (b-a)
