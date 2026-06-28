class_name LevelCreationScreen extends Panel
## Manages the level creation screen.

const CUSTOM_DATA_PATH := "user://CustomLevelData"
const ENTRY_SCENE := preload("res://Scenes/UIElements/CustomLevelEntry.tscn")

static var working_data:LevelData: set = set_working_data
func set_working_data(to:LevelData):
	working_data = to

	# Reset all the modules to their correct base values.
	if working_data:
		
		if not is_node_ready(): await ready
		
		## Rank Threshold
		for spin_box in rank_threshold_spin_boxes:
			spin_box.set_value_no_signal(working_data.ranking_maximums[rank_threshold_spin_boxes[spin_box]])
		f_rank_label.text = "> %s sec" % int(working_data.ranking_maximums[LevelData.RANKINGS.D])
		
		## Score and Base Speed
		score_spin_box       .value = working_data.score_threshold
		player_speed_spin_box.value = working_data.base_player_speed
		
		## Level Name
		level_name_edit.text = working_data.name
		old_name = working_data.name

static var level_data:Array[LevelData]
var entries:Array[CustomLevelEntry]

@onready var selector := $HBoxContainer/Selector
@onready var animator := $AnimationPlayer
@onready var editor   := $LevelEditor

#region Right-Side Controls.
## Level Name
var old_name := ""
@onready var level_name_edit := $HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Label

## Rank Threshold Module
@onready var rank_threshold_spin_boxes:Dictionary[SpinBox, LevelData.RANKINGS] = {
	$HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Ranking/MarginContainer/VBoxContainer/HBoxContainer2/OptionButton: LevelData.RANKINGS.S,
	$HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Ranking/MarginContainer/VBoxContainer/HBoxContainer3/OptionButton: LevelData.RANKINGS.A,
	$HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Ranking/MarginContainer/VBoxContainer/HBoxContainer4/OptionButton: LevelData.RANKINGS.B,
	$HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Ranking/MarginContainer/VBoxContainer/HBoxContainer5/OptionButton: LevelData.RANKINGS.C,
	$HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Ranking/MarginContainer/VBoxContainer/HBoxContainer6/OptionButton: LevelData.RANKINGS.D,
}
@onready var f_rank_label := $HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Ranking/MarginContainer/VBoxContainer/HBoxContainer7/Label2

## Base Player Speed Module
@onready var player_speed_spin_box := $HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Speed/MarginContainer/VBoxContainer/SpinBox

## Score Threshold Module
@onready var score_spin_box := $HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/Score/MarginContainer/VBoxContainer/SpinBox
#endregion

## Command Buttons (Edit/Delete/New)
@onready var edit_button := $HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer2/Edit
@onready var del_button  := $HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer2/Delete
@onready var new_button  := $HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer2/New

func _ready() -> void:
	
	# Make sure the level data folder exists.
	assure_user_directory("user://CustomLevelData")
	
	# Load the custom levels that already exist into the array.
	level_data = Global.get_level_data(CUSTOM_DATA_PATH)
	
	selector.data = level_data
	selector.create_level_entries()
	
	## Command Buttons
	edit_button.pressed.connect(func(): if working_data:
		
		animator.play("ToEditorIn")
		
		await animator.animation_finished
		
		
		
		animator.play("ToEditorOut")
	
		)
	
	#region Right-Side Settings
	
	## Level Name Change
	level_name_edit.editing_toggled.connect(func(to):
		if working_data and not to:
			
			if level_name_edit.text == "" or name_exists(level_name_edit.text):
				working_data.name    = old_name
				level_name_edit.text = old_name
			else:
				working_data.name = level_name_edit.text
				old_name = level_name_edit.text
				
			selector.find_entry_for_data(working_data)._on_runs_updated()
		
		)
	
	## Change the score threshold w/ the spinbox.
	score_spin_box.value_changed.connect(func(to:float):
		if working_data:
			working_data.score_threshold = int(to)
			
		)
	
	## Change the base speed w/ the spinbox.
	player_speed_spin_box.value_changed.connect(func(to:float):
		if working_data:
			working_data.base_player_speed = int(to)
	)
	
	## Change rank thresholds w/ their spinboxes.
	var rank_threshold_update := func(to:float, rank:LevelData.RANKINGS):
		if working_data:
			working_data.ranking_maximums[rank] = to
			
			for i in 5:
				for rk in 5:
					if rk > 0:
						working_data.ranking_maximums[rk] = max(working_data.ranking_maximums[rk], working_data.ranking_maximums[rk - 1] + 1)
					if rk < 4:
						working_data.ranking_maximums[rk] = min(working_data.ranking_maximums[rk], working_data.ranking_maximums[rk + 1] - 1)
			
			for spin_box in rank_threshold_spin_boxes:
				spin_box.set_value_no_signal(working_data.ranking_maximums[rank_threshold_spin_boxes[spin_box]])
			
			f_rank_label.text = "> %s sec" % int(working_data.ranking_maximums[LevelData.RANKINGS.D])
	for spin_box in rank_threshold_spin_boxes:
		spin_box.value_changed.connect(rank_threshold_update.bind(rank_threshold_spin_boxes[spin_box]))
	
	#endregion

## Update the contents of CUSTOM_DATA_PATH to reflect any changes to the files.
# Ran when the player clicks to go back to the main menu.
func update_custom_level_files() -> void:
	
	print("REMOVIN'")
	#region Remove all the existing files.
	
	# Get all the paths to existing files.
	
	var file_paths:Array[StringName]
	
	var dir = DirAccess.open(CUSTOM_DATA_PATH)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			## REMAPN'T
			file_name = file_name.replace(".remap", "")
			
			if not dir.current_is_dir() and file_name.contains(".tres"):
				file_paths.append(CUSTOM_DATA_PATH + "/" + file_name)
			file_name = dir.get_next()
	
	# Delete all said files.
	for path in file_paths: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	
	#endregion
	
	print("SAVIN'")
	## Save the level_data currently loaded into CUSTOM_DATA_PATH.
	for data in level_data:
		print("saving ", data, "\t to ", CUSTOM_DATA_PATH + "/" + data.name + ".tres")
		ResourceSaver.save(data, CUSTOM_DATA_PATH + "/" + data.name + ".tres")

## Make sure a directory exists. If not, make it.
func assure_user_directory(path:StringName) -> Error:
	if not DirAccess.dir_exists_absolute(path):
		return DirAccess.make_dir_absolute(path)
	return Error.OK

static func name_exists(level_name:String):
	for data in level_data + Global.LEVEL_DATA:
		if data.name == level_name: return true
	return false
