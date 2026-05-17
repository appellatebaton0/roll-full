class_name Tooltip extends Control

var text:String

var reveal_timer := 0.0
const REVEAL_TIME := 0.25

@onready var label := $PanelContainer/MarginContainer/RichTextLabel

func _ready() -> void: 
	label.text = text
	label.visible_characters = 0

func _process(delta: float) -> void:
	get_parent().size = get_parent().size / 2
	
	label.visible_characters = lerp(0, label.get_total_character_count(), reveal_timer)
	
	reveal_timer = move_toward(reveal_timer, 1.0, delta / REVEAL_TIME)
