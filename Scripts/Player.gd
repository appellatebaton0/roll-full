class_name Player extends CharacterBody2D
## The driver for the player's movement.

signal dash_reset ## The dash cooldown just ran out.
signal dashed ## The player just dashed.

signal jumped ## The player just jumped.
signal landed ## The player just landed.

signal reset ## The player just reset (died). There's no distinction.

const DEBUG := true

## Visuals Variables
@export var sprite:Node2D
@export var pointer:Node2D

#region Movement Variable
@export var base_speed := 2500.0
@export var jump_height := 670.0

@export var gravity_scale := 1.0

@export_group("Raycast", "ray_")
@export var ray_node:RayCast2D
@export var ray_distance := 200.0
@export var ray_fallback := 1.2
var ray_fall_time := 0.0
var ray_resetting := false

@export_group("Dashing", "dash_")
@export var dash_cooldown := 0.5
var dash_cooldown_time := 0.0:
	set(to):
		
		if dash_cooldown_time > 0 and to <= 0:
			## Just reset :D
			dash_reset.emit()
		
		dash_cooldown_time = to
var dash_direction:Vector2:
	set(to): 
		dash_direction = to.normalized()
		pointer.rotation = dash_direction.angle()

const DASH_BUFFER := 0.1
var dash_buffering := 0.0
var dash_slow_timer := 0.0
@export var dash_slow_curve:Curve

const JUMP_BUFFER := 0.1
var jump_buffering := 0.0
var jumping := false
#endregion

@onready var respawn_position := global_position

## Whether the player was on the wall the previous prame.
var was_on_wall := false
var slide_mag := 0. ## The magnitude of the player's velocity slid against the wall on contact.

# A normalized vector of the direction the player is grinding in.
var direction := Vector2(1,0):
	set(to): direction = to.normalized()

func _ready() -> void: 
	Global.reset_level.connect(_on_reset)
	
	## Allows for a custom base speed on a level-by-level basis.
	if Global.current_data and base_speed == 2500: 
		base_speed = Global.current_data.base_player_speed

## The last direction, normalized, of the surface intersected by the raycast.
var last_normal:Vector2
func _physics_process(delta: float) -> void:
	
	var on_wall := is_on_wall() # Gets reused, so might as well call it once.
	
	# When debugging, draw the debug lines and update em every frame.
	if DEBUG: queue_redraw()
	
	# Buffer the jump input.
	jump_buffering = move_toward(jump_buffering, 0, delta)
	if Input.is_action_just_pressed("Jump"): jump_buffering = JUMP_BUFFER
	
	# On-wall-hit velocity projection.
	if not was_on_wall and on_wall and not ray_node.is_colliding():
		var wn := get_wall_normal()
		var wall_dir := Vector2(wn.y, -wn.x)
		
		var projection := velocity.project(wall_dir)
		
		slide_mag = projection.distance_to(Vector2.ZERO)
		
		landed.emit()
	was_on_wall = on_wall
	
	# Control the ray target.
	if on_wall and not ray_resetting: # If on wall, pierce the surface.
		var goal_pos := -get_wall_normal() * ray_distance
		
		ray_node.target_position = goal_pos
		
		ray_fall_time = 0.0
	elif not ray_node.is_colliding(): # Otherwise, slowly return to Vector2.ZERO
		ray_node.target_position = lerp(-last_normal * ray_distance, Vector2.ZERO, ease(ray_fall_time, ray_fallback))
		
		ray_fall_time = move_toward(ray_fall_time, 1.0, delta)
		ray_resetting = false
	
	# Grinding
	if ray_node.is_colliding() and not ray_resetting:
		
		## Wind down the dash cooldown.
		dash_cooldown_time = move_toward(dash_cooldown_time, 0.0, delta)
		
		## -- DIRECTION SETTING -- ##
		
		# Update the last normal.
		last_normal = ray_node.get_collision_normal()
		
		
		# Find the two vectors parallel to the rail.
		var a = Vector2(-last_normal.y,  last_normal.x).normalized() ## 90* Counterclockwise
		var b = Vector2( last_normal.y, -last_normal.x).normalized() ## 90* Clockwise
		
		# Figure out which direction is closer to the current direction, and set to that.
		direction = closest_vector(a, b, direction)
		
		## -- VELOCITY APPLICATION -- ##
		
		velocity = direction * max(base_speed, slide_mag)
		
		
		## -- JUMPING -- ##
		if jump_buffering:
			
			# Reset the ray target so you don't snap right back to the wall.
			ray_node.target_position = Vector2.ZERO
			ray_fall_time = 1.0
			
			# Apply jump velocity
			velocity += last_normal * jump_height * 300.0
			
			# Clear the jump buffer so you don't spam jumps.
			jump_buffering = 0.0
			
			jumped.emit()
		else:
			# Wall sticking.
			var collision_point := ray_node.get_collision_point() - global_position
			position += collision_point.normalized() * (collision_point.distance_to(Vector2.ZERO) - 32.)
	
	# Freefall
	else:
		velocity += Vector2(0, 980 * delta * gravity_scale)
		
		# Set the current direction to the velocity (automatically normalized).
		direction = velocity
	
	if sprite:
		sprite.rotate(deg_to_rad(mag(velocity) * direction.rotated(-last_normal.angle()).y * delta))
	
	## -- Dashing -- ##
	
	# Buffering
	dash_buffering = move_toward(dash_buffering, 0.0, delta)
	if Input.is_action_just_released("Dash"): dash_buffering = DASH_BUFFER
	
	# Time slowing
	if Input.is_action_pressed("Dash"):
		$Pointer.visible = true
		
		dash_slow_timer = move_toward(dash_slow_timer, dash_slow_curve.get_domain_range(), delta)
		
		Global.set_timescale_modifier("Dashslow", dash_slow_curve.sample(dash_slow_timer))
	else:
		dash_slow_timer = dash_slow_curve.min_domain
		$Pointer.visible = false
		Global.set_timescale_modifier("Dashslow", 1.0)
	
	# Get the new dash direction.
	var new_dash_direction:Vector2
	match Global.input_type:
		Global.INPUT_TYPE.KEYBMOUSE:
			new_dash_direction = get_global_mouse_position() - global_position
		Global.INPUT_TYPE.CONTROLLER:
			new_dash_direction = Input.get_vector("JL", "JR", "JU", "JD")
	
	# Only update it if the direction has changed.
	if dash_direction != new_dash_direction: dash_direction = new_dash_direction
	
	if dash_buffering > 0 and dash_cooldown_time <= 0:
		
		velocity = dash_direction * max(base_speed, mag(velocity) * 0.9)
		
		ray_node.target_position = Vector2.ZERO
		ray_fall_time = 1.0
		
		dash_cooldown_time = dash_cooldown
		dash_buffering = 0.0
		
		
		var vec23 = func(a:Vector2): return Vector3(a.x, a.y, 0.0)
		$DashEffectParticles.process_material.direction = -vec23.call(velocity.normalized())
		dashed.emit()
	
	move_and_slide()

func _on_reset() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	
	ray_node.target_position = Vector2.ZERO
	ray_fall_time = 1.0
	ray_resetting = true
	
	last_normal = Vector2.ZERO
	
	## Reset buffers and cooldowns.
	jump_buffering = 0.0
	dash_cooldown_time = 0.0
	
	reset.emit()
	

# Returns the Vector2 that is most similar to the comparator out of the given array.
func closest_vector(a:Vector2, b:Vector2, compared_to:Vector2):
	
	var a_dot := a.dot(compared_to)
	var b_dot := b.dot(compared_to)
	
	if a_dot > b_dot: return a
	return b

func mag(of:Vector2): return of.distance_to(Vector2.ZERO)

# DEBUG GRAPHICS
func _process(_delta: float) -> void: if DEBUG: queue_redraw()

const LINE_COEFF := 500.0
func _draw() -> void: if DEBUG:

	# Debug lines to show the direction and plane parallel. NOTE: Doesn't show correctly with rotation.
	draw_line(Vector2.ZERO, direction * 250, Color.RED, 15) 
	
	draw_line(Vector2.ZERO, velocity.normalized() * LINE_COEFF, Color.AQUA, 10)
	
	if is_on_wall():
		draw_line(Vector2.ZERO, -get_wall_normal() * LINE_COEFF, Color.WEB_PURPLE, 10)
	
	
	var jump_direction = get_wall_normal()
	draw_line(Vector2.ZERO, jump_direction * mag(velocity) / 100, Color.BLUE, 15)
	
	draw_line(Vector2.ZERO, velocity / 8., Color.GREEN, 15)
	#draw_line(Vector2.ZERO, real_velocity / 8., Color.LIGHT_SALMON, 12)
	
	draw_circle(ray_node.target_position, 10.0, Color.TEAL)
	
	var collision_point := ray_node.get_collision_point() - global_position
	draw_circle(collision_point, 3.0, Color.GREEN_YELLOW, false, 1.2)
	draw_line(collision_point, collision_point + ray_node.get_collision_normal() * 20., Color.GREEN_YELLOW, 1.2)
	
	draw_circle(collision_point.normalized() * (collision_point.distance_to(Vector2.ZERO) - 32.), 3.5, Color.DARK_GREEN, false, 1.2)
