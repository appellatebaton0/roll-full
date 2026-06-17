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

## The UndoRedo used for... undoing and redoing, duh.
@onready var undo_redo := UndoRedo.new()

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

## Selection Module
@onready var selection_name_lab      := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/Label2
@onready var selection_scale_spin    := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/VBoxContainer/Scale/SpinBox
@onready var selection_rotation_spin := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/VBoxContainer/Rotation/SpinBox
@onready var selection_delete_button := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/Button

@onready var spline_add_segment_button    := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/SplineButtons/SplineButton
@onready var spline_delete_segment_button := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/SplineButtons/SplineButton2
@onready var spline_button_box            := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/SplineButtons

## Undo Redo Module
@onready var undo := $MarginContainer/VBoxContainer/Layout/Panels/UndoRedo/MarginContainer/HBoxContainer2/Undo
@onready var redo := $MarginContainer/VBoxContainer/Layout/Panels/UndoRedo/MarginContainer/HBoxContainer2/Redo

## Music Tracks Module
@onready var music_track_buttons:Array[Button] = [
	$MarginContainer/VBoxContainer/Layout/Panels/MusicTracks/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/Button,
	$MarginContainer/VBoxContainer/Layout/Panels/MusicTracks/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/Button,
	$MarginContainer/VBoxContainer/Layout/Panels/MusicTracks/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer4/Button,
	$MarginContainer/VBoxContainer/Layout/Panels/MusicTracks/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer5/Button
]
@onready var open_music_folder_button := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Button2
@onready var refresh_music_button := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Button
@onready var music_panel := $PanelContainer
@onready var built_in_music_tree := $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/Tree
@onready var custom_music_tree   := $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer2/Tree

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
var sel_from_undo_redo := false
func _set_selection(to:ScenePlaceholder):
	
	selected = to
	
	## Update the module display.
	if selected:
		selection_name_lab.text = selected.display_name
		
		_set_selection_scale   (selected.scale.x,          false)
		_set_selection_rotation(selected.rotation_degrees, false)
		
		selection_scale_spin   .editable = true
		selection_rotation_spin.editable = true
	else:
		selection_name_lab.text = "None"
		
		_set_selection_scale   (1.0, false)
		_set_selection_rotation(1.0, false)
		
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
	refresh_music_button.pressed.connect(_update_music_track_options)
	
	_update_music_track_options()
	
	selection_rotation_spin.value_changed.connect(_set_selection_rotation.bind(true))
	selection_scale_spin.value_changed.connect(_set_selection_scale.bind(true))
	
	# Delete prefabs w/ the button.
	selection_delete_button.pressed.connect(func():
		if selected:
			prefabs.erase(selected)
			selected.queue_free()
			
			selected = null
		
		)
	# Add segments to a spline
	var add_segment := func(onto:SplinePlaceholder):
		var offset:Vector2 = 150 * (onto.line.points[onto.line.points.size() - 1] - onto.line.points[onto.line.points.size() - 2]).normalized()
		for i in 3:
			onto.line.add_point(onto.line.points[onto.line.points.size() - 1] + offset)
	var del_segment := func(onto:SplinePlaceholder):
		if onto.line.points.size() > 4:
			for i in 3:
				onto.line.remove_point(onto.line.points.size() - 1)
	
	spline_add_segment_button.pressed.connect(func():
		
		if selected is SplinePlaceholder:
			undo_redo.create_action("Add Segment")
			undo_redo.add_do_method(add_segment.bind(selected))
			undo_redo.add_undo_method(del_segment.bind(selected))
			undo_redo.commit_action()
		
		)
	spline_delete_segment_button.pressed.connect(func():
		if selected is SplinePlaceholder:
			undo_redo.create_action("Delete Segment")
			undo_redo.add_do_method(del_segment.bind(selected))
			undo_redo.add_undo_method(add_segment.bind(selected))
			undo_redo.commit_action()
			
		
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
	
	## Connect the undo and redo buttons to the UndoRedo.
	undo.pressed.connect(func(): 
		undo_redo.undo()
		_update_undo_redo_buttons()
	)
	redo.pressed.connect(func(): 
		undo_redo.redo()
		_update_undo_redo_buttons()
	)
	# Update the buttons' disabled states when the version changes
	undo_redo.version_changed.connect(_update_undo_redo_buttons)
	_update_undo_redo_buttons()

func _update_undo_redo_buttons() -> void:
	
	#print("# -- VERSION HISTORY -- #")
	#for i in undo_redo.get_history_count():
		#print(undo_redo.get_action_name(i))
		
	undo.disabled = not undo_redo.has_undo()
	redo.disabled = not undo_redo.has_redo()

## Update the list of available music tracks
func _update_music_track_options() -> void:
	
	var path_dictionary:Dictionary[TreeItem, StringName]
	
	## Built-in Music
	built_in_music_tree.clear()
	# Make the root
	built_in_music_tree.create_item()
	built_in_music_tree.hide_root = true
	# Fill the tree
	path_dictionary.merge(dir_to_tree(built_in_music_tree.get_root(), "res://Assets/Music/"))
	
	## Custom Music
	custom_music_tree.clear()
	# Make the root
	custom_music_tree.create_item()
	custom_music_tree.hide_root = true
	# Fill the tree
	path_dictionary.merge(dir_to_tree(custom_music_tree.get_root(), "user://Music/"))
	
	


func dir_to_tree(item:TreeItem, path:String) -> Dictionary[TreeItem, StringName]:
		
		var path_dictionary:Dictionary[TreeItem, StringName]
		
		var dir = DirAccess.open(path)
		
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					# Make an item for the new directory.
					var dir_item := item.create_child()
					
					dir_item.set_text(0, file_name)
					
					# Add it to the pathdict
					path_dictionary[dir_item] = path + file_name + "/"
					
					# Search down the rest of the directory.
					path_dictionary.merge(dir_to_tree(dir_item, path + file_name + "/"))
				else:
					# If the file is an AudioStream, load it to the tree.
					if file_name.contains(".import"): 
						file_name = dir.get_next()
						continue
					var file := ResourceLoader.load(ProjectSettings.globalize_path(path + file_name))
					print(path + file_name)
					
					if file and file is AudioStream:
						print(" -> ", file.get_class())
						var file_item := item.create_child()
						
						file_item.set_text(0, file_name)
						
						path_dictionary[file_item] = path + file_name
					
				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access the path.")
		
		return path_dictionary

# UndoRedo-supporting wrappers for setting the selection's scale & rotation
func _set_selection_scale(to:float, via_undo_redo := true):
	if selected:
		if via_undo_redo:
			undo_redo.create_action("Set Selection Scale")
			undo_redo.add_do_property(selection_scale_spin, "value", to)
			undo_redo.add_do_property(selected, "scale", Vector2.ONE * to)
			undo_redo.add_undo_method(selection_scale_spin.set_value_no_signal.bind(selected.scale.x))
			undo_redo.add_undo_property(selected, "scale", selected.scale)
			undo_redo.commit_action()
		else:
			selection_scale_spin.set_value_no_signal(to)
			selected.scale = Vector2.ONE * to
func _set_selection_rotation(to:float, via_undo_redo := true):
	if selected:
		if via_undo_redo:
			undo_redo.create_action("Set Selection Rotation")
			undo_redo.add_do_property(selection_rotation_spin, "value", to)
			undo_redo.add_do_property(selected, "rotation_degrees", to)
			undo_redo.add_undo_method(selection_rotation_spin.set_value_no_signal.bind(selected.rotation_degrees))
			undo_redo.add_undo_property(selected, "rotation_degrees", selected.rotation_degrees)
			undo_redo.commit_action()
		else:
			selection_rotation_spin.set_value_no_signal(to)
			selected.rotation_degrees = to
		
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
var soft_delete_buffer:Array[ScenePlaceholder]
func _on_prefab_button_pressed(scene_path: StringName) -> void:
	
	var delete_prefab := func(prefab:ScenePlaceholder):
		prefabs.erase(prefab)
		soft_delete_buffer.push_back(prefab)
		prefab.hide()
		#prefab.queue_free()
	
	create_prefab(scene_path)
	
	undo_redo.create_action("Create Prefab")
	undo_redo.add_do_method(soft_create_prefab)
	undo_redo.add_undo_method(func(): delete_prefab.call(prefabs.back()))
	undo_redo.commit_action(false)

func soft_create_prefab():
	var new := soft_delete_buffer.pop_back() as ScenePlaceholder
	
	new.show()
	prefabs.append(new)

func create_prefab(scene_path) -> ScenePlaceholder:
	
	var new := load(scene_path).instantiate() as ScenePlaceholder
		
	viewport.add_child(new)
	new.position = viewport_camera.position
	
	prefabs.append(new)
	selected = new
	
	new.selected.connect(_set_selection.bind(new))
	
	new.drag_ended.connect(func(from:Vector2, to:Vector2):
		# Plug drags into the UR
		
		undo_redo.create_action("Moved Prefab")
		undo_redo.add_do_property  (new, "global_position", to)
		undo_redo.add_undo_property(new, "global_position", from)
		undo_redo.commit_action()
		
		)
	
	# Hook spline line changes up to the UndoRedo
	if new is SplinePlaceholder:
		print("!")
		new.points_changed.connect(func(from:PackedVector2Array, to:PackedVector2Array):
			print(":D")
			undo_redo.create_action("Moved Spline Points")
			undo_redo.add_do_property(new.line, "points", to)
			undo_redo.add_undo_property(new.line, "points", from)
			undo_redo.commit_action(false)
			
			)
	
	return new
