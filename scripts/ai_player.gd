extends Node

class_name AIPlayer

var hand: Array = []
var difficulty: String = "medium" # "easy", "medium", "hard"

signal ai_turn_complete

# --- AI Decision Making ---

func take_turn(top_card, deck_manager) -> void:
	"""AI takes its turn - either plays a card or draws"""
	await get_tree().create_timer(1.0).timeout # Delay for realism
	
	var playable_cards = _find_playable_cards(top_card)
	
	if playable_cards.size() > 0:
		var chosen_card = _choose_card_to_play(playable_cards, top_card)
		_play_card(chosen_card, deck_manager)
	else:
		# No playable cards - must draw
		var drawn_card = deck_manager.draw_card_for_ai(self)
		if drawn_card != null:
			hand.append(drawn_card)
			
			# Check if drawn card is playable
			await get_tree().create_timer(0.5).timeout
			if _can_play_card(drawn_card, top_card):
				if randf() > 0.3: # 70% chance to play immediately
					_play_card(drawn_card, deck_manager)
					return
		
		# Turn ends without playing
		ai_turn_complete.emit()

func _find_playable_cards(top_card) -> Array:
	"""Returns all cards the AI can legally play"""
	var playable = []
	
	for card in hand:
		if _can_play_card(card, top_card):
			playable.append(card)
	
	return playable

func _can_play_card(card, top_card) -> bool:
	"""Checks if a card can be played on top_card"""
	if card == null or top_card == null:
		return false
	
	# Wild cards can always be played
	if card.card_color >= 4:
		return true
	
	# Match color or value
	return card.card_color == top_card.card_color or card.card_value == top_card.card_value

func _choose_card_to_play(playable_cards: Array, top_card) -> Variant:
	"""AI strategy for choosing which card to play"""
	
	match difficulty:
		"easy":
			return playable_cards[randi() % playable_cards.size()] # Random
		
		"medium":
			return _medium_strategy(playable_cards, top_card)
		
		"hard":
			return _hard_strategy(playable_cards, top_card)
		
		_:
			return playable_cards[0]

func _medium_strategy(playable_cards: Array, top_card) -> Variant:
	"""Medium AI: Prefers action cards and matching colors"""
	
	# 1. Play action cards first (Skip, Reverse, Draw2)
	for card in playable_cards:
		if card.card_type in [1, 2, 3]: # SKIP, REVERSE, DRAW2
			return card
	
	# 2. Play cards matching the current color
	for card in playable_cards:
		if card.card_color == top_card.card_color and card.card_color < 4:
			return card
	
	# 3. Save wild cards for last
	var non_wild = playable_cards.filter(func(c): return c.card_color < 4)
	if non_wild.size() > 0:
		return non_wild[0]
	
	return playable_cards[0]

func _hard_strategy(playable_cards: Array, top_card) -> Variant:
	"""Hard AI: Analyzes hand composition and plays optimally"""
	
	# 1. If only one card left, play it
	if hand.size() == 1:
		return playable_cards[0]
	
	# 2. Count cards by color to determine most common
	var color_counts = [0, 0, 0, 0] # R, B, G, Y
	for card in hand:
		if card.card_color < 4:
			color_counts[card.card_color] += 1
	
	var most_common_color = color_counts.find(color_counts.max())
	
	# 3. Play action cards that match most common color
	for card in playable_cards:
		if card.card_type in [1, 2, 3] and card.card_color == most_common_color:
			return card
	
	# 4. Play any action card
	for card in playable_cards:
		if card.card_type in [1, 2, 3]:
			return card
	
	# 5. Play cards matching most common color
	for card in playable_cards:
		if card.card_color == most_common_color:
			return card
	
	# 6. Play any non-wild card
	var non_wild = playable_cards.filter(func(c): return c.card_color < 4)
	if non_wild.size() > 0:
		return non_wild[0]
	
	# 7. Play wild card as last resort
	return playable_cards[0]

func _play_card(card, deck_manager) -> void:
	"""Executes playing a card"""
	if card == null:
		ai_turn_complete.emit()
		return
	
	hand.erase(card)
	
	# Handle wild cards
	if card.card_color >= 4:
		var chosen_color = _choose_wild_color()
		card.card_color = chosen_color
		deck_manager.ai_play_wild_card(card, chosen_color)
	else:
		deck_manager.ai_play_card(card)
	
	await get_tree().create_timer(0.3).timeout
	ai_turn_complete.emit()

func _choose_wild_color() -> int:
	"""AI chooses a color for wild cards based on hand composition"""
	var color_counts = [0, 0, 0, 0]
	
	for card in hand:
		if card.card_color < 4:
			color_counts[card.card_color] += 1
	
	# Choose color AI has the most of
	var best_color = 0
	var max_count = 0
	for i in range(4):
		if color_counts[i] > max_count:
			max_count = color_counts[i]
			best_color = i
	
	return best_color

func add_card(card) -> void:
	"""Adds a card to AI's hand"""
	if card != null:
		hand.append(card)

func get_hand_size() -> int:
	return hand.size()

func has_won() -> bool:
	return hand.size() == 0
