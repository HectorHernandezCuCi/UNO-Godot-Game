extends Node2D

@onready var cards_parent = $Cards # El nodo donde están todos tus sprites
@export var deck_position: Vector2 = Vector2(150, 150) # Posición de la pila
@export var hand_start_pos: Vector2 = Vector2(200, 550) # Posición de la mano

var deck: Array = [] # La "cola" de cartas (pila)
var hand: Array = [] # Cartas actualmente en la mano

func _ready():
	# Esperamos un instante para que todos los nodos estén listos
	await get_tree().process_frame
	setup_game()

func setup_game():
	# 1. Llenar el mazo con los hijos del nodo Cards
	deck = cards_parent.get_children()
	
	# 2. Barajar aleatoriamente
	deck.shuffle()
	
	# 3. Colocar visualmente todas las cartas en la pila
	for i in range(deck.size()):
		var card = deck[i]
		card.position = deck_position
		card.z_index = i # Las cartas de arriba tapan a las de abajo
		if "is_in_hand" in card:
			card.is_in_hand = false
	
	# 4. Repartir 7 cartas iniciales
	for i in range(7):
		draw_card_to_hand()

func draw_card_to_hand():
	if deck.size() > 0:
		var card = deck.pop_back() # Sacamos la de arriba
		hand.append(card)
		
		if "is_in_hand" in card:
			card.is_in_hand = true
		
		# Animación hacia la mano
		var tween = create_tween()
		var spacing = 70 # Espacio entre cartas en la mano
		var target_pos = hand_start_pos + Vector2(hand.size() * spacing, 0)
		
		# Movimiento suave
		tween.tween_property(card, "position", target_pos, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		card.z_index = 100 + hand.size() # Asegurar que la mano esté encima del mazo

func _input(event):
	# Detectar si hacemos click cerca de la posición de la pila
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_global_mouse_position().distance_to(deck_position) < 80:
			draw_card_to_hand()
