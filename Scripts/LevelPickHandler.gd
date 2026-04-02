class_name LevelPickHandler extends Control
## Handles the world / level selection screen.

@export var focused := true

## The world screens to create.
@export_dir var screen_dir:String
@onready var screen_scenes:Array[PackedScene] = get_screen_scenes()
var screens:Array[WorldScreen]

@export var current_index := 0

@export var animator:AnimationPlayer
@export var level_popup:LevelPopup

func _ready() -> void:
	for scene in screen_scenes:
		var new:WorldScreen = scene.instantiate()
		
		add_child(new)
		move_child(new, 0)
		
		screens.append(new)
		
		new.request_popup.connect(_on_popup_request)

func _on_popup_request(with:LevelData) -> void:
	
	print("!")
	level_popup.update_with(with)
	if not animator.is_playing(): 
		animator.play("OpenPopup")

func get_screen_scenes() -> Array[PackedScene]:
	
	var file_names:Array[StringName]
	
	var dir = DirAccess.open(screen_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				file_names.append(screen_dir + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	# Sort alphebetically. (A-Z then 0-9)
	file_names.sort()
	file_names.reverse()
	
	var scenes:Array[PackedScene]
	
	for file_name in file_names:
		var file = load(file_name)
		if file is PackedScene:
			scenes.append(file)
	
	return scenes
