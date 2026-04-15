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

# ═══════════════════════════════════════════════
#  GESTIÓN DE SERVIDOR / CLIENTE
# ═══════════════════════════════════════════════

func create_server(username: String) -> void:
	local_username = username
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MAX_PLAYERS) != OK:
		connection_failed.emit()
		return

	multiplayer.multiplayer_peer = peer
	# El host siempre es ID 1
	players[1] = {"username": username}
	
	current_room_code = RoomRegistry.host_open_room()
	if current_room_code.is_empty():
		connection_failed.emit()
		return
	server_created.emit(current_room_code)

func join_by_code(code: String, username: String) -> void:
	local_username = username
	current_room_code = code
	
	# Limpiar señales previas para evitar conexiones dobles
	if RoomRegistry.room_found.is_connected(_connect_to_ip):
		RoomRegistry.room_found.disconnect(_connect_to_ip)
	
	RoomRegistry.room_found.connect(_connect_to_ip.bind(username), CONNECT_ONE_SHOT)
	RoomRegistry.room_not_found.connect(func(): connection_failed.emit(), CONNECT_ONE_SHOT)
	RoomRegistry.client_find_room(code)

func _connect_to_ip(ip: String, username: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	else:
		connection_failed.emit()

func disconnect_game() -> void:
	if is_host(): 
		RoomRegistry.host_close_room()
	multiplayer.multiplayer_peer = null
	players.clear()
	current_room_code = ""

# ═══════════════════════════════════════════════
#  CALLBACKS DE RED
# ═══════════════════════════════════════════════

func _on_peer_connected(id: int) -> void:
	# Si yo soy el Host, le mando al nuevo la lista de todos los que ya están
	if is_host():
		for pid in players:
			_register_player.rpc_id(id, players[pid].username, pid)

func _on_connected_to_server() -> void:
	# Al conectar, le mando mi nombre al Host para que me registre
	_register_player.rpc_id(1, local_username, get_my_id())
	joined_server.emit()

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		player_disconnected.emit(id)

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

# ═══════════════════════════════════════════════
#  RPC - REGISTRO DE JUGADORES
# ═══════════════════════════════════════════════

@rpc("any_peer", "reliable")
func _register_player(username: String, id_to_register: int) -> void:
	# Registrar al jugador en el diccionario local
	players[id_to_register] = {"username": username}
	player_registered.emit(id_to_register, username)
	
	# Si soy el host y acabo de recibir un nuevo jugador, 
	# aviso a los demás clientes sobre este nuevo integrante
	if is_host():
		_register_player.rpc(username, id_to_register)

# ═══════════════════════════════════════════════
#  UTILIDADES
# ═══════════════════════════════════════════════

func is_host() -> bool:
	return multiplayer.is_server()

func get_my_id() -> int:
	return multiplayer.get_unique_id()

func get_ordered_ids() -> Array:
	var ids = players.keys()
	ids.sort()
	return ids
