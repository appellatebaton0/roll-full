class_name LevelEditor extends PanelContainer
## Manages most if not all of the functionality for the LevelEditor.

## Viewport variables
@onready var viewport_container := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer
@onready var viewport_camera    := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer/SubViewport/Camera
@onready var viewport           := $MarginContainer/VBoxContainer/Layout/PanelContainer2/MarginContainer/PanelContainer/SubViewportContainer/SubViewport

func _ready() -> void:
	viewport_container.gui_input.connect(_viewport_gui_input)

# Catch inputs into the viewport for camera scrolling.
func _viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			
			var direction:Vector2
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:    direction = Vector2.UP
				MOUSE_BUTTON_WHEEL_DOWN:  direction = Vector2.DOWN
				MOUSE_BUTTON_WHEEL_LEFT:  direction = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_RIGHT: direction = Vector2.RIGHT
				_: return
			
			if event.shift_pressed: direction = direction.rotated(PI / 2)
			
			viewport_camera.position += direction * 15 / viewport_camera.zoom
