@tool
class_name DeathBorder extends Node2D

@onready var player:Player:
	get():
		if not player: player = get_tree().get_first_node_in_group("Player")
		return player

@export_range(0.0, 15000.0, 1) var width := 0.:
	set(to):
		width = to
		queue_redraw()
@export_range(0.0, 15000.0, 1) var height := 0.:
	set(to):
		height = to
		queue_redraw()

@export var visual_width := 2000.0:
	set(to):
		visual_width = to
		queue_redraw()
@export var border_color:Color = Color(0.389, 0.093, 0.093, 1.0)

func _draw() -> void: 
	if Engine.is_editor_hint():
		draw_line(Vector2(-width, -height), Vector2(-width, height), Color.RED, 20.0)
		draw_line(Vector2(width, -height), Vector2(width, height), Color.RED, 20.0)
		draw_line(Vector2(width, -height), Vector2(-width, -height), Color.RED, 20.0)
		draw_line(Vector2(width, height), Vector2(-width, height), Color.RED, 20.0)
	draw_rect(Rect2(width, -height - visual_width, visual_width, height * 2 + visual_width), border_color)
	draw_rect(Rect2(-width - visual_width, -height - visual_width, visual_width, height * 2 + visual_width), border_color)
	draw_rect(Rect2(-width - visual_width, -height - visual_width, width * 2 + visual_width, visual_width), border_color)
	draw_rect(Rect2(-width - visual_width, height, width * 2 + visual_width * 2, visual_width), border_color)

var has_reset := false
func _process(_delta: float) -> void: if player and not Engine.is_editor_hint():
	if outside_bounds(player.global_position):
		if not has_reset:
			## Something something reset.
			Global.request_animation.emit("ResetIn")
			has_reset = true
	else: has_reset = false ## Reset the tracker when the player leaves the border.

func outside_bounds(a:Vector2) -> bool:
	return a.x >  width + global_position.x || a.x < -width + global_position.x || a.y >  height + global_position.y || a.y < -height + global_position.y
