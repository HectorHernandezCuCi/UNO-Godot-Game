extends Node2D

@onready var cards_parent = $Cards

@export_group("Layout Settings")
@export var deck_position: Vector2 = Vector2(120, 150)
@export var hand_center_pos: Vector2 = Vector2(576, 580)
@export var discard_position: Vector2 = Vector2(576, 324)
@export var card_overlap: float = 50.0 
@export var hover_lift: float = 80.0
@export var hover_scale: float = 1.2

@export_group("UI Scenes")
@export var color_selector_scene: PackedScene # Drag your ColorSelect.tscn here

var deck: Array = [] 
var hand: Array = [] 
var discard_pile: Array = []
var hovered_card = null
var is_waiting_for_color: bool = false

# --- Initialization ---

func _ready():
	await get_tree().process_frame
	setup_game()

func check_top_card_wild():
	if discard_pile.size() > 0:
		var top_card = discard_pile.back()
		# Si la carta superior es WILD (índices 4 o 5)
		if top_card.card_color >= 4:
			_start_color_selection(top_card)

func setup_game():
	# 1. Collect and Shuffle
	deck = cards_parent.get_children()
	deck.shuffle()
	
	for i in range(deck.size()):
		var card = deck[i]
		card.position = deck_position
		card.z_index = i
		card.is_in_hand = false
	
	# 2. Play first card to discard pile
	if deck.size() > 0:
		var first_card = deck.pop_back()
		_play_to_discard(first_card, true)
	
	# 3. Deal initial 7 cards
	for i in range(7):
		draw_card_to_hand()

# --- Card Logic ---

func draw_card_to_hand():
	if deck.size() > 0 and not is_waiting_for_color:
		var card = deck.pop_back() 
		hand.append(card)
		card.is_in_hand = true
		reorganize_hand()
		check_top_card_wild() 

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
		card.base_position = target_pos
		
		# Only animate if not currently hovered
		if card != hovered_card:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(card, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "scale", Vector2.ONE, 0.2)
			card.z_index = 100 + i 

func request_play_card(card):
	# Prevent playing while color menu is open
	if is_waiting_for_color: return

	var top_card = discard_pile.back()
	
	# WILD Check (Index 4 is WILD, Index 5 is WILD DRAW 4)
	var is_wild = card.card_color >= 4 
	var matches_top = card.card_color == top_card.card_color or card.card_value == top_card.card_value

	if is_wild or matches_top:
		if is_wild:
			_start_color_selection(card)
		else:
			_play_to_discard(card)
	else:
		_shake_card(card)

# --- Wild Color Selection ---

func _start_color_selection(card):
	is_waiting_for_color = true
	var selector = color_selector_scene.instantiate()
	add_child(selector)
	
	# Wait for signal from UI
	selector.color_selected.connect(func(color_index):
		card.card_color = color_index 
		
		# Visual feedback for the new color
		var colors = [Color.RED, Color.CORNFLOWER_BLUE, Color.GREEN, Color.YELLOW]
		card.modulate = colors[color_index]
		
		_play_to_discard(card)
		is_waiting_for_color = false
	)

# --- Discard and Visuals ---

func _play_to_discard(card, is_initial = false):
	if not is_initial:
		hand.erase(card)
		card.is_in_hand = false
		if hovered_card == card: hovered_card = null
	
	discard_pile.append(card)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", discard_position, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3)
	
	card.z_index = discard_pile.size()
	reorganize_hand()

func _shake_card(card):
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color.RED, 0.1)
	tween.tween_property(card, "modulate", Color.WHITE, 0.1)

# --- Interaction Handling ---

func _process(_delta):
	if not is_waiting_for_color:
		_update_hover_priority()

func _update_hover_priority():
	var mouse_pos = get_global_mouse_position()
	var potential_cards = []

	for card in hand:
		var area = card.get_node("Area2D")
		var shapes = area.get_children()
		for s in shapes:
			if s is CollisionShape2D:
				if s.shape.get_rect().has_point(card.to_local(mouse_pos)):
					potential_cards.append(card)
					break

	var top_card = null
	if potential_cards.size() > 0:
		top_card = potential_cards[0]
		for c in potential_cards:
			if c.z_index > top_card.z_index: top_card = c

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
