class_name LevelCreationScreen extends Panel
## Manages the level creation screen.

var custom_levels:Array[LevelData]
var entries:Array[CustomLevelEntry]

const ENTRY_SCENE := preload("res://Scenes/UIElements/CustomLevelEntry.tscn")

func _ready() -> void:
	
	# Make sure the level data folder exists.
	assure_user_directory("user://CustomLevelData")
	
	# Save a practice level into the folder.
	#var new := LevelData.new()
	#new.name = "Test Level Name For Fun Jesus Christ"
	#
	#print("E: ", ResourceSaver.save(new, "user://CustomLevelData/" + new.name + ".tres") as Error)
	
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://CustomLevelData/Test Level Name For Fun Jesus Christ.tres"))
	
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://CustomLevelData"))
	
	# Load the custom levels that already exist into the array.
	custom_levels = Global.get_level_data(ProjectSettings.globalize_path("user://CustomLevelData"))
	
	print(custom_levels)

func assure_user_directory(path:StringName) -> Error:
	if not DirAccess.dir_exists_absolute(path):
		return DirAccess.make_dir_absolute(path)
	return Error.OK
