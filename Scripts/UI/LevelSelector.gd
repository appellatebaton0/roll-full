class_name LevelSelector extends Control
## Manages the LevelSelection nodes.

signal selection_updated(to:LevelData)

const LEVEL_ENTRY_SCENE := preload("res://Scenes/UIElements/LevelEntry.tscn")

@export var focused := false

@export var spin_container :SpinContainer
@export var entry_container:CycleContainer
var level_entries:Array[LevelEntry]

## The currently selected level entry.
var selected:LevelEntry:
	set(to):
		if selected: selected.selected = false
		selected = to
		if selected: selected.selected = true
		
		selection_updated.emit(to.level_data)
		
		_on_focused()

func _ready() -> void:
	create_level_entries()
	
	## Wire up the signals so that when a entry is clicked on, it's selected, and when one is focused,
	## The currently selected one is focused instead.
	for entry in level_entries:
		entry.pressed.connect(select.bind(entry))
		entry.focus_entered.connect(_on_focused.bind(entry))

	focus_entered.connect(_on_focused)

func _on_focused(node:Node = self) -> void: if node != selected: selected.grab_focus()

func _process(delta: float) -> void: if focused:
	
	## Per entry, move 137 units on the cycle, 9.23u on the spin.
	
	## Scroll the cycle and spin containers to center on the selected entry.
	if selected:
		var selected_center_y := selected.global_position.y + (selected.size.y * selected.scale.y / 2)
		if abs(selected_center_y - 432) > 1:
			entry_container.scroll_offset += (432 - selected_center_y) * 10 * delta
			
		elif abs(selected_center_y - 432) > 0.2:
			entry_container.scroll_offset += (432 - selected_center_y)
	spin_container.add_angle = 19.8 + (entry_container.scroll_offset * (9.23 / 137.))
	
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
	if target is int: selected = level_entries[target]
	if target is LevelEntry: if level_entries.has(target): selected = target

## Creates all the needed level_entries, and adds them to the entry_container.
func create_level_entries() -> void:
	
	var level_data := Global.LEVEL_DATA
	
	var entries:Array[LevelEntry]
	for node in entry_container.get_children(): 
		if node is LevelEntry: entries.append(node)
	
	# Make sure the amount of entries is correct, but use existing ones.
	var len_dist := len(entries) - len(level_data)
	while len_dist != 0:
		# If extra, get rid of them.
		if   len_dist > 0: entries.pop_back().queue_free()
		# If missing some, make more.
		elif len_dist < 0: 
			var new:LevelEntry = LEVEL_ENTRY_SCENE.instantiate()
			
			new.focus_mode = Control.FOCUS_NONE
			
			entry_container.add_child(new)
			entries.append(new)
		
		# Update the check.
		len_dist = len(entries) != len(level_data)
	
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
