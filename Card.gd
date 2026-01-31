extends Sprite2D

enum CardColor { RED, BLUE, GREEN, YELLOW, WILD }
enum CardType { NUMBER, SKIP, REVERSE, DRAW2, DRAW4, WILD_COLOR }

@export var card_color: CardColor = CardColor.RED
@export var card_type: CardType = CardType.NUMBER
@export var card_value: int = 0 

var is_in_hand: bool = false 
var base_position: Vector2

func set_hover(active: bool, lift: float = 60.0, scale_amount: float = 1.15):
	if not is_in_hand: return
	
	var tween = create_tween().set_parallel(true)
	if active:
		var hover_pos = base_position + Vector2(0, -lift)
		tween.tween_property(self, "position", hover_pos, 0.2).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "scale", Vector2.ONE * scale_amount, 0.2)
	else:
		tween.tween_property(self, "position", base_position, 0.2).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func _on_area_2d_card_action(left: bool) -> void:
	if is_in_hand and left:
		print("Jugando carta: ", card_value)
