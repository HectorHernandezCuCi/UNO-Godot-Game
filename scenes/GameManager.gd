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
@export var color_selector_scene: PackedScene

var deck: Array = [] 
var hand: Array = [] 
var discard_pile: Array = []
var hovered_card = null
var is_waiting_for_color: bool = false
var is_processing_play: bool = false # Prevents double-clicks

# --- Initialization ---

func _ready():
	# Initial Validation
	if cards_parent == null:
		push_error("CRITICAL: 'Cards' node not found! Cannot start game.")
		return
	
	if color_selector_scene == null:
		push_error("WARNING: color_selector_scene not assigned! Wild cards won't work.")
	
	await get_tree().process_frame
	setup_game()

func setup_game():
	# 1. Collect and Shuffle
	deck = cards_parent.get_children()
	
	if deck.size() == 0:
		push_error("CRITICAL: No cards found in Cards node!")
		return
	
	deck.shuffle()
	
	# Initialize all cards
	for i in range(deck.size()):
		var card = deck[i]
		if card == null:
			push_error("WARNING: Null card found at index %d" % i)
			continue
		
		card.position = deck_position
		card.z_index = i
		card.is_in_hand = false
		
		if not card.has_method("set_hover"):
			push_error("WARNING: Card at index %d doesn't have set_hover method!" % i)
	
	# 2. Play first card to discard pile
	if deck.size() > 0:
		var first_card = deck.pop_back()
		_play_to_discard(first_card, true)
		
		# If the first card is WILD, force color selection
		await get_tree().process_frame
		check_top_card_wild()
	
	# 3. Deal initial 7 cards
	for i in range(7):
		if deck.size() == 0:
			push_warning("Deck empty! Could only deal %d cards." % i)
			break
		draw_card_to_hand()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		SceneManager.pause_game(true)

	

# --- Card Logic ---

func check_top_card_wild():
	"""Checks if the top card is WILD and requires color selection"""
	if discard_pile.size() == 0:
		return
	
	var top_card = discard_pile.back()
	if top_card == null:
		push_error("ERROR: Top card in discard pile is null!")
		return
	
	# If top card is WILD (indices 4 or 5) and has no color assigned
	if top_card.card_color >= 4 and not is_waiting_for_color:
		_start_color_selection(top_card)

func draw_card_to_hand():
	"""Draws a card from the deck to the player hand"""
	if deck.size() == 0:
		push_warning("Cannot draw: deck is empty!")
		return
	
	if is_waiting_for_color:
		push_warning("Cannot draw: waiting for wild card color selection")
		return
	
	var card = deck.pop_back()
	
	if card == null:
		push_error("ERROR: Drew null card from deck!")
		return
	
	hand.append(card)
	card.is_in_hand = true
	reorganize_hand()

func reorganize_hand():
	"""Reorganizes hand cards with dynamic spacing"""
	# Filter null references
	hand = hand.filter(func(c): return c != null)
	var card_count = hand.size()
	
	if card_count == 0:
		return
	
	# Calculate dynamic spacing to prevent cards from going off-screen
	var dynamic_overlap = card_overlap
	if card_count > 10:
		dynamic_overlap = 400.0 / (card_count - 1)
	
	var total_width = dynamic_overlap * (card_count - 1)
	var start_x = hand_center_pos.x - (total_width / 2)
	
	for i in range(card_count):
		var card = hand[i]
		if card == null:
			continue
		
		var target_pos = Vector2(start_x + (i * dynamic_overlap), hand_center_pos.y)
		card.base_position = target_pos
		
		# Only animate if not currently hovered
		if card != hovered_card:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(card, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "scale", Vector2.ONE, 0.2)
			card.z_index = 100 + i

func request_play_card(card):
	"""Attempts to play a card from the hand"""
	if card == null:
		push_error("ERROR: Attempted to play null card!")
		return
	
	if is_processing_play:
		return 
	
	if is_waiting_for_color:
		push_warning("Cannot play: waiting for wild card color selection")
		return
	
	if not card.is_in_hand:
		push_warning("Cannot play: card is not in hand!")
		return
	
	# CRITICAL: Only allow playing the card currently hovered
	if card != hovered_card:
		return
	
	if not card in hand:
		push_error("ERROR: Card not found in hand array!")
		return
	
	if discard_pile.size() == 0:
		push_error("ERROR: Discard pile is empty!")
		return
	
	var top_card = discard_pile.back()
	if top_card == null:
		push_error("ERROR: Top card in discard pile is null!")
		return
	
	# Verify move validity
	var is_wild = card.card_color >= 4
	var matches_color = card.card_color == top_card.card_color
	var matches_value = card.card_value == top_card.card_value
	var matches_top = matches_color or matches_value
	
	is_processing_play = true
	
	if is_wild or matches_top:
		if is_wild:
			_start_color_selection(card)
		else:
			_play_to_discard(card)
	else:
		_shake_card(card)
	
	is_processing_play = false

# --- Wild Color Selection ---

func _start_color_selection(card):
	"""Initializes color selection process for WILD cards"""
	if card == null:
		push_error("ERROR: Cannot start color selection for null card!")
		return
	
	if color_selector_scene == null:
		push_error("CRITICAL: color_selector_scene not assigned! Falling back to Red.")
		card.card_color = 0 # Fallback to RED
		if card.is_in_hand:
			_play_to_discard(card)
		return
	
	is_waiting_for_color = true
	var selector = color_selector_scene.instantiate()
	
	if selector == null:
		push_error("ERROR: Failed to instantiate color selector!")
		is_waiting_for_color = false
		return
	
	add_child(selector)
	
	if not selector.has_signal("color_selected"):
		push_error("ERROR: Color selector missing 'color_selected' signal!")
		selector.queue_free()
		is_waiting_for_color = false
		return
	
	selector.color_selected.connect(func(color_index):
		_on_wild_color_selected(card, color_index, selector)
	)

func _on_wild_color_selected(card, color_index: int, selector):
	"""Callback for when a user selects a color for a WILD card"""
	if card == null:
		push_error("ERROR: Card became null during color selection!")
		is_waiting_for_color = false
		if selector != null and is_instance_valid(selector):
			selector.queue_free()
		return
	
	if color_index < 0 or color_index > 3:
		push_error("ERROR: Invalid color index: %d. Defaulting to RED." % color_index)
		color_index = 0
	
	card.card_color = color_index
	
	# Visual feedback for the chosen color
	var colors = [Color.RED, Color.CORNFLOWER_BLUE, Color.GREEN, Color.YELLOW]
	card.modulate = colors[color_index]
	
	if card.is_in_hand and card in hand:
		_play_to_discard(card)
	
	is_waiting_for_color = false

# --- Discard and Visuals ---

func _play_to_discard(card, is_initial: bool = false):
	"""Moves a card to the discard pile"""
	if card == null:
		push_error("ERROR: Attempted to discard null card!")
		return
	
	# Remove from hand if not the initial setup card
	if not is_initial:
		if card in hand:
			hand.erase(card)
		card.is_in_hand = false
		if hovered_card == card: 
			hovered_card = null
	
	discard_pile.append(card)
	
	# Discard animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", discard_position, 0.4)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3)
	
	card.z_index = discard_pile.size()
	
	reorganize_hand()

func _shake_card(card):
	"""Visual feedback for an invalid move"""
	if card == null or not is_instance_valid(card):
		return
	
	var original_modulate = card.modulate
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color.RED, 0.1)
	tween.tween_property(card, "modulate", original_modulate, 0.1)

# --- Interaction Handling ---

func _process(_delta):
	if not is_waiting_for_color and not is_processing_play:
		_update_hover_priority()

func _update_hover_priority():
	"""Determines which card should be hovered based on mouse position and Z-index"""
	var mouse_pos = get_global_mouse_position()
	var potential_cards = []
	
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
	for card in hand:
		if not card.has_node("Area2D"):
			continue
		
		var area = card.get_node("Area2D")
		var shapes = area.get_children()
		for s in shapes:
			if s is CollisionShape2D and s.shape != null:
				var rect = s.shape.get_rect()
				if rect.has_point(card.to_local(mouse_pos)):
					potential_cards.append(card)
					break
	
	# Find the card with the highest z_index (the one on top visually)
	var top_card = null
	if potential_cards.size() > 0:
		top_card = potential_cards[0]
		for c in potential_cards:
			if c.z_index > top_card.z_index: 
				top_card = c
	
	# Update hover status only if it changed
	if top_card != hovered_card:
		if hovered_card != null and is_instance_valid(hovered_card):
			if hovered_card.has_method("set_hover"):
				hovered_card.set_hover(false)
		
		hovered_card = top_card
		if hovered_card != null and is_instance_valid(hovered_card):
			hovered_card.z_index = 300 # Bring to very front
			if hovered_card.has_method("set_hover"):
				hovered_card.set_hover(true, hover_lift, hover_scale)
			reorganize_hand()

func _input(event):
	"""Handles user inputs like clicking the deck"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Draw card when clicking the deck area
		if get_global_mouse_position().distance_to(deck_position) < 80:
			draw_card_to_hand()
