class_name DashCooldownBar extends ProgressBar

var fill_stylebox:StyleBoxFlat
var player:Player:
	get(): 
		if not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("Player")
		
		return player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_stylebox = get_theme_stylebox("fill")

# Called every frame. 'delta' is the elapsed time since the previous frame.
@onready var new_value := value
func _process(_delta: float) -> void: if is_visible_in_tree():
	
	if player:
		new_value = 1. - (player.dash_cooldown_time / player.dash_cooldown)
		
	if new_value != value:
		value = new_value
		
		if value >= 1.:
			fill_stylebox.bg_color = Color(0.132, 0.81, 0.057, 0.627)
		elif value >= 0.75:
			fill_stylebox.bg_color = Color(0.81, 0.71, 0.057, 0.627)
		elif value >= 0.4:
			fill_stylebox.bg_color = Color(0.81, 0.458, 0.057, 0.627)
		else:
			fill_stylebox.bg_color = Color(0.81, 0.057, 0.057, 0.627)
		fill_stylebox.border_color = fill_stylebox.bg_color * 0.8
		
		
