class_name LevelData extends Resource
## Holds all the reference data for a level.

signal runs_updated

@export var name:String ## The name of the level.

@export var scene:PackedScene ## The scene containing this level.

class Run:
	var time:float
	var score:int
	var ranking:int
	var bonused:bool
	var speed:float
	func _init(set_time:float, set_score:int, set_ranking:int, set_bonused:bool, set_speed:float):
		time = set_time
		score = set_score
		
		ranking = set_ranking# _get_ranking()
		bonused = set_bonused# _is_bonused(ranking)
		
		speed = set_speed
	
	## How many points this run is worth.
	func rating() -> int:
		
		var points := 0
		
		## Add two points per rank level (S is 10, A is 8, F is 0, etc)
		var rank := ranking
		if rank != -1:
			points += 10 - (rank * 2)
		
		## Add an extra point if bonused. This way, bonused runs always beat out non-bonused of the same rank.
		if bonused: points += 1
		
		return points
	
	func ranking_as_string(rank:RANKINGS = ranking as RANKINGS) -> String:
		match rank:
			RANKINGS.S: return "S"
			RANKINGS.A: return "A"
			RANKINGS.B: return "B"
			RANKINGS.C: return "C"
			RANKINGS.D: return "D"
		return "F"

var runs:Array[Run]: ## Stores time:score runs, in seconds and points
	set(to):
		runs = to
		
		## Update the best run.
		best_run = _get_best_run()
		
		## Update the ranking and bonused.
		ranking = best_run.ranking
		bonused = best_run.bonused
		
		## Update the best time/score
		best_time  = _get_best_time()
		best_score = _get_best_score()
		
		runs_updated.emit()
var best_run:Run ## The best run, overall.

enum RANKINGS {S, A, B, C, D}
@export var ranking_maximums:Dictionary[RANKINGS, float] = {
	RANKINGS.S: 0,
	RANKINGS.A: 0,
	RANKINGS.B: 0,
	RANKINGS.C: 0,
	RANKINGS.D: 0,
}
@export var score_threshold:int

## The current letter ranking for this level.
var ranking:int
var bonused:bool

var best_time:float
var best_score:int

func _get_best_run() -> Run:
	## Turn each Run into their rating.
	var ratings := []
	for run in runs:
		ratings.append(run.rating())
	
	## Get the best rating out of the list
	var best := 0
	for rating in ratings:
		best = max(best, rating)
	
	## Return the run that has that best rating.
	return runs[ratings.find(best)]

func _get_best_time() -> float:
	## Turn each Run into their time.
	var times := []
	for run in runs:
		times.append(run.time)
	
	## Get the best time out of the list
	var best := 0
	for time in times:
		best = max(best, time)
	
	return best

func _get_best_score() -> int:
	# Turn each Run into their score.
	var scores := []
	for run in runs:
		scores.append(run.score)
	
	# Get the best time out of the list
	var best := 0
	for score in scores:
		best = max(best, score)
	
	return best

## Ran whenever a level is beat.
func log_run(time:float, score:int):
	var rank := _get_ranking(time) # Get the ranking.
	# Append the new run to the list.
	runs += [Run.new(time, score, rank, _is_bonused(score), Global.default_time_scale)]

## Figure out the ranking for a time.
func _get_ranking(time:float) -> int:
	var current_max := 0.0

	# From S to D, check if the time is under the time threshold.
	for i in range(RANKINGS.size()):
		current_max = ranking_maximums[i]
		
		# It's under, so this is the rank.
		# Ex, S = 12 seconds, an 11 second run would return RANKINGS.S
		if time <= current_max: return i as RANKINGS
	
	# -1 counts for F, and is the default.
	return -1

## Whether the input score is over the threshold.
func _is_bonused(score:int) -> bool: return score >= score_threshold
