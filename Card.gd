extends Sprite2D

# Enums para categorizar la carta
enum CardColor { RED, BLUE, GREEN, YELLOW, WILD }
enum CardType { NUMBER, SKIP, REVERSE, DRAW2, DRAW4, WILD_COLOR }

@export_group("Card Settings")
@export var card_color: CardColor = CardColor.RED
@export var card_type: CardType = CardType.NUMBER
@export var card_value: int = 0 

# Esta variable es vital para que el GameManager la reconozca
var is_in_hand: bool = false 

func _on_area_2d_card_action(left: bool) -> void:
	# Si la carta está en el mazo, no hacemos nada
	if not is_in_hand:
		return

	if left:
		var color_str: String = CardColor.keys()[card_color]
		var type_str: String = CardType.keys()[card_type]
		print("Acción en mano: ", color_str, " | ", type_str, " | Valor: ", card_value)
		
		# Aquí podrías llamar a: GameManager.play_card(self)
	else:
		print("Click derecho detectado en la mano")
