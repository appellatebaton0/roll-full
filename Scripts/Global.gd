extends Node

@warning_ignore("unused_signal")
signal request_animation(anim_name:String)
@warning_ignore("unused_signal")
signal reset_level
@warning_ignore("unused_signal")
signal level_complete

## -- GAME STATE -- ##

const PROGRESSION_OVERRIDE := false

var world_progression := 0: ## The number of worlds completed.
	set(to): pass ## Temporarily for this demo, don't allow progression to other worlds.

var current_level:Node
var current_data :LevelData

var run_timer:RunTimer

var default_time_scale := 2.0

## -- COMBO MANAGEMENT -- ##

signal finished_combo(combo:Combo)
signal trick_ended

const COMBO_LENGTH := 3
const ACTION_POINTS := 8 ## How many points a single direction press is worth.

enum DIR {UP, RIGHT, DOWN, LEFT}

var combo_buffer:Array[DIR]
var score := 0
var score_buffer := 0

class Combo:
	var key:Array[DIR]
	var multiplier:float
	var name:String
	
	func _init(set_name:String, set_key:Array[int], set_mult:float = 1.5) -> void:
		name = set_name
		key = set_key as Array[DIR]
		multiplier = set_mult

@onready var combos := [
	
	# 270 degree arc
	Combo.new("Arc", [0, 1, 2], 1.3), Combo.new("Arc", [1, 2, 3], 1.3), 
	Combo.new("Arc", [2, 3, 0], 1.3), Combo.new("Arc", [3, 0, 1], 1.3),
	Combo.new("Arc", [2, 1, 0], 1.3), Combo.new("Arc", [3, 2, 1], 1.3), 
	Combo.new("Arc", [0, 3, 2], 1.3), Combo.new("Arc", [1, 0, 3], 1.3),
	
	# Triple-Taps
	Combo.new("Triple", [0, 0, 0], 1.5), Combo.new("Triple", [1, 1, 1], 1.5), 
	Combo.new("Triple", [2, 2, 2], 1.5), Combo.new("Triple", [3, 3, 3], 1.5),
	
	]

func push_direction(direction:DIR):
	
	combo_buffer.append(direction)
	
	## IF this is the final action in the combo, finish the combo.
	if len(combo_buffer) >= COMBO_LENGTH: complete_combo()

## Figure out what the current combo is, and complete it.
func complete_combo() -> void:
	var this_combo:Combo
	
	# Add the action points
	score_buffer += int(len(combo_buffer) * ACTION_POINTS)
	
	## Check existing combos for a specific one.
	for combo in combos:
		if combo_buffer as Array[int] == combo.key:
			this_combo = combo
			break
	## Default combo if no specific ones found.
	if not this_combo: this_combo = Combo.new("Basic", combo_buffer as Array[int], 1.1)
	
	# Apply the multiplier
	score_buffer = int(score_buffer * this_combo.multiplier)
	
	# Emit the combo and clear the buffer.
	finished_combo.emit(this_combo)
	combo_buffer.clear()

## Push the current score_buffer into the score.
func end_trick_sequence() -> void:
	combo_buffer.clear()
	
	if score_buffer > 0:
		score += score_buffer
		score_buffer = 0
		
	trick_ended.emit()

func _ready() -> void: reset_level.connect(_on_reset)
func _on_reset() -> void: 
	end_trick_sequence()
	score = 0

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
