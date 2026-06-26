class_name Camera extends Camera2D
## Follows the player f a n c i l y

const DEBUG := false

## Second-order-system time? Idk...

@onready var target:Player = get_tree().get_first_node_in_group("Player")

var hijack_position:Vector2

var xp:Vector2 # Previous input

# State variables
var y:Vector2
var yd:Vector2

# Dynamic constants
var k1:float
var k2:float
var k3:float

@export var f := 0.75 ## The follow speed.
@export var z := 2.0 ## The bounce/overshoot.
@export var r := 2.15 ## The follow-ahead.

## How much the timescale affects the follow-ahead.
@export var r_timescale_weight := 0.5
## How much the timescale affects the zoom.
@export var zoom_timescale_weight := 0.3

func _ready() -> void:
	Global.reset_level.connect(_on_reset)
	_on_reset()
	
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_reset() -> void:
	# Compute constants
	k1 = z / (PI * f)
	k2 = 1 / ((2 * PI * f) *  (2 * PI * f))
	k3 = r * z / (2 * PI * f)
	
	# Initialize variables
	var x0 = global_position
	xp = x0
	y = x0
	yd = Vector2.ZERO
	

func target_position(delta:float): 
	
	var target_pos:Vector2
	
	if hijack_position:
		target_pos = hijack_position
	else:
		target_pos = target.global_position #+ (target.velocity / 3.)
	
	var te := scaled_timescale_effect(r_timescale_weight, 0.3, 1.2)
	
	# Compute constants
	k1 = z / (PI * f)
	k2 = 1 / ((2 * PI * f) *  (2 * PI * f))
	k3 = (r * te) * z / (2 * PI * f)
	
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

	if not target:
		target = get_tree().get_first_node_in_group("Player")
		
		global_position = target.global_position
		
		_on_reset()
		
		return
	
	if Global.spinning_camera:
		# The angle of the rotation, rotated 90 degrees
		var targ_angle := target.velocity.angle() + (0.5 * PI)
		
		# Solves the issue of the camera turning the wrong way when more
		# than 180* from the target angle. PI = 180* in radians.
		
		# IF the angles are more than 180* apart, move them 360* closer.
		while abs(targ_angle - rotation) > PI:
			targ_angle += PI *2 * sign(rotation - targ_angle)
		
		# Rotate towards the target angle.
		rotation = move_toward(rotation, targ_angle, abs(rotation - targ_angle) / 10)
	else:
		rotation = 0.0
	
	if DEBUG:
		global_position = target.global_position
		zoom = Vector2.ONE * 1.6
		return
	
	global_position = target_position(delta)
	
	var goal_zoom := 0.7 - pow(target.mag(target.velocity) / 50000., 1./3.) * scaled_timescale_effect(zoom_timescale_weight, 0.8, 1.1)
	goal_zoom = clamp(goal_zoom, 0.25, 3.3)
	
	zoom = lerp(zoom, Vector2.ONE * goal_zoom, 0.1)

func scaled_timescale_effect(weight:float, min_value:float, max_value:float) -> float:
	return clamp((weight * (Engine.time_scale - 1.)) + 1., min_value, max_value)
