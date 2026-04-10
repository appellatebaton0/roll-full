@tool
class_name AnimatedSpline2D extends Spline2D
## A spline with support for being animated.
## Loses support for textures and most Line2D functions as a tradeoff.

enum LOOP_TYPE {REPEAT, REVERSE, STOP}
@export var loop_type := LOOP_TYPE.REPEAT

@export_storage var animator:AnimationPlayer
var from_end := false

func _ready() -> void: 
	default_color = Color(0,0,0,0)
	
	regenerate_sample()
	queue_redraw()
	
	## Create the collision nodes.
	fabricate_collision()
	if Engine.is_editor_hint():
		fabricate_animator()
	else:
		
		if not animator: animator = find_animator()
		
		if animator:
		
			## Connect the signal and add the child, since those apparently get ruined.
			if not animator.animation_finished.is_connected(_on_animation_finished):
				animator.animation_finished.connect(_on_animation_finished)
			if not animator.get_parent():
				add_child(animator)
			
			Global.reset_level.connect(_on_reset)
			_on_reset()

func _draw() -> void: draw_polygon(sample_mesh, [color])
func _process(_delta: float) -> void: if points != last_points: 
	
	regenerate_sample()
	queue_redraw()
	generate()
	
	last_points = points

func fabricate_animator() -> void: if Engine.is_editor_hint() and not animator:
	var new := AnimationPlayer.new()
	
	add_child(new)
	new.name = "Player"
	new.owner = get_tree().edited_scene_root
	
	animator = new

func _on_animation_finished(_anim_name:StringName) -> void:
	## Repeat.
	if loop_type == LOOP_TYPE.STOP: return
	if loop_type == LOOP_TYPE.REVERSE: from_end = !from_end
	animator.play(get_anim(), -1, -1.0 if from_end else 1.0, from_end)

func _on_reset():
	from_end = false
	animator.stop()
	animator.play(get_anim(), -1, 1.0, from_end)

func get_anim() -> StringName:
	for anim in animator.get_animation_list():
		if anim != "RESET": return anim
	return ""

func find_animator() -> AnimationPlayer:
	for child in get_children(): if child is AnimationPlayer:
		return child
	return animator
