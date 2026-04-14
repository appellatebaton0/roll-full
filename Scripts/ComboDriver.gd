class_name ComboDriver extends Node2D

@export var player:Player

@export var dir_sprites:Dictionary[Global.DIR, Node2D] = {
	Global.DIR.UP: null,
	Global.DIR.RIGHT: null,
	Global.DIR.DOWN: null,
	Global.DIR.LEFT: null,
}

func _ready() -> void:
	Global.reset_level.connect(_on_reset)

func _process(delta: float) -> void:

	if not player.is_on_wall():
		var inputs := {
			Global.DIR.UP: "ComboUp",
			Global.DIR.RIGHT: "ComboRight",
			Global.DIR.DOWN: "ComboDown",
			Global.DIR.LEFT: "ComboLeft",
		}
		for input in inputs:
			if Input.is_action_just_pressed(inputs[input]):
				_on_combo_input(input)
	else: Global.end_trick_sequence()

	for dir in Global.DIR.values():
		dir_sprites[dir as int].self_modulate.a = move_toward(dir_sprites[dir as int].self_modulate.a, 0.0, delta * 3.5)

func _on_combo_input(input:Global.DIR) -> void:
	dir_sprites[input as int].self_modulate.a = 1.0
	dir_sprites[input as int].scale = Vector2.ONE
	
	Global.push_direction(input)
	print(Global.score_buffer)

func _on_reset() -> void:
	for dir in Global.DIR.values():
		dir_sprites[dir as int].self_modulate.a = 0.0
