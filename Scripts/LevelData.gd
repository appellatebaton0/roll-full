class_name LevelData extends Resource
## Holds all the reference data for a level.

@export var name:String ## The name of the level.

@export var scene:PackedScene ## The scene containing this level.

var times:Array[float]: ## Stores time, in seconds
	set(to):
		times = to
		
		## Update the best time.
		best_time = _get_best_time()
		
		## Update the ranking
		ranking = _get_ranking()
var best_time:float ## The best time out of times.

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

func _get_best_time() -> float: 
	var best:float = INF
	
	for time in times:
		if min(best, time) == time:
			best = time
	
	return best

func _get_ranking(for_time := best_time) -> String:
	var current_max := 0.0
	
	for rank in RANKINGS:
		current_max = ranking_maximums[rank]
		
		if for_time <= current_max:
			match rank: # Return as single-character
				RANKINGS.D: return "D"
				RANKINGS.C: return "C"
				RANKINGS.B: return "B"
				RANKINGS.A: return "A"
				RANKINGS.S: return "S"
	
	return "F"
