extends Area2D

# Signal to notify when the card is clicked
signal card_action(left: bool)

# _viewport and _shape_idx are prefixed with "_" to avoid "UNUSED_PARAMETER" warnings
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	# Check for Left Click
	if event.is_action_pressed("ClickL"):
		card_action.emit(true)
	
	# Check for Right Click
	elif event.is_action_pressed("ClickR"):
		card_action.emit(false)
