class_name Player extends CharacterBody2D
## Allows a node to snap to surfaces, and grind along them / jump off them.
## Best used w/ a circle collider.

const DEBUG := true

@export var grind_speed := 1000.0
@export var jump_height := 670.0

@export var stick_force := 500.0

@export var gravity_scale := 1.0

@export var sprite:Node2D

@export_group("Raycast", "ray_")
@export var ray_node:RayCast2D
@export var ray_distance := 200.0
@export var ray_fallback := 1.2
var ray_fall_time := 0.0
var ray_resetting := false

const JUMP_BUFFER := 0.1
var jump_buffering := 0.0
var jumping := false

@onready var respawn_position := global_position

## Whether the player was on the wall the previous prame.
var was_on_wall := false
var slide_mag := 0. ## The magnitude of the player's velocity slid against the wall on contact.

# A normalized vector of the direction the player is grinding in.
var direction := Vector2(1,1):
	set(to): direction = to.normalized()

func _ready() -> void:
	Global.reset_level.connect(_on_reset)

## The last direction, normalized, of the surface intersected by the raycast.
var last_normal:Vector2
func _physics_process(delta: float) -> void:
	print(delta)
	
	# For the line debugging.
	if DEBUG: queue_redraw()
	
	# Buffer the jump input.
	jump_buffering = move_toward(jump_buffering, 0, delta)
	if Input.is_action_just_pressed("Jump"): jump_buffering = JUMP_BUFFER
	
	# On hitting a wall...
	if not was_on_wall and is_on_wall():
		var wn := get_wall_normal()
		var wall_dir := Vector2(wn.y, -wn.x)
		
		var projection := velocity.project(wall_dir)
		
		slide_mag = mag(projection)
		
		
	was_on_wall = is_on_wall()
	
	# Control the ray target.
	if is_on_wall() and not ray_resetting: # If on wall, pierce the surface.
		ray_node.target_position = Global.d_lerp(ray_node.target_position, -get_wall_normal() * ray_distance, 0.0001, delta)
		ray_fall_time = 0.0
	elif not ray_node.is_colliding(): # Otherwise, slowly return to Vector2.ZERO
		ray_node.target_position = lerp(-last_normal * ray_distance, Vector2.ZERO, ease(ray_fall_time, ray_fallback))
		
		ray_fall_time = move_toward(ray_fall_time, 1.0, delta)
		ray_resetting = false
	
	# Grinding
	if ray_node.is_colliding() and not ray_resetting:
		
		## -- DIRECTION SETTING -- ##
		
		# Update the last normal.
		last_normal = ray_node.get_collision_normal()
		
		
		# Find the two vectors parallel to the rail.
		var a = Vector2(-last_normal.y,  last_normal.x) ## 90* Counterclockwise
		var b = Vector2( last_normal.y, -last_normal.x) ## 90* Clockwise
		
		# Figure out which direction is closer to the current direction, and set to that.
		direction = closest([a,b], direction)
		
		## -- VELOCITY APPLICATION -- ##
		
		velocity = direction * max(grind_speed, slide_mag) - (last_normal * stick_force) 
		
		
		## -- JUMPING -- ##
		if jump_buffering:
			
			# Reset the ray target so you don't snap right back to the wall.
			ray_node.target_position = Vector2.ZERO
			ray_fall_time = 1.0
			
			# Apply jump velocity
			velocity += last_normal * jump_height * 300.0
			
			# Clear the jump buffer so you don't spam jumps.
			jump_buffering = 0.0
	
	# Freefall
	else:
		
		velocity += get_gravity() * delta * gravity_scale
		
		# Set the current direction to the velocity (automatically normalized).
		direction = velocity
	
	if sprite:
		sprite.rotate(deg_to_rad(mag(velocity) * direction.rotated(-last_normal.angle()).y / 110))
	
	move_and_slide()
	
	#print(mag(velocity))

func _on_reset() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	
	ray_node.target_position = Vector2.ZERO
	ray_fall_time = 1.0
	ray_resetting = true
	
	last_normal = Vector2.ZERO
	

# Returns the Vector2 that is most similar to the comparator out of the given array.
func closest(of:Array[Vector2], compared_to:Vector2):
	var best:Vector2
	var best_dot:float
	
	for vec2 in of:
		var vec_dot := vec2.normalized().dot(compared_to)
		
		# IF the best doesn't exist, or this is better than that.
		if not best or vec_dot > best_dot:
			best = vec2
			best_dot = vec_dot
			continue
	
	return best

func mag(of:Vector2): return sqrt(pow(of.x, 2) + pow(of.y, 2))

# DEBUG GRAPHICS
func _process(_delta: float) -> void: if DEBUG: queue_redraw()

const LINE_COEFF := 500.0
func _draw() -> void: 
	
	if not DEBUG: return
	
	
	
	else:
		# Debug lines to show the direction and plane parallel. NOTE: Doesn't show correctly with rotation.
		draw_line(Vector2.ZERO, direction * 250, Color.RED, 15) 
		
		draw_line(Vector2.ZERO, velocity.normalized() * LINE_COEFF, Color.AQUA, 10)
		
		if is_on_wall():
			draw_line(Vector2.ZERO, -get_wall_normal() * LINE_COEFF, Color.WEB_PURPLE, 10)
		
		
		var jump_direction = get_wall_normal()
		draw_line(Vector2.ZERO, jump_direction * mag(velocity) / 100, Color.BLUE, 15)
		
		draw_line(Vector2.ZERO, velocity, Color.GREEN, 15)
	
	
	draw_circle(ray_node.target_position, 10.0, Color.ALICE_BLUE)
	
	#draw_line(to_local(snapped_to.global_position), (Vector2.DOWN.rotated(snapped_to.rotation) * 250) + to_local(snapped_to.global_position), Color.GREEN, 15)
