class_name LevelData extends Resource
## Holds all the reference data for a level.

@export var scene:PackedScene

var times:Array[float]: ## Stores time, in seconds
	set(to):
		times = to
		
		## Update the best time.
		best_time = _get_best_time()
		
		## Update the ranking
		ranking = _get_ranking()
var best_time:float

enum RANKINGS {S, A, B, C, D, F}
@export var ranking_minimums:Dictionary[RANKINGS, float] = {
	RANKINGS.S: 0,
	RANKINGS.A: 0,
	RANKINGS.B: 0,
	RANKINGS.C: 0,
	RANKINGS.D: 0,
	RANKINGS.F: 0,
}

## The letter ranking for this level.
var ranking:String

func _get_best_time(): 
	var best:float = INF
	
	for time in times:
		if min(best, time) == time:
			best = time
	
	return best

func _get_ranking():
	var current_min := 0.0
	
	for rank in RANKINGS:
		current_min = ranking_minimums[rank]
		
		if best_time <= current_min:
			match rank: # Return as single-character
				RANKINGS.F: return "F"
				RANKINGS.D: return "D"
				RANKINGS.C: return "C"
				RANKINGS.B: return "B"
				RANKINGS.A: return "A"
				RANKINGS.S: return "S"
