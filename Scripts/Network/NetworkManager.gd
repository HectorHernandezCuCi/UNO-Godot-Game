extends Node

const PORT = 7777
const MAX_PLAYERS = 5

var players: Dictionary = {}
var local_username: String = "Jugador"
var current_room_code: String = ""

signal server_created(code: String)
signal joined_server
signal connection_failed
signal server_disconnected
signal player_registered(peer_id: int, username: String)
signal player_disconnected(peer_id: int)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_server(username: String) -> void:
	local_username = username
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MAX_PLAYERS) != OK:
		connection_failed.emit()
		return

	multiplayer.multiplayer_peer = peer
	players[1] = {"username": username}
	
	current_room_code = RoomRegistry.host_open_room()
	if current_room_code.is_empty():
		connection_failed.emit()
		return
	server_created.emit(current_room_code)

func join_by_code(code: String, username: String) -> void:
	local_username = username
	current_room_code = code
	RoomRegistry.room_found.connect(_connect_to_ip.bind(username), CONNECT_ONE_SHOT)
	RoomRegistry.room_not_found.connect(func(): connection_failed.emit(), CONNECT_ONE_SHOT)
	RoomRegistry.client_find_room(code)

func _connect_to_ip(ip: String, username: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, PORT) == OK:
		multiplayer.multiplayer_peer = peer

func disconnect_game() -> void:
	if is_host(): RoomRegistry.host_close_room()
	multiplayer.multiplayer_peer = null
	players.clear()
	current_room_code = ""

func is_host() -> bool: return multiplayer.is_server()
func get_my_id() -> int: return multiplayer.get_unique_id()
func get_ordered_ids() -> Array:
	var ids = players.keys()
	ids.sort()
	return ids

# --- Callbacks y RPC ---
func _on_peer_connected(id: int) -> void: pass
func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	_register_player.rpc_id(1, local_username)
	joined_server.emit()

func _on_connection_failed() -> void: connection_failed.emit()
func _on_server_disconnected() -> void: server_disconnected.emit()

@rpc("any_peer", "reliable")
func _register_player(username: String) -> void:
	var sender = multiplayer.get_remote_sender_id()
	players[sender] = {"username": username}
	player_registered.emit(sender, username)
	if is_host():
		for pid in players:
			_register_player.rpc_id(sender, players[pid].username)
