extends Node2D

signal someone_won(winning_player: String)

@onready var player_hand      = $PlayerHand/HandManager
@onready var discard_pile     = $DiscardPile
@onready var cpu1_hand        = $Cpu1Hand/HandManager
@onready var cpu2_hand        = $Cpu2Hand/HandManager
@onready var cpu3_hand        = $Cpu3Hand/HandManager
@onready var game_hud         = $GameHud
@onready var color_selector   = $ColorSelector
@onready var card_shuffle_sfx = $CardShuffleSfx
@onready var game_over_screen = $GameOverScreen
@onready var pause_menu       = $PauseLayer/PauseMenu

var game_ended: bool = false

func _ready() -> void:
	GameMaster.connect("player_hand_changed",  _on_GameMaster_player_hand_changed)
	GameMaster.connect("discard_pile_changed", _on_GameMaster_discard_pile_changed)
	GameMaster.connect("cpu1_hand_changed",    _on_GameMaster_cpu1_hand_changed)
	GameMaster.connect("cpu2_hand_changed",    _on_GameMaster_cpu2_hand_changed)
	GameMaster.connect("cpu3_hand_changed",    _on_GameMaster_cpu3_hand_changed)
	GameMaster.connect("new_round",            _on_GameMaster_new_round)
	pause_menu.connect("resumed", _on_pause_menu_resumed)
	pause_menu.hide()

	if GameMaster.is_multiplayer:
		GameMaster.connect("multiplayer_state_updated", _on_multiplayer_state_updated)
		GameMaster.connect("game_over",                 _on_multiplayer_game_over)
		_init_multiplayer_ui()

		# Avisarle al host que esta escena ya cargó.
		# El host recibe confirm_scene_ready() por RPC.
		# El host mismo lo llama directo (no puede hacerse rpc_id a sí mismo).
		if NetworkManager.is_host():
			NetworkManager.confirm_scene_ready()
		else:
			NetworkManager.confirm_scene_ready.rpc_id(1)
	else:
		init_game()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	var is_paused = not get_tree().paused
	SceneManager.pause_game(is_paused)
	if is_paused: pause_menu.show()
	else:         pause_menu.hide()

# ── Single Player ─────────────────────────────────────────────────────────────

func init_game() -> void:
	game_ended = false
	card_shuffle_sfx.play()
	GameMaster.init_deck()
	GameMaster.player_hand.clear()
	GameMaster.cpu1_hand.clear()
	GameMaster.cpu2_hand.clear()
	GameMaster.cpu3_hand.clear()
	GameMaster.discard_pile.clear()
	discard_pile.clear_discard_pile()
	GameMaster.current_player = 0
	game_hud.change_pointer_position(0)
	GameMaster.draw_to_player_hand(7)
	GameMaster.draw_to_cpu_hand(7, 1)
	GameMaster.draw_to_cpu_hand(7, 2)
	GameMaster.draw_to_cpu_hand(7, 3)
	color_selector.hide()
	game_over_screen.hide()
	pause_menu.hide()
	GameMaster.draw_to_discard(1)
	if GameMaster.get_top_discard_card().get_meta("Color") == "Wild":
		GameMaster.current_color = GameMaster.color_map.keys().pick_random()
	game_hud.change_pointer_color(GameMaster.color_map[GameMaster.current_color], 0.5)
	game_hud.change_take_card_button_color(GameMaster.color_map[GameMaster.current_color], 0.5)
	game_hud.change_take_card_button_number(1)

func _on_GameMaster_player_hand_changed() -> void:
	player_hand.update_hand()

func _on_GameMaster_cpu1_hand_changed() -> void:
	cpu1_hand.update_hand()

func _on_GameMaster_cpu2_hand_changed() -> void:
	cpu2_hand.update_hand()

func _on_GameMaster_cpu3_hand_changed() -> void:
	cpu3_hand.update_hand()

func _on_GameMaster_discard_pile_changed() -> void:
	discard_pile.update_discard_pile()

func _on_GameMaster_new_round() -> void:
	if GameMaster.is_multiplayer: return
	if game_ended: return

	match GameMaster.current_player:
		0:
			if GameMaster.cards_to_be_taken > 0:
				game_hud.change_take_card_button_number(1, 0.5)
				game_hud.change_pointer_position(0.0, 0.75)
				game_hud.change_take_card_button_number(GameMaster.cards_to_be_taken, 0.5)
				player_hand.can_play(true, true)
				await game_hud.take_card_button_clicked
				player_hand.can_play()
			else:
				game_hud.change_take_card_button_number(1, 0.5)
				game_hud.change_pointer_position(0.0, 0.75)
				game_hud.change_take_card_button_color(GameMaster.color_map[GameMaster.current_color], 0.5)
				player_hand.can_play()
		1:
			game_hud.change_pointer_position(0.25, 0.75)
			game_hud.change_take_card_button_color(Color.WHITE, 0.5)
			player_hand.can_play(false)
			GameMaster.cpu_play(1)
		2:
			game_hud.change_pointer_position(0.5, 0.75)
			game_hud.change_take_card_button_color(Color.WHITE, 0.5)
			player_hand.can_play(false)
			GameMaster.cpu_play(2)
		3:
			game_hud.change_pointer_position(0.75, 0.75)
			game_hud.change_take_card_button_color(Color.WHITE, 0.5)
			player_hand.can_play(false)
			GameMaster.cpu_play(3)

func _on_card_played(card_color: String, card_value: String) -> void:
	if GameMaster.is_multiplayer: return

	match card_color:
		"Blue", "Green", "Red", "Yellow":
			GameMaster.current_color = card_color
		"Wild":
			if GameMaster.current_player == 0:
				color_selector.show()
				await color_selector.color_selected
			else:
				GameMaster.current_color = GameMaster.color_map.keys().pick_random()

	game_hud.change_pointer_color(GameMaster.color_map[GameMaster.current_color], 0.5)
	match card_value:
		"Picker":   GameMaster.cards_to_be_taken += 2
		"PickFour": GameMaster.cards_to_be_taken += 4
	GameMaster.next_turn(card_value == "Skip", card_value == "Reverse")

func _on_someone_won(winning_player: String) -> void:
	game_ended = true
	game_over_screen.show()
	game_over_screen.change_winning_player(winning_player, 1.0)

func _on_game_over_screen_restart_pressed() -> void:
	if GameMaster.is_multiplayer:
		NetworkManager.disconnect_game()
		SceneManager.go_to_menu()
		return
	init_game()

func _on_pause_menu_resumed() -> void:
	pause_menu.hide()

# ── Multijugador ──────────────────────────────────────────────────────────────

func _init_multiplayer_ui() -> void:
	game_ended = false
	color_selector.hide()
	game_over_screen.hide()
	pause_menu.hide()
	card_shuffle_sfx.play()

# Llamado desde CardLogic cuando el jugador toca una Wild
func _on_card_color_pick_needed(card_color: String, card_value: String) -> void:
	color_selector.set_pending_wild(card_color, card_value)
	color_selector.show()
	await color_selector.color_selected

# Se dispara cada vez que el host sincroniza el estado
func _on_multiplayer_state_updated() -> void:
	if game_ended: return

	game_hud.change_pointer_color(GameMaster.color_map[GameMaster.current_color], 0.5)

	var visual_idx = _peer_to_visual_index(GameMaster._get_current_peer_id())
	game_hud.change_pointer_position(_visual_to_pointer(visual_idx), 0.75)

	if GameMaster._is_my_turn():
		if GameMaster.cards_to_be_taken > 0:
			game_hud.change_take_card_button_number(GameMaster.cards_to_be_taken, 0.5)
			player_hand.can_play(true, true)
			await game_hud.take_card_button_clicked
			player_hand.can_play()
		else:
			game_hud.change_take_card_button_number(1, 0.5)
			game_hud.change_take_card_button_color(GameMaster.color_map[GameMaster.current_color], 0.5)
			player_hand.can_play()
	else:
		game_hud.change_take_card_button_color(Color.WHITE, 0.5)
		player_hand.can_play(false)

func _peer_to_visual_index(peer_id: int) -> int:
	var ordered    = NetworkManager.get_ordered_ids()
	var my_index   = ordered.find(NetworkManager.get_my_id())
	var peer_index = ordered.find(peer_id)
	if peer_index == -1 or my_index == -1: return 0
	return (peer_index - my_index + ordered.size()) % ordered.size()

func _visual_to_pointer(visual_index: int) -> float:
	match visual_index:
		0: return 0.0
		1: return 0.25
		2: return 0.5
		3: return 0.75
	return 0.0

func _on_multiplayer_game_over(winner_peer_id: int) -> void:
	game_ended = true
	var winner_name = NetworkManager.players.get(winner_peer_id, {"username": "Jugador"}).username
	game_over_screen.show()
	game_over_screen.change_winning_player(winner_name, 1.0)
