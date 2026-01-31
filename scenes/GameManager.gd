extends Node2D

@onready var cards_parent = $Cards
@export var deck_position: Vector2 = Vector2(120, 150)
@export var hand_center_pos: Vector2 = Vector2(576, 580)
@export var card_overlap: float = 50.0 
@export var hover_lift: float = 80.0
@export var hover_scale: float = 1.2

var deck: Array = [] 
var hand: Array = [] 
var hovered_card = null

func _ready():
	await get_tree().process_frame
	setup_game()

func setup_game():
	deck = cards_parent.get_children()
	deck.shuffle()
	
	for i in range(deck.size()):
		var card = deck[i]
		card.position = deck_position
		card.z_index = i
		if "is_in_hand" in card: card.is_in_hand = false
	
	for i in range(7):
		draw_card_to_hand()

func draw_card_to_hand():
	if deck.size() > 0:
		var card = deck.pop_back() 
		hand.append(card)
		if "is_in_hand" in card: card.is_in_hand = true
		reorganize_hand()

func reorganize_hand():
	var card_count = hand.size()
	if card_count == 0: return
	
	var dynamic_overlap = card_overlap
	if card_count > 10:
		dynamic_overlap = 400.0 / (card_count - 1)

	var total_width = dynamic_overlap * (card_count - 1)
	var start_x = hand_center_pos.x - (total_width / 2)
	
	for i in range(card_count):
		var card = hand[i]
		var target_pos = Vector2(start_x + (i * dynamic_overlap), hand_center_pos.y)
		
		if "base_position" in card: card.base_position = target_pos
		
		if card != hovered_card:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(card, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "scale", Vector2.ONE, 0.2)
			card.z_index = 100 + i 

func _process(_delta):
	_update_hover_priority()

func _update_hover_priority():
	var mouse_pos = get_global_mouse_position()
	var potential_cards = []

	for card in hand:
		var area = card.get_node("Area2D")
		# Verificamos si el ratón está sobre el Area2D de la carta
		# Nota: Asegúrate de que 'Pickable' esté activado en el Inspector del Area2D
		var shapes = area.get_children()
		for s in shapes:
			if s is CollisionShape2D:
				var shape_rect = s.shape.get_rect()
				if shape_rect.has_point(card.to_local(mouse_pos)):
					potential_cards.append(card)
					break

	var top_card = null
	if potential_cards.size() > 0:
		top_card = potential_cards[0]
		for c in potential_cards:
			if c.z_index > top_card.z_index:
				top_card = c

	if top_card != hovered_card:
		if hovered_card: hovered_card.set_hover(false)
		hovered_card = top_card
		if hovered_card:
			hovered_card.z_index = 300 
			hovered_card.set_hover(true, hover_lift, hover_scale)
			reorganize_hand()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_global_mouse_position().distance_to(deck_position) < 80:
			draw_card_to_hand()
