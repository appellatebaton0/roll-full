class_name LevelSelector extends Control
## Manages the LevelSelection nodes.

signal selection_updated(to:LevelData)

@onready var data := Global.LEVEL_DATA

@export var entry_scene := preload("res://Scenes/UIElements/LevelEntry.tscn")

@export var focused := false

@export var spin_container :SpinContainer
@export var entry_container:CycleContainer
var level_entries:Array[Control]

## The currently selected level entry.
var selected:Control:
	set(to):
		if selected: selected.selected = false
		
		selected = to
		if selected: 
			selected.selected = true
		
		selection_updated.emit(to.level_data)
		
		_on_focused()
		tween_spin()

func _ready() -> void:
	create_level_entries()
	
	## Wire up the signals so that when a entry is clicked on, it's selected, and when one is focused,
	## The currently selected one is focused instead.
	for entry in level_entries:
		entry.pressed.connect(select.bind(entry))
		entry.focus_entered.connect(_on_focused.bind(entry))

	focus_entered.connect(_on_focused)

func _on_focused(node:Node = self) -> void: if node != selected: 
	selected.grab_focus()

var spin_tween:Tween
## Tween the Spin/CycleContainers to show the selection accurately.
func tween_spin():
	if not selected: return
	
	var a := wrapf(-entry_container.scroll_offset / entry_container.item_seperation, 0, level_entries.size())
	var b := level_entries.find(selected) as float
	
	var dist := wrapf(b-a, ceil(-level_entries.size() / 2.), floor(level_entries.size() / 2.))
	
	if spin_tween and spin_tween.is_running(): spin_tween.kill()
	
	spin_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	
	# Tween the entry container
	spin_tween.tween_property(entry_container, "scroll_offset", entry_container.scroll_offset -(dist * entry_container.item_seperation), 0.3)
	# Tween the spin container
	spin_tween.tween_property(spin_container, "add_angle", spin_container.add_angle - (dist * 360. / spin_container.get_children().filter(func(l):return l is Control).size()), 0.3)


func _process(_delta: float) -> void: if focused:
	
	## Allow for using Up/Down inputs to move the selection.
	if selected.has_focus():
		if Input.is_action_just_pressed("ui_up"):
			var index = wrap(level_entries.find(selected) - 1, 0, len(level_entries))
			select(index)
		elif Input.is_action_just_pressed("ui_down"):
			var index = wrap(level_entries.find(selected) + 1, 0, len(level_entries))
			select(index)

## Make a index or node the selected level entry
func select(target:Variant):
	if target is int: 
		selected = level_entries[target]
	if target is Control: if level_entries.has(target): 
		selected = target

## Creates all the needed level_entries, and adds them to the entry_container.
func create_level_entries(level_data:Array[LevelData] = data) -> void:
	
	level_data += level_data # Make two copies to allow wrapping.
	
	var entries:Array[Control]
	for node in entry_container.get_children(): 
		if node is Control: entries.append(node)
	
	# Make sure the amount of entries is correct, but use existing ones.
	var len_dist := entries.size() - level_data.size()
	while len_dist != 0:
		# If extra, get rid of them.
		if   len_dist > 0: entries.pop_back().queue_free()
		# If missing some, make more.
		elif len_dist < 0: 
			var new:Control = entry_scene.instantiate()
			
			entry_container.add_child(new)
			entries.append(new)
		
		# Update the check.
		len_dist = entries.size() - level_data.size()
	
	# Set each entry's level data.
	for i in len(level_data): entries[i].level_data = level_data[i]
	
	# Constant settings for the entries.
	for entry in entries:
		
		# Any focus movement up or down will loop back into the selector.
		entry.focus_neighbor_bottom = self.get_path()
		entry.focus_neighbor_top = self.get_path()
		
		# Inherit this node's neighbors for the remaining sides.
		entry.focus_neighbor_right = get_node(focus_neighbor_right).get_path()
		entry.focus_neighbor_left  = get_node(focus_neighbor_left).get_path()
	
	level_entries = entries
	
	select(0)

func find_entry_for_data(ldata:LevelData):
	for entry in level_entries:
		if entry.get("level_data") == ldata: return entry
	return null
