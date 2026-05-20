class_name DashCooldownBar extends ProgressBar

var fill_stylebox:StyleBoxFlat
var player:Player:
	get(): 
		# If the player has since been freed, look for the new one.
		if not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("Player")
		
		return player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_stylebox = get_theme_stylebox("fill")

const COLOR_BANK:Array[Color] = [
	Color(0.336, 0.866, 0.96, 0.902),
	Color(0.735, 0.692, 0.91, 0.902),
	Color(0.87, 0.452, 0.564, 0.722),
	Color(0.9, 0.126, 0.294, 0.722)
]

# Called every frame. 'delta' is the elapsed time since the previous frame.
@onready var new_value:float = value
@onready var goal_value:float = value
var index:int
func _process(_delta: float) -> void: if is_visible_in_tree():
	
	if index == null: 
		index = get_color_index(goal_value)
	
	if player:
		new_value = 1. - (player.dash_cooldown_time / player.dash_cooldown)
	
		var new_index := get_color_index(new_value)
		if new_index != index:
			modulate = COLOR_BANK[new_index]
			
			index = new_index
		
		goal_value = new_value
	
	value = lerp(value, goal_value, 0.3)


func get_color_index(for_value:float) -> int:
	if   for_value >= 1.:   return 0
	elif for_value >= 0.75: return 1
	elif for_value >= 0.4:  return 2
	return 3
