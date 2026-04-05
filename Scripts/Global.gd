extends Node

@warning_ignore("unused_signal")
signal request_animation(anim_name:String)
@warning_ignore("unused_signal")
signal reset_level

## -- GAME STATE -- ##

var world_progression := 1 ## The number of worlds completed.

## -- GENERIC -- ## 

func seconds_as_timer(amount:float, show_mili := true) -> String:
	
	var minutes:int = floor(amount / 60)
	var seconds = int(amount) % 60
	var milis = int(amount * 100) % 100
	
	if show_mili:
		return "%s:%s.%s" % [digitize(minutes, 2),digitize(seconds, 2),digitize(milis, 2)]
	else:
		return "%s:%s" % [digitize(minutes, 2),digitize(seconds, 2)]

func digitize(value:int, digits:int) -> String:
	
	var response := ""
	var string = str(value)
	
	for i in range(digits - len(string)):
		response += "0"
	response += string
	
	return response

func d_lerp(a, b, r:float, delta:float) -> Variant:
	if a is Vector2 and b is Vector2:
		return Vector2(d_lerp(a.x, b.x, r, delta), d_lerp(a.y, b.y, r, delta))
	
	return ((a - b) * pow(r, delta)) + b
