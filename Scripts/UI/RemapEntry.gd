extends BoxContainer

@export var action:String
@export var label_override:String

@export var buttons:Array[RemapButton]

func _ready() -> void:
	
	$InputLabel.text = action if not label_override else label_override
	
	for button in buttons:
		button.action = action
		
		for targ in buttons: 
			if targ == button: continue
			
			button.remapped.connect(targ._toggled)
		
		button._toggled()
