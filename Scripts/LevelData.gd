class_name LevelData extends Resource
## Holds all the reference data for a level.

signal times_updated
signal scores_updated

@export var name:String ## The name of the level.

@export var scene:PackedScene ## The scene containing this level.

var times:Array[float]: ## Stores time, in seconds
	set(to):
		times = to
		
		## Update the best time.
		best_time = _get_best(times)
		
		## Update the ranking
		ranking = _get_ranking()
		
		times_updated.emit()
var best_time:float ## The best time out of times.

var scores:Array[float]: ## Stores time, in seconds
	set(to):
		scores = to
		
		## Update the best time.
		best_score = _get_best(scores)
		
		## Update the ranking
		ranking = _get_ranking()
		
		scores_updated.emit()
var best_score:float ## The best time out of times.

enum RANKINGS {S, A, B, C, D}
@export var ranking_maximums:Dictionary[RANKINGS, float] = {
	RANKINGS.S: 0,
	RANKINGS.A: 0,
	RANKINGS.B: 0,
	RANKINGS.C: 0,
	RANKINGS.D: 0,
}

## The current letter ranking for this level.
var ranking:String

func _get_best(from:Array[float]) -> float: 
	var best:float = INF
	
	for val in from:
		if min(best, val) == val:
			best = val
	
	return best

func _get_ranking(for_time := best_time) -> String:
	var current_max := 0.0
	
	for i in range(RANKINGS.size()):
		current_max = ranking_maximums[i]
		
		if for_time <= current_max:
			match i as RANKINGS: # Return as single-character
				RANKINGS.D: return "D"
				RANKINGS.C: return "C"
				RANKINGS.B: return "B"
				RANKINGS.A: return "A"
				RANKINGS.S: return "S"
	
	return "F"
