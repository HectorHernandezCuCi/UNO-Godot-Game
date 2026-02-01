extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

signal game_started
signal game_ended(player_won: bool)
signal turn_changed(new_turn: int)
signal card_played(card, player_type: int)

# ============================================================================
# NODE REFERENCES
# ============================================================================

@onready var cards_parent = $Cards

# ============================================================================
# EXPORT VARIABLES - Layout Settings
# ============================================================================

@export_group("Layout Settings")
@export var deck_position: Vector2 = Vector2(120, 150)
@export var hand_center_pos: Vector2 = Vector2(576, 580)
@export var ai_hand_center_pos: Vector2 = Vector2(576, 60)
@export var discard_position: Vector2 = Vector2(576, 324)
@export var card_overlap: float = 50.0 
@export var hover_lift: float = 80.0
@export var hover_scale: float = 1.2

# ============================================================================
# EXPORT VARIABLES - UI Scenes
# ============================================================================

@export_group("UI Scenes")
@export var color_selector_scene: PackedScene
@export var uno_button_scene: PackedScene
@export var uno_announcement_scene: PackedScene

# ============================================================================
# EXPORT VARIABLES - AI Settings
# ============================================================================

@export_group("AI Settings")
@export var ai_difficulty: String = "medium"
@export var enable_ai: bool = true

# ============================================================================
# EXPORT VARIABLES - Game Rules
# ============================================================================

@export_group("Game Rules")
@export var initial_cards_count: int = 7
@export var enable_uno_penalty: bool = false  # Desactivado por defecto
@export var uno_penalty_timeout: float = 3.0  # Tiempo para decir UNO (si está activado)
@export var uno_penalty_cards: int = 2  # Cartas de penalización

# ============================================================================
# GAME STATE VARIABLES
# ============================================================================

var deck: Array = [] 
var hand: Array = [] 
var discard_pile: Array = []
var hovered_card = null
var is_waiting_for_color: bool = false
var is_processing_play: bool = false
var game_active: bool = false

# ============================================================================
# TURN SYSTEM
# ============================================================================

enum Turn { PLAYER, AI }
var current_turn: Turn = Turn.PLAYER
var ai_player: AIPlayer = null

# ============================================================================
# UNO SYSTEM
# ============================================================================

var player_called_uno: bool = false
var ai_called_uno: bool = false
var uno_button_ui = null
var uno_announcement_ui = null
var uno_penalty_timer: Timer = null
var waiting_for_uno_call: bool = false
var uno_button_visible: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	_validate_setup()
	_setup_uno_ui()
	_setup_ai()
	
	# Wait for scene to be ready
	await get_tree().process_frame
	setup_game()

func _validate_setup() -> bool:
	"""Validates that all required nodes and resources are properly set up"""
	var is_valid = true
	
	# Check Cards parent node
	if cards_parent == null:
		push_error("CRITICAL: 'Cards' node not found! Cannot start game.")
		is_valid = false
	
	# Check color selector scene (warning only)
	if color_selector_scene == null:
		push_warning("WARNING: color_selector_scene not assigned! Wild cards will auto-select red.")
	
	# Validate export values
	if initial_cards_count < 1 or initial_cards_count > 20:
		push_warning("initial_cards_count should be between 1-20, clamping to 7")
		initial_cards_count = 7
	
	if uno_penalty_timeout < 0.5:
		push_warning("uno_penalty_timeout too short, setting to 2.0")
		uno_penalty_timeout = 2.0
	
	if uno_penalty_cards < 1:
		push_warning("uno_penalty_cards must be at least 1, setting to 2")
		uno_penalty_cards = 2
	
	return is_valid

func _setup_uno_ui():
	"""Sets up UNO button and announcement UI with error handling"""
	# Setup UNO Button
	if uno_button_scene:
		uno_button_ui = uno_button_scene.instantiate()
		if uno_button_ui == null:
			push_error("Failed to instantiate uno_button_scene!")
			return
		
		add_child(uno_button_ui)
		
		# Connect signal safely
		if uno_button_ui.has_signal("uno_button_pressed"):
			if not uno_button_ui.uno_button_pressed.is_connected(_on_uno_button_pressed):
				uno_button_ui.uno_button_pressed.connect(_on_uno_button_pressed)
		else:
			push_error("UNO button doesn't have 'uno_button_pressed' signal!")
	else:
		push_warning("uno_button_scene not assigned! UNO button won't work.")
	
	# Setup UNO Announcement
	if uno_announcement_scene:
		uno_announcement_ui = uno_announcement_scene.instantiate()
		if uno_announcement_ui == null:
			push_error("Failed to instantiate uno_announcement_scene!")
			return
		
		add_child(uno_announcement_ui)
	else:
		push_warning("uno_announcement_scene not assigned! UNO announcements won't show.")
	
	# Setup Penalty Timer (only if penalty is enabled)
	if enable_uno_penalty:
		uno_penalty_timer = Timer.new()
		uno_penalty_timer.wait_time = uno_penalty_timeout
		uno_penalty_timer.one_shot = true
		uno_penalty_timer.timeout.connect(_on_uno_penalty_timeout)
		add_child(uno_penalty_timer)
		print("UNO penalty system ENABLED - you have %.1f seconds to call UNO" % uno_penalty_timeout)
	else:
		print("UNO penalty system DISABLED - button stays until you call UNO")

func _setup_ai():
	"""Sets up AI player with error handling"""
	if not enable_ai:
		print("AI disabled - single player mode")
		return
	
	ai_player = AIPlayer.new()
	if ai_player == null:
		push_error("Failed to create AIPlayer!")
		enable_ai = false
		return
	
	ai_player.difficulty = ai_difficulty
	
	# Connect AI signal safely
	if ai_player.has_signal("ai_turn_complete"):
		if not ai_player.ai_turn_complete.is_connected(_on_ai_turn_complete):
			ai_player.ai_turn_complete.connect(_on_ai_turn_complete)
	else:
		push_error("AIPlayer doesn't have 'ai_turn_complete' signal!")
	
	add_child(ai_player)
	print("AI initialized with difficulty: ", ai_difficulty)

# ============================================================================
# GAME SETUP
# ============================================================================

func setup_game():
	"""Initializes the game state and deals cards"""
	if cards_parent == null:
		push_error("Cannot setup game - cards_parent is null!")
		return
	
	# Get all cards
	deck = cards_parent.get_children()
	
	if deck.size() == 0:
		push_error("CRITICAL: No cards found in Cards node!")
		return
	
	print("Setting up game with %d cards" % deck.size())
	
	# Shuffle deck
	deck.shuffle()
	
	# Reset all cards to deck position
	_reset_cards_to_deck()
	
	# Place first card on discard pile
	if deck.size() > 0:
		var first_card = deck.pop_back()
		if first_card != null:
			_play_to_discard(first_card, true)
			await get_tree().process_frame
			check_top_card_wild()
	
	# Deal initial cards to player
	var cards_dealt = 0
	for i in range(initial_cards_count):
		if deck.size() == 0:
			push_warning("Deck ran out while dealing to player!")
			break
		if _deal_card_to_player():
			cards_dealt += 1
	
	print("Dealt %d cards to player" % cards_dealt)
	
	# Deal initial cards to AI
	if enable_ai and ai_player != null:
		cards_dealt = 0
		for i in range(initial_cards_count):
			if deck.size() == 0:
				push_warning("Deck ran out while dealing to AI!")
				break
			if _deal_card_to_ai():
				cards_dealt += 1
		print("Dealt %d cards to AI" % cards_dealt)
	
	# Start game
	game_active = true
	current_turn = Turn.PLAYER
	_display_turn_indicator()
	game_started.emit()

func _reset_cards_to_deck():
	"""Resets all cards to deck position with proper z-indexing"""
	for i in range(deck.size()):
		var card = deck[i]
		if card == null or not is_instance_valid(card):
			continue
		
		card.position = deck_position
		card.z_index = i
		card.is_in_hand = false
		card.visible = true

func _deal_card_to_player() -> bool:
	"""Deals one card to player hand, returns true if successful"""
	if deck.size() == 0:
		return false
	
	var card = deck.pop_back()
	if card == null or not is_instance_valid(card):
		push_error("Invalid card drawn from deck!")
		return false
	
	hand.append(card)
	card.is_in_hand = true
	card.visible = true
	reorganize_hand()
	
	return true

func _deal_card_to_ai() -> bool:
	"""Deals one card to AI hand, returns true if successful"""
	if deck.size() == 0 or ai_player == null:
		return false
	
	var card = deck.pop_back()
	if card == null or not is_instance_valid(card):
		push_error("Invalid card drawn from deck!")
		return false
	
	ai_player.add_card(card)
	card.position = ai_hand_center_pos
	card.visible = false
	
	return true

# ============================================================================
# UNO CALL SYSTEM
# ============================================================================

func _check_uno_status():
	"""Checks if player or AI should call UNO - ROBUST VERSION"""
	if not game_active:
		return
	
	# Clean hand before checking
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
	# ========== PLAYER UNO CHECK ==========
	var player_has_one_card = (hand.size() == 1)
	
	print("DEBUG UNO: hand.size() = %d, player_called_uno = %s, waiting_for_uno_call = %s" % [hand.size(), player_called_uno, waiting_for_uno_call])
	
	if player_has_one_card and not player_called_uno:
		# Player needs to call UNO
		print(">>> DETECTADO: 1 CARTA - MOSTRANDO BOTÓN UNO <<<")
		_show_uno_button()
		waiting_for_uno_call = true
		
		# Start penalty timer only if enabled
		if enable_uno_penalty and uno_penalty_timer != null:
			if not uno_penalty_timer.is_stopped():
				uno_penalty_timer.stop()
			uno_penalty_timer.start()
			print(">>> UNO TIMER STARTED - %.1f seconds to call UNO! <<<" % uno_penalty_timeout)
		else:
			print(">>> TIENES 1 CARTA - ¡PRESIONA EL BOTÓN UNO! <<<")
	
	elif not player_has_one_card:
		# Player has != 1 card, reset UNO state
		if player_called_uno or waiting_for_uno_call:
			print(">>> Ya no tienes 1 carta - reseteando estado UNO <<<")
			player_called_uno = false
			_hide_uno_button()
			waiting_for_uno_call = false
			
			if enable_uno_penalty and uno_penalty_timer != null and not uno_penalty_timer.is_stopped():
				uno_penalty_timer.stop()
	
	# ========== AI UNO CHECK ==========
	if enable_ai and ai_player != null:
		var ai_has_one_card = (ai_player.get_hand_size() == 1)
		
		if ai_has_one_card and not ai_called_uno:
			_ai_call_uno()
		elif not ai_has_one_card:
			ai_called_uno = false

func _show_uno_button():
	"""Shows the UNO button for player with validation"""
	print("DEBUG: _show_uno_button() llamado")
	
	if uno_button_ui == null:
		push_warning("Cannot show UNO button - uno_button_ui is null!")
		return
	
	if not is_instance_valid(uno_button_ui):
		push_warning("Cannot show UNO button - uno_button_ui is not valid!")
		return
	
	if not uno_button_ui.has_method("show_button"):
		push_warning("UNO button UI doesn't have 'show_button' method!")
		uno_button_ui.show()  # Fallback to regular show
		uno_button_visible = true
		print(">>> BOTÓN UNO MOSTRADO (fallback) <<<")
		return
	
	uno_button_ui.show_button()
	uno_button_visible = true
	print(">>> BOTÓN UNO MOSTRADO <<<")

func _hide_uno_button():
	"""Hides the UNO button with validation"""
	print("DEBUG: _hide_uno_button() llamado")
	
	if uno_button_ui == null or not is_instance_valid(uno_button_ui):
		return
	
	if not uno_button_ui.has_method("hide_button"):
		uno_button_ui.hide()  # Fallback
		uno_button_visible = false
		return
	
	uno_button_ui.hide_button()
	uno_button_visible = false

func _on_uno_button_pressed():
	"""Called when player clicks UNO button - ROBUST VERSION"""
	print(">>> BOTÓN UNO PRESIONADO <<<")
	
	if not game_active:
		push_warning("UNO button pressed but game not active!")
		return
	
	if hand.size() != 1:
		push_warning("UNO called but player has %d cards!" % hand.size())
		# Allow it anyway - maybe they're about to play
	
	# Mark UNO as called
	player_called_uno = true
	waiting_for_uno_call = false
	
	# Stop penalty timer
	if enable_uno_penalty and uno_penalty_timer != null and not uno_penalty_timer.is_stopped():
		uno_penalty_timer.stop()
	
	# Hide button
	_hide_uno_button()
	
	# Show announcement
	if uno_announcement_ui != null and is_instance_valid(uno_announcement_ui):
		if uno_announcement_ui.has_method("show_uno_announcement"):
			uno_announcement_ui.show_uno_announcement("TÚ")
	
	print(">>> ¡DIJISTE UNO! <<<")

func _on_uno_penalty_timeout():
	"""Called when player fails to call UNO in time - only if penalty enabled"""
	if not enable_uno_penalty:
		return
	
	if not game_active:
		return
	
	if hand.size() == 1 and not player_called_uno and waiting_for_uno_call:
		_apply_uno_penalty()

func _apply_uno_penalty():
	"""Applies penalty for forgetting to call UNO - ROBUST VERSION"""
	print(">>> ¡OLVIDASTE DECIR UNO! +%d CARTAS <<<" % uno_penalty_cards)
	
	# Show penalty message
	if uno_announcement_ui != null and is_instance_valid(uno_announcement_ui):
		if uno_announcement_ui.has_method("show_penalty_message"):
			uno_announcement_ui.show_penalty_message()
	
	# Reset UNO state
	waiting_for_uno_call = false
	player_called_uno = false
	_hide_uno_button()
	
	# Draw penalty cards
	var cards_drawn = 0
	for i in range(uno_penalty_cards):
		if deck.size() == 0:
			push_warning("Deck empty, cannot draw penalty cards!")
			break
		
		if _deal_card_to_player():
			cards_drawn += 1
	
	print("Drew %d penalty cards" % cards_drawn)
	
	# Check UNO status again (in case we're back to 1 card somehow)
	_check_uno_status()

func _ai_call_uno():
	"""AI automatically calls UNO - ROBUST VERSION"""
	if not enable_ai or ai_player == null:
		return
	
	ai_called_uno = true
	
	if uno_announcement_ui != null and is_instance_valid(uno_announcement_ui):
		if uno_announcement_ui.has_method("show_ai_uno"):
			uno_announcement_ui.show_ai_uno()
	
	print(">>> ¡LA IA DIJO UNO! <<<")

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

func _display_turn_indicator():
	"""Displays current turn information"""
	if current_turn == Turn.PLAYER:
		print(">>> TU TURNO <<<")
	else:
		print(">>> TURNO DE LA IA <<<")
	
	turn_changed.emit(current_turn)

func end_player_turn():
	"""Ends player turn and starts AI turn - ROBUST VERSION"""
	if not game_active:
		return
	
	if current_turn != Turn.PLAYER:
		push_warning("Trying to end player turn but it's not player's turn!")
		return
	
	# Check for win condition
	if hand.size() == 0:
		_game_over(true)
		return
	
	# Check UNO status before switching turns
	_check_uno_status()
	
	# If AI is disabled, just stay on player turn
	if not enable_ai or ai_player == null:
		return
	
	# Switch to AI turn
	current_turn = Turn.AI
	_display_turn_indicator()
	
	# Start AI turn after small delay
	await get_tree().create_timer(0.5).timeout
	
	if not game_active:
		return
	
	if discard_pile.size() > 0:
		var top_card = discard_pile.back()
		if top_card != null and is_instance_valid(top_card):
			ai_player.take_turn(top_card, self)
		else:
			push_error("Top card of discard pile is invalid!")
			current_turn = Turn.PLAYER
			_display_turn_indicator()

func _on_ai_turn_complete():
	"""Called when AI finishes its turn - ROBUST VERSION"""
	if not game_active:
		return
	
	if ai_player == null:
		return
	
	# Check if AI won
	if ai_player.has_won():
		_game_over(false)
		return
	
	# Check UNO status for AI
	_check_uno_status()
	
	# Switch back to player turn
	current_turn = Turn.PLAYER
	_display_turn_indicator()

func _game_over(player_won: bool):
	"""Handles game over state - ROBUST VERSION"""
	game_active = false
	
	if player_won:
		print("=== ¡GANASTE! ===")
	else:
		print("=== LA IA GANÓ ===")
	
	# Hide UNO button
	_hide_uno_button()
	
	# Stop any timers
	if uno_penalty_timer != null and not uno_penalty_timer.is_stopped():
		uno_penalty_timer.stop()
	
	# Emit signal
	game_ended.emit(player_won)

# ============================================================================
# CARD LOGIC
# ============================================================================

func check_top_card_wild():
	"""Checks if top discard card is wild and needs color selection"""
	if discard_pile.size() == 0:
		return
	
	var top_card = discard_pile.back()
	if top_card == null or not is_instance_valid(top_card):
		push_error("Top card is invalid!")
		return
	
	# Check if card has card_color property
	if not "card_color" in top_card:
		push_warning("Top card doesn't have card_color property!")
		return
	
	print("DEBUG: Top card color = %d" % top_card.card_color)
	
	# Wild cards have color >= 4
	if top_card.card_color >= 4 and not is_waiting_for_color:
		print(">>> CARTA WILD DETECTADA - INICIANDO SELECCIÓN DE COLOR <<<")
		_start_color_selection(top_card)

func draw_card_to_hand():
	"""Draws a card from deck to player hand - ROBUST VERSION"""
	if not game_active:
		push_warning("Cannot draw - game not active!")
		return
	
	if current_turn != Turn.PLAYER:
		push_warning("Cannot draw - not player's turn!")
		return
	
	if deck.size() == 0:
		push_warning("Cannot draw - deck is empty!")
		end_player_turn()
		return
	
	if is_waiting_for_color:
		push_warning("Cannot draw - waiting for wild card color selection!")
		return
	
	if is_processing_play:
		push_warning("Cannot draw - currently processing a play!")
		return
	
	# Draw the card
	if _deal_card_to_player():
		print("Drew 1 card from deck (%d remaining)" % deck.size())
		
		# Check UNO status after drawing
		_check_uno_status()
		
		# End turn
		end_player_turn()
	else:
		push_error("Failed to draw card!")

func draw_card_for_ai(ai: AIPlayer):
	"""Draws a card for AI player - ROBUST VERSION"""
	if ai == null or not is_instance_valid(ai):
		push_error("AI is invalid!")
		return null
	
	if deck.size() == 0:
		push_warning("Cannot draw for AI - deck is empty!")
		return null
	
	var card = deck.pop_back()
	if card == null or not is_instance_valid(card):
		push_error("Drew invalid card from deck!")
		return null
	
	card.visible = false
	return card

func reorganize_hand():
	"""Reorganizes player hand with smooth animations - ROBUST VERSION"""
	# Filter out null/invalid cards
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
	var card_count = hand.size()
	
	if card_count == 0:
		return
	
	# Calculate dynamic overlap for large hands
	var dynamic_overlap = card_overlap
	if card_count > 10:
		dynamic_overlap = min(card_overlap, 400.0 / (card_count - 1))
	
	var total_width = dynamic_overlap * (card_count - 1)
	var start_x = hand_center_pos.x - (total_width / 2)
	
	# Position each card
	for i in range(card_count):
		var card = hand[i]
		if card == null or not is_instance_valid(card):
			continue
		
		var target_pos = Vector2(start_x + (i * dynamic_overlap), hand_center_pos.y)
		
		# Set base_position if it exists
		if "base_position" in card:
			card.base_position = target_pos
		
		# Don't animate hovered card
		if card == hovered_card:
			continue
		
		# Animate to position
		var tween = create_tween().set_parallel(true)
		tween.tween_property(card, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "scale", Vector2.ONE, 0.2)
		card.z_index = 100 + i

func request_play_card(card):
	"""Attempts to play a card from hand - ROBUST VERSION"""
	if not game_active:
		push_warning("Cannot play - game not active!")
		return
	
	if current_turn != Turn.PLAYER:
		push_warning("Cannot play - not player's turn!")
		return
	
	if card == null or not is_instance_valid(card):
		push_error("Invalid card!")
		return
	
	if is_processing_play:
		return
	
	if is_waiting_for_color:
		push_warning("Cannot play - waiting for color selection!")
		return
	
	if not "is_in_hand" in card or not card.is_in_hand:
		push_warning("Card is not in hand!")
		return
	
	if card != hovered_card:
		return
	
	if not card in hand:
		push_warning("Card not found in hand array!")
		return
	
	if discard_pile.size() == 0:
		push_error("Discard pile is empty!")
		return
	
	var top_card = discard_pile.back()
	if top_card == null or not is_instance_valid(top_card):
		push_error("Top card is invalid!")
		return
	
	# Check if cards have required properties
	if not "card_color" in card or not "card_value" in card:
		push_error("Card missing properties!")
		return
	
	if not "card_color" in top_card or not "card_value" in top_card:
		push_error("Top card missing properties!")
		return
	
	# Check if card can be played
	var is_wild = card.card_color >= 4
	var matches_color = card.card_color == top_card.card_color
	var matches_value = card.card_value == top_card.card_value
	var can_play = is_wild or matches_color or matches_value
	
	print("DEBUG PLAY: is_wild=%s, matches_color=%s, matches_value=%s, can_play=%s" % [is_wild, matches_color, matches_value, can_play])
	
	is_processing_play = true
	
	if can_play:
		if is_wild:
			# Wild card - need color selection
			print(">>> JUGANDO CARTA WILD - INICIANDO SELECCIÓN <<<")
			_start_color_selection(card)
		else:
			# Regular card - play it
			_play_to_discard(card)
			card_played.emit(card, Turn.PLAYER)
			
			# Check UNO status after playing
			_check_uno_status()
			
			# End turn
			end_player_turn()
	else:
		# Cannot play this card
		_shake_card(card)
		print("Cannot play this card!")
	
	is_processing_play = false

# ============================================================================
# AI CARD PLAYING
# ============================================================================

func ai_play_card(card):
	"""Plays an AI card to discard pile - ROBUST VERSION"""
	if card == null or not is_instance_valid(card):
		push_error("AI tried to play invalid card!")
		return
	
	discard_pile.append(card)
	
	card.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", discard_position, 0.4)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3)
	
	card.z_index = discard_pile.size()
	card_played.emit(card, Turn.AI)

func ai_play_wild_card(card, chosen_color: int):
	"""Plays an AI wild card with chosen color - ROBUST VERSION"""
	if card == null or not is_instance_valid(card):
		push_error("AI tried to play invalid wild card!")
		return
	
	# Validate color
	if chosen_color < 0 or chosen_color > 3:
		push_warning("Invalid color %d chosen by AI, defaulting to 0" % chosen_color)
		chosen_color = 0
	
	if "card_color" in card:
		card.card_color = chosen_color
	
	var colors = [Color.RED, Color.CORNFLOWER_BLUE, Color.GREEN, Color.YELLOW]
	card.modulate = colors[chosen_color]
	
	ai_play_card(card)

# ============================================================================
# WILD COLOR SELECTION
# ============================================================================

func _start_color_selection(card):
	"""Starts color selection process for wild card - ROBUST VERSION"""
	print("DEBUG: _start_color_selection() llamado")
	
	if card == null or not is_instance_valid(card):
		push_error("Invalid card for color selection!")
		return
	
	# Fallback if no color selector scene
	if color_selector_scene == null:
		push_warning("No color selector scene - auto-selecting red")
		if "card_color" in card:
			card.card_color = 0
		if "is_in_hand" in card and card.is_in_hand:
			_play_to_discard(card)
			_check_uno_status()
			end_player_turn()
		return
	
	is_waiting_for_color = true
	print(">>> INSTANCIANDO SELECTOR DE COLOR <<<")
	var selector = color_selector_scene.instantiate()
	
	if selector == null:
		push_error("Failed to instantiate color selector!")
		is_waiting_for_color = false
		return
	
	add_child(selector)
	print(">>> SELECTOR DE COLOR AÑADIDO A LA ESCENA <<<")
	
	# Connect signal
	if not selector.has_signal("color_selected"):
		push_error("Color selector doesn't have 'color_selected' signal!")
		selector.queue_free()
		is_waiting_for_color = false
		return
	
	selector.color_selected.connect(func(color_index):
		_on_wild_color_selected(card, color_index, selector)
	)
	
	print(">>> ESPERANDO SELECCIÓN DE COLOR <<<")

func _on_wild_color_selected(card, color_index: int, selector):
	"""Called when color is selected for wild card - ROBUST VERSION"""
	print("DEBUG: Color seleccionado: %d" % color_index)
	
	if card == null or not is_instance_valid(card):
		push_error("Card became invalid during color selection!")
		is_waiting_for_color = false
		if selector != null and is_instance_valid(selector):
			selector.queue_free()
		return
	
	# Validate color index
	if color_index < 0 or color_index > 3:
		push_warning("Invalid color index %d, using 0" % color_index)
		color_index = 0
	
	# Set card color
	if "card_color" in card:
		card.card_color = color_index
	
	var colors = [Color.RED, Color.CORNFLOWER_BLUE, Color.GREEN, Color.YELLOW]
	card.modulate = colors[color_index]
	
	print("Wild card color selected: %d" % color_index)
	
	# Play card if it's in player hand
	if "is_in_hand" in card and card.is_in_hand and card in hand:
		_play_to_discard(card)
		card_played.emit(card, Turn.PLAYER)
		_check_uno_status()
		end_player_turn()
	
	is_waiting_for_color = false
	
	# Clean up selector
	if selector != null and is_instance_valid(selector):
		selector.queue_free()
	
	print(">>> SELECTOR DE COLOR ELIMINADO <<<")

# ============================================================================
# DISCARD AND VISUALS
# ============================================================================

func _play_to_discard(card, is_initial: bool = false):
	"""Plays a card to the discard pile - ROBUST VERSION"""
	if card == null or not is_instance_valid(card):
		push_error("Cannot play invalid card to discard!")
		return
	
	# Remove from hand if not initial card
	if not is_initial:
		if card in hand:
			hand.erase(card)
		if "is_in_hand" in card:
			card.is_in_hand = false
		if hovered_card == card: 
			hovered_card = null
	
	# Add to discard pile
	discard_pile.append(card)
	
	# Animate to discard position
	card.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", discard_position, 0.4)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3)
	
	card.z_index = discard_pile.size()
	
	# Reorganize hand
	reorganize_hand()

func _shake_card(card):
	"""Shakes a card to indicate it cannot be played - ROBUST VERSION"""
	if card == null or not is_instance_valid(card):
		return
	
	var original_modulate = card.modulate
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color.RED, 0.1)
	tween.tween_property(card, "modulate", original_modulate, 0.1)

# ============================================================================
# INTERACTION HANDLING
# ============================================================================

func _process(_delta):
	"""Main process loop for hover detection"""
	if not game_active:
		return
	
	if current_turn == Turn.PLAYER and not is_waiting_for_color and not is_processing_play:
		_update_hover_priority()

func _update_hover_priority():
	"""Updates which card is currently hovered - ROBUST VERSION"""
	var mouse_pos = get_global_mouse_position()
	var potential_cards = []
	
	# Filter valid cards
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
	# Check each card for hover
	for card in hand:
		if not card.has_node("Area2D"):
			continue
		
		var area = card.get_node("Area2D")
		if area == null or not is_instance_valid(area):
			continue
		
		var shapes = area.get_children()
		for s in shapes:
			if s is CollisionShape2D and s.shape != null:
				var rect = s.shape.get_rect()
				if rect.has_point(card.to_local(mouse_pos)):
					potential_cards.append(card)
					break
	
	# Find topmost card
	var top_card = null
	if potential_cards.size() > 0:
		top_card = potential_cards[0]
		for c in potential_cards:
			if c.z_index > top_card.z_index: 
				top_card = c
	
	# Update hover state
	if top_card != hovered_card:
		# Un-hover previous card
		if hovered_card != null and is_instance_valid(hovered_card):
			if hovered_card.has_method("set_hover"):
				hovered_card.set_hover(false)
		
		# Hover new card
		hovered_card = top_card
		if hovered_card != null and is_instance_valid(hovered_card):
			hovered_card.z_index = 300
			if hovered_card.has_method("set_hover"):
				hovered_card.set_hover(true, hover_lift, hover_scale)
			reorganize_hand()

func _input(event):
	"""Handles input events - ROBUST VERSION"""
	if not game_active:
		return
	
	if current_turn != Turn.PLAYER:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Check if clicking on deck
		if mouse_pos.distance_to(deck_position) < 80:
			draw_card_to_hand()

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_hand_size() -> int:
	"""Returns current hand size"""
	return hand.size()

func get_deck_size() -> int:
	"""Returns current deck size"""
	return deck.size()

func get_current_turn() -> Turn:
	"""Returns current turn"""
	return current_turn

func is_game_active() -> bool:
	"""Returns if game is active"""
	return game_active
