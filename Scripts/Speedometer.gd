class_name Speedometer extends Label

func _process(delta: float) -> void:
	var player:Player = get_tree().get_first_node_in_group("Player")
	if player:
		var speed = (floor(player.velocity.distance_to(Vector2.ZERO)) / 100)
		if speed < 10:
			speed = "0" + str(speed)
		else: speed = str(speed)
		
		text = speed + "m/s"
