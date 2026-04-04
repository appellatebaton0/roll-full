class_name Camera extends Camera2D
## Follows the player f a n c i l y

## Second-order-system time? Idk...

@onready var target:Player = get_tree().get_first_node_in_group("Player")
@export var lerp_speed := 0.2

var hijack_position:Vector2

var xp:Vector2 # Previous input

# State variables
var y:Vector2
var yd:Vector2

# Dynamic constants
var k1:float
var k2:float
var k3:float

@export var f:float
@export var z:float
@export var r:float

func _ready() -> void:
	# Compute constants
	k1 = z / (PI * f)
	k2 = 1 / ((2 * PI * f) *  (2 * PI * f))
	k3 = r * z / (2 * PI * f)
	
	# Initialize variables
	var x0 = global_position
	xp = x0
	y = x0
	yd = Vector2.ZERO
	
	Global.reset_level.connect(_on_reset)
	_on_reset()

func _on_reset() -> void: global_position = target.global_position

#func _draw():
	#draw_circle(Vector2.ZERO, 20.0, Color.RED)
	#queue_redraw()

func target_position(delta:float):
	
	var target_pos:Vector2
	
	if hijack_position:
		target_pos = hijack_position
	else:
		target_pos = target.global_position
	
	# Compute constants
	k1 = z / (PI * f)
	k2 = 1 / ((2 * PI * f) *  (2 * PI * f))
	k3 = r * z / (2 * PI * f)
	
	var xd:Vector2
	var x = target_pos
	
	xd = (x - xp) / delta
	xp = x
	
	y = y + delta * yd
	yd = yd + delta * (x + k3*xd - y - k1*yd) / k2
	
	return y

var applied_velocity := Vector2.ZERO
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = target_position(delta) + applied_velocity
	
	zoom = lerp(zoom, Vector2.ONE * clamp((0.7 - pow(target.mag(target.velocity) / 50000., 1./3.)), 0.05, 1.), 0.1)
	
	applied_velocity = lerp(applied_velocity, target.velocity / 4, 0.1)
