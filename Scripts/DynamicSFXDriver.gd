class_name DynamicSFXDriver extends Node
## Allows for automatically setting up UI sounds.

static var _existing_driver:DynamicSFXDriver
static var setup_queue:Array[Node] ## Nodes waiting to be set up.
static func setup(with:Node):
	
	# Recursively get all the node's children.
	var total_nodes:Array[Node] = []
	var queued_nodes:Array[Node] = [with]
	while queued_nodes.size():
		var node := queued_nodes.pop_back() as Node
		total_nodes += [node]
		queued_nodes += node.get_children()
	
	# Set up all the nodes
	setup_queue += total_nodes

@export var initial_setup:Array[Node]

@export var sound_bank:Dictionary[String, AudioStream]
@export var instant_setup_classes:Array[String]

func _ready() -> void:
	
	
	if _existing_driver:
		queue_free()
		_existing_driver.instant_setup_classes += instant_setup_classes
	else:
		_existing_driver = self
	
	# Pass the initial setup stuff to the queue.
	for node in initial_setup: setup(node)
	
	get_tree().node_added.connect(func(node:Node):
		
		for type in instant_setup_classes:
			if node.is_class(type): 
				setup_queue += [node]
				return
		
		)

func _process(_delta: float) -> void: 
	
	
	
	if _existing_driver == self:
		
		## Set up any nodes in the queue.
		while setup_queue.size() > 0:
			
			var node = setup_queue.pop_back()
			
			# Make sure the node's alright.
			if not is_instance_valid(node):      continue
			if node is not Node:                 continue
			if node.has_meta("IgnoreSFXDriver"): continue
			
			# For every pack of signals (ie, "button_pressed" is one,
			# but this also supports saying "button_pressed,button_down" to
			# connect both signals to the same sound.
			for signal_pack:String in sound_bank.keys():
				var sound := sound_bank[signal_pack]
				var target_class:String = ""
				if signal_pack.contains(":"): 
					target_class = signal_pack.get_slice(":", 0)
					signal_pack = signal_pack.replace(target_class + ":", "")
				var signal_names := signal_pack.split("/")
				
				# Bind all the signals in this pack to the requester.
				for signal_name in signal_names:
					if node.has_signal(signal_name) and (node.is_class(target_class) or target_class == ""):
						
						node.connect(signal_name, request_sound.bind(sound))

var player_pool:Array[AudioStreamPlayer]

func request_sound(sound:AudioStream):
	
	var player := find_player()
	
	if player.stream != sound: player.stream = sound
	
	player.play()

func find_player() -> AudioStreamPlayer:
	
	# Check the existing players for any that're unused.
	for player in player_pool:
		if not player.playing:
			return player
	
	# Found none, make a new one.
	var new := AudioStreamPlayer.new()
	new.bus = &"SFX"
	add_child(new)
	
	return new
