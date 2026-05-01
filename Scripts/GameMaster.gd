extends Node

# ═══════════════════════════════════════════════
#  SEÑALES
# ═══════════════════════════════════════════════
signal player_hand_changed
signal discard_pile_changed
signal deck_changed
signal cpu1_hand_changed
signal cpu2_hand_changed
signal cpu3_hand_changed
signal new_round()
signal game_started_multiplayer
signal multiplayer_state_updated
signal game_over(winner_peer_id: int)

@onready var card_draw_sfx = $CardDrawSfx

# ═══════════════════════════════════════════════
#  ESTADO DEL JUEGO
# ═══════════════════════════════════════════════
var current_player:    int    = 0
var current_color:     String = "Red"
var clockwise:         bool   = true
var cards_to_be_taken: int    = 0
var player_count:      int    = 4

var card_scene    = preload("res://Scenes/Cards/Card.tscn")
var deck:          Array = []
var discard_pile:  Array = []
var player_hand:   Array = []
var cpu1_hand:     Array = []
var cpu2_hand:     Array = []
var cpu3_hand:     Array = []

# ═══════════════════════════════════════════════
#  ESTADO MULTIPLAYER
# ═══════════════════════════════════════════════
var is_multiplayer: bool = false

# Solo el host usa estas:
var _mp_hands:        Array      = []   # _mp_hands[i] = Array de dicts {Color, Value}
var _peer_index:      Dictionary = {}   # peer_id → índice en _mp_hands
var _player_count_mp: int        = 0

# ═══════════════════════════════════════════════
#  CONSTANTES
# ═══════════════════════════════════════════════
const color_map = {
	"Blue":   Color(0, 0.764, 0.898),
	"Green":  Color(0.184, 0.886, 0.607),
	"Red":    Color(0.960, 0.392, 0.384),
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
		"Picker":  preload("res://Assets/Cards/Blue/blue_picker.png"),
		"Reverse": preload("res://Assets/Cards/Blue/blue_reverse.png"),
		"Skip":    preload("res://Assets/Cards/Blue/blue_skip.png"),
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
		"Picker":  preload("res://Assets/Cards/Green/green_picker.png"),
		"Reverse": preload("res://Assets/Cards/Green/green_reverse.png"),
		"Skip":    preload("res://Assets/Cards/Green/green_skip.png"),
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
		"Picker":  preload("res://Assets/Cards/Red/red_picker.png"),
		"Reverse": preload("res://Assets/Cards/Red/red_reverse.png"),
		"Skip":    preload("res://Assets/Cards/Red/red_skip.png"),
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
		"Picker":  preload("res://Assets/Cards/Yellow/yellow_picker.png"),
		"Reverse": preload("res://Assets/Cards/Yellow/yellow_reverse.png"),
		"Skip":    preload("res://Assets/Cards/Yellow/yellow_skip.png"),
	},
	"Wild": {
		"ColorChanger": preload("res://Assets/Cards/Wild/wild_colorchanger.png"),
		"PickFour":     preload("res://Assets/Cards/Wild/wild_pickfour.png"),
	},
}

# ═══════════════════════════════════════════════
#  INICIO MULTIPLAYER
#  Solo lo llama el host cuando todos cargaron la escena
# ═══════════════════════════════════════════════
func start_multiplayer_game() -> void:
	if not NetworkManager.is_host():
		return

	var ordered       = NetworkManager.get_ordered_ids()
	_player_count_mp  = ordered.size()
	_peer_index.clear()
	_mp_hands.clear()

	for i in _player_count_mp:
		_peer_index[ordered[i]] = i
		_mp_hands.append([])

	player_count = _player_count_mp
	_host_init_deck()

	# Repartir 7 cartas a cada jugador
	for i in _player_count_mp:
		_mp_hands[i] = _host_draw(7)

	# Primera carta del descarte — nunca Wild
	_host_draw_to_discard()
	while get_top_discard_card().get_meta("Color") == "Wild":
		_host_draw_to_discard()

	current_player    = 0
	clockwise         = true
	cards_to_be_taken = 0
	current_color     = get_top_discard_card().get_meta("Color")

	# Primero sincronizar, luego notificar inicio
	_host_sync_hands()
	_host_sync_state()
	_rpc_notify_game_started.rpc()

# ═══════════════════════════════════════════════
#  ACCIONES DEL JUGADOR LOCAL
# ═══════════════════════════════════════════════

func mp_play_card(color: String, value: String, chosen_color: String = "") -> void:
	if not _is_my_turn():
		return
	if NetworkManager.is_host():
		_host_play_card(NetworkManager.get_my_id(), color, value, chosen_color)
	else:
		_rpc_request_play.rpc_id(1, color, value, chosen_color)

func mp_draw_card() -> void:
	if not _is_my_turn():
		return
	if NetworkManager.is_host():
		_host_draw_card(NetworkManager.get_my_id(), 1, true)
	else:
		_rpc_request_draw.rpc_id(1)

func mp_draw_penalty() -> void:
	if not _is_my_turn():
		return
	var count         = cards_to_be_taken
	cards_to_be_taken = 0
	if NetworkManager.is_host():
		_host_draw_card(NetworkManager.get_my_id(), count, true)
	else:
		_rpc_request_draw_penalty.rpc_id(1, count)

# ═══════════════════════════════════════════════
#  RPCs CLIENTE → HOST
# ═══════════════════════════════════════════════

@rpc("any_peer", "reliable")
func _rpc_request_play(color: String, value: String, chosen_color: String) -> void:
	if not NetworkManager.is_host(): return
	_host_play_card(multiplayer.get_remote_sender_id(), color, value, chosen_color)

@rpc("any_peer", "reliable")
func _rpc_request_draw() -> void:
	if not NetworkManager.is_host(): return
	_host_draw_card(multiplayer.get_remote_sender_id(), 1, true)

@rpc("any_peer", "reliable")
func _rpc_request_draw_penalty(count: int) -> void:
	if not NetworkManager.is_host(): return
	cards_to_be_taken = 0
	_host_draw_card(multiplayer.get_remote_sender_id(), count, true)

# ═══════════════════════════════════════════════
#  LÓGICA DEL HOST
# ═══════════════════════════════════════════════

func _host_play_card(peer_id: int, color: String, value: String, chosen_color: String) -> void:
	var idx = _peer_index.get(peer_id, -1)
	if idx == -1: return

	var ordered = NetworkManager.get_ordered_ids()
	if ordered[current_player] != peer_id:
		push_warning("Turno incorrecto: esperaba peer %d, recibí de %d" % [ordered[current_player], peer_id])
		return

	# Buscar carta en la mano
	var hand   = _mp_hands[idx]
	var target = {}
	for card in hand:
		if card["Color"] == color and card["Value"] == value:
			target = card
			break

	if target.is_empty():
		push_warning("Carta %s %s no encontrada en mano de peer %d" % [color, value, peer_id])
		return

	if not _host_can_play(target):
		push_warning("Carta inválida de peer %d" % peer_id)
		return

	# Color elegido (Wild)
	if not chosen_color.is_empty():
		current_color = chosen_color
	elif color != "Wild":
		current_color = color

	# Pasar carta al descarte
	hand.erase(target)
	discard_pile.append(_make_card_node(target["Color"], target["Value"]))

	# Victoria
	if hand.is_empty():
		_host_sync_hands()
		_host_sync_state()
		_rpc_notify_game_over.rpc(peer_id)
		return

	# Efecto de la carta
	await _host_apply_effect(value)
	_host_sync_hands()
	_host_sync_state()

func _host_draw_card(peer_id: int, count: int, advance: bool) -> void:
	var idx = _peer_index.get(peer_id, -1)
	if idx == -1: return
	_mp_hands[idx].append_array(_host_draw(count))
	if advance:
		_advance_turn()
	_host_sync_hands()
	_host_sync_state()

func _host_apply_effect(value: String) -> void:
	match value:
		"Skip":
			_advance_turn(true)
		"Reverse":
			clockwise = not clockwise
			_advance_turn()
		"Picker":
			_advance_turn()
			_mp_hands[current_player].append_array(_host_draw(2))
			_advance_turn()
		"PickFour":
			_advance_turn()
			_mp_hands[current_player].append_array(_host_draw(4))
			_advance_turn()
		_:
			_advance_turn()

func _host_can_play(card: Dictionary) -> bool:
	var color = card["Color"]
	var value = card["Value"]
	if color == "Wild":
		return true
	if color == current_color:
		return true
	if value == get_top_discard_card().get_meta("Value"):
		return true
	return false

# ═══════════════════════════════════════════════
#  SINCRONIZACIÓN HOST → CLIENTES
# ═══════════════════════════════════════════════

func _host_sync_hands() -> void:
	var ordered = NetworkManager.get_ordered_ids()
	for i in ordered.size():
		var pid          = ordered[i]
		var my_hand_arr  = _mp_hands[i].duplicate()   # dicts, seguros para RPC

		# Contar cartas de rivales (en orden relativo: primer rival, segundo, tercero)
		var rival_counts: Array[int] = []
		for j in ordered.size():
			if j != i:
				rival_counts.append(_mp_hands[j].size())

		if pid == NetworkManager.get_my_id():
			# Host: llamada directa, SIN RPC
			_apply_hand_update(my_hand_arr, rival_counts)
		else:
			# Cliente: por RPC
			_rpc_receive_hand.rpc_id(pid, my_hand_arr, rival_counts)

func _host_sync_state() -> void:
	var top   = get_top_discard_card()
	var state = {
		"current_player"   : current_player,
		"current_color"    : current_color,
		"clockwise"        : clockwise,
		"cards_to_be_taken": cards_to_be_taken,
		"discard_color"    : top.get_meta("Color"),
		"discard_value"    : top.get_meta("Value"),
	}
	# Host: llamada directa
	_apply_state_update(state)
	# Clientes: broadcast (sin call_local para no ejecutarlo dos veces en el host)
	_rpc_receive_state.rpc(state)

# ═══════════════════════════════════════════════
#  RPCs HOST → CLIENTES
#  Sin call_local — el host se llama directo arriba
# ═══════════════════════════════════════════════

@rpc("authority", "reliable")
func _rpc_receive_hand(my_hand_arr: Array, rival_counts: Array) -> void:
	_apply_hand_update(my_hand_arr, rival_counts)

@rpc("authority", "reliable")
func _rpc_receive_state(state: Dictionary) -> void:
	_apply_state_update(state)

# Con call_local: notificaciones de eventos globales
@rpc("authority", "call_local", "reliable")
func _rpc_notify_game_started() -> void:
	emit_signal("game_started_multiplayer")

@rpc("authority", "call_local", "reliable")
func _rpc_notify_game_over(winner_peer_id: int) -> void:
	emit_signal("game_over", winner_peer_id)

# ═══════════════════════════════════════════════
#  APLICAR ACTUALIZACIONES LOCALMENTE
# ═══════════════════════════════════════════════

func _apply_hand_update(my_hand_arr: Array, rival_counts: Array) -> void:
	# Reconstruir mano propia como nodos
	player_hand.clear()
	for d in my_hand_arr:
		player_hand.append(_make_card_node(d["Color"], d["Value"]))
	emit_signal("player_hand_changed")

	# Reconstruir manos de rivales como dorsos
	var rival_arrays = [cpu1_hand, cpu2_hand, cpu3_hand]
	var rival_signals = ["cpu1_hand_changed", "cpu2_hand_changed", "cpu3_hand_changed"]
	for i in 3:
		rival_arrays[i].clear()
		if i < rival_counts.size():
			for _j in rival_counts[i]:
				rival_arrays[i].append(_make_back_node())
		emit_signal(rival_signals[i])

func _apply_state_update(state: Dictionary) -> void:
	current_player    = state["current_player"]
	current_color     = state["current_color"]
	clockwise         = state["clockwise"]
	cards_to_be_taken = state["cards_to_be_taken"]

	# Reconstruir carta del descarte
	var top = _make_card_node(state["discard_color"], state["discard_value"])
	discard_pile = [top]

	emit_signal("discard_pile_changed")
	emit_signal("new_round")
	emit_signal("multiplayer_state_updated")

# ═══════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════

func _is_my_turn() -> bool:
	if not is_multiplayer: return true
	var ordered = NetworkManager.get_ordered_ids()
	if ordered.is_empty() or current_player >= ordered.size(): return false
	return ordered[current_player] == NetworkManager.get_my_id()

func _get_current_peer_id() -> int:
	var ordered = NetworkManager.get_ordered_ids()
	if ordered.is_empty() or current_player >= ordered.size(): return -1
	return ordered[current_player]

func _advance_turn(skip: bool = false) -> void:
	var dir = 1 if clockwise else -1
	if skip: dir *= 2
	current_player = (current_player + dir) % _player_count_mp
	if current_player < 0: current_player += _player_count_mp

func _make_card_node(color: String, value: String) -> Node:
	var card = card_scene.instantiate()
	card.set_meta("Color", color)
	card.set_meta("Value", value)
	card.set_meta("CardBack", false)
	card.set_meta("HoverEffect", false)
	card.set_meta("CanBePlayed", false)
	return card

func _make_back_node() -> Node:
	var card = card_scene.instantiate()
	card.set_meta("Color", "Wild")
	card.set_meta("Value", "ColorChanger")
	card.set_meta("CardBack", true)
	card.set_meta("HoverEffect", false)
	card.set_meta("CanBePlayed", false)
	return card

# ═══════════════════════════════════════════════
#  DECK HOST ONLY (trabaja con dicts, no con nodos)
# ═══════════════════════════════════════════════

func _host_init_deck() -> void:
	deck.clear()
	for color in sprite_map.keys():
		for value in sprite_map[color].keys():
			for _i in range(player_count):
				deck.append({"Color": color, "Value": value})
	deck.shuffle()

func _host_draw(count: int) -> Array:
	var drawn = []
	for _i in count:
		if deck.is_empty():
			_host_refill_deck()
		if not deck.is_empty():
			drawn.append(deck.pop_back())
	card_draw_sfx.play()
	return drawn

func _host_refill_deck() -> void:
	if discard_pile.size() <= 1: return
	var top_node = discard_pile.pop_back()
	for node in discard_pile:
		deck.append({"Color": node.get_meta("Color"), "Value": node.get_meta("Value")})
	discard_pile.clear()
	discard_pile.append(top_node)
	deck.shuffle()

func _host_draw_to_discard() -> void:
	if deck.is_empty(): return
	var d = deck.pop_back()
	discard_pile.append(_make_card_node(d["Color"], d["Value"]))

# ═══════════════════════════════════════════════
#  SINGLE PLAYER — intacto
# ═══════════════════════════════════════════════

func next_turn(skip: bool = false, reverse: bool = false) -> void:
	if reverse: clockwise = not clockwise
	var dir = 1 if clockwise else -1
	if skip: dir *= 2
	current_player = (current_player + dir) % player_count
	if current_player < 0: current_player += player_count
	new_round.emit()

func clear_deck() -> void:
	deck = []
	emit_signal("deck_changed")

func clear_discard_pile() -> void:
	discard_pile = []
	emit_signal("discard_pile_changed")

func clear_player_hand() -> void:
	player_hand = []
	emit_signal("player_hand_changed")

func fill_deck() -> void:
	for color in sprite_map.keys():
		for value in sprite_map[color].keys():
			for _i in range(player_count):
				var card = card_scene.instantiate()
				card.set_meta("Color", color)
				card.set_meta("Value", value)
				card.set_meta("CardBack", false)
				card.set_meta("HoverEffect", false)
				card.set_meta("CanBePlayed", false)
				deck.append(card)
	emit_signal("deck_changed")

func refill_deck() -> void:
	var shown_card = discard_pile.pop_back()
	deck.append_array(discard_pile)
	discard_pile.clear()
	discard_pile.append(shown_card)

func shuffle_deck() -> void:
	deck.shuffle()
	emit_signal("deck_changed")

func init_deck() -> void:
	clear_deck()
	fill_deck()
	shuffle_deck()
	emit_signal("deck_changed")

func draw_from_deck(card_count: int) -> Array:
	var drawn_cards = []
	if deck.size() > card_count:
		for _i in range(card_count):
			drawn_cards.append(deck.pop_back())
		emit_signal("deck_changed")
		card_draw_sfx.play()
		return drawn_cards
	else:
		refill_deck()
		return await draw_from_deck(card_count)

func draw_to_player_hand(card_count: int) -> void:
	if deck.size() > card_count:
		for _i in range(card_count):
			player_hand.append(deck.pop_back())
		sort_player_hand()
		emit_signal("deck_changed")
		emit_signal("player_hand_changed")
		card_draw_sfx.play()
	else:
		refill_deck()
		draw_to_player_hand(card_count)

func draw_to_cpu_hand(card_count: int, cpu_hand: int) -> void:
	if deck.size() > card_count:
		card_draw_sfx.play()
		var drawn = []
		for _i in range(card_count):
			drawn.append(deck.pop_back())
		match cpu_hand:
			1:
				cpu1_hand.append_array(drawn)
				sort_cpu_hand(1)
				emit_signal("cpu1_hand_changed")
			2:
				cpu2_hand.append_array(drawn)
				sort_cpu_hand(2)
				emit_signal("cpu2_hand_changed")
			3:
				cpu3_hand.append_array(drawn)
				sort_cpu_hand(3)
				emit_signal("cpu3_hand_changed")
		emit_signal("deck_changed")
	else:
		refill_deck()
		draw_to_cpu_hand(card_count, cpu_hand)

func draw_to_discard(card_count: int) -> void:
	if deck.size() > card_count:
		for _i in range(card_count):
			var card = deck.pick_random()
			discard_pile.append(card)
			deck.erase(card)
		current_color = get_top_discard_card().get_meta("Color")
		emit_signal("deck_changed")
		emit_signal("discard_pile_changed")
	else:
		refill_deck()
		draw_to_discard(card_count)

func play_to_discard(played_from: int, played_card) -> void:
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
	await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
	match cpu_id:
		1:
			if cards_to_be_taken > 0:
				for card in cpu1_hand:
					if card.can_be_played(card, true, true): playable_cards.append(card)
				if playable_cards.size() > 0:
					playable_cards.pick_random().play_card(cpu_id)
				else:
					draw_to_cpu_hand(cards_to_be_taken, cpu_id)
					cards_to_be_taken = 0
					cpu_play(cpu_id)
			else:
				for card in cpu1_hand:
					if card.can_be_played(card, true): playable_cards.append(card)
				if playable_cards.size() > 0:
					playable_cards.pick_random().play_card(cpu_id)
				else:
					draw_to_cpu_hand(1, cpu_id)
					cpu_play(cpu_id)
		2:
			if cards_to_be_taken > 0:
				for card in cpu2_hand:
					if card.can_be_played(card, true, true): playable_cards.append(card)
				if playable_cards.size() > 0:
					playable_cards.pick_random().play_card(cpu_id)
				else:
					draw_to_cpu_hand(cards_to_be_taken, cpu_id)
					cards_to_be_taken = 0
					cpu_play(cpu_id)
			else:
				for card in cpu2_hand:
					if card.can_be_played(card, true): playable_cards.append(card)
				if playable_cards.size() > 0:
					playable_cards.pick_random().play_card(cpu_id)
				else:
					draw_to_cpu_hand(1, cpu_id)
					cpu_play(cpu_id)
		3:
			if cards_to_be_taken > 0:
				for card in cpu3_hand:
					if card.can_be_played(card, true, true): playable_cards.append(card)
				if playable_cards.size() > 0:
					playable_cards.pick_random().play_card(cpu_id)
				else:
					draw_to_cpu_hand(cards_to_be_taken, cpu_id)
					cards_to_be_taken = 0
					cpu_play(cpu_id)
			else:
				for card in cpu3_hand:
					if card.can_be_played(card, true): playable_cards.append(card)
				if playable_cards.size() > 0:
					playable_cards.pick_random().play_card(cpu_id)
				else:
					draw_to_cpu_hand(1, cpu_id)
					cpu_play(cpu_id)

func get_top_discard_card() -> Node2D:
	return discard_pile[-1]

func sort_player_hand() -> void:
	player_hand.sort_custom(compare_cards)
	emit_signal("player_hand_changed")

func sort_cpu_hand(cpu_hand: int) -> void:
	match cpu_hand:
		1:
			cpu1_hand.sort_custom(compare_cards)
			emit_signal("cpu1_hand_changed")
		2:
			cpu2_hand.sort_custom(compare_cards)
			emit_signal("cpu2_hand_changed")
		3:
			cpu3_hand.sort_custom(compare_cards)
			emit_signal("cpu3_hand_changed")

func compare_cards(card1, card2) -> bool:
	var color_order = {"Blue": 0, "Green": 1, "Red": 2, "Yellow": 3, "Wild": 4}
	var c1 = card1.get_meta("Color")
	var c2 = card2.get_meta("Color")
	if color_order[c1] != color_order[c2]:
		return color_order[c1] < color_order[c2]
	return card1.get_meta("Value") < card2.get_meta("Value")
