class_name MainMusicDriver extends Node
## Handles all the music happening in the level.

@export var menu_player:AudioStreamPlayer
var menu_bpm := -1
var menu_beat := 0.0:
	set(to):
		menu_beat_delta = abs(to - menu_beat)
		menu_beat = to
var menu_beat_delta := 0.
var in_menu := true
@export var transition_beats := 4.

var level_drivers:Array[LevelMusicDriver]

## Request the start of a level's music tracks.
func _request_level_music(for_level:LevelData = Global.current_data) -> void:
	
	# Transition out the menu music
	in_menu = false
	
	# Load this level data to a LevelMusicDriver
	var this_driver := _find_driver()
	this_driver.reload(for_level)
	
	# Transition out all the other drivers.
	for driver in level_drivers:
		if driver != this_driver:
			driver.resolve()

## Request the start of the menu music.
func _resolve_to_menu(anim_name:String, _optional_data:Variant = true) -> void: if anim_name == "Game->Levels":
	
	# Transition out all the drivers.
	for driver in level_drivers: driver.resolve()
	
	# Transition in the menu music.
	in_menu = true

func _ready() -> void:
	Global.starting_level.connect(_request_level_music)
	Global.request_animation.connect(_resolve_to_menu)
	
	if menu_player.stream:
		menu_bpm = menu_player.stream.get("bpm")

func _process(_delta: float) -> void:
	menu_beat = (menu_player.get_playback_position() +  AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * menu_bpm / 60
	
	# Transition the menu volume to what it should be.
	if menu_player.volume_linear != (in_menu as int):
		menu_player.set_volume_linear(move_toward(menu_player.volume_linear, in_menu as int, menu_beat_delta / transition_beats))

func _find_driver() -> LevelMusicDriver:
	
	# Check the existing drivers for an empty one.
	for driver in level_drivers:
		if driver.level_data == null: return driver
	
	# If none exist, create a new one.
	var new := LevelMusicDriver.new()
	new.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(new)
	level_drivers += [new]
	
	return new
