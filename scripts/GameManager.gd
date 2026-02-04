extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

signal game_started
signal game_ended(player_won: bool)
signal turn_changed(new_turn: int)
signal card_played(card, player_type: int)
signal ai_card_drawn
signal ai_card_played

# ============================================================================
# NODE REFERENCES
# ============================================================================

@onready var cards_parent = $Cards
@onready var ai_visual_hand = $AIVisualHand

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
@export var ai_card_overlap: float = 30.0

# ============================================================================
# EXPORT VARIABLES - UI Scenes
# ============================================================================

@export_group("UI Scenes")
@export var color_selector_scene: PackedScene
@export var uno_button_scene: PackedScene
@export var uno_announcement_scene: PackedScene
@export var card_back_texture: Texture2D

# ============================================================================
# EXPORT VARIABLES - AI Settings
# ============================================================================

@export_group("AI Settings")
@export var ai_difficulty: String = "medium"
@export var enable_ai: bool = true

# ============================================================================
# EXPORT VARIABLES - AI Visual Settings
# ============================================================================

@export_group("AI Visual Settings")
@export var show_ai_card_backs: bool = true
@export var ai_card_scale: float = 0.8
@export var enable_ai_animations: bool = true

# ============================================================================
# EXPORT VARIABLES - Game Rules
# ============================================================================

@export_group("Game Rules")
@export var initial_cards_count: int = 7
@export var enable_uno_penalty: bool = false
@export var uno_penalty_timeout: float = 3.0
@export var uno_penalty_cards: int = 2

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
var player_turn_skipped: bool = false
var ai_turn_skipped: bool = false


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
# AI VISUAL SYSTEM
# ============================================================================

var ai_visual_cards: Array = []

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	_validate_setup()
	_setup_ai_visual_hand()
	_setup_uno_ui()
	_setup_ai()
	
	await get_tree().process_frame
	setup_game()

func _validate_setup() -> bool:
	"""Validates that all required nodes and resources are properly set up"""
	var is_valid = true
	
	if cards_parent == null:
		push_error("CRITICAL: 'Cards' node not found! Cannot start game.")
		is_valid = false
	
	if color_selector_scene == null:
		push_warning("WARNING: color_selector_scene not assigned! Wild cards will auto-select red.")
	
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

func _setup_ai_visual_hand():
	"""Sets up the visual system for AI cards"""
	if ai_visual_hand == null:
		ai_visual_hand = Node2D.new()
		ai_visual_hand.name = "AIVisualHand"
		add_child(ai_visual_hand)
	
	print("AI visual hand system initialized")

func _setup_uno_ui():
	"""Sets up UNO button and announcement UI with error handling"""
	if uno_button_scene:
		uno_button_ui = uno_button_scene.instantiate()
		if uno_button_ui == null:
			push_error("Failed to instantiate uno_button_scene!")
			return
		
		add_child(uno_button_ui)
		
		if uno_button_ui.has_signal("uno_button_pressed"):
			if not uno_button_ui.uno_button_pressed.is_connected(_on_uno_button_pressed):
				uno_button_ui.uno_button_pressed.connect(_on_uno_button_pressed)
		else:
			push_error("UNO button doesn't have 'uno_button_pressed' signal!")
	else:
		push_warning("uno_button_scene not assigned! UNO button won't work.")
	
	if uno_announcement_scene:
		uno_announcement_ui = uno_announcement_scene.instantiate()
		if uno_announcement_ui == null:
			push_error("Failed to instantiate uno_announcement_scene!")
			return
		
		add_child(uno_announcement_ui)
	else:
		push_warning("uno_announcement_scene not assigned! UNO announcements won't show.")
	
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
	
	if ai_player.has_signal("ai_turn_complete"):
		if not ai_player.ai_turn_complete.is_connected(_on_ai_turn_complete):
			ai_player.ai_turn_complete.connect(_on_ai_turn_complete)
	else:
		push_error("AIPlayer doesn't have 'ai_turn_complete' signal!")
	
	add_child(ai_player)
	print("AI initialized with difficulty: ", ai_difficulty)

# ============================================================================
# AI VISUAL CARD SYSTEM
# ============================================================================

func _create_ai_card_back() -> Sprite2D:
	"""Creates a card back sprite for AI"""
	var card_back = Sprite2D.new()
	
	if card_back_texture != null:
		card_back.texture = card_back_texture
	else:
		# Create placeholder if no texture provided
		var placeholder = ColorRect.new()
		placeholder.size = Vector2(80, 112)
		placeholder.color = Color(0.2, 0.2, 0.8, 1.0)
		
		# Add border
		var border = Line2D.new()
		border.width = 2
		border.default_color = Color.WHITE
		var rect_size = Vector2(80, 112) * ai_card_scale
		border.add_point(Vector2(-rect_size.x/2, -rect_size.y/2))
		border.add_point(Vector2(rect_size.x/2, -rect_size.y/2))
		border.add_point(Vector2(rect_size.x/2, rect_size.y/2))
		border.add_point(Vector2(-rect_size.x/2, rect_size.y/2))
		border.add_point(Vector2(-rect_size.x/2, -rect_size.y/2))
		card_back.add_child(border)
	
	card_back.scale = Vector2(ai_card_scale, ai_card_scale)
	card_back.z_index = 50
	
	return card_back

func _update_ai_visual_hand():
	"""Updates the visual representation of AI cards"""
	if not show_ai_card_backs or ai_player == null:
		return
	
	var ai_hand_size = ai_player.get_hand_size()
	
	while ai_visual_cards.size() < ai_hand_size:
		var card_back = _create_ai_card_back()
		ai_visual_hand.add_child(card_back)
		ai_visual_cards.append(card_back)
	
	while ai_visual_cards.size() > ai_hand_size:
		var card = ai_visual_cards.pop_back()
		if card != null and is_instance_valid(card):
			card.queue_free()
	
	_reorganize_ai_visual_hand()

func _reorganize_ai_visual_hand():
	"""Reorganizes AI visual cards with animation"""
	var card_count = ai_visual_cards.size()
	
	if card_count == 0:
		return
	
	var dynamic_overlap = ai_card_overlap
	if card_count > 10:
		dynamic_overlap = min(ai_card_overlap, 300.0 / (card_count - 1))
	
	var total_width = dynamic_overlap * (card_count - 1)
	var start_x = ai_hand_center_pos.x - (total_width / 2)
	
	for i in range(card_count):
		var card = ai_visual_cards[i]
		if card == null or not is_instance_valid(card):
			continue
		
		var target_pos = Vector2(start_x + (i * dynamic_overlap), ai_hand_center_pos.y)
		
		if enable_ai_animations:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(card, "position", target_pos, 0.3)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "rotation", randf_range(-0.05, 0.05), 0.3)
		else:
			card.position = target_pos
		
		card.z_index = 50 + i

func _animate_ai_draw_card():
	"""Animates AI drawing a card"""
	if not show_ai_card_backs or not enable_ai_animations:
		_update_ai_visual_hand()
		return
	
	var new_card = _create_ai_card_back()
	ai_visual_hand.add_child(new_card)
	new_card.position = deck_position
	new_card.scale = Vector2.ZERO
	new_card.modulate.a = 0
	
	ai_visual_cards.append(new_card)
	
	var card_count = ai_visual_cards.size()
	var dynamic_overlap = ai_card_overlap
	if card_count > 10:
		dynamic_overlap = min(ai_card_overlap, 300.0 / (card_count - 1))
	
	var total_width = dynamic_overlap * (card_count - 1)
	var start_x = ai_hand_center_pos.x - (total_width / 2)
	var target_pos = Vector2(start_x + ((card_count - 1) * dynamic_overlap), ai_hand_center_pos.y)
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(new_card, "modulate:a", 1.0, 0.2)
	tween.tween_property(new_card, "scale", Vector2(ai_card_scale, ai_card_scale) * 1.2, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(new_card, "position", target_pos, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_card, "scale", Vector2(ai_card_scale, ai_card_scale), 0.3)
	tween.tween_property(new_card, "rotation", randf_range(-0.1, 0.1), 0.5)\
		.set_trans(Tween.TRANS_ELASTIC)
	
	tween.chain()
	tween.tween_callback(_reorganize_ai_visual_hand)
	
	ai_card_drawn.emit()

func _animate_ai_play_card():
	"""Animates AI playing a card"""
	if not show_ai_card_backs or ai_visual_cards.size() == 0:
		_update_ai_visual_hand()
		return
	
	if not enable_ai_animations:
		if ai_visual_cards.size() > 0:
			var card = ai_visual_cards.pop_back()
			if card != null and is_instance_valid(card):
				card.queue_free()
		_update_ai_visual_hand()
		return
	
	var card_to_play = ai_visual_cards.pop_back()
	if card_to_play == null or not is_instance_valid(card_to_play):
		_update_ai_visual_hand()
		return
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(card_to_play, "position:y", card_to_play.position.y - 30, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_to_play, "scale", Vector2(ai_card_scale, ai_card_scale) * 1.3, 0.2)
	tween.tween_property(card_to_play, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2)
	
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(card_to_play, "position", discard_position, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(card_to_play, "rotation", randf_range(-1.0, 1.0), 0.4)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card_to_play, "scale", Vector2.ZERO, 0.3).set_delay(0.2)
	tween.tween_property(card_to_play, "modulate:a", 0.0, 0.2).set_delay(0.3)
	
	tween.chain()
	tween.tween_callback(func():
		if card_to_play != null and is_instance_valid(card_to_play):
			card_to_play.queue_free()
		_reorganize_ai_visual_hand()
	)
	
	ai_card_played.emit()

func _add_ai_thinking_effect():
	"""Adds visual thinking effect when AI is deciding"""
	if ai_visual_cards.size() == 0:
		return
	
	for i in range(min(3, ai_visual_cards.size())):
		var card = ai_visual_cards[randi() % ai_visual_cards.size()]
		if card == null or not is_instance_valid(card):
			continue
		
		var tween = create_tween().set_parallel(true)
		var lift_amount = randf_range(5, 15)
		
		tween.tween_property(card, "position:y", card.position.y - lift_amount, 0.2)\
			.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card, "scale", Vector2.ONE * ai_card_scale * 1.1, 0.2)
		
		tween.chain()
		tween.set_parallel(true)
		tween.tween_property(card, "position:y", card.position.y, 0.2)\
			.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card, "scale", Vector2.ONE * ai_card_scale, 0.2)

# ============================================================================
# GAME SETUP
# ============================================================================

func setup_game():
	"""Initializes the game state and deals cards"""
	if cards_parent == null:
		push_error("Cannot setup game - cards_parent is null!")
		return
	
	deck = cards_parent.get_children()
	
	if deck.size() == 0:
		push_error("CRITICAL: No cards found in Cards node!")
		return
	
	print("Setting up game with %d cards" % deck.size())
	
	deck.shuffle()
	_reset_cards_to_deck()
	
	if deck.size() > 0:
		var first_card = deck.pop_back()
		if first_card != null:
			_play_to_discard(first_card, true)
			await get_tree().process_frame
			check_top_card_wild()
	
	var cards_dealt = 0
	for i in range(initial_cards_count):
		if deck.size() == 0:
			push_warning("Deck ran out while dealing to player!")
			break
		if _deal_card_to_player():
			cards_dealt += 1
	
	print("Dealt %d cards to player" % cards_dealt)
	
	if enable_ai and ai_player != null:
		cards_dealt = 0
		for i in range(initial_cards_count):
			if deck.size() == 0:
				push_warning("Deck ran out while dealing to AI!")
				break
			if _deal_card_to_ai():
				cards_dealt += 1
		print("Dealt %d cards to AI" % cards_dealt)
	
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
	"""Deals one card to AI hand with visual feedback"""
	if deck.size() == 0 or ai_player == null:
		return false
	
	var card = deck.pop_back()
	if card == null or not is_instance_valid(card):
		push_error("Invalid card drawn from deck!")
		return false
	
	ai_player.add_card(card)
	card.position = ai_hand_center_pos
	card.visible = false
	
	if show_ai_card_backs:
		_animate_ai_draw_card()
	
	return true

# ============================================================================
# UNO CALL SYSTEM
# ============================================================================

func _check_uno_status():
	"""Checks if player or AI should call UNO"""
	if not game_active:
		return
	
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
	var player_has_one_card = (hand.size() == 1)
	
	print("DEBUG UNO: hand.size() = %d, player_called_uno = %s, waiting_for_uno_call = %s" % [hand.size(), player_called_uno, waiting_for_uno_call])
	
	if player_has_one_card and not player_called_uno:
		print(">>> DETECTED: 1 CARD - SHOWING UNO BUTTON <<<")
		_show_uno_button()
		waiting_for_uno_call = true
		
		if enable_uno_penalty and uno_penalty_timer != null:
			if not uno_penalty_timer.is_stopped():
				uno_penalty_timer.stop()
			uno_penalty_timer.start()
			print(">>> UNO TIMER STARTED - %.1f seconds to call UNO! <<<" % uno_penalty_timeout)
		else:
			print(">>> YOU HAVE 1 CARD - PRESS UNO BUTTON! <<<")
	
	elif not player_has_one_card:
		if player_called_uno or waiting_for_uno_call:
			print(">>> No longer 1 card - resetting UNO state <<<")
			player_called_uno = false
			_hide_uno_button()
			waiting_for_uno_call = false
			
			if enable_uno_penalty and uno_penalty_timer != null and not uno_penalty_timer.is_stopped():
				uno_penalty_timer.stop()
	
	if enable_ai and ai_player != null:
		var ai_has_one_card = (ai_player.get_hand_size() == 1)
		
		if ai_has_one_card and not ai_called_uno:
			_ai_call_uno()
		elif not ai_has_one_card:
			ai_called_uno = false

func _show_uno_button():
	"""Shows the UNO button for player with validation"""
	print("DEBUG: _show_uno_button() called")
	
	if uno_button_ui == null:
		push_warning("Cannot show UNO button - uno_button_ui is null!")
		return
	
	if not is_instance_valid(uno_button_ui):
		push_warning("Cannot show UNO button - uno_button_ui is not valid!")
		return
	
	if not uno_button_ui.has_method("show_button"):
		push_warning("UNO button UI doesn't have 'show_button' method!")
		uno_button_ui.show()
		uno_button_visible = true
		print(">>> UNO BUTTON SHOWN (fallback) <<<")
		return
	
	uno_button_ui.show_button()
	uno_button_visible = true
	print(">>> UNO BUTTON SHOWN <<<")

func _hide_uno_button():
	"""Hides the UNO button with validation"""
	print("DEBUG: _hide_uno_button() called")
	
	if uno_button_ui == null or not is_instance_valid(uno_button_ui):
		return
	
	if not uno_button_ui.has_method("hide_button"):
		uno_button_ui.hide()
		uno_button_visible = false
		return
	
	uno_button_ui.hide_button()
	uno_button_visible = false

func _on_uno_button_pressed():
	"""Called when player clicks UNO button"""
	print(">>> UNO BUTTON PRESSED <<<")
	
	if not game_active:
		push_warning("UNO button pressed but game not active!")
		return
	
	if hand.size() != 1:
		push_warning("UNO called but player has %d cards!" % hand.size())
	
	player_called_uno = true
	waiting_for_uno_call = false
	
	if enable_uno_penalty and uno_penalty_timer != null and not uno_penalty_timer.is_stopped():
		uno_penalty_timer.stop()
	
	_hide_uno_button()
	
	if uno_announcement_ui != null and is_instance_valid(uno_announcement_ui):
		if uno_announcement_ui.has_method("show_uno_announcement"):
			uno_announcement_ui.show_uno_announcement("YOU")
	
	print(">>> YOU SAID UNO! <<<")

func _on_uno_penalty_timeout():
	"""Called when player fails to call UNO in time"""
	if not enable_uno_penalty:
		return
	
	if not game_active:
		return
	
	if hand.size() == 1 and not player_called_uno and waiting_for_uno_call:
		_apply_uno_penalty()

func _apply_uno_penalty():
	"""Applies penalty for forgetting to call UNO"""
	print(">>> YOU FORGOT TO SAY UNO! +%d CARDS <<<" % uno_penalty_cards)
	
	if uno_announcement_ui != null and is_instance_valid(uno_announcement_ui):
		if uno_announcement_ui.has_method("show_penalty_message"):
			uno_announcement_ui.show_penalty_message()
	
	waiting_for_uno_call = false
	player_called_uno = false
	_hide_uno_button()
	
	var cards_drawn = 0
	for i in range(uno_penalty_cards):
		if deck.size() == 0:
			push_warning("Deck empty, cannot draw penalty cards!")
			break
		
		if _deal_card_to_player():
			cards_drawn += 1
	
	print("Drew %d penalty cards" % cards_drawn)
	_check_uno_status()

func _ai_call_uno():
	"""AI automatically calls UNO"""
	if not enable_ai or ai_player == null:
		return
	
	ai_called_uno = true
	
	if uno_announcement_ui != null and is_instance_valid(uno_announcement_ui):
		if uno_announcement_ui.has_method("show_ai_uno"):
			uno_announcement_ui.show_ai_uno()
	
	print(">>> AI SAID UNO! <<<")

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

func _display_turn_indicator():
	"""Displays current turn information"""
	if current_turn == Turn.PLAYER:
		print(">>> YOUR TURN <<<")
	else:
		print(">>> AI TURN <<<")
	
	turn_changed.emit(current_turn)

func end_player_turn():
	"""Ends player turn and starts AI turn"""
	if not game_active:
		return
	
	if current_turn != Turn.PLAYER:
		push_warning("Trying to end player turn but it's not player's turn!")
		return
	
	if hand.size() == 0:
		_game_over(true)
		return
	
	_check_uno_status()
	
	if not enable_ai or ai_player == null:
		return
	
	current_turn = Turn.AI
	_display_turn_indicator()
	
	if show_ai_card_backs and enable_ai_animations:
		_add_ai_thinking_effect()
	
	await get_tree().create_timer(0.8).timeout
	
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
	"""Called when AI finishes its turn"""
	if not game_active:
		return
	
	if ai_player == null:
		return
	
	if ai_player.has_won():
		_game_over(false)
		return
	
	_check_uno_status()
	
	current_turn = Turn.PLAYER
	_display_turn_indicator()

func _game_over(player_won: bool):
	"""Handles game over state"""
	game_active = false
	
	if player_won:
		print("=== YOU WON! ===")
	else:
		print("=== AI WON ===")
	
	_hide_uno_button()
	
	if uno_penalty_timer != null and not uno_penalty_timer.is_stopped():
		uno_penalty_timer.stop()
	
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
	
	if not "card_color" in top_card:
		push_warning("Top card doesn't have card_color property!")
		return
	
	print("DEBUG: Top card color = %d" % top_card.card_color)
	
	if top_card.card_color >= 4 and not is_waiting_for_color:
		print(">>> WILD CARD DETECTED - STARTING COLOR SELECTION <<<")
		_start_color_selection(top_card)

func draw_card_to_hand():
	"""Draws a card from deck to player hand"""
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
	
	if _deal_card_to_player():
		print("Drew 1 card from deck (%d remaining)" % deck.size())
		_check_uno_status()
		end_player_turn()
	else:
		push_error("Failed to draw card!")

func draw_card_for_ai(ai: AIPlayer):
	"""Draws a card for AI player with visual feedback"""
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
	
	if show_ai_card_backs:
		_animate_ai_draw_card()
	
	return card

func reorganize_hand():
	"""Reorganizes player hand with smooth animations"""
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
	var card_count = hand.size()
	
	if card_count == 0:
		return
	
	var dynamic_overlap = card_overlap
	if card_count > 10:
		dynamic_overlap = min(card_overlap, 400.0 / (card_count - 1))
	
	var total_width = dynamic_overlap * (card_count - 1)
	var start_x = hand_center_pos.x - (total_width / 2)
	
	for i in range(card_count):
		var card = hand[i]
		if card == null or not is_instance_valid(card):
			continue
		
		var target_pos = Vector2(start_x + (i * dynamic_overlap), hand_center_pos.y)
		
		if "base_position" in card:
			card.base_position = target_pos
		
		if card == hovered_card:
			continue
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(card, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "scale", Vector2.ONE, 0.2)
		card.z_index = 100 + i

func request_play_card(card):
	"""Attempts to play a card from hand (ROBUST VERSION)"""

	# ─────────────────────────────
	# VALIDACIONES DURAS
	# ─────────────────────────────
	if not game_active:
		return

	if current_turn != Turn.PLAYER:
		return

	if card == null or not is_instance_valid(card):
		push_error("Invalid card!")
		return

	if is_processing_play:
		return

	if is_waiting_for_color:
		return

	if not ("is_in_hand" in card and card.is_in_hand):
		return

	if card != hovered_card:
		return

	if not hand.has(card):
		return

	if discard_pile.is_empty():
		push_error("Discard pile empty!")
		return

	var top_card = discard_pile.back()
	if top_card == null or not is_instance_valid(top_card):
		push_error("Invalid top card!")
		return

	if not ("card_color" in card and "card_value" in card and "card_type" in card):
		push_error("Card missing properties!")
		return

	if not ("card_color" in top_card and "card_value" in top_card):
		push_error("Top card missing properties!")
		return

	# ─────────────────────────────
	# REGLAS DE JUGADA
	# ─────────────────────────────
	var is_wild: bool = card.card_color >= 4
	var matches_color: bool = card.card_color == top_card.card_color
	var matches_value: bool = card.card_value == top_card.card_value
	var can_play: bool = is_wild or matches_color or matches_value


	if not can_play:
		_shake_card(card)
		return

	# ─────────────────────────────
	# BLOQUEO DE INPUT
	# ─────────────────────────────
	is_processing_play = true

	# ─────────────────────────────
	# WILD → selección de color (sale aquí)
	# ─────────────────────────────
	if is_wild:
		_start_color_selection(card)
		is_processing_play = false
		return

	# ─────────────────────────────
	# JUGAR CARTA NORMAL
	# ─────────────────────────────
	_play_to_discard(card)
	card_played.emit(card, Turn.PLAYER)

	# ─────────────────────────────
	# EFECTOS DE CARTAS
	# ─────────────────────────────
	match card.card_type:

		card.CardType.DRAW2:
			_apply_draw_two(Turn.AI)
			is_processing_play = false
			return

		card.CardType.DRAW4:
			_apply_draw_four(Turn.AI)
			is_processing_play = false
			return

		card.CardType.SKIP:
			_apply_skip(Turn.AI)
			is_processing_play = false
			return

		card.CardType.REVERSE:
			# En 1v1 = SKIP
			_apply_reverse()
			is_processing_play = false
			return

		_:
			pass # carta normal

	# ─────────────────────────────
	# FLUJO NORMAL
	# ─────────────────────────────
	_check_uno_status()
	is_processing_play = false
	end_player_turn()

# ============================================================================
# AI CARD PLAYING
# ============================================================================
func ai_play_card(card):
	"""Plays an AI card to discard pile with visual feedback"""

	# Seguridad
	if card == null or not is_instance_valid(card):
		push_error("AI tried to play invalid card!")
		return

	# Animación carta AI
	if show_ai_card_backs and enable_ai_animations:
		_animate_ai_play_card()

	# Añadir al descarte
	discard_pile.append(card)

	card.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", discard_position, 0.4) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3)

	card.z_index = discard_pile.size()

	# Notificar carta jugada
	card_played.emit(card, Turn.AI)

	# ─────────────────────────────
	# APLICAR EFECTOS (AQUÍ SÍ)
	# ─────────────────────────────
	match card.card_type:
		card.CardType.DRAW2:
			_apply_draw_two(Turn.PLAYER)

		card.CardType.SKIP:
			_skip_turn(Turn.PLAYER)

		card.CardType.REVERSE:
			_apply_reverse()

		card.CardType.DRAW4:
			_apply_draw_four(Turn.PLAYER)

		card.CardType.WILD_COLOR:
			pass # solo cambia color, ya manejado



func ai_play_wild_card(card, chosen_color: int):
	"""Plays an AI wild card with visual feedback"""
	if card == null or not is_instance_valid(card):
		push_error("AI tried to play invalid wild card!")
		return
	
	if chosen_color < 0 or chosen_color > 3:
		push_warning("Invalid color %d chosen by AI, defaulting to 0" % chosen_color)
		chosen_color = 0
	
	if "card_color" in card:
		card.card_color = chosen_color
	
	var colors = [Color.RED, Color.CORNFLOWER_BLUE, Color.GREEN, Color.YELLOW]
	card.modulate = colors[chosen_color]
	
	if show_ai_card_backs and enable_ai_animations and ai_visual_cards.size() > 0:
		var visual_card = ai_visual_cards.back()
		if visual_card != null and is_instance_valid(visual_card):
			var flash_tween = create_tween()
			flash_tween.tween_property(visual_card, "modulate", colors[chosen_color], 0.3)
			await flash_tween.finished
	
	ai_play_card(card)

# ============================================================================
# WILD COLOR SELECTION
# ============================================================================

func _start_color_selection(card):
	"""Starts color selection process for wild card"""
	print("DEBUG: _start_color_selection() called")
	
	if card == null or not is_instance_valid(card):
		push_error("Invalid card for color selection!")
		return
	
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
	print(">>> INSTANTIATING COLOR SELECTOR <<<")
	var selector = color_selector_scene.instantiate()
	
	if selector == null:
		push_error("Failed to instantiate color selector!")
		is_waiting_for_color = false
		return
	
	add_child(selector)
	print(">>> COLOR SELECTOR ADDED TO SCENE <<<")
	
	if not selector.has_signal("color_selected"):
		push_error("Color selector doesn't have 'color_selected' signal!")
		selector.queue_free()
		is_waiting_for_color = false
		return
	
	selector.color_selected.connect(func(color_index):
		_on_wild_color_selected(card, color_index, selector)
	)
	
	print(">>> WAITING FOR COLOR SELECTION <<<")

func _on_wild_color_selected(card, color_index: int, selector):
	"""Called when color is selected for wild card"""
	print("DEBUG: Color selected: %d" % color_index)
	
	if card == null or not is_instance_valid(card):
		push_error("Card became invalid during color selection!")
		is_waiting_for_color = false
		if selector != null and is_instance_valid(selector):
			selector.queue_free()
		return
	
	if color_index < 0 or color_index > 3:
		push_warning("Invalid color index %d, using 0" % color_index)
		color_index = 0
	
	if "card_color" in card:
		card.card_color = color_index
	
	var colors = [Color.RED, Color.CORNFLOWER_BLUE, Color.GREEN, Color.YELLOW]
	card.modulate = colors[color_index]
	
	print("Wild card color selected: %d" % color_index)
	
	if "is_in_hand" in card and card.is_in_hand and card in hand:
		_play_to_discard(card)
		card_played.emit(card, Turn.PLAYER)
		_check_uno_status()
		end_player_turn()
	
	is_waiting_for_color = false
	
	if selector != null and is_instance_valid(selector):
		selector.queue_free()
	
	print(">>> COLOR SELECTOR REMOVED <<<")

# ============================================================================
# DISCARD AND VISUALS
# ============================================================================

func _play_to_discard(card, is_initial: bool = false):
	"""Plays a card to the discard pile"""
	if card == null or not is_instance_valid(card):
		push_error("Cannot play invalid card to discard!")
		return
	
	if not is_initial:
		if card in hand:
			hand.erase(card)
		if "is_in_hand" in card:
			card.is_in_hand = false
		if hovered_card == card: 
			hovered_card = null
	
	discard_pile.append(card)
	
	card.visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", discard_position, 0.4)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3)
	
	card.z_index = discard_pile.size()
	reorganize_hand()

func _shake_card(card):
	"""Shakes a card to indicate it cannot be played"""
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
	"""Updates which card is currently hovered"""
	var mouse_pos = get_global_mouse_position()
	var potential_cards = []
	
	hand = hand.filter(func(c): return c != null and is_instance_valid(c))
	
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
	
	var top_card = null
	if potential_cards.size() > 0:
		top_card = potential_cards[0]
		for c in potential_cards:
			if c.z_index > top_card.z_index: 
				top_card = c
	
	if top_card != hovered_card:
		if hovered_card != null and is_instance_valid(hovered_card):
			if hovered_card.has_method("set_hover"):
				hovered_card.set_hover(false)
		
		hovered_card = top_card
		if hovered_card != null and is_instance_valid(hovered_card):
			hovered_card.z_index = 300
			if hovered_card.has_method("set_hover"):
				hovered_card.set_hover(true, hover_lift, hover_scale)
			reorganize_hand()

func _input(event):
	"""Handles input events"""
	if not game_active:
		return
	
	if current_turn != Turn.PLAYER:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
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
	
#Function to pause game
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		print("ESC detectado en GameManager")
		SceneManager.pause_game(not get_tree().paused)
		get_viewport().set_input_as_handled()
		
func _skip_turn(target: Turn):
	if target == Turn.PLAYER:
		player_turn_skipped = true
		print("Player turn will be skipped.")
		# Como el jugador fue saltado, pasamos el control a la IA
		_start_ai_turn() 
	else:
		ai_turn_skipped = true
		print("AI turn will be skipped.")
		# Como la IA fue saltada, devolvemos el control al jugador
		_start_player_turn()

# Funciones auxiliares para organizar el flujo
func _start_ai_turn():
	if ai_turn_skipped:
		print("AI turn skipped after player action")
		ai_turn_skipped = false
		current_turn = Turn.PLAYER
		_display_turn_indicator()
		return


	current_turn = Turn.AI
	_display_turn_indicator()

	await get_tree().create_timer(0.8).timeout

	if ai_player and game_active:
		ai_player.take_turn(discard_pile.back(), self)


func _start_player_turn():
	current_turn = Turn.PLAYER
	_display_turn_indicator()
	is_processing_play = false # Desbloqueamos el input del jugador

func _reshuffle_discard_into_deck():
	print(">>> Reshuffling discard pile into deck...")
	
	# Keep the top card so the game can continue
	var top_card = discard_pile.pop_back()
	
	# Move everything else back to deck
	while discard_pile.size() > 0:
		var card = discard_pile.pop_back()
		card.visible = false # Hide cards going back to deck
		card.position = deck_position
		deck.append(card)
	
	deck.shuffle()
	
	# Put the top card back on the discard pile
	discard_pile.append(top_card)
	print(">>> Deck refilled with %d cards." % deck.size())

func _apply_draw_two(target: Turn):
	print(">>> DRAW +2 applied to ", target)

	for i in range(2):
		if deck.size() == 0:
			# Si el mazo está vacío, intentamos rellenarlo o cancelamos el robo
			if discard_pile.size() > 1:
				_reshuffle_discard_into_deck() # Implementa esta función si no la tienes
			else:
				push_warning("Deck empty during +2")
				break # IMPORTANTE: break permite que el código siga hacia _skip_turn

		if target == Turn.PLAYER:
			_deal_card_to_player()
		else:
			_deal_card_to_ai()

	# Una vez dadas las cartas, saltamos el turno del afectado
	_skip_turn(target)



func _apply_draw_four(target: Turn):
	print(">>> DRAW +4 applied to ", target)

	for i in range(4):
		if deck.size() == 0:
			push_warning("Deck empty during +4")
			return

		if target == Turn.PLAYER:
			_deal_card_to_player()
		else:
			_deal_card_to_ai()

	_skip_turn(target)
	
func _apply_skip(target: Turn):
	print(">>> SKIP applied to ", target)
	_skip_turn(target)

func _apply_reverse():
	print(">>> REVERSE applied")

	# En 1v1 (Player vs AI), reverse = skip
	_skip_turn(Turn.PLAYER)
