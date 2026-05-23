class_name LevelMusicDriver extends AudioStreamPlayer
## Handles the adaptive music for a level.

@onready var player:Player = get_tree().get_first_node_in_group("Player"):
	get():
		if not is_instance_valid(player) or not player:
			player = get_tree().get_first_node_in_group("Player")
		return player

## -- BEAT INFORMATION -- ##

var bpm := -1.

var beat_delta:float # The amount the beat has changed since the last frame.
var beat := 0.0:
	set(to):
		beat_delta = abs(to - beat)
		beat = to

## -- TRANSITION STATE -- ##

# Which tracks should be active
@export_flags_2d_render var state:int: set = set_state
# Which tracks are transitioning to full volume.
var untransitioned:int = 0
var level_data:LevelData

# - TRANSITION BUFFERING - #

var transition_start_beat := -1   # When the transition should start.
var state_buffer:int              # What to transition to.
@export var transition_beats := 8 # How many beats it takes to transition

## Whether the current level has been complete, and this track should fade out.
var resolving := false
func resolve() -> void:
	
	# Already resolved.
	if state == 0 and not level_data: return
	
	resolving = true
	state = 0

func _ready() -> void: 
	bus = &"Music"
	Global.reset_level.connect(func(): state = 1)

func reload(from:LevelData):
	level_data = from
	
	## Create the stream.
	var new_stream := AudioStreamSynchronized.new()
	var track_count:int = len(from.tracks)
	bpm = -1
	
	# Update the stream count.,
	new_stream.set_stream_count(track_count)
	
	# Create all the sync streams from the tracks.
	for i in range(track_count):
		new_stream.set_sync_stream(i, from.tracks[i])
		new_stream.set_sync_stream_volume(i, linear_to_db(0))
		
		# If the bpm hasn't been set yet, try to set it from this track.
		if bpm < 0 and from.tracks[i]:
			var beats_per = from.tracks[i].get("bpm")
			if beats_per: bpm = beats_per
	
	set_stream(new_stream)
	
	# Start the playback.
	play()

func _process(_delta: float) -> void:
	
	# Update the beat.
	beat = (get_playback_position() +  AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * bpm / 60
	
	# See if the state has changed, and so should make a transition to the new state.
	if player and level_data: if player.is_on_wall():
		var new_state := level_data._get_track_state(player.real_velocity.distance_to(Vector2.ZERO) / 100., Global.score)
		#print(new_state, " vs ", state, "/", state_buffer)
		
		if new_state != state and new_state != state_buffer:
			state = new_state
	
	# If there's a waiting buffer, attempt to clear it.
	if state_buffer != state: state = state_buffer
	
	# Transition the state.
	transition()
	
	# IF the state is everything off, and it's done making that transition, clear everything out.
	if resolving and untransitioned == 0:
		stream = null
		level_data = null
		resolving = false
		stop()


## Manage the transition of track volumes.
func transition() -> void:
	if stream is AudioStreamSynchronized:
		var index := 1
		
		for i in range(31): 
			if untransitioned & index:
				
				var new_value:float = move_toward(db_to_linear(stream.get_sync_stream_volume(i)), float((state & index) >> i), beat_delta / transition_beats)
				
				stream.set_sync_stream_volume(i, linear_to_db(new_value))
				
				# If the value is what it's supposed to be, erase
				# This index from the untransitioned list.
				if new_value == (state & index) >> (i):
					untransitioned ^= index
			
			index *= 2

func set_state(to:int): 
	# If it's time to start the transition.
	if transition_start_beat > ceil(beat):
		transition_start_beat = ceil(beat)
	
	#print(floor(beat),"|", transition_start_beat,"|", transition_start_beat >= 0)
	if floor(beat) > transition_start_beat and transition_start_beat >= 0:
		## Note which bits have changed, since they'll need to be transitioned.
		## Keep on any that still aren't done.
		untransitioned = untransitioned | (state ^ to)
		
		## Update the state
		state = to
		
		transition_start_beat = -1
	
	# If this is the first attempt to set this beat.
	else:
		if transition_start_beat == -1:
			transition_start_beat = ceil(beat)
		state_buffer = to
