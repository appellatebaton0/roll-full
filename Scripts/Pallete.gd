class_name ColorPallete extends Resource
## Like a theme, but not. The colors used in the game.

@export_group("Base", "base_")
@export var base:Color           ## The base color for UI elements.
@export var base_text:Color      ## The color of text on the base.
@export var base_text_high:Color ## The color of special text on the base.

@export_group("Highlight", "high_")

@export var high:Color        ## The base color for UI highlight elements.
@export var high_text:Color   ## The color of text on highlight elements.
@export var high_shadow:Color ## The color of shadows on UI highlight elements.

@export_group("Other")
@export var secondary:Color  ## Used for the level background.
@export var transition:Color ## The color used mainly for transitions.
