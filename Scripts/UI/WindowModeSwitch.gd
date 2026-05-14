class_name WindowModeSwitch extends OptionButton
## Allows the user to change the window mode.

const OPTIONS:Dictionary[String, DisplayServer.WindowMode] = {
	"Fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"Maximized":  DisplayServer.WINDOW_MODE_MAXIMIZED,
	"Minimized":  DisplayServer.WINDOW_MODE_MINIMIZED,
	"Windowed":   DisplayServer.WINDOW_MODE_WINDOWED,	
}

func _ready() -> void:
	clear()
	for option in OPTIONS: add_item(option)
	
	selected = OPTIONS.values().find(DisplayServer.window_get_mode())
	
	item_selected.connect(_selected)

func _selected(new:int): 
	DisplayServer.window_set_mode(OPTIONS[get_item_text(new)])
