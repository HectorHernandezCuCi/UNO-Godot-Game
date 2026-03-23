extends Control

# ── Nodos ───────────────────────────────────────────────────────────────────
@onready var start_button       = $HBoxContainer/LeftPanel/VBoxContainer/StartButton
@onready var leave_button       = $HBoxContainer/LeftPanel/VBoxContainer/LeaveButton
@onready var player_count_label = $HBoxContainer/RightPanel/VBoxContainer/PlayerCountLabel
@onready var status_label       = $HBoxContainer/RightPanel/VBoxContainer/StatusLabel
@onready var ip_value_label     = $HBoxContainer/RightPanel/VBoxContainer/IPValueLabel

@onready var player_slots = [
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot0,
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot1,
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot2,
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot3,
]

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	start_button.visible = NetworkManager.is_host()
	NetworkManager.player_registered.connect(_on_player_update)
	NetworkManager.player_disconnected.connect(_on_player_update)
	GameMaster.game_started_multiplayer.connect(_on_game_started)
	if NetworkManager.is_host():
		ip_value_label.text = _get_local_ip() + " : 7777"
	else:
		ip_value_label.text = "—"
	_refresh_ui()

# ── Refresca toda la UI ─────────────────────────────────────────────────────

func _refresh_ui(_a = null, _b = null) -> void:
	var ids = NetworkManager.get_ordered_ids()
	var count = ids.size()

	player_count_label.text = "%d / %d jugadores" % [count, NetworkManager.MAX_PLAYERS]
	status_label.text = "Esperando jugadores..." if count < 2 else "Listo para iniciar"
	start_button.disabled = count < 2

	for i in player_slots.size():
		var slot = player_slots[i]
		var name_label = slot.get_node_or_null("NameLabel")  # ← get_node_or_null evita crash
		var tag_label  = slot.get_node_or_null("TagLabel")
		var badge      = slot.get_node_or_null("Badge")

		# Saltar si los nodos no existen
		if not name_label or not tag_label or not badge:
			continue

		if i < ids.size():
			var pid = ids[i]
			# Verificar que el pid existe en el diccionario antes de acceder
			if not NetworkManager.players.has(pid):
				continue
			var username     = NetworkManager.players[pid].username
			var is_me        = pid == NetworkManager.get_my_id()
			var is_host_slot = pid == 1

			name_label.text = username + (" (tú)" if is_me else "")
			tag_label.text  = "Host" if is_host_slot else "Conectado"
			badge.text      = "HOST" if is_host_slot else "LISTO"
			badge.visible   = true
			slot.modulate   = Color(1, 1, 1, 1)
		else:
			name_label.text = "Esperando..."
			tag_label.text  = ""
			badge.visible   = false
			slot.modulate   = Color(1, 1, 1, 0.4)

# ── Botones ──────────────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	if NetworkManager.is_host() and NetworkManager.players.size() >= 2:
		GameMaster.start_multiplayer_game()

func _on_leave_pressed() -> void:
	NetworkManager.disconnect_game()
	SceneManager.go_to_menu()

# ── Ir a la partida ──────────────────────────────────────────────────────────

func _on_game_started() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game/GameScreen.tscn")

# ── Señal cuando se actualiza la lista ───────────────────────────────────────

func _on_player_update(_a = null, _b = null) -> void:
	_refresh_ui()

# ── Obtener IP local ─────────────────────────────────────────────────────────

func _get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.") or addr.begins_with("10."):
			return addr
	return "127.0.0.1"
