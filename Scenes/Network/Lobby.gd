extends Control

@onready var start_button       = $HBoxContainer/LeftPanel/VBoxContainer/StartButton
@onready var leave_button       = $HBoxContainer/LeftPanel/VBoxContainer/LeaveButton
@onready var player_count_label = $HBoxContainer/RightPanel/VBoxContainer/PlayerCountLabel
@onready var status_label       = $HBoxContainer/RightPanel/VBoxContainer/StatusLabel
@onready var ip_value_label      = $HBoxContainer/RightPanel/VBoxContainer/IPValueLabel

@onready var player_slots = [
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot0,
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot1,
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot2,
	$HBoxContainer/LeftPanel/VBoxContainer/PlayerSlot3,
]

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	
	NetworkManager.player_registered.connect(_on_player_update)
	NetworkManager.player_disconnected.connect(_on_player_update)
	# Nota: GameMaster.game_started_multiplayer ya no es estrictamente necesario 
	# si el cambio de escena lo hace NetworkManager, pero lo dejamos por si acaso.
	
	if NetworkManager.current_room_code != "":
		ip_value_label.text = "CÓDIGO: " + NetworkManager.current_room_code
	else:
		ip_value_label.text = "Error al generar código"

	start_button.visible = NetworkManager.is_host()
	_refresh_ui()

func _refresh_ui(_a = null, _b = null) -> void:
	var ids = NetworkManager.get_ordered_ids()
	var count = ids.size()

	player_count_label.text = "%d / %d jugadores" % [count, NetworkManager.MAX_PLAYERS]
	status_label.text = "Esperando..." if count < 2 else "Listo para iniciar"
	start_button.disabled = count < 2

	for i in player_slots.size():
		var slot = player_slots[i]
		if i < ids.size():
			var pid = ids[i]
			if NetworkManager.players.has(pid):
				var username = NetworkManager.players[pid].username
				slot.get_node("NameLabel").text = username + (" (tú)" if pid == NetworkManager.get_my_id() else "")
				slot.get_node("Badge").visible = true
				slot.modulate = Color.WHITE
		else:
			slot.get_node("NameLabel").text = "Esperando..."
			slot.get_node("Badge").visible = false
			slot.modulate = Color(1, 1, 1, 0.4)

func _on_start_pressed() -> void:
	if NetworkManager.is_host():
		# Llamamos a la nueva función de red que cambia la escena para todos
		NetworkManager.host_start_game()

func _on_leave_pressed() -> void:
	NetworkManager.disconnect_game()
	SceneManager.go_to_menu()

func _on_player_update(_a=null, _b=null) -> void:
	_refresh_ui()
