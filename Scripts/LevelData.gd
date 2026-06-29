class_name LevelData extends Resource
## Holds all the reference data for a level.

## -- RUN INFORMATION -- ## 

signal runs_updated

@export var name:String ## The name of the level.
@export_range(0, 6400, 20) var base_player_speed := 2500

@export var scene:PackedScene ## The scene containing this level.
@export var editor_scene:PackedScene ## The scene containing the placeholder representation of this level.

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
		
		if to.size() > 0:
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
	RANKINGS.S: 70,
	RANKINGS.A: 80,
	RANKINGS.B: 90,
	RANKINGS.C: 100,
	RANKINGS.D: 120,
}
@export var score_threshold:int = 1000

## The current letter ranking for this level.
var ranking:int
var bonused:bool

var best_time:float
var best_score:int

func _get_best_run() -> Run:
	
	var best:Run = null
	var viable_runs := runs.duplicate()
	
	## Cut the options down to the highest rank achieved thus far.
	
	# Get the best rank.
	#for i in RANKINGS.size():
	
	var best_rank := 7
	for run in viable_runs:
		var val:int = run.ranking if run.ranking != -1 else 5
		best_rank = min(val, best_rank)
	
	# Filter to just those with that rank.
	viable_runs = viable_runs.filter(func(a:Run) -> bool:
		return (a.ranking if a.ranking != -1 else 5) == best_rank
		)
	
	## If any are bonused, filter to just bonused options.
	
	# Figure out if any are bonused.
	var has_bonused := false
	for run in viable_runs: if run.bonused: 
		has_bonused = true
		break
	
	# If any are, filter to just the bonused rankings.
	if has_bonused:
		viable_runs = viable_runs.filter(func(a:Run) -> bool:
			return a.bonused
			)
	
	## Return the run out of the remaining options with the best time.
	
	for run in viable_runs:
		if best == null: 
			best = run
			continue
		
		if best.time > run.time:
			best = run
	
	return best

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
	runs += [Run.new(time, score, rank, _is_bonused(score), Global.time_scale_modifiers["Gamespeed"])]

## Figure out the ranking for a time.
func _get_ranking(time:float) -> int:
	var current_max := 0.0

	# From S to D, check if the time is under the time threshold.
	for i in RANKINGS.size():
		current_max = ranking_maximums[i]
		
		# It's under, so this is the rank.
		# Ex, S = 12 seconds, an 11 second run would return RANKINGS.S
		if time <= current_max: return i as RANKINGS
	
	# -1 counts for F, and is the default.
	return -1

## Whether the input score is over the threshold.
func _is_bonused(score:int) -> bool: return score >= score_threshold

## -- MUSIC INFORMATION -- ##

## An override for the bpm, otherwise it'll be looked for in the tracks.
@export var override_bpm:float = -1.

## The tracks that make up this level's song. There should be 4.
@export var tracks:Dictionary[int, AudioStream] = {
	0: null,
	1: null,
	2: null,
	3: null,
}
