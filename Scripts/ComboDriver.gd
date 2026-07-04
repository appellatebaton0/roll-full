class_name ComboDriver extends Node2D


## When WASD (or other combo inputs) are pressed while midair.
## Does not fire for the final input in a combo. Combine w/ finished_combo.
@warning_ignore("unused_signal") signal combo_input
## When a combo is finished, ie the last input in the train of 3 is pressed.
@warning_ignore("unused_signal") signal finished_combo
## When the player lands after performing at least 1 combo midair.
@warning_ignore("unused_signal") signal trick_ended

@export var player:Player

@export var dir_sprites:Dictionary[Global.DIR, Node2D] = {
	Global.DIR.UP: null,
	Global.DIR.RIGHT: null,
	Global.DIR.DOWN: null,
	Global.DIR.LEFT: null,
}

@export var input_cooldown := 0.05
var cooldown_time := 0.0

func _ready() -> void:
	Global.reset_level.connect(_on_reset)
	
	# Move all the relevant Global signals out into signals from this, for SFX.
	for signal_name in ["combo_input", "finished_combo", "trick_ended"]:
		# Uses func(..._args) to ignore finished_combo's argument.
		Global.connect(signal_name, func(..._args:Array): get(signal_name).emit())

func _process(delta: float) -> void:
	
	cooldown_time = move_toward(cooldown_time, 0, delta)

	if not player.is_on_wall():
		var inputs := {
			Global.DIR.UP: "ComboUp",
			Global.DIR.RIGHT: "ComboRight",
			Global.DIR.DOWN: "ComboDown",
			Global.DIR.LEFT: "ComboLeft",
		}
		for input in inputs:
			if Input.is_action_just_pressed(inputs[input]) and cooldown_time <= 0:
				_on_combo_input(input)
				cooldown_time = input_cooldown
	else: Global.end_trick_sequence()

	for dir in Global.DIR.values():
		dir_sprites[dir].self_modulate.a = move_toward(dir_sprites[dir].self_modulate.a, 0.0, delta * 3.5)

func _on_combo_input(input:Global.DIR) -> void:
	dir_sprites[input].self_modulate.a = 1.0
	dir_sprites[input].scale = Vector2.ONE
	
	Global.push_direction(input)

func _on_reset() -> void:
	for dir in Global.DIR.values():
		dir_sprites[dir].self_modulate.a = 0.0
