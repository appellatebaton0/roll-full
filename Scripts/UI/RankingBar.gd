class_name RankingBar extends HBoxContainer
## Displays an attempt's time as a ranking percentage.

@onready var bar              := $MarginContainer/Panel/Bar
@onready var label_container  := $LabelContainer
@onready var sample_label_box := $LabelContainer/LabelBox
var label_boxes:Dictionary[LevelData.RANKINGS, HBoxContainer]

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
		
		# Bar
		bar.min_value = -d
		bar.max_value = -s
		
		# Run time
		if run is LevelData.Run: bar.value = -run.time
		else: bar.value = -d
		
		# Label Boxes, has level data.
		for i in LevelData.RANKINGS.keys().size():
			var box := label_boxes[i as LevelData.RANKINGS]
			
			# Information
			box.get_child(0).text = ['S','A','B','C','D'][i]
			box.get_child(1).text = "<" + Global.seconds_as_timer(level_data.ranking_maximums[i], false)
			
			# Position
			box.position.y = lerp(0, 285, inv_lerp(s, d, level_data.ranking_maximums[i]))
	else:
		# Label Boxes, no level data.
		for i in LevelData.RANKINGS.keys().size():
			var box := label_boxes[i as LevelData.RANKINGS]
			
			# Information
			box.get_child(0).text = ['S','A','B','C','D'][i]
			box.get_child(1).text = "<--:--"
			
			# Position
			box.position.y = lerp(0, 285, float(i) / (len(LevelData.RANKINGS.keys()) - 1))
		
func inv_lerp(a:float, b:float, t:float): return (t-a) / (b-a)
