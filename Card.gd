extends Sprite2D

enum CardColor { RED, BLUE, GREEN, YELLOW, WILD }
enum CardType { NUMBER, SKIP, REVERSE, DRAW2, DRAW4, WILD_COLOR }

@export_group("Card Settings")
@export var card_color: CardColor = CardColor.RED
@export var card_type: CardType = CardType.NUMBER
@export var card_value: int = 0 

var is_in_hand: bool = false 
var base_position: Vector2 = Vector2.ZERO
var is_hovered: bool = false
var current_tween: Tween = null  # Reference to the active tween

# Validation in _ready
func _ready():
	# Verify Area2D exists
	if not has_node("Area2D"):
		push_warning("Card '%s' missing Area2D node!" % name)
		return
	
	var area = get_node("Area2D")
	
	# Connect signals if they exist
	if area.has_signal("input_event"):
		if not area.input_event.is_connected(_on_area_2d_input_event):
			area.input_event.connect(_on_area_2d_input_event)

func set_hover(active: bool, lift: float = 60.0, scale_amount: float = 1.15):
	"""Applies or removes the hover effect"""
	if not is_in_hand: 
		return
	
	is_hovered = active
	
	# Kill previous tween if it exists
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	
	# Create new tween
	current_tween = create_tween().set_parallel(true)
	
	if active:
		var hover_pos = base_position + Vector2(0, -lift)
		current_tween.tween_property(self, "position", hover_pos, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		current_tween.tween_property(self, "scale", Vector2(scale_amount, scale_amount), 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		current_tween.tween_property(self, "position", base_position, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		current_tween.tween_property(self, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	"""Handles clicks on the card"""
	if not (event is InputEventMouseButton):
		return
	
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	# Only allow click if in hand AND hovered
	if not is_in_hand or not is_hovered:
		return
	
	# Search for GameManager (Current Scene)
	var manager = get_tree().current_scene
	if manager == null:
		push_error("ERROR: Could not find current scene!")
		return
	
	if not manager.has_method("request_play_card"):
		push_error("ERROR: Current scene doesn't have request_play_card method!")
		return
	
	manager.request_play_card(self)

# Legacy compatibility method
func _on_area_2d_card_action(left: bool) -> void:
	if is_in_hand and left and is_hovered:
		var manager = get_tree().current_scene
		if manager != null and manager.has_method("request_play_card"):
			manager.request_play_card(self)
