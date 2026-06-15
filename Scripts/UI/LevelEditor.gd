class_name LevelEditor extends PanelContainer
## Manages most if not all of the functionality for the LevelEditor.

## The LevelData currently being worked on. Should be set by the selection screen.
var working_data:LevelData:
	set(to):
		working_data = to
		
		# Reset all the modules to their correct base values.
		if working_data:
			
			update_zoom_to(1.0)
			
			## Rank Threshold
			for spin_box in rank_threshold_spin_boxes:
				spin_box.set_value_no_signal(working_data.ranking_maximums[rank_threshold_spin_boxes[spin_box]])
			f_rank_label.text = "> %s sec" % int(working_data.ranking_maximums[LevelData.RANKINGS.D])
			
			## Score and Base Speed
			score_spin_box       .value = working_data.score_threshold
			player_speed_spin_box.value = working_data.base_player_speed
			
			## Level Name
			level_name_edit.text = working_data.name

## Level Name
@onready var level_name_edit := $MarginContainer/VBoxContainer/HBoxContainer/TextEdit

## Viewport variables
@onready var viewport_container := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer
@onready var viewport_camera    := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer/SubViewport/Camera
@onready var viewport           := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer/SubViewport

## -- Module Variables -- ##

## Zoom Module
@onready var zoom_spin_box := $MarginContainer/VBoxContainer/Layout/Panels/Zoom/MarginContainer/HBoxContainer2/HBoxContainer/SpinBox
@onready var zoom_slider   := $MarginContainer/VBoxContainer/Layout/Panels/Zoom/MarginContainer/HBoxContainer2/HSlider

## Base Player Speed Module
@onready var player_speed_spin_box := $MarginContainer/VBoxContainer/Layout/Panels/Speed/MarginContainer/VBoxContainer/SpinBox

## Score Threshold Module
@onready var score_spin_box := $MarginContainer/VBoxContainer/Layout/Panels/Score/MarginContainer/VBoxContainer/SpinBox

## Rank Threshold Module
@onready var rank_threshold_spin_boxes:Dictionary[SpinBox, LevelData.RANKINGS] = {
	$MarginContainer/VBoxContainer/Layout/Panels/Ranking/MarginContainer/VBoxContainer/HBoxContainer2/OptionButton: LevelData.RANKINGS.S,
	$MarginContainer/VBoxContainer/Layout/Panels/Ranking/MarginContainer/VBoxContainer/HBoxContainer3/OptionButton: LevelData.RANKINGS.A,
	$MarginContainer/VBoxContainer/Layout/Panels/Ranking/MarginContainer/VBoxContainer/HBoxContainer4/OptionButton: LevelData.RANKINGS.B,
	$MarginContainer/VBoxContainer/Layout/Panels/Ranking/MarginContainer/VBoxContainer/HBoxContainer5/OptionButton: LevelData.RANKINGS.C,
	$MarginContainer/VBoxContainer/Layout/Panels/Ranking/MarginContainer/VBoxContainer/HBoxContainer6/OptionButton: LevelData.RANKINGS.D,
}
@onready var f_rank_label := $MarginContainer/VBoxContainer/Layout/Panels/Ranking/MarginContainer/VBoxContainer/HBoxContainer7/Label2

## Custom Music Folder Module
@onready var open_music_folder_button := $MarginContainer/VBoxContainer/Layout/Panels/MusicTracks/MarginContainer/VBoxContainer/Button

## Selection Module
@onready var selection_name_lab      := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/Label2
@onready var selection_scale_spin    := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/VBoxContainer/Scale/SpinBox
@onready var selection_rotation_spin := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/VBoxContainer/Rotation/SpinBox
@onready var selection_delete_button := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/Button

@onready var spline_add_segment_button    := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/SplineButtons/SplineButton
@onready var spline_delete_segment_button := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/SplineButtons/SplineButton2
@onready var spline_button_box            := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/SplineButtons

## Tabs
@onready var tabs := $MarginContainer/VBoxContainer/HBoxContainer/TabBar
@onready var modules:Dictionary[String, PanelContainer] = {
	"Zoom":        $MarginContainer/VBoxContainer/Layout/Panels/Zoom,
	"Prefabs":     $MarginContainer/VBoxContainer/Layout/Panels/Prefabs,
	"Selection":   $MarginContainer/VBoxContainer/Layout/Panels/Selection,
	"UndoRedo":    $MarginContainer/VBoxContainer/Layout/Panels/UndoRedo,
	"Speed":       $MarginContainer/VBoxContainer/Layout/Panels/Speed,
	"MusicTracks": $MarginContainer/VBoxContainer/Layout/Panels/MusicTracks,
	"Ranking":     $MarginContainer/VBoxContainer/Layout/Panels/Ranking,
	"Score":       $MarginContainer/VBoxContainer/Layout/Panels/Score
}

var selected :ScenePlaceholder: set = _set_selection
func _set_selection(to:ScenePlaceholder):
	selected = to
	
	## Update the module display.
	if selected:
		selection_name_lab.text = selected.display_name
		
		selection_scale_spin   .value = selected.scale.x
		selection_rotation_spin.value = selected.rotation_degrees
		
		selection_scale_spin   .editable = true
		selection_rotation_spin.editable = true
	else:
		selection_name_lab.text = "None"
		
		selection_scale_spin   .value = 1.0
		selection_rotation_spin.value = 1.0
		
		selection_scale_spin   .editable = false
		selection_rotation_spin.editable = false
	
	spline_button_box.visible = selected is SplinePlaceholder

func _ready() -> void:
	# NOTE: For debugging.
	working_data = LevelData.new()
	
	
	## Connect the input detection from the viewport for scrolling.
	viewport_container.gui_input.connect(_viewport_gui_input)
	
	## Level Name Change
	level_name_edit.text_changed.connect(func(to):
		if working_data:
			working_data.name = to
	)
	
	## Hook up the zoom module to update the camera and itself.
	zoom_slider  .value_changed.connect(update_zoom_to)
	zoom_spin_box.value_changed.connect(update_zoom_to)
	update_zoom_to(0.4)
	
	## Change the base speed w/ the spinbox.
	player_speed_spin_box.value_changed.connect(func(to:float):
		if working_data:
			working_data.base_player_speed = int(to)
	)
	
	
	## Change the score threshold w/ the spinbox.
	score_spin_box.value_changed.connect(func(to:float):
		if working_data:
			working_data.score_threshold = int(to)
			
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
	
	
	## Custom Music Folder opening.
	open_music_folder_button.pressed.connect(func():
		# Make the folder if it don't exist.
		if not DirAccess.dir_exists_absolute("user://Music"):
			DirAccess.make_dir_absolute("user://Music")
		
		# Open that there folder.
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://Music"))
	)
	
	## Change placeholder properties w/ the spins.
	selection_scale_spin.value_changed.connect(func(to):
		if selected:
			selected.scale = Vector2.ONE * to
		)
	selection_rotation_spin.value_changed.connect(func(to):
		if selected:
			selected.rotation_degrees = to
		)
	# Delete prefabs w/ the button.
	selection_delete_button.pressed.connect(func():
		if selected:
			prefabs.erase(selected)
			selected.queue_free()
			
			selected = null
		
		)
	# Add segments to a spline
	spline_add_segment_button.pressed.connect(func():
		
		if selected is SplinePlaceholder:
			var offset:Vector2 = 150 * (selected.line.points[selected.line.points.size() - 1] - selected.line.points[selected.line.points.size() - 2]).normalized()
			for i in 3:
				selected.line.add_point(selected.line.points[selected.line.points.size() - 1] + offset)
		
		)
	spline_delete_segment_button.pressed.connect(func():
		if selected is SplinePlaceholder: if selected.line.points.size() > 4:
			for i in 3:
				selected.line.remove_point(selected.line.get_point_count() - 1)
			
		
		)
	
	selected = null
	
	## Change visible modules w/ tab.
	tabs.tab_selected.connect(func(index:int):
		
		var tab_modules:Array[Array] = [
			["Zoom", "Prefabs", "Selection", "UndoRedo"], # Layout
			["Zoom", "Speed", "MusicTracks", "Ranking", "Score"]
		]
		
		for module in modules:
				modules[module].visible = tab_modules[index].has(module)
		
		for prefab in prefabs:
			prefab.can_be_held = not index
		
		)
	tabs.current_tab = 0


# Catch inputs into the viewport for camera scrolling and zooming.
func _viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			
			var direction:Vector2
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:    direction = Vector2.UP
				MOUSE_BUTTON_WHEEL_DOWN:  direction = Vector2.DOWN
				MOUSE_BUTTON_WHEEL_LEFT:  direction = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_RIGHT: direction = Vector2.RIGHT
				_: return
			
			if event.ctrl_pressed:
				zoom_slider.value -= direction.y * 0.03
				return
			
			if event.shift_pressed: direction = direction.rotated(PI / 2)
			
			viewport_camera.position += direction * 15 / viewport_camera.zoom

func update_zoom_to(value:float):
	viewport_camera.zoom = Vector2.ONE * value
	if zoom_slider.value   != value: zoom_slider.value   = value
	if zoom_spin_box.value != value: zoom_spin_box.value = value

var prefabs:Array[ScenePlaceholder]
func _on_prefab_button_pressed(scene_path: StringName) -> void:
	
	var new:ScenePlaceholder = load(scene_path).instantiate()
	
	viewport.add_child(new)
	new.position = viewport_camera.position
	
	prefabs.append(new)
	selected = new
	
	new.selected.connect(_set_selection.bind(new))
