class_name AmbientParticles extends Node
## Manages the ambient particles floating in the air.

class Particle:
	var node:Sprite2D
	var velocity:Vector2
	var spin:float
	
	func _init(set_node:Sprite2D) -> void:
		node = set_node
	
	func process(delta:float):
		node.global_position += velocity * delta
		node.rotate(spin * delta)

@onready var template_particle := $TemplateParticle
var particles:Array[Particle]

@export var particle_count := 64
@export var texture_size := Vector2i(8,8)
@export var min_velocity := Vector2.ZERO
@export var max_velocity := Vector2.ZERO
@export var min_spin := 0.0
@export var max_spin := 0.0
@export var scale_out := 0.8
@export var time_range := Vector2(1.0, 1.5)
var viewport_bounds:Rect2
var wrap_bounds:Rect2

func _ready() -> void:
	min_spin = deg_to_rad(min_spin)
	max_spin = deg_to_rad(max_spin)
	
	viewport_bounds = get_global_viewport_bounds()
	
	#var p = func(pos:Vector2, sca:Vector2):
		#var new = template_particle.duplicate()
		#add_child(new)
		#new.global_position = pos
		#new.scale = sca / Vector2(texture_size)
		#
	#p.call(viewport_bounds.position + (viewport_bounds.size / 2), viewport_bounds.size)
	
	for i in range(particle_count):
		create_particle()
	template_particle.queue_free()

func _process(delta: float) -> void:
	viewport_bounds = get_global_viewport_bounds()
	
	wrap_bounds = viewport_bounds
	wrap_bounds.position -= Vector2(texture_size)
	wrap_bounds.size += Vector2(texture_size)
	
	for particle in particles: process_particle(particle, delta)

func get_global_viewport_bounds() -> Rect2:
	var port := get_viewport().get_visible_rect()
	var camera := get_viewport().get_camera_2d()
	
	port.size *= scale_out
	port.position += camera.global_position - (port.size / 2)

	port.size += port.position
	
	return port

func create_particle() -> Particle:
	if not template_particle: return null
	
	var new_node:Sprite2D = template_particle.duplicate()
	add_child(new_node)
	
	var new := Particle.new(new_node)
	particles.append(new)
	
	new_node.global_position.x = randf_range(viewport_bounds.position.x, viewport_bounds.size.x)
	new_node.global_position.y = randf_range(viewport_bounds.position.y, viewport_bounds.size.y)
	
	new_node.scale.x = randf_range(0.9, 1.1)
	new_node.scale.y = randf_range(0.9, 1.1)
	
	return new

func process_particle(particle:Particle, delta:float):
	
	if wrap_particle(particle): reload_particle(particle)
	
	particle.process(delta)

func reload_particle(particle:Particle):
	particle.node.scale.x = randf_range(0.9, 1.1)
	particle.node.scale.y = randf_range(0.9, 1.1)
	
	particle.velocity.x = randf_range(min_velocity.x, max_velocity.x)
	particle.velocity.y = randf_range(min_velocity.y, max_velocity.y)
	
	particle.spin = randf_range(min_spin, max_spin)

func wrap_particle(particle:Particle) -> bool:
	var starting_position := particle.node.global_position
	
	particle.node.global_position.x = wrap(particle.node.global_position.x, wrap_bounds.position.x, wrap_bounds.size.x)
	particle.node.global_position.y = wrap(particle.node.global_position.y, wrap_bounds.position.y, wrap_bounds.size.y)
	
	return starting_position != particle.node.global_position
