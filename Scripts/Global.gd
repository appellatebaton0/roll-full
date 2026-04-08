extends Node

@warning_ignore("unused_signal")
signal request_animation(anim_name:String)
@warning_ignore("unused_signal")
signal reset_level
@warning_ignore("unused_signal")
signal level_complete

## -- GAME STATE -- ##

const PROGRESSION_OVERRIDE := true

var world_progression := 0 ## The number of worlds completed.

var current_level:Node
var current_data :LevelData

var run_timer:RunTimer

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

## Sorts the array via merge sort.
func merge_sort(array:Array, condition:Callable) -> Array:
	
	var length = len(array)
	
	if length <= 1: return array
	
	@warning_ignore("integer_division")
	var left = array.slice(0, floor((length + 1) / 2))
	@warning_ignore("integer_division")
	var right = array.slice(floor((length + 1) / 2), length)
	
	
	left  = merge_sort(left,  condition)
	right = merge_sort(right, condition)
	
	# The array's already sorted.
	if   len(left)  <= 0: return right 
	elif len(right) <= 0: return left 
	
	var li = 0
	var ri = 0
	
	var response:Array

	while len(response) < len(left) + len(right):
		
		# One of the arrays is empty; append the other and end.
		if li >= len(left): 
			response.append_array(right.slice(ri))
			break
		elif ri >= len(right):
			response.append_array(left.slice(li))
			break
		
		# Otherwise, append the next.
		if condition.call(left[li], right[ri]): 
			response.append(right[ri])
			ri += 1
		else:
			response.append(left[li])
			li += 1
	
	return response
