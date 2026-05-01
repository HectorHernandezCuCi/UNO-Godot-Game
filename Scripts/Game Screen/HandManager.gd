extends Node2D

signal someone_won(winning_player: String)

var vertical_card_curve:   Curve = preload("res://Assets/Curves/VerticalCardCurve.tres")
var horizontal_card_curve: Curve = preload("res://Assets/Curves/HorizontalCardCurve.tres")
var card_rotate_curve:     Curve = preload("res://Assets/Curves/CardHandRotateCurve.tres")

@export_enum("Player's Hand", "Cpu1's Hand", "Cpu2's Hand", "Cpu3's Hand") var hand_id: String
@export var rotation_factor: float = 0.3
@export var spread_amount:   int   = 300

func _ready() -> void:
	var game_screen = get_tree().root.get_node("GameScreen")
	someone_won.connect(game_screen._on_someone_won)

func clear_hand() -> void:
	for child in get_children():
		remove_child(child)

func update_hand() -> void:
	clear_hand()

	# Obtener conteo según la mano
	var card_count: int
	match hand_id:
		"Player's Hand":
			card_count = GameMaster.player_hand.size()
			if   card_count < 4:  spread_amount = 50
			elif card_count < 6:  spread_amount = 100
			else:                 spread_amount = 200
		"Cpu1's Hand":
			card_count = GameMaster.cpu1_hand.size()
			if   card_count < 4:  spread_amount = 25
			elif card_count < 6:  spread_amount = 50
			else:                 spread_amount = 100
		"Cpu2's Hand":
			card_count = GameMaster.cpu2_hand.size()
			if   card_count < 4:  spread_amount = 25
			elif card_count < 6:  spread_amount = 50
			else:                 spread_amount = 100
		"Cpu3's Hand":
			card_count = GameMaster.cpu3_hand.size()
			if   card_count < 4:  spread_amount = 25
			elif card_count < 6:  spread_amount = 50
			else:                 spread_amount = 100

	# ── FIX 1: card_count == 0 ───────────────────────────────────────────────
	# En multiplayer los slots de cpu que no tienen rival asignado quedan
	# vacíos intencionalmente — NO emitir victoria, solo salir.
	if card_count == 0:
		if GameMaster.is_multiplayer:
			return   # slot vacío normal en partida de 2-3 jugadores
		# Single player: mano vacía = alguien ganó
		match hand_id:
			"Player's Hand": someone_won.emit("Jugador")
			"Cpu1's Hand":   someone_won.emit("Cpu 1")
			"Cpu2's Hand":   someone_won.emit("Cpu 2")
			"Cpu3's Hand":   someone_won.emit("Cpu 3")
		return   # salir SIN crear Tween — fix del error "Tween with no Tweeners"

	# ── FIX 2: Tween solo se crea cuando hay cartas que animar ───────────────
	var tween = create_tween().set_parallel()

	if card_count >= 2:
		# Agregar cartas al árbol
		match hand_id:
			"Player's Hand":
				for card in GameMaster.player_hand:
					add_child(card)
			"Cpu1's Hand":
				for card in GameMaster.cpu1_hand:
					add_child(card)
			"Cpu2's Hand":
				for card in GameMaster.cpu2_hand:
					add_child(card)
			"Cpu3's Hand":
				for card in GameMaster.cpu3_hand:
					add_child(card)

		# Posicionar y rotar cada carta
		for card in get_children():
			var hand_ratio     = float(card.get_index()) / float(card_count - 1)
			var local_position: Vector2
			if hand_id == "Player's Hand":
				card.rotation = card_rotate_curve.sample(hand_ratio) * rotation_factor
				local_position = Vector2(
					vertical_card_curve.sample(hand_ratio) * spread_amount,
					horizontal_card_curve.sample(hand_ratio)
				)
			else:
				local_position = Vector2(vertical_card_curve.sample(hand_ratio) * spread_amount, 0)
			tween.tween_property(card, "position", local_position, 0.5)

			if hand_id == "Player's Hand":
				card.set_meta("HoverEffect", true)
				card.set_meta("CanBePlayed", true)
				card.set_card_back(false)
			else:
				card.set_meta("HoverEffect", false)
				card.set_meta("CanBePlayed", false)
				card.set_card_back(true)

	else:  # card_count == 1
		var card: Node2D
		match hand_id:
			"Player's Hand": card = GameMaster.player_hand[0]
			"Cpu1's Hand":   card = GameMaster.cpu1_hand[0]
			"Cpu2's Hand":   card = GameMaster.cpu2_hand[0]
			"Cpu3's Hand":   card = GameMaster.cpu3_hand[0]

		var hand_ratio     = 0.5
		var local_position = Vector2(
			vertical_card_curve.sample(hand_ratio),
			vertical_card_curve.sample(hand_ratio)
		)
		tween.tween_property(card, "position", local_position, 0.5)
		card.rotation = 0

		if hand_id == "Player's Hand":
			card.set_meta("HoverEffect", true)
			card.set_meta("CanBePlayed", true)
			card.set_card_back(false)
		else:
			card.set_meta("HoverEffect", false)
			card.set_meta("CanBePlayed", false)
			card.set_card_back(true)
		add_child(card)

func can_play(play: bool = true, picker: bool = false) -> void:
	if play:
		if picker:
			for card in get_children():
				if card.can_be_played(card, false, true):
					card.get_child(0).material.set_shader_parameter("grayscale", false)
					card.set_meta("HoverEffect", true)
					card.set_meta("CanBePlayed", true)
		else:
			for card in get_children():
				card.get_child(0).material.set_shader_parameter("grayscale", false)
				card.set_meta("HoverEffect", true)
				card.set_meta("CanBePlayed", true)
	else:
		for card in get_children():
			card.get_child(0).material.set_shader_parameter("grayscale", true)
			card.set_meta("HoverEffect", false)
			card.set_meta("CanBePlayed", false)
