extends Node

const PORT = 7777
const MAX_PLAYERS = 5

var players: Dictionary = {} #peer_id -> {"username": String }
var local_username: String = "Jugador"

signal server_created
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
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("Error creando servidor: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	#Registrar al host
	players[1] = {"username": username}
	emit_signal("server_created")

#========== Funciones de Crear y Unirse =============
func join_server(ip: String, username: String) -> void:
	local_username = username
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		emit_signal("connection_failed")
		return
	multiplayer.multiplayer_peer = peer
	
func disconnect_game() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()

func is_host() -> bool:
	return multiplayer.is_server()
	
func get_my_id() -> int:
	return multiplayer.get_unique_id()
func get_ordered_ids() -> Array:
	var ids = players.keys()
	ids.sort()
	return ids

#============ Callbacks ===============
func _on_peer_connected(peer_id: int) -> void:
	#Enviarle nuestra informacion
	if is_host():
		_register_player.rpc_id(peer_id, local_username)

func _on_peer_disconnected(peer_id: int) -> void:
	players.erase(peer_id)
	emit_signal("player_disconnected", peer_id)

func _on_connected_to_server() -> void:
	_register_player.rpc_id(1, local_username)
	emit_signal("joined_server")

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed")

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	emit_signal("server_disconnected")

# ====== RPCs ========
@rpc("any_peer", "reliable")
func _register_player(username: String) -> void:
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = 1
	players[sender] = {"username": username}
	emit_signal("player_registered", sender, username)
	print("PLAYERS DICT ahora: ", players)
	
	#El host reenvia la lista completa al nuevo jugador
	if is_host() and sender != 1:
		_sync_player_list.rpc_id(sender, players)

@rpc("authority", "reliable")
func _sync_player_list(player_dict: Dictionary) -> void:
	for pid in player_dict:
		if not players.has(pid):
			players[pid] = player_dict[pid]
			emit_signal("player_registered", pid, player_dict[pid].username)
