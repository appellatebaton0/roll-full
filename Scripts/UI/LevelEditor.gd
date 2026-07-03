class_name LevelEditor extends PanelContainer
## Manages most if not all of the functionality for the LevelEditor.

## Emitted when the level is done being edited, and the working data is all up-to-date.
signal finished_editing

## The LevelData currently being worked on. Should be set by the selection screen.
var working_data:LevelData:
	set(to):
		working_data = to
		
		
		if working_data:
			
			if not is_node_ready(): await ready
			
			## Reset all the modules to their correct base values.
			
			update_zoom_to(1.0)
			
			## Rank Threshold
			for spin_box in rank_threshold_spin_boxes:
				spin_box.set_value_no_signal(working_data.ranking_maximums[rank_threshold_spin_boxes[spin_box]])
			f_rank_label.text = "> %s sec" % int(working_data.ranking_maximums[LevelData.RANKINGS.D])
			
			## Score and Base Speed
			score_spin_box       .value = working_data.score_threshold
			player_speed_spin_box.value = working_data.base_player_speed / 100.
			
			## Level Name
			level_name_edit.text = working_data.name
			old_name = working_data.name
			
			## Music Track Names
			for i in working_data.tracks: if working_data.tracks[i]: if working_data.tracks[i].resource_path: 
				
				# Turn the path into just the filename -> 'res://some/path/file.ogg' -> 'file.ogg'
				var filename := Array(working_data.tracks[i].resource_path.split("/")).back() as String
				
				music_track_buttons[i].text = filename
			
			## Load the editor_scene into the editor, if there is one.
			_load_editor_scene()

## The UndoRedo used for... undoing and redoing, duh.
@onready var undo_redo := UndoRedo.new()

## Level Name
@onready var level_name_edit := $MarginContainer/VBoxContainer/HBoxContainer/TextEdit
var old_name:String

## Viewport variables
@onready var viewport_container := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer
@onready var viewport           := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer/BuildViewport
@onready var viewport_camera    := (func() -> Camera2D:
	for child in viewport.get_children(): if child is Camera2D: return child
	return null).call() as Camera2D # Gets the camera live from the build viewport.
@onready var demo_container     := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer2
@onready var demo_viewport      := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer2/TestViewport

## Top Right Buttons
@onready var test_button := $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Button
@onready var fini_button := $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Button2

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
@onready var selection_delete_button := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/Button2
@onready var selection_dupe_button   := $MarginContainer/VBoxContainer/Layout/Panels/Selection/MarginContainer/HBoxContainer/Button

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
@onready var bpm_spin_box := $MarginContainer/VBoxContainer/Layout/Panels/MusicTracks/MarginContainer/VBoxContainer/HBoxContainer3/SpinBox
# Music panel
var mp_from_button:Button # The button used to open the panel.
var selected_track_path:String: # The path to the file of the selected track in the panel.
	set(to):
		if to == null:
			select_track_button.text = "Select Track"
		else:
			select_track_button.text = "Select Track (%s)" % (to.split("/") as Array[String]).back()
		
		selected_track_path = to

@onready var music_panel              := $PanelContainer
@onready var select_track_button      := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Button
@onready var open_music_folder_button := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Button2
@onready var built_in_music_tree      := $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/Tree
@onready var custom_music_tree        := $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer2/Tree
@onready var refresh_music_button     := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Button

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


var selected:ScenePlaceholder: set = _set_selection
var sel_from_undo_redo := false
func _set_selection(to:ScenePlaceholder):
	
	selected = to
	
	## Update the module display.
	if selected:
		selection_name_lab.text = selected.display_name
		
		_set_selection_scale   (selected.scale.x,          false)
		_set_selection_rotation(selected.rotation_degrees, false)
		
		selection_scale_spin   .editable = selected.scalable
		selection_rotation_spin.editable = selected.rotatable
	else:
		selection_name_lab.text = "None"
		
		_set_selection_scale   (1.0, false)
		_set_selection_rotation(1.0, false)
		
		selection_scale_spin   .editable = false
		selection_rotation_spin.editable = false
	
	selection_dupe_button.disabled   = not (selected and prefabs.has(selected))
	selection_delete_button.disabled = not (selected and selected.deletable)
	
	spline_button_box.visible = selected is SplinePlaceholder

func _ready() -> void:
	
	initialize_prefabs(viewport.get_children())
	
	## Connect the input detection from the viewport for scrolling.
	viewport_container.gui_input.connect(_viewport_gui_input)
	
	## Level Name Change
	level_name_edit.editing_toggled.connect(func(to):
		if working_data and not to:
			
			if level_name_edit.text == "" or LevelCreationScreen.name_exists(level_name_edit.text):
				working_data.name    = old_name
				level_name_edit.text = old_name
			else:
				working_data.name = level_name_edit.text
				old_name = level_name_edit.text
	)
	
	## Finishing editing.
	fini_button.pressed.connect(func():
		
		# Save the placeholder and regular versions of the level to PackedScenes.
		_save_placeholder()
		_save_level()
		
		finished_editing.emit()
		
		)
	
	## Hook up the zoom module to update the camera and itself.
	zoom_slider  .value_changed.connect(update_zoom_to)
	zoom_spin_box.value_changed.connect(update_zoom_to)
	update_zoom_to(0.4)
	
	## Change the base speed w/ the spinbox.
	player_speed_spin_box.value_changed.connect(func(to:float):
		if working_data:
			working_data.base_player_speed = int(to * 100)
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
	
	
	## BPM Spinbox
	bpm_spin_box.value_changed.connect(func(to:float):
		if working_data: working_data.override_bpm = to
		
		#for i in working_data.tracks.size():
			#print(i, ": ", working_data.tracks[i])
		#print("bpm ", working_data.override_bpm)
		
		)
	
	## Music Track Selecting.
	select_track_button.pressed.connect(func(): 
		
		if working_data:
		
			if selected_track_path != null:
				var file := load_music(selected_track_path)
				var track_index := music_track_buttons.find(mp_from_button)
				
				working_data.tracks[track_index] = file
				
				mp_from_button.text = (selected_track_path.split("/") as Array[String]).back()
		
		_toggle_music_panel(false)
		
		)
	
	## Music Panel Opening
	var open_mp := func(button:Button):
		mp_from_button = button
		_toggle_music_panel(true)
	for button in music_track_buttons:
		button.pressed.connect(open_mp.bind(button))
	
	## Music Track Selecting
	for tree:Tree in [built_in_music_tree, custom_music_tree]:
		tree.item_selected.connect(_update_track_selection.bind(tree))
	
	## Custom Music Folder opening.
	open_music_folder_button.pressed.connect(func():
		# Make the folder if it don't exist.
		LevelCreationScreen.assure_user_directory("user://Music")
		
		# Open that there folder.
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://Music"))
	)
	refresh_music_button.pressed.connect(_update_music_track_options)
	
	_update_music_track_options()
	
	selection_rotation_spin.value_changed.connect(_set_selection_rotation.bind(true))
	selection_scale_spin.value_changed.connect(_set_selection_scale.bind(true))
	
	# Delete prefabs w/ the button.
	selection_delete_button.pressed.connect(func():
		if selected and selected.deletable:
			
			# Wire up adding/deleting to the undo_redo.
			undo_redo.create_action("Delete Prefab")
			undo_redo.add_do_method(soft_delete_prefab)
			undo_redo.add_undo_method(soft_create_prefab)
			undo_redo.commit_action()
		
		)
	
	# Duplicate prefabs w/ the button.
	selection_dupe_button.pressed.connect(func():
		
		if selected and prefabs.has(selected):
			var new := create_prefab("", selected.duplicate() as ScenePlaceholder)
			new.position = selected.position + Vector2.ONE * 40
			
			selected = new
		
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
		
		# Update all the prefabs; added and existing.
		for prefab in viewport.get_children().filter(func(a): return a is ScenePlaceholder):
			prefab.can_be_held = (not index) != (prefab is MusicSectionerPlaceholder)
		
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
	undo.disabled = not undo_redo.has_undo()
	redo.disabled = not undo_redo.has_redo()

## -- Music Functions -- ##

## Update the list of available music tracks
var music_path_dictionary:Dictionary[TreeItem, StringName]
func _update_music_track_options() -> void:
	
	## Built-in Music
	built_in_music_tree.clear()
	# Make the root
	built_in_music_tree.create_item()
	built_in_music_tree.hide_root = true
	# Fill the tree
	music_path_dictionary.merge(dir_to_tree(built_in_music_tree.get_root(), "res://Assets/Music/"))
	
	## Custom Music
	# Make sure the directory exists, first, so there's no error.
	LevelCreationScreen.assure_user_directory("user://Music/")
	custom_music_tree.clear()
	# Make the root
	custom_music_tree.create_item()
	custom_music_tree.hide_root = true
	# Fill the tree
	music_path_dictionary.merge(dir_to_tree(custom_music_tree.get_root(), "user://Music/"))

## Toggle the visibility of the music panel
var music_panel_tween:Tween
func _toggle_music_panel(to_state:bool = !music_panel.visible):
	if to_state == music_panel.visible: return
	
	if music_panel_tween and music_panel_tween.is_running(): music_panel_tween.kill()
	
	if to_state:
		music_panel.modulate.a = 0.0
		
		music_panel_tween = music_panel.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		music_panel_tween.tween_callback(music_panel.show)
		music_panel_tween.tween_property(music_panel, "modulate:a", 1.0, 0.1)
	else:
		music_panel.modulate.a = 1.0
		
		music_panel_tween = music_panel.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		music_panel_tween.tween_property(music_panel, "modulate:a", 0.0, 0.1)
		music_panel_tween.tween_callback(music_panel.hide)

func _update_track_selection(from:Tree):
	var item := from.get_selected()
	var path := music_path_dictionary[item]
	
	# Deselect the other tree's selection.
	for tree:Tree in [custom_music_tree, built_in_music_tree]:
		if tree != from: tree.deselect_all()
	
	# If the selected item is actually a music file, and not a directory,
	# make it the current selection.
	if path_is_music_file(path): selected_track_path = path

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
					dir_item.set_tooltip_text(0, "")
					
					# Add it to the pathdict
					path_dictionary[dir_item] = path + file_name + "/"
					
					# Search down the rest of the directory.
					path_dictionary.merge(dir_to_tree(dir_item, path + file_name + "/"))
				else:
					
					if path_is_music_file(file_name):
						var file_item := item.create_child()
						
						file_item.set_text(0, file_name)
						file_item.set_tooltip_text(0, "")
						
						path_dictionary[file_item] = path + file_name
					
				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access the path: ", path)
		
		return path_dictionary

func path_is_music_file(path:String) -> bool:
	return (path.contains(".ogg") or path.contains(".mp3") or path.contains(".wav")) and not path.contains(".import")

func load_music(path:String) -> AudioStream:
	var file:AudioStream
	
	# In userspace, needs special loading.
	if path.contains("user://"):
		
		if path.contains(".ogg"):
			file = AudioStreamOggVorbis.load_from_file(path)
		elif path.contains(".mp3"):
			file = AudioStreamMP3.load_from_file(path)
		elif path.contains(".wav"):
			file = AudioStreamWAV.load_from_file(path)
		
	# Otherwise, just use load()
	else:
		file = load(path)
	
	if not file.resource_path:
		file.resource_path = path
	
	return file

## -- Selection Property Setters -- ##

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

## -- Camera Control -- ##

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
				
				# Zoom in/out, relative to the mouse position.
				# This gets slid a bit sometimes because of the step, but that's alr.
				var mouse_pos:Vector2 = viewport_camera.get_global_mouse_position()
				zoom_slider.value -= direction.y * 0.03
				var new_mouse_pos :Vector2= viewport_camera.get_global_mouse_position()
				viewport_camera.position += mouse_pos - new_mouse_pos

				return
			
			if event.shift_pressed: direction = direction.rotated(PI / 2)
			
			viewport_camera.position += direction * 15 / viewport_camera.zoom

func update_zoom_to(value:float):
	
	if not is_node_ready(): await ready
	
	viewport_camera.zoom = Vector2.ONE * value
	if zoom_slider.value   != value: zoom_slider.value   = value
	if zoom_spin_box.value != value: zoom_spin_box.value = value


## -- Prefab Creation / Destruction -- ##

var prefabs:Array[ScenePlaceholder]
func _on_prefab_button_pressed(scene_path: StringName) -> void: create_prefab(scene_path)
func create_prefab(scene_path:String = "", override_for_hookup:ScenePlaceholder = null) -> ScenePlaceholder:
	
	var new := override_for_hookup if override_for_hookup else load(scene_path).instantiate() as ScenePlaceholder
		
	viewport.add_child(new)
	
	if not override_for_hookup:
		new.position = viewport_camera.position
	
	prefabs.append(new)
	new.deletable = true
	new.can_be_held = true
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
		new.points_changed.connect(func(from:PackedVector2Array, to:PackedVector2Array):
			undo_redo.create_action("Moved Spline Points")
			undo_redo.add_do_property(new.line, "points", to)
			undo_redo.add_undo_property(new.line, "points", from)
			undo_redo.commit_action(false)
			)
	
	# Wire up adding/deleting via the undo_redo to the undo_redo.
	undo_redo.create_action("Create Prefab")
	undo_redo.add_do_method(soft_create_prefab)
	undo_redo.add_undo_method(soft_delete_prefab)
	undo_redo.commit_action(false)
	
	return new

var soft_delete_buffer:Array[ScenePlaceholder]
func soft_delete_prefab(prefab:ScenePlaceholder = prefabs.back()):
	if not prefab: return
	
	prefabs.erase(prefab)
	soft_delete_buffer.push_back(prefab)
	prefab.hide()
	selected = null
func soft_create_prefab():
	# 'new'. Already exists.
	var new := soft_delete_buffer.pop_back() as ScenePlaceholder
	
	new.show()
	prefabs.append(new)
	
	selected = new

## -- Real Scene Loading/Save -- ## (stuff for turning the placeholders into the actual level, and back.)

# Load and unload the demo w/ the press of a button.
func _on_demo_button_toggled(toggled_on: bool) -> void:
	
	test_button.text = "STOP" if toggled_on else "TEST"
	
	if toggled_on:
		_load_to_viewport()
		
		demo_container.show()
	
	else:
		_unload_from_viewport()
		
		demo_container.hide()

var loaded_in_demo:Array[Node]

# Loads the currently-being-edited-on scene into the demo viewport.
func _load_to_viewport() -> void:
	
	var child_queue:Array[Node] # All the nodes to add to the view.
	
	# Background parallax thingy
	child_queue.append(preload('res://Scenes/RockBackground.tscn').instantiate())
	
	# Camera
	child_queue.append(Camera.new())
	
	# Modulate
	var canv_modu := CanvasModulate.new()
	canv_modu.color = Color("d4d4d4")
	child_queue.append(canv_modu)
	
	# Environment
	var world_env := WorldEnvironment.new()
	world_env.environment = preload("res://Assets/Resources/Environment.tres")
	child_queue.append(world_env)
	
	# Ambient Particles
	child_queue.append(preload("res://Scenes/AmbientParticles.tscn").instantiate())
	
	# Add all the prefab placeholders.
	for prefab:ScenePlaceholder in viewport.get_children().filter(func(a): return a is ScenePlaceholder and a.visible):
		var instance := prefab.get_instance()
		
		if instance is Player: instance.base_speed = working_data.base_player_speed
		
		child_queue.append(instance)
	
	# Reset the runtimer, among other things.
	Global.reset_level.emit()
	
	# Add everything to the demo viewport.
	for node in child_queue:
		demo_viewport.add_child(node)
	loaded_in_demo += child_queue

# Unloads all the nodes in the demo viewport.
func _unload_from_viewport() -> void:
	for child in loaded_in_demo:
		child.queue_free()
	loaded_in_demo.clear()
	
	# Reset the viewport freeze if the player is mid-countdown/reset anim.
	get_tree().paused = false

# Load the working_data.editor_scene into the editor viewport.
func _load_editor_scene() -> void:
	
	if not (working_data and working_data.editor_scene): return
	
	# Free *ALL* the viewport's children, since the editor_scene saves all.
	for child in viewport.get_children(): if child is ScenePlaceholder: child.queue_free()
	
	# Load in the editor_scene and give it to the viewport.
	var instance := working_data.editor_scene.instantiate()
	
	var resassigns := recur_assign_owner(instance)
	for child in instance.get_children():
		child.owner = null
		child.reparent(viewport)
	for node in resassigns:
		node.owner = viewport
	
	# Connect up all da signals.
	initialize_prefabs(viewport.get_children())

func initialize_prefabs(array:Array[Node]):
	for prefab in array: if prefab is ScenePlaceholder:
		if not prefab.selected.is_connected(_set_selection):
			prefab.selected.connect(_set_selection.bind(prefab))
		
		prefab.drag_ended.connect(func(from:Vector2, to:Vector2):
			# Plug drags into the UR
			
			undo_redo.create_action("Moved Prefab")
			undo_redo.add_do_property  (prefab, "global_position", to)
			undo_redo.add_undo_property(prefab, "global_position", from)
			undo_redo.commit_action()
		
		)
		
		prefab.can_be_held = prefab is not MusicSectionerPlaceholder
		
		if prefab is DeathBorderPlaceholder:
			prefab.points_changed.connect(func(from:PackedVector2Array, to:PackedVector2Array):
				
				undo_redo.create_action("Moved DeathBorder Points")
				undo_redo.add_do_property(prefab.polygon, "polygon", to)
				undo_redo.add_undo_property(prefab.polygon, "polygon", from)
				undo_redo.commit_action(false)
			)
		
		# Extra stuff for non-static prefabs.
		if not prefab.has_meta("StaticPrefab"):
			# Hook spline line changes up to the UndoRedo
			if prefab is SplinePlaceholder:
				prefab.points_changed.connect(func(from:PackedVector2Array, to:PackedVector2Array):
					undo_redo.create_action("Moved Spline Points")
					undo_redo.add_do_property(prefab.line, "points", to)
					undo_redo.add_undo_property(prefab.line, "points", from)
					undo_redo.commit_action(false)
					)
			
			# Wire up adding/deleting via the undo_redo to the undo_redo.
			undo_redo.create_action("Create Prefab")
			undo_redo.add_do_method(soft_create_prefab)
			undo_redo.add_undo_method(soft_delete_prefab)
			undo_redo.commit_action(false)

# Saves the placeholder version of the level into a 
# PackedScene, and gives it to the working data.
func _save_placeholder() -> void: if working_data:
	
	working_data.editor_scene = recur_pack(viewport, Node.new(), func(a): return a is ScenePlaceholder)

# Saves the real version of the level into a 
# PackedScene, and gives it to the working data.
func _save_level() -> void: if working_data:
	# Make sure the level is freshly loaded in the demo viewport. If it already is it needs to be reloaded.
	if loaded_in_demo.size():
		_unload_from_viewport()
		
		demo_container.hide()
	
	_load_to_viewport()
	
	var node := Node.new()
	node.add_to_group(&"Level", true)
	
	working_data.scene = recur_pack(demo_viewport, node, func(a): return loaded_in_demo.has(a))
	
	# Unload the demo that was loaded for packing.
	_unload_from_viewport()

## Packs a node's children into a PackedSceen with [to] as the root,
## without disturbing the original node at all.
func recur_pack(children_of:Node, to:Node, filter_function:Callable = func(_a):return true) -> PackedScene:
	
	# Move all the children to the target temporarily.
	var reassigns := recur_assign_owner(children_of)
	for child in children_of.get_children(): child.reparent(to)
	
	if filter_function: reassigns = reassigns.filter(filter_function)
	
	for node in reassigns: node.owner = to
	
	var scene := PackedScene.new()
	scene.pack(to)
	
	# Move all the children back and reassign the owner.
	for child in to.get_children(): 
		child.owner = null
		child.reparent(children_of)
	
	for node in reassigns: node.owner = children_of
	
	# Return the complete scene.
	return scene

## Get the nodes to assign a new owner to.
func recur_assign_owner(parent:Node, allowed_owners:Array[Node] = []) -> Array[Node]:
	var response:Array[Node] = []
	
	for child in parent.get_children():
		allowed_owners += [child]
		
		
		if not allowed_owners.has(child.owner):
			response += [child]
		
		response += recur_assign_owner(child, allowed_owners)
	
	return response
