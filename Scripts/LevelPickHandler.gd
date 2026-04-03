class_name LevelPickHandler extends Control
## Handles the world / level selection screen.

@export var focused := true

## The world screens to create.
@export_dir var screen_dir:String
@onready var screen_scenes:Array[PackedScene] = get_screen_scenes()
var screens:Array[WorldScreen]
var ori_x:Array[float]

@export var lerp_time := 1.
var lerp_timer := 0.
@export var lerp_ease := -2.

@export var current_index := 0

@export var animator:AnimationPlayer
@export var level_popup:LevelPopup

@onready var viewport_width := get_viewport_rect().size.x

func _ready() -> void:
	for i in range(len(screen_scenes)):
		var new:WorldScreen = screen_scenes[i].instantiate()
		
		add_child(new)
		move_child(new, 0)
		
		screens.append(new)
		ori_x.append((viewport_width * i) - (viewport_width * current_index))
		
		new.request_popup.connect(_on_popup_request)
		
		new.next_button.pressed.connect(cycle_right)
		new.prev_button.pressed.connect(cycle_left)
	
	screens.front().prev_button.modulate.a = 0.0
	screens.back() .next_button.modulate.a = 0.0
	
	lerp_timer = lerp_time

func _process(delta: float) -> void:
	for i in range(len(screens)):
		var screen := screens[i]
		var targ_x := (viewport_width * i) - (viewport_width * current_index)
		
		screen.position.x = lerp(ori_x[i], targ_x, ease(lerp_timer / lerp_time, lerp_ease))
		
		screen.next_button.modulate.a = 1.0 if (i < Global.world_progression) and not i == len(screens) else 0.0
		
	lerp_timer = move_toward(lerp_timer, lerp_time, delta)
	
	if Input.is_action_just_pressed("Cycle World Left"): cycle_left()
	if Input.is_action_just_pressed("Cycle World Right"): cycle_right()


func cycle_left() -> void: if focused:
	current_index = clamp(current_index - 1, 0 , Global.world_progression)
	lerp_timer = 0.0
	
	for i in range(len(screens)):
		ori_x[i] = screens[i].position.x
func cycle_right() -> void: if focused:
	current_index = clamp(current_index + 1, 0 , Global.world_progression)
	lerp_timer = 0.0
	
	for i in range(len(screens)):
		ori_x[i] = screens[i].position.x

func _on_popup_request(with:LevelData) -> void:
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
	
	var scenes:Array[PackedScene]
	
	for file_name in file_names:
		var file = load(file_name)
		if file is PackedScene:
			scenes.append(file)
	
	return scenes
