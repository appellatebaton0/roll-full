class_name AnimationButton extends Button
## Plays an animation off an animator, or the global one.

@export var animation_name:String
@export var use_global := false
@export var animator:AnimationPlayer

func _ready() -> void:
	if not animator and not use_global:
		animator = find_animator()

func _pressed() -> void:
	if use_global: 
		Global.request_animation.emit(animation_name)
		return
	
	if animator:
		if animator.has_animation(animation_name) and not animator.is_playing():
			animator.play(animation_name)

func find_animator(with:Node = self, depth := 7) -> AnimationPlayer:
	
	if not with or depth == 0: return null 
	
	if with is AnimationPlayer:
		return with
	
	for child in with.get_children():
		if child is AnimationPlayer: return child
	
	return find_animator(with.get_parent(), depth - 1)
