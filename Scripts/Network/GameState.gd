extends Node
# Serializa un nodo carta a diccionario (para que pueda ser enviado por la red)
static func card_to_dict(card: Node) -> Dictionary:
	return {
		"Color": card.get_meta("Color"),  # FIX: era "color" minúscula, causaba que las cartas
		"Value": card.get_meta("Value")   # FIX: era "value" minúscula — se deserializaban mal
	}

# Serializa un array de nodos carta
static func hand_to_array(hand: Array) -> Array:
	var result = []
	for card in hand:
		result.append(card_to_dict(card))
	return result

# Crea un nodo carta desde un diccionario
static func dict_to_card(data: Dictionary) -> Node:
	var card_scene = preload("res://Scenes/Cards/Card.tscn")
	var card = card_scene.instantiate()
	card.set_meta("Color", data["Color"])  # FIX: consistente con mayúscula
	card.set_meta("Value", data["Value"])  # FIX: consistente con mayúscula
	card.set_meta("CardBack", false)       # FIX: inicializar meta necesaria para Card._ready()
	card.set_meta("HoverEffect", false)
	card.set_meta("CanBePlayed", false)
	return card

# Construye el estado público del juego
static func build_public_state(gm) -> Dictionary:
	var top_card = gm.get_top_discard_card()
	return {
		"current_player"   : gm.current_player,
		"current_color"    : gm.current_color,
		"clockwise"        : gm.clockwise,
		"cards_to_be_taken": gm.cards_to_be_taken,  # FIX: era gm.cards_to_be_taken con typo de URL
		"deck_size"        : gm.deck.size(),
		"discard_top"      : card_to_dict(top_card),
		"player_order"     : NetworkManager.get_ordered_ids(),
		"hand_sizes"       : _build_hand_sizes(gm),
	}

static func _build_hand_sizes(gm) -> Dictionary:
	var ids = NetworkManager.get_ordered_ids()
	var sizes = {}
	var hands = [gm.player_hand, gm.cpu1_hand, gm.cpu2_hand, gm.cpu3_hand]
	for i in ids.size():
		sizes[str(ids[i])] = hands[i].size()  # FIX: clave como String para consistencia en RPC
	return sizes
