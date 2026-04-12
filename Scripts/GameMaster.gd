extends Node

signal player_hand_changed #when a card is added to or removed from the player hand
signal discard_pile_changed #when a card is added to or removed from the discard pile
signal deck_changed #when a card is added to or removed from the deck
signal cpu1_hand_changed #when a card is added to or removed from the cpu1's hand
signal cpu2_hand_changed #ditto
signal cpu3_hand_changed
signal new_round()

signal game_started_multiplayer
signal multiplayer_state_updated
signal game_over(winner_peer_id: int)

@onready var card_draw_sfx = $CardDrawSfx

var players = ["player", "cpu1", "cpu2", "cpu3"]
var current_player: int = 0
var current_color: String
var clockwise = true
var cards_to_be_taken: int = 0

var player_count: int = 4 #how many players are playing
var card_scene = preload("res://Scenes/Cards/Card.tscn") #the card scene

var deck = [] #the deck from which all cards are drawn
var discard_pile = [] #the pile where played cards go to
var player_hand = [] #cards in the player's hand
var cpu1_hand = [] #cards in cpu1's hand
var cpu2_hand = [] #ditto
var cpu3_hand = []

var is_multiplayer: bool = false
var peer_to_hand_index: Dictionary = {}
var my_hand_data: Array = []

const color_map = {
	"Blue": Color(0, 0.764, 0.898),
	"Green": Color(0.184, 0.886, 0.607),
	"Red": Color(0.960, 0.392, 0.384),
	"Yellow": Color(0.968, 0.890, 0.349),
}

const sprite_map: Dictionary = {
	"Blue": {
		"0": preload("res://Assets/Cards/Blue/blue_0.png"),
		"1": preload("res://Assets/Cards/Blue/blue_1.png"),
		"2": preload("res://Assets/Cards/Blue/blue_2.png"),
		"3": preload("res://Assets/Cards/Blue/blue_3.png"),
		"4": preload("res://Assets/Cards/Blue/blue_4.png"),
		"5": preload("res://Assets/Cards/Blue/blue_5.png"),
		"6": preload("res://Assets/Cards/Blue/blue_6.png"),
		"7": preload("res://Assets/Cards/Blue/blue_7.png"),
		"8": preload("res://Assets/Cards/Blue/blue_8.png"),
		"9": preload("res://Assets/Cards/Blue/blue_9.png"),
		"Picker": preload("res://Assets/Cards/Blue/blue_picker.png"),
		"Reverse": preload("res://Assets/Cards/Blue/blue_reverse.png"),
		"Skip": preload("res://Assets/Cards/Blue/blue_skip.png"),
	},
	"Green": {
		"0": preload("res://Assets/Cards/Green/green_0.png"),
		"1": preload("res://Assets/Cards/Green/green_1.png"),
		"2": preload("res://Assets/Cards/Green/green_2.png"),
		"3": preload("res://Assets/Cards/Green/green_3.png"),
		"4": preload("res://Assets/Cards/Green/green_4.png"),
		"5": preload("res://Assets/Cards/Green/green_5.png"),
		"6": preload("res://Assets/Cards/Green/green_6.png"),
		"7": preload("res://Assets/Cards/Green/green_7.png"),
		"8": preload("res://Assets/Cards/Green/green_8.png"),
		"9": preload("res://Assets/Cards/Green/green_9.png"),
		"Picker": preload("res://Assets/Cards/Green/green_picker.png"),
		"Reverse": preload("res://Assets/Cards/Green/green_reverse.png"),
		"Skip": preload("res://Assets/Cards/Green/green_skip.png"),
	},
	"Red": {
		"0": preload("res://Assets/Cards/Red/red_0.png"),
		"1": preload("res://Assets/Cards/Red/red_1.png"),
		"2": preload("res://Assets/Cards/Red/red_2.png"),
		"3": preload("res://Assets/Cards/Red/red_3.png"),
		"4": preload("res://Assets/Cards/Red/red_4.png"),
		"5": preload("res://Assets/Cards/Red/red_5.png"),
		"6": preload("res://Assets/Cards/Red/red_6.png"),
		"7": preload("res://Assets/Cards/Red/red_7.png"),
		"8": preload("res://Assets/Cards/Red/red_8.png"),
		"9": preload("res://Assets/Cards/Red/red_9.png"),
		"Picker": preload("res://Assets/Cards/Red/red_picker.png"),
		"Reverse": preload("res://Assets/Cards/Red/red_reverse.png"),
		"Skip": preload("res://Assets/Cards/Red/red_skip.png"),
	},
	"Yellow": {
		"0": preload("res://Assets/Cards/Yellow/yellow_0.png"),
		"1": preload("res://Assets/Cards/Yellow/yellow_1.png"),
		"2": preload("res://Assets/Cards/Yellow/yellow_2.png"),
		"3": preload("res://Assets/Cards/Yellow/yellow_3.png"),
		"4": preload("res://Assets/Cards/Yellow/yellow_4.png"),
		"5": preload("res://Assets/Cards/Yellow/yellow_5.png"),
		"6": preload("res://Assets/Cards/Yellow/yellow_6.png"),
		"7": preload("res://Assets/Cards/Yellow/yellow_7.png"),
		"8": preload("res://Assets/Cards/Yellow/yellow_8.png"),
		"9": preload("res://Assets/Cards/Yellow/yellow_9.png"),
		"Picker": preload("res://Assets/Cards/Yellow/yellow_picker.png"),
		"Reverse": preload("res://Assets/Cards/Yellow/yellow_reverse.png"),
		"Skip": preload("res://Assets/Cards/Yellow/yellow_skip.png"),
	},
	"Wild": {
		"ColorChanger": preload("res://Assets/Cards/Wild/wild_colorchanger.png"),
		"PickFour": preload("res://Assets/Cards/Wild/wild_pickfour.png"),
	},
}

func start_multiplayer_game() -> void:
	if not NetworkManager.is_host():
		return
	print("START ordered: ", NetworkManager.get_ordered_ids())
	print("START players: ", NetworkManager.players)
	is_multiplayer = true
	
	#Mapear peer_ids a indices de mano
	var ordered = NetworkManager.get_ordered_ids()
	for i in ordered.size():
		peer_to_hand_index[ordered[i]] = i
	
	#Inicializar mazo y repartir usando la logica existente
	init_deck()
	
	for i in ordered.size():
		var drawn = await draw_from_deck(7)
		_set_hand_by_index(i, drawn)
	
	#Primera carta del descarte (no Wild)
	draw_to_discard(1)
	while get_top_discard_card().get_meta("Color") == "wild":
		draw_to_discard(1)
	current_player = 0
	clockwise = true
	cards_to_be_taken = 0
	
	#Sincronizar a todos
	_sync_all_hands()
	_sync_public_state()
	
	#Notificar inicio
	_rpc_game_started.rpc()
	
# ========== Acciones del Jugador Local ============
#El jugador local quiere jugar una carta
func mp_request_play(card_color: String, card_value: String, chosen_color: String="") -> void:
	if not _is_my_turn():
		return
	if NetworkManager.is_host():
		_server_play_card(NetworkManager.get_my_id(), card_color, card_value, chosen_color)
	else:
		_rpc_request_play.rpc_id(1, card_color, card_value, chosen_color)

#El Jugador local roba una carta
func mp_request_draw() -> void:
	if not _is_my_turn():
		return
	if NetworkManager.is_host():
		_server_draw_card(NetworkManager.get_my_id(), 1, true)
	else:
		_rpc_request_draw.rpc_id(1)

# ============= RPCs Cliente -> Host ============
@rpc("any_peer", "reliable")
func _rpc_request_play(color: String, value: String, chosen_color: String) -> void:
	if not NetworkManager.is_host():
		return
	var sender = multiplayer.get_remote_sender_id()
	_server_play_card(sender, color, value, chosen_color)

@rpc("any_peer", "reliable")
func _rpc_request_draw() -> void:
	if not NetworkManager.is_host():
		return
	var sender = multiplayer.get_remote_sender_id()
	_server_draw_card(sender, 1, true)
	
#============ Logia del HOST (arbitro) =================
func _server_play_card(peer_id: int, color: String, value: String,
		chosen_color: String) -> void:
	var hand_idx = peer_to_hand_index.get(peer_id, -1)
	if hand_idx == -1:
		return

	# Validar turno
	var ordered = NetworkManager.get_ordered_ids()
	if ordered[current_player] != peer_id:
		push_warning("Jugada rechazada: no es el turno de %d" % peer_id)
		return

	# Buscar la carta en la mano
	var hand = _get_hand_by_index(hand_idx)
	var target_card: Node = null
	for card in hand:
		if card.get_meta("Color") == color and card.get_meta("Value") == value:
			target_card = card
			break

	if not target_card:
		push_warning("Carta no encontrada en mano de %d" % peer_id)
		return

	# Validar jugada usando tu lógica existente
	if not target_card.can_be_played(target_card, false):
		push_warning("Carta inválida de %d: %s %s sobre %s %s" % [
			peer_id, color, value, current_color,
			get_top_discard_card().get_meta("Value")
		])
		return
	if color == "Wild":
		if not chosen_color.is_empty():
			current_color = chosen_color
		else:
			current_color = color_map.keys().pick_random()
	else:
		current_color = color

	# Jugar la carta usando tu función existente
	play_to_discard(hand_idx, target_card)
	
	var top = get_top_discard_card()

	# Verificar victoria
	if _get_hand_by_index(hand_idx).is_empty():
		_rpc_game_over.rpc(peer_id)
		return

	# Aplicar efecto de la carta (skip, reverse, etc.)
	# Tu lógica de efectos ya existe en Card.gd — aquí solo avanzamos turno
	# Si tu Card.gd llama next_turn() internamente, esto ya está cubierto
	# Si no, puedes llamarlo aquí según el valor:
	_apply_card_effect_server(value, hand_idx)
	_sync_all_hands()
	_sync_public_state()

func _server_draw_card(peer_id: int, count: int, advance: bool) -> void:
	var hand_idx = peer_to_hand_index.get(peer_id, -1)
	if hand_idx == -1:
		return

	var drawn = await draw_from_deck(count)
	var hand = _get_hand_by_index(hand_idx)
	hand.append_array(drawn)

	if advance:
		next_turn()

	_sync_all_hands()
	_sync_public_state()

func _apply_card_effect_server(value: String, played_by_idx: int) -> void:
	match value:
		"Skip":
			next_turn(true, false)
		"Reverse":
			next_turn(false, true)
		"Picker":   # +2
			next_turn()
			var next_idx = peer_to_hand_index.get(
				NetworkManager.get_ordered_ids()[current_player], -1
			)
			if next_idx != -1:
				var drawn = await draw_from_deck(2)
				_get_hand_by_index(next_idx).append_array(drawn)
			next_turn()
		"PickFour": # +4
			next_turn()
			var next_idx = peer_to_hand_index.get(
				NetworkManager.get_ordered_ids()[current_player], -1
			)
			if next_idx != -1:
				var drawn = await draw_from_deck(4)
				_get_hand_by_index(next_idx).append_array(drawn)
			next_turn()
		_:
			next_turn()

# ══ SINCRONIZACIÓN HOST → CLIENTES ════════════════════════════════════════════

func _sync_all_hands() -> void:
	var ordered = NetworkManager.get_ordered_ids()
	for i in ordered.size():
		var pid = ordered[i]
		var hand_arr = GameState.hand_to_array(_get_hand_by_index(i))
		if pid == NetworkManager.get_my_id():  # host se actualiza localmente
			_rpc_receive_hand(hand_arr)
		else:
			_rpc_receive_hand.rpc_id(pid, hand_arr)

func _sync_public_state() -> void:
	var state = GameState.build_public_state(self)
	_rpc_receive_state(state)
	_rpc_receive_state.rpc(state)

# ══ RPCs HOST → CLIENTES ═════════════════════════════════════════════════════

@rpc("authority", "reliable", "call_local")
func _rpc_game_started() -> void:
	is_multiplayer = true
	emit_signal("game_started_multiplayer")

@rpc("authority", "reliable")
func _rpc_receive_hand(hand_data: Array) -> void:
	# Reconstruir nodos carta desde los dicts
	my_hand_data = hand_data
	player_hand.clear()
	for d in hand_data:
		player_hand.append(GameState.dict_to_card(d))
	emit_signal("player_hand_changed")

@rpc("authority", "reliable")
func _rpc_receive_state(state: Dictionary) -> void:
	print("RECV STATE discard_top: " , state["discard_top"])
	current_player    = state["current_player"]
	current_color     = state["current_color"]
	clockwise         = state["clockwise"]
	cards_to_be_taken = state["cards_to_be_taken"]

	#Solo reconstruir el descarte si cambio
	var top_data = state["discard_top"]
	var current_top = discard_pile.back() if not discard_pile.is_empty() else null
	var needs_update = true
	if current_top != null:
		if current_top.get_meta("Color") == top_data["color"] and current_top.get_meta("Value") == top_data["value"]:
			needs_update = false
	if needs_update:
		var top = GameState.dict_to_card(top_data)
		discard_pile = [top]
		emit_signal("discard_pile_changed")
	emit_signal("new_round")
	emit_signal("multiplayer_state_updated")

@rpc("authority", "reliable", "call_local")
func _rpc_game_over(winner_peer_id: int) -> void:
	emit_signal("game_over", winner_peer_id)

# ══ HELPERS ══════════════════════════════════════════════════════════════════

func _is_my_turn() -> bool:
	if not is_multiplayer:
		return true
	var ordered = NetworkManager.get_ordered_ids()
	if ordered.is_empty() or current_player >= ordered.size():
		return false
	return ordered[current_player] == NetworkManager.get_my_id()

func _get_hand_by_index(idx: int) -> Array:
	match idx:
		0: return player_hand
		1: return cpu1_hand
		2: return cpu2_hand
		3: return cpu3_hand
	return []

func _set_hand_by_index(idx: int, hand: Array) -> void:
	match idx:
		0: player_hand = hand
		1: cpu1_hand   = hand
		2: cpu2_hand   = hand
		3: cpu3_hand   = hand

func next_turn(skip: bool = false, reverse: bool = false) -> void:
	if reverse:
		clockwise = not clockwise
	var player_count_total = NetworkManager.get_ordered_ids().size() if is_multiplayer else players.size()
	
	var direction_modifier = 1 if clockwise else -1
	if skip:
		direction_modifier *= 2
	var new_index = (current_player + direction_modifier) % player_count_total
	if new_index < 0:
		new_index += player_count_total
	current_player = new_index
	new_round.emit()

func clear_deck() -> void: #empty the deck
	deck = []
	emit_signal("deck_changed")

func clear_discard_pile() -> void: #empty the discard pile
	discard_pile = []
	emit_signal("discard_pile_changed")

func clear_player_hand() -> void: #empty the player hand
	player_hand = []
	emit_signal("player_hand_changed")

func fill_deck() -> void: #generate cards based on the number of players
	for color in sprite_map.keys():
		for value in sprite_map[color].keys():
			for _i in range(player_count):
				var card = card_scene.instantiate()
				card.set_meta("Color", color)
				card.set_meta("Value", value)
				deck.append(card)
	emit_signal("deck_changed")

func refill_deck() -> void: #move all but the last card from the discard pile to deck
	var shown_card = discard_pile.pop_back()
	deck.append_array(discard_pile)
	discard_pile.clear()
	discard_pile.append(shown_card)

func shuffle_deck() -> void: #shuffle the cards in the deck
	deck.shuffle()
	emit_signal("deck_changed")

func init_deck() -> void: #clear, fill, and then shuffle the deck
	clear_deck()
	fill_deck()
	shuffle_deck()
	emit_signal("deck_changed")

func draw_from_deck(card_count: int) -> Array: #removes the amount of wanted cards from the deck and returns them
	var drawn_cards = []
	if deck.size() > card_count:
		for i in range(card_count):
			var card = deck.pop_back()
			drawn_cards.append(card)
		emit_signal("deck_changed")
		card_draw_sfx.play()
		return drawn_cards
	else:
		refill_deck()
		return await draw_from_deck(card_count)

func draw_to_player_hand(card_count: int) -> void: #removes the amount of wanted cards from the deck and moves them to player's hand
	var drawn_cards = []
	if deck.size() > card_count:
		for i in range(card_count):
			var card = deck.pop_back()
			drawn_cards.append(card)
		player_hand += drawn_cards
		sort_player_hand()
		emit_signal("deck_changed")
		emit_signal("player_hand_changed")
		card_draw_sfx.play()
	else:
		refill_deck()
		draw_to_player_hand(card_count)

func draw_to_cpu_hand(card_count: int, cpu_hand: int): #removes the amount of wanted cards from the deck and moves them to given cpu's hand
	var drawn_cards = []
	if deck.size() > card_count:
		card_draw_sfx.play()
		for i in range(card_count):
			var card = deck.pop_back()
			drawn_cards.append(card)
		if cpu_hand == 1:
			cpu1_hand.append_array(drawn_cards)
			sort_cpu_hand(1)
			emit_signal("deck_changed")
			emit_signal("cpu1_hand_changed")
		elif cpu_hand == 2:
			cpu2_hand.append_array(drawn_cards)
			sort_cpu_hand(2)
			emit_signal("deck_changed")
			emit_signal("cpu2_hand_changed")
		elif cpu_hand == 3:
			cpu3_hand.append_array(drawn_cards)
			sort_cpu_hand(3)
			emit_signal("deck_changed")
			emit_signal("cpu3_hand_changed")
	else:
		refill_deck()
		draw_to_cpu_hand(card_count, cpu_hand)

func draw_to_discard(card_count: int) -> void: #removes the amount of random wanted cards from the deck and moves them to the discard pile
	var drawn_cards = []
	if deck.size() > card_count:
		for i in range(card_count):
			var card = deck.pick_random()
			drawn_cards.append(card)
		discard_pile += drawn_cards
		for card in drawn_cards:
			deck.erase(card)
		current_color = get_top_discard_card().get_meta("Color")
		emit_signal("deck_changed")
		emit_signal("discard_pile_changed")
	else:
		refill_deck()
		draw_to_discard(card_count)

func play_to_discard(played_from: int, played_card: Variant): #removes the given card from the given hand and moves it to the discard pile
	match played_from:
		0:
			discard_pile.append(played_card)
			player_hand.erase(played_card)
			emit_signal("player_hand_changed")
			emit_signal("discard_pile_changed")
		1:
			discard_pile.append(played_card)
			cpu1_hand.erase(played_card)
			emit_signal("cpu1_hand_changed")
			emit_signal("discard_pile_changed")
		2:
			discard_pile.append(played_card)
			cpu2_hand.erase(played_card)
			emit_signal("cpu2_hand_changed")
			emit_signal("discard_pile_changed")
		3:
			discard_pile.append(played_card)
			cpu3_hand.erase(played_card)
			emit_signal("cpu3_hand_changed")
			emit_signal("discard_pile_changed")

func cpu_play(cpu_id: int) -> void:
	var playable_cards = []
	var random_delay = randf_range(1.0, 3.0)
	await get_tree().create_timer(random_delay).timeout
	match cpu_id:
		1:
			if cards_to_be_taken > 0:
				for card in cpu1_hand:
					if card.can_be_played(card, true, true):
						playable_cards.append(card)
				if playable_cards.size() > 0:
					var card_to_play = playable_cards.pick_random()
					card_to_play.play_card(cpu_id)
				else:
					draw_to_cpu_hand(cards_to_be_taken, cpu_id)
					cards_to_be_taken = 0
					cpu_play(cpu_id)
			else:
				for card in cpu1_hand:
					if card.can_be_played(card, true):
						playable_cards.append(card)
				if playable_cards.size() > 0:
					var card_to_play = playable_cards.pick_random()
					card_to_play.play_card(cpu_id)
				else:
					draw_to_cpu_hand(1, cpu_id)
					cpu_play(cpu_id)
		2:
			if cards_to_be_taken > 0:
				for card in cpu2_hand:
					if card.can_be_played(card, true, true):
						playable_cards.append(card)
				if playable_cards.size() > 0:
					var card_to_play = playable_cards.pick_random()
					card_to_play.play_card(cpu_id)
				else:
					draw_to_cpu_hand(cards_to_be_taken, cpu_id)
					cards_to_be_taken = 0
					cpu_play(cpu_id)
			else:
				for card in cpu2_hand:
					if card.can_be_played(card, true):
						playable_cards.append(card)
				if playable_cards.size() > 0:
					var card_to_play = playable_cards.pick_random()
					card_to_play.play_card(cpu_id)
				else:
					draw_to_cpu_hand(1, cpu_id)
					cpu_play(cpu_id)
		3:
			if cards_to_be_taken > 0:
				for card in cpu3_hand:
					if card.can_be_played(card, true, true):
						playable_cards.append(card)
				if playable_cards.size() > 0:
					var card_to_play = playable_cards.pick_random()
					card_to_play.play_card(cpu_id)
				else:
					draw_to_cpu_hand(cards_to_be_taken, cpu_id)
					cards_to_be_taken = 0
					cpu_play(cpu_id)
			else:
				for card in cpu3_hand:
					if card.can_be_played(card, true):
						playable_cards.append(card)
				if playable_cards.size() > 0:
					var card_to_play = playable_cards.pick_random()
					card_to_play.play_card(cpu_id)
				else:
					draw_to_cpu_hand(1, cpu_id)
					cpu_play(cpu_id)


func get_top_discard_card() -> Node2D: #returns the top card in the discard pile
	return discard_pile[-1]

func sort_player_hand() -> void: #sorts the cards in the player's hand
	player_hand.sort_custom(compare_cards)
	emit_signal("player_hand_changed")

func sort_cpu_hand(cpu_hand: int) -> void:
	if cpu_hand == 1:
		cpu1_hand.sort_custom(compare_cards)
		emit_signal("cpu1_hand_changed")
	elif cpu_hand == 2:
		cpu2_hand.sort_custom(compare_cards)
		emit_signal("cpu2_hand_changed")
	elif cpu_hand == 3:
		cpu3_hand.sort_custom(compare_cards)
		emit_signal("cpu3_hand_changed")


func compare_cards(card1, card2): #the sorting algorithm which first sorts cards based on color then value
	var color_order = {"Blue": 0, "Green": 1, "Red": 2, "Yellow": 3, "Wild": 4}
	var card1_color = card1.get_meta("Color")
	var card2_color = card2.get_meta("Color")
	if color_order[card1_color] != color_order[card2_color]:
		return color_order[card1_color] < color_order[card2_color]
	else:
		return card1.get_meta("Value") < card2.get_meta("Value")

# Devuelve el peer_id del jugador cuyo turno es ahora
func _get_current_peer_id() -> int:
	var ordered = NetworkManager.get_ordered_ids()
	if ordered.is_empty() or current_player >= ordered.size():
		return -1
	return ordered[current_player]

# Versión multijugador del "robar por penalización" (Picker/PickFour acumulados)
func mp_request_draw_penalty() -> void:
	if not _is_my_turn():
		return
	var count = cards_to_be_taken
	cards_to_be_taken = 0
	if NetworkManager.is_host():
		_server_draw_card(NetworkManager.get_my_id(), count, true)
	else:
		_rpc_request_draw_penalty.rpc_id(1, count)

@rpc("any_peer", "reliable")
func _rpc_request_draw_penalty(count: int) -> void:
	if not NetworkManager.is_host():
		return
	var sender = multiplayer.get_remote_sender_id()
	cards_to_be_taken = 0
	_server_draw_card(sender, count, true)
