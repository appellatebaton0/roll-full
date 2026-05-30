@tool
extends Node
## Records the player's gameplay, and allows for exporting it to an AnimationPlayer

@export var frame_mod := 5

@export_tool_button("EXPORT") var export := func():
	print("!")
	
	var animation := export_player.get_animation(export_animation)
	
	# Set up the track.
	var track_index := animation.add_track(0 as Animation.TrackType) if export_track_index < 0 else export_track_index
	export_track_index = track_index
	
	animation.track_set_path(track_index, NodePath(String(owner.get_path_to(export_node)) + ":position"))
	
	# Remove existing keys
	while animation.track_get_key_count(track_index):
		animation.track_remove_key(track_index, 0)
	
	for key in veclog:
		animation.track_insert_key(track_index, key, veclog[key])

@export var export_player:AnimationPlayer
@export var export_animation:StringName
@export var export_track_index := -1
@export var export_node:Node2D

@export var veclog:Dictionary[float, Vector2]
@onready var player := get_tree().get_first_node_in_group("Player")

func _ready() -> void: if not Engine.is_editor_hint():
	export_player.play(export_animation)
	veclog.clear()

var timer := 0.
var frame := 0
func _process(delta: float) -> void:
	
	if Engine.is_editor_hint(): return
	timer += delta
	frame += 1
	
	if frame % frame_mod == 0:
		veclog[timer] = player.global_position
	
