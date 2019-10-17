extends Camera2D

onready var tween:Tween = $Tween

func _ready():
	pass # Replace with function body.

func _input(event):
	if tween.is_active():
		return

	if event.is_action_pressed("next"):
		_move_vertical(1)
	elif event.is_action_pressed("prev"):
		_move_vertical(-1)

func _move_vertical(dir:int):
	var new_position_y = global_position.y + _delta_height() * dir
	tween.interpolate_property(self, "global_position:y", global_position.y,  new_position_y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()
	
func _delta_height() -> float:
	return get_tree().get_root().get_viewport().get_visible_rect().size.y