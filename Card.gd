extends Sprite2D

# Enums to categorize the card
enum CardColor { RED, BLUE, GREEN, YELLOW, WILD }
enum CardType { NUMBER, SKIP, REVERSE, DRAW2, DRAW4, WILD_COLOR }

@export_group("Card Settings")
@export var card_color: CardColor = CardColor.RED
@export var card_type: CardType = CardType.NUMBER
@export var card_value: int = 0 # Only used if card_type is NUMBER

func _on_area_2d_card_action(left: bool) -> void:
	if left:
		# Get the name of the enum value as a string for debugging
		var color_str: String = CardColor.keys()[card_color]
		var type_str: String = CardType.keys()[card_type]
		
		print("Card Clicked! Info: ", color_str, " | ", type_str, " | Value: ", card_value)
		
		# Example logic: if you need to pass this data to a GameManager
		# GameManager.play_card(self)
	else:
		print("Right click detected (optional action)")
