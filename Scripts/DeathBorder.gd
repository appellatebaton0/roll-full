@tool
class_name DeathBorder extends Polygon2D

@onready var collision_poly := $Area2D/CollisionPolygon2D
@onready var area := $Area2D

@onready var player:Player:
	get():
		if not player: player = get_tree().get_first_node_in_group("Player")
		return player

func _ready() -> void:
	collision_poly.polygon = polygon

var has_reset := true
func _process(_delta: float) -> void: if player and not Engine.is_editor_hint():
	if not area.get_overlapping_bodies().has(player):
		if not has_reset:
			## Something something reset.
			Global.request_animation.emit("ResetIn")
			has_reset = true
	else: has_reset = false ## Reset the tracker when the player leaves the border.
