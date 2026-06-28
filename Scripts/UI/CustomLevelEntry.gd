class_name CustomLevelEntry extends Button
## Provides an interface into a level.

@onready var level_name:Label           = $MarginContainer/HBoxContainer/ScrollContainer/LevelName
@onready var scroll_container:ScrollContainer = $MarginContainer/HBoxContainer/ScrollContainer
@onready var scroll_h := scroll_container.get_h_scroll_bar()

var scroll_tween:Tween

@export var level_data:LevelData:
	set(to):
		level_data = to
		
		_on_runs_updated()

@export var selected := false:
	set(to):
		selected = to
		
		if selected:
			level_name.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			
			if scroll_tween and scroll_tween.is_running(): scroll_tween.kill()
			
			await scroll_h.changed
			
			# Possible Godot bug: max_value adds the size of the scroll container rect, so we need to correct for that
			# See: https://github.com/godotengine/godot/issues/62043
			var maxValueCorrected = scroll_h.max_value - scroll_container.get_rect().size.x

			# Account for content margins of scroll container stylebox
			var stylebox = scroll_container.get_theme_stylebox("panel")
			var margin_l = stylebox.get_margin(SIDE_LEFT)
			var margin_r = stylebox.get_margin(SIDE_RIGHT)
			maxValueCorrected += margin_l + margin_r
			
			# Looping scroll back-n-forth.
			scroll_tween = create_tween().set_loops()
			scroll_tween.tween_property(scroll_h, "value", maxValueCorrected, 2.5)
			scroll_tween.tween_interval(1.7)
			scroll_tween.tween_property(scroll_h, "value", 0, 2.)
			scroll_tween.tween_interval(1.2)
			
			
		else:
			level_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			
			# Reset to minimum scroll.
			if scroll_tween and scroll_tween.is_running(): scroll_tween.kill()
			await scroll_h.changed
			scroll_h.value = 0


func _on_runs_updated() -> void: if level_data:
	
	if not is_node_ready(): await ready
	
	level_name.text = level_data.name
